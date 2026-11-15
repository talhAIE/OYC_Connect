import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

abstract class RecoverySessionStore {
  Future<bool> read();
  Future<bool> readReady();
  Future<List<String>> readHandledLinks();
  Future<void> rememberLink(String fingerprint);
  Future<void> write(bool active, {bool ready = false});
}

class PreferencesRecoverySessionStore implements RecoverySessionStore {
  static const _key = 'oyc.password_recovery_active';
  static const _readyKey = 'oyc.password_recovery_ready';
  static const _linksKey = 'oyc.password_recovery_handled_links';

  @override
  Future<bool> read() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<bool> readReady() async =>
      (await SharedPreferences.getInstance()).getBool(_readyKey) ?? false;

  @override
  Future<List<String>> readHandledLinks() async =>
      (await SharedPreferences.getInstance()).getStringList(_linksKey) ?? [];

  @override
  Future<void> rememberLink(String fingerprint) async {
    final preferences = await SharedPreferences.getInstance();
    final links = preferences.getStringList(_linksKey) ?? [];
    links.remove(fingerprint);
    links.add(fingerprint);
    if (!await preferences.setStringList(
      _linksKey,
      links.length > 12 ? links.sublist(links.length - 12) : links,
    )) {
      throw StateError('Could not save password recovery link state.');
    }
  }

  @override
  Future<void> write(bool active, {bool ready = false}) async {
    final preferences = await SharedPreferences.getInstance();
    // Clear readiness before accepting a new callback. A process interrupted
    // during exchange must not reuse an unrelated pre-existing login.
    if (!await preferences.setBool(_readyKey, active && ready)) {
      throw StateError('Could not save password recovery state.');
    }
    if (!await preferences.setBool(_key, active)) {
      throw StateError('Could not save password recovery state.');
    }
  }
}

/// Owns recovery links and isolates their temporary session from normal login.
/// Supabase's automatic link exchange must be disabled when using this owner.
class PasswordRecoveryController extends ChangeNotifier {
  PasswordRecoveryController({
    required this.repository,
    required this.store,
    required this.initialLink,
    required this.links,
  });

  final AuthRepository repository;
  final RecoverySessionStore store;
  final Future<Uri?> Function() initialLink;
  final Stream<Uri> links;
  StreamSubscription<Uri>? _linksSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  final Set<String> _handledLinks = {};
  final List<Uri> _launchLinks = [];
  bool _collectingLaunchLinks = true;
  Future<void> _work = Future.value();
  Future<void>? _initialization;
  bool _disposed = false;
  int _pendingLinks = 0;

  bool initializing = true;
  bool active = false;
  bool busy = false;
  bool ready = false;
  String? error;

  static bool isRecoveryLink(Uri uri) =>
      uri.scheme == 'oycconnect' &&
      (uri.host == 'reset-password' ||
          (uri.host.isEmpty && uri.path == '/reset-password'));

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    // Subscribe before requesting the launch link. Some platforms emit it on
    // both channels; handleLink consumes each one-time code only once.
    _linksSubscription = links.listen((uri) {
      if (_collectingLaunchLinks) {
        _launchLinks.add(uri);
      } else {
        unawaited(handleLink(uri));
      }
    }, onError: (Object _) {});
    _authSubscription = repository.authStateChanges.listen((state) {
      if (!active && state.event == AuthChangeEvent.signedIn) error = null;
      _changed();
    }, onError: (Object _) => _changed());
    try {
      final abandonedRecovery = await store.read();
      _handledLinks.addAll(await store.readHandledLinks());
      Uri? uri;
      try {
        uri = await initialLink();
      } catch (_) {
        // A platform launch-link failure is not a password-reset request.
      }
      if (uri != null) _launchLinks.add(uri);

      // Upgrade cleanup: older builds persisted only a recovery flag, without
      // tracking consumed URLs. Do not exchange their retained launch intent
      // again or turn an abandoned recovery session into a normal login.
      if (abandonedRecovery && _handledLinks.isEmpty) {
        for (final link in _launchLinks.where(isRecoveryLink).toList()) {
          final fingerprint = _fingerprint(link);
          await store.rememberLink(fingerprint);
          _handledLinks.add(fingerprint);
        }
      }
      final freshLinks = _launchLinks
          .where(isRecoveryLink)
          .where((link) => !_handledLinks.contains(_fingerprint(link)))
          .toList();
      _launchLinks.clear();
      if (abandonedRecovery && freshLinks.isEmpty) {
        await _endSession();
      }
      _collectingLaunchLinks = false;
      // A genuinely new link can arrive while abandoned-session cleanup is
      // awaiting native/storage work. Do not lose that callback.
      freshLinks.addAll(_launchLinks.where(isRecoveryLink));
      _launchLinks.clear();
      for (final link in freshLinks) {
        await handleLink(link);
      }
      await _work;
    } catch (_) {
      // If persisted recovery state is unreadable, discard the local session
      // rather than manufacture an expired reset page on every normal launch.
      try {
        await _endSession();
      } catch (_) {
        active = true;
        error = 'Could not close the reset session. Please try Back again.';
      }
    } finally {
      _collectingLaunchLinks = false;
      initializing = false;
      _changed();
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final task = _work.then((_) => action());
    // Keep cancellation available even if a previous operation failed.
    _work = task.catchError((Object _) {});
    return task;
  }

  Future<void> handleLink(Uri uri) {
    if (!isRecoveryLink(uri)) return _work;
    final fingerprint = _fingerprint(uri);
    if (!_handledLinks.add(fingerprint)) return _work;
    _pendingLinks++;
    // Lock routes BEFORE exchange emits signedIn/passwordRecovery, including
    // callbacks without type=recovery and PKCE callbacks.
    active = true;
    ready = false;
    busy = true;
    error = null;
    _changed();
    return _enqueue(() async {
      var rejectedAndClosed = false;
      error = null;
      try {
        // Persist before exchange: restarting the app must not turn a recovery
        // session into an ordinary authenticated dashboard session.
        await store.write(true);
        // Persist only a hash, never a second copy of callback tokens. Both
        // successful and rejected one-time links must not replay on restart.
        await store.rememberLink(fingerprint);
        await repository.recoverSessionFromUrl(uri);
        if (repository.currentUser == null)
          throw StateError('No recovery session');
        await store.write(true, ready: true);
        ready = _pendingLinks == 1;
      } catch (_) {
        ready = false;
        try {
          await _endSession();
          rejectedAndClosed = true;
          error =
              'This reset link has expired or is invalid. Request a new link.';
        } catch (_) {
          error = 'Could not close the reset session. Please try Back again.';
        }
      } finally {
        _pendingLinks--;
        if (rejectedAndClosed) active = _pendingLinks > 0;
        busy = _pendingLinks > 0;
        _changed();
      }
    });
  }

  String _fingerprint(Uri uri) =>
      sha256.convert(utf8.encode(uri.toString())).toString();

  Future<bool> complete(String password) async {
    if (!active || !ready || busy) return false;
    busy = true;
    error = null;
    _changed();
    var completed = false;
    await _enqueue(() async {
      try {
        await repository.updatePassword(password);
        await _endSession();
        completed = true;
      } catch (_) {
        error = 'Could not finish the password reset. Please try again.';
      } finally {
        busy = _pendingLinks > 0;
        _changed();
      }
    });
    return completed;
  }

  Future<bool> cancel() async {
    var cancelled = false;
    // Queue behind any in-flight exchange/update so it cannot sign in again
    // after Back has discarded the temporary session.
    await _enqueue(() async {
      busy = true;
      _changed();
      try {
        await _endSession();
        cancelled = true;
      } catch (_) {
        error = 'Could not close the reset session. Please try Back again.';
      } finally {
        busy = _pendingLinks > 0;
        _changed();
      }
    });
    return cancelled;
  }

  Future<void> _endSession() async {
    await repository.signOutRecoverySession();
    // Do not release the routing guard until the temporary session is gone.
    await store.write(false);
    active = _pendingLinks > 0;
    ready = false;
    error = null;
  }

  /// Shared by the app router and regression tests. No side-effect navigation.
  String? redirect(String path, {required bool isLoggedIn}) {
    if (initializing) return path == '/' ? null : '/';
    if (active) {
      return path == '/set-new-password' ? null : '/set-new-password';
    }
    if (path == '/set-new-password') return '/login';
    final publicRoute =
        path == '/login' || path == '/register' || path == '/forgot-password';
    if (!isLoggedIn && !publicRoute) return '/login';
    if (isLoggedIn &&
        (path == '/' || path == '/login' || path == '/register')) {
      return '/home';
    }
    return null;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_linksSubscription?.cancel());
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
