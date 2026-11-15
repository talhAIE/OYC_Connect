import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

abstract class PushGateway {
  void initialize(
    String appId,
    VoidCallback changed,
    void Function(Map<String, dynamic>) tapped,
    bool Function() canDisplay,
  );
  Future<void> login(String id);
  Future<void> logout();
  Future<void> optIn();
  Future<void> optOut();
  Future<bool> canRequest();
  Future<bool> requestPermission(bool fallbackToSettings);
  bool get permission;
  bool get optedIn;
  bool get hasToken;
  String? get subscriptionId;
  void dispose();
}

class OneSignalPushGateway implements PushGateway {
  OnPushSubscriptionChangeObserver? _subscriptionObserver;
  OnNotificationPermissionChangeObserver? _permissionObserver;
  OnNotificationClickListener? _clickListener;
  OnNotificationWillDisplayListener? _foregroundListener;
  @override
  void initialize(
    String appId,
    VoidCallback changed,
    void Function(Map<String, dynamic>) tapped,
    bool Function() canDisplay,
  ) {
    OneSignal.initialize(appId);
    _subscriptionObserver = (_) => changed();
    _permissionObserver = (_) => changed();
    _clickListener = (event) => tapped({
      ...?event.notification.additionalData,
      // Older server pushes had no type. Keep their visible title available
      // for the narrowly scoped legacy prayer fallback.
      '_notificationTitle': event.notification.title,
    });
    _foregroundListener = (event) {
      if (!canDisplay()) event.preventDefault();
    };
    OneSignal.User.pushSubscription.addObserver(_subscriptionObserver!);
    OneSignal.Notifications.addPermissionObserver(_permissionObserver!);
    OneSignal.Notifications.addClickListener(_clickListener!);
    OneSignal.Notifications.addForegroundWillDisplayListener(
      _foregroundListener!,
    );
  }

  @override
  Future<void> login(String id) => OneSignal.login(id);
  @override
  Future<void> logout() => OneSignal.logout();
  @override
  Future<void> optIn() => OneSignal.User.pushSubscription.optIn();
  @override
  Future<void> optOut() => OneSignal.User.pushSubscription.optOut();
  @override
  Future<bool> canRequest() => OneSignal.Notifications.canRequest();
  @override
  Future<bool> requestPermission(bool fallbackToSettings) =>
      OneSignal.Notifications.requestPermission(fallbackToSettings);
  @override
  bool get permission => OneSignal.Notifications.permission;
  @override
  bool get optedIn => OneSignal.User.pushSubscription.optedIn ?? false;
  @override
  bool get hasToken =>
      OneSignal.User.pushSubscription.token?.isNotEmpty ?? false;
  @override
  String? get subscriptionId => OneSignal.User.pushSubscription.id;
  @override
  void dispose() {
    if (_subscriptionObserver != null)
      OneSignal.User.pushSubscription.removeObserver(_subscriptionObserver!);
    if (_permissionObserver != null)
      OneSignal.Notifications.removePermissionObserver(_permissionObserver!);
    if (_clickListener != null)
      OneSignal.Notifications.removeClickListener(_clickListener!);
    if (_foregroundListener != null)
      OneSignal.Notifications.removeForegroundWillDisplayListener(
        _foregroundListener!,
      );
  }
}

final pushNotifications = PushNotificationService(
  OneSignalPushGateway(),
  supported:
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS),
);
final pushNotificationServiceProvider =
    ChangeNotifierProvider<PushNotificationService>((ref) => pushNotifications);

class PushNotificationService extends ChangeNotifier {
  PushNotificationService(this.gateway, {required this.supported});
  final PushGateway gateway;
  final bool supported;
  bool initialized = false;
  bool preferenceEnabled = false;
  String? _userId;
  bool _sessionBound = false;
  bool _promptAttempted = false;
  int _revision = 0;
  Future<void> _pending = Future.value();
  String? lastError;
  void Function(Map<String, dynamic>)? _tapHandler;
  Map<String, dynamic>? _pendingTap;

  void initialize(String appId) {
    if (!supported || initialized || appId.isEmpty) return;
    gateway.initialize(appId, notifyListeners, (data) {
      if (_tapHandler == null) {
        _pendingTap = data;
      } else {
        _tapHandler!(data);
      }
    }, () => preferenceEnabled);
    initialized = true;
  }

  void setTapHandler(void Function(Map<String, dynamic>)? handler) {
    _tapHandler = handler;
    if (handler != null && _pendingTap != null) {
      final data = _pendingTap!;
      _pendingTap = null;
      handler(data);
    }
  }

  Future<void> synchronize(
    String? userId, {
    required bool? enabled,
    bool prompt = false,
  }) {
    final revision = ++_revision;
    // Profile reloads on resume are not an opt-out. Preserve a confirmed
    // preference for this account until its refreshed profile arrives.
    final effectiveEnabled =
        enabled ?? (_sessionBound && _userId == userId && preferenceEnabled);
    // Apply the user's choice immediately, even while older SDK work is pending.
    preferenceEnabled = userId != null && effectiveEnabled;
    final task = _pending.catchError((_) {}).then((_) async {
      if (!initialized || revision != _revision) return;
      try {
        if (!_sessionBound || _userId != userId) {
          if (userId == null) {
            await gateway.optOut();
            await gateway.logout();
          } else {
            await gateway.login(userId);
          }
          _userId = userId;
          _sessionBound = true;
        }
        if (revision != _revision) return;
        preferenceEnabled = userId != null && effectiveEnabled;
        if (!preferenceEnabled) {
          await gateway.optOut();
        } else {
          var allowed = gateway.permission;
          if (!allowed &&
              (prompt || (!_promptAttempted && await gateway.canRequest()))) {
            _promptAttempted = true;
            allowed = await gateway.requestPermission(prompt);
          }
          if (revision != _revision) return;
          if (allowed) {
            await gateway.optIn();
          } else if (prompt) {
            throw StateError(
              'Allow notifications in your phone settings, then try again.',
            );
          }
        }
        lastError = null;
      } catch (_) {
        lastError =
            'Could not synchronize notifications. Check your connection and phone settings.';
        rethrow;
      } finally {
        notifyListeners();
      }
    });
    _pending = task;
    return task;
  }

  String? get subscriptionId => initialized ? gateway.subscriptionId : null;
  String get status {
    if (!supported)
      return 'Push notifications are supported on Android and iPhone.';
    if (!initialized) return 'Notification configuration is missing.';
    if (lastError != null) return lastError!;
    if (_userId == null) return 'Sign in to enable notifications.';
    if (!preferenceEnabled)
      return 'Notifications are disabled in your profile.';
    if (!gateway.permission)
      return 'Notifications are blocked by your phone. Tap Enable to review permission.';
    if (!gateway.optedIn)
      return 'This device is opted out. Tap Enable to reconnect.';
    if (!gateway.hasToken || subscriptionId == null)
      return 'Device registration is pending. Check internet and FCM/APNs setup.';
    return 'This device is registered for notifications.';
  }

  @override
  void dispose() {
    gateway.dispose();
    super.dispose();
  }
}

({String location, int? tab}) notificationDestination(
  Map<String, dynamic> data,
) {
  final type = (data['type'] ?? '').toString().trim().toLowerCase();
  // Only use title inference for old untyped messages. Explicit community
  // notices may mention prayer times and must still open Notices.
  final legacyPrayer =
      type.isEmpty &&
      RegExp(
        r'\b(fajr|fajar|dhuhr|zuhr|asr|maghrib|isha|jummah|jumuah|namaz|salah|adhan|iqamah)\b',
        caseSensitive: false,
      ).hasMatch((data['_notificationTitle'] ?? '').toString());
  if (legacyPrayer) return (location: '/home', tab: null);
  return switch (type) {
    'prayer' ||
    'namaz' ||
    'salah' ||
    'jummah' ||
    'jumuah' => (location: '/home', tab: null),
    'donation' => (location: '/profile/admin/donations', tab: null),
    _ => (location: '/community?tab=notices', tab: 1),
  };
}
