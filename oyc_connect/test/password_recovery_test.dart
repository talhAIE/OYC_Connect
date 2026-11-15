import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyc_connect/core/router/router.dart';
import 'package:oyc_connect/features/auth/data/auth_repository.dart';
import 'package:oyc_connect/features/auth/data/password_recovery_controller.dart';
import 'package:oyc_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryRecoveryStore implements RecoverySessionStore {
  bool active = false;
  bool ready = false;
  final handledLinks = <String>[];

  @override
  Future<List<String>> readHandledLinks() async => [...handledLinks];

  @override
  Future<void> rememberLink(String fingerprint) async {
    handledLinks.add(fingerprint);
  }

  @override
  Future<bool> read() async => active;

  @override
  Future<bool> readReady() async => ready;

  @override
  Future<void> write(bool value, {bool ready = false}) async {
    active = value;
    this.ready = value && ready;
  }
}

class FakeRecoveryRepository extends AuthRepository {
  FakeRecoveryRepository()
    : super(SupabaseClient('https://example.com', 'public-test-key'));

  final events = StreamController<AuthState>.broadcast(sync: true);
  bool signedIn = false;
  bool invalidLink = false;
  bool updateFails = false;
  bool signOutFails = false;
  int exchanges = 0;
  int signOuts = 0;
  String? password;
  Completer<void>? exchangeGate;
  Completer<void>? signOutGate;
  void Function()? duringExchange;

  @override
  User? get currentUser => signedIn
      ? User(
          id: 'recovery-user',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-27T00:00:00Z',
        )
      : null;

  @override
  Stream<AuthState> get authStateChanges => events.stream;

  @override
  Future<void> recoverSessionFromUrl(Uri uri) async {
    exchanges++;
    await exchangeGate?.future;
    if (invalidLink) throw const AuthException('Expired');
    signedIn = true;
    // Some callbacks produce signedIn rather than passwordRecovery.
    events.add(AuthState(AuthChangeEvent.signedIn, null));
    duringExchange?.call();
  }

  @override
  Future<void> updatePassword(String value) async {
    if (updateFails) throw const AuthException('Update failed');
    password = value;
    events.add(AuthState(AuthChangeEvent.userUpdated, null));
  }

  @override
  Future<void> signOutRecoverySession() async {
    signOuts++;
    await signOutGate?.future;
    if (signOutFails) throw StateError('Session still exists');
    signedIn = false;
    events.add(AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {}
}

void main() {
  final recoveryUri = Uri.parse(
    'oycconnect://reset-password#access_token=test&refresh_token=test&type=recovery',
  );
  late FakeRecoveryRepository repository;
  late MemoryRecoveryStore store;
  late StreamController<Uri> links;
  late PasswordRecoveryController recovery;

  PasswordRecoveryController create({Future<Uri?> Function()? initialLink}) {
    return PasswordRecoveryController(
      repository: repository,
      store: store,
      initialLink: initialLink ?? () async => null,
      links: links.stream,
    );
  }

  setUp(() {
    repository = FakeRecoveryRepository();
    store = MemoryRecoveryStore();
    links = StreamController<Uri>.broadcast(sync: true);
    recovery = create();
  });

  tearDown(() async {
    recovery.dispose();
    await repository.events.close();
    await links.close();
  });

  test(
    'cold launch waits for the initial recovery link before Login',
    () async {
      final initial = Completer<Uri?>();
      recovery.dispose();
      recovery = create(initialLink: () => initial.future);
      final startup = recovery.initialize();
      expect(recovery.redirect('/login', isLoggedIn: false), '/');
      initial.complete(recoveryUri);
      await startup;
      expect(recovery.ready, isTrue);
      expect(
        recovery.redirect('/login', isLoggedIn: true),
        '/set-new-password',
      );
      expect(recovery.redirect('/set-new-password', isLoggedIn: true), isNull);
    },
  );

  test('warm link locks routes before signedIn is emitted', () async {
    await recovery.initialize();
    repository.duringExchange = () {
      expect(store.active, isTrue);
      expect(recovery.redirect('/home', isLoggedIn: true), '/set-new-password');
    };
    links.add(recoveryUri);
    await recovery.handleLink(recoveryUri);
    expect(recovery.ready, isTrue);
    expect(repository.exchanges, 1);
  });

  test(
    'initial and streamed copies exchange the one-time code only once',
    () async {
      recovery.dispose();
      recovery = create(
        initialLink: () async {
          links.add(recoveryUri);
          return recoveryUri;
        },
      );
      await recovery.initialize();
      await recovery.handleLink(recoveryUri);
      expect(repository.exchanges, 1);
      expect(recovery.ready, isTrue);
    },
  );

  test('PKCE callback without a recovery event still opens reset', () async {
    await recovery.initialize();
    await recovery.handleLink(
      Uri.parse('oycconnect://reset-password?code=test'),
    );
    expect(recovery.ready, isTrue);
    expect(recovery.redirect('/home', isLoggedIn: true), '/set-new-password');
  });

  test(
    'normal restart discards an abandoned recovery and returns to Login',
    () async {
      await recovery.initialize();
      await recovery.handleLink(recoveryUri);
      recovery.dispose();
      recovery = create();
      await recovery.initialize();
      expect(recovery.ready, isFalse);
      expect(recovery.active, isFalse);
      expect(repository.signedIn, isFalse);
      expect(store.active, isFalse);
      expect(recovery.redirect('/home', isLoggedIn: false), '/login');
    },
  );

  test('Back signs out before releasing the recovery route guard', () async {
    await recovery.initialize();
    await recovery.handleLink(recoveryUri);
    repository.signOutGate = Completer<void>();
    final cancelling = recovery.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(store.active, isTrue);
    expect(recovery.redirect('/home', isLoggedIn: true), '/set-new-password');
    repository.signOutGate!.complete();
    expect(await cancelling, isTrue);
    expect(repository.signedIn, isFalse);
    expect(store.active, isFalse);
    expect(recovery.redirect('/home', isLoggedIn: false), '/login');
  });

  test('Back during exchange waits then discards the late session', () async {
    await recovery.initialize();
    repository.exchangeGate = Completer<void>();
    final exchange = recovery.handleLink(recoveryUri);
    final cancelling = recovery.cancel();
    repository.exchangeGate!.complete();
    await exchange;
    expect(await cancelling, isTrue);
    expect(repository.signedIn, isFalse);
    expect(recovery.active, isFalse);
    expect(store.active, isFalse);
  });

  test('failed session cleanup never opens the dashboard', () async {
    await recovery.initialize();
    await recovery.handleLink(recoveryUri);
    repository.signOutFails = true;
    expect(await recovery.cancel(), isFalse);
    expect(store.active, isTrue);
    expect(recovery.redirect('/home', isLoggedIn: true), '/set-new-password');
    repository.signOutFails = false;
    expect(await recovery.cancel(), isTrue);
  });

  test(
    'successful reset updates the password then requires manual login',
    () async {
      await recovery.initialize();
      await recovery.handleLink(recoveryUri);
      expect(await recovery.complete('new-password'), isTrue);
      expect(repository.password, 'new-password');
      expect(repository.signedIn, isFalse);
      expect(store.active, isFalse);
      expect(
        recovery.redirect('/set-new-password', isLoggedIn: false),
        '/login',
      );
      expect(recovery.redirect('/home', isLoggedIn: false), '/login');
    },
  );

  test('failed password update retains recovery for retry', () async {
    await recovery.initialize();
    await recovery.handleLink(recoveryUri);
    repository.updateFails = true;
    expect(await recovery.complete('new-password'), isFalse);
    expect(recovery.active, isTrue);
    expect(recovery.ready, isTrue);
    expect(store.active, isTrue);
    expect(repository.signOuts, 0);
  });

  test(
    'expired link cannot reuse an existing login to change a password',
    () async {
      await recovery.initialize();
      repository.signedIn = true;
      repository.invalidLink = true;
      await recovery.handleLink(recoveryUri);
      expect(recovery.ready, isFalse);
      expect(recovery.error, contains('expired'));
      expect(recovery.active, isFalse);
      expect(store.active, isFalse);
      expect(repository.signedIn, isFalse);
      expect(await recovery.complete('new-password'), isFalse);
      expect(repository.password, isNull);
      expect(await recovery.cancel(), isTrue);
      expect(repository.signedIn, isFalse);
    },
  );

  test('stale recovery flag without a session is cleared on restart', () async {
    store.active = true;
    await recovery.initialize();
    expect(recovery.ready, isFalse);
    expect(recovery.error, isNull);
    expect(recovery.active, isFalse);
    expect(store.active, isFalse);
    expect(recovery.redirect('/home', isLoggedIn: false), '/login');
  });

  test(
    'interrupted or invalid exchange cannot reuse an old login after restart',
    () async {
      store.active = true;
      store.ready = false;
      repository.signedIn = true;
      await recovery.initialize();
      expect(recovery.ready, isFalse);
      expect(repository.signedIn, isFalse);
      expect(recovery.active, isFalse);
      expect(recovery.redirect('/home', isLoggedIn: false), '/login');
      expect(await recovery.complete('new-password'), isFalse);
      expect(repository.password, isNull);
    },
  );

  test('unrelated URLs cannot trigger password recovery', () async {
    await recovery.initialize();
    for (final value in [
      'oycconnect://stripe-redirect?code=test',
      'https://example.com/reset-password?code=test',
      'oycconnect://other?redirect=reset-password',
    ]) {
      await recovery.handleLink(Uri.parse(value));
    }
    expect(repository.exchanges, 0);
    expect(recovery.active, isFalse);
  });

  test('normal login and protected-route behavior is preserved', () async {
    await recovery.initialize();
    expect(recovery.redirect('/home', isLoggedIn: false), '/login');
    expect(recovery.redirect('/login', isLoggedIn: false), isNull);
    expect(recovery.redirect('/login', isLoggedIn: true), '/home');
    expect(recovery.redirect('/home', isLoggedIn: true), isNull);
    expect(recovery.redirect('/set-new-password', isLoggedIn: false), '/login');
  });

  test('restarting with a rejected launch URL does not reopen reset', () async {
    await recovery.initialize();
    repository.invalidLink = true;
    await recovery.handleLink(recoveryUri);
    expect(recovery.active, isFalse);
    recovery.dispose();
    recovery = create(initialLink: () async => recoveryUri);
    await recovery.initialize();
    expect(repository.exchanges, 1);
    expect(recovery.active, isFalse);
    expect(recovery.error, isNull);
    expect(recovery.redirect('/', isLoggedIn: false), '/login');
  });

  test(
    'old launch URL cannot interrupt normal login after a completed reset',
    () async {
      await recovery.initialize();
      await recovery.handleLink(recoveryUri);
      await recovery.complete('new-password');
      repository.signedIn = true; // A later, normal password login.
      final previousSignOuts = repository.signOuts;
      recovery.dispose();
      recovery = create(initialLink: () async => recoveryUri);
      await recovery.initialize();
      expect(repository.exchanges, 1);
      expect(repository.signOuts, previousSignOuts);
      expect(repository.signedIn, isTrue);
      expect(recovery.active, isFalse);
      expect(recovery.redirect('/', isLoggedIn: true), '/home');
    },
  );

  test(
    'cancelled launch URL is ignored on both channels after restart',
    () async {
      await recovery.initialize();
      await recovery.handleLink(recoveryUri);
      await recovery.cancel();
      recovery.dispose();
      recovery = create(
        initialLink: () async {
          links.add(recoveryUri);
          return recoveryUri;
        },
      );
      await recovery.initialize();
      expect(repository.exchanges, 1);
      expect(recovery.active, isFalse);
      expect(recovery.error, isNull);
    },
  );

  test(
    'upgrade clears the old recovery flag and stale intent from earlier builds',
    () async {
      store.active = true;
      repository.signedIn = true;
      repository.invalidLink = true;
      recovery.dispose();
      recovery = create(initialLink: () async => recoveryUri);
      await recovery.initialize();
      expect(repository.exchanges, 0);
      expect(repository.signedIn, isFalse);
      expect(store.active, isFalse);
      expect(recovery.active, isFalse);
      expect(recovery.error, isNull);
    },
  );

  test(
    'a genuinely new reset link still opens after an abandoned attempt',
    () async {
      await recovery.initialize();
      await recovery.handleLink(recoveryUri);
      recovery.dispose();
      recovery = create(
        initialLink: () async =>
            Uri.parse('oycconnect://reset-password?code=new-code'),
      );
      await recovery.initialize();
      expect(repository.exchanges, 2);
      expect(recovery.active, isTrue);
      expect(recovery.ready, isTrue);
      expect(recovery.error, isNull);
    },
  );

  test(
    'new link arriving during abandoned-session cleanup is not lost',
    () async {
      store.active = true;
      repository.signOutGate = Completer<void>();
      final startup = recovery.initialize();
      await Future<void>.delayed(Duration.zero);
      links.add(recoveryUri);
      repository.signOutGate!.complete();
      await startup;
      expect(repository.exchanges, 1);
      expect(recovery.ready, isTrue);
    },
  );

  test(
    'platform launch-link error does not manufacture recovery or sign out a normal user',
    () async {
      repository.signedIn = true;
      recovery.dispose();
      recovery = create(
        initialLink: () async => throw StateError('Native link unavailable'),
      );
      await recovery.initialize();
      expect(recovery.active, isFalse);
      expect(repository.signedIn, isTrue);
      expect(repository.signOuts, 0);
      expect(recovery.redirect('/', isLoggedIn: true), '/home');
    },
  );

  test('recovery marker survives a new preference-store instance', () async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesRecoverySessionStore().write(true, ready: true);
    expect(await PreferencesRecoverySessionStore().read(), isTrue);
    expect(await PreferencesRecoverySessionStore().readReady(), isTrue);
    await PreferencesRecoverySessionStore().write(true);
    expect(await PreferencesRecoverySessionStore().readReady(), isFalse);
    await PreferencesRecoverySessionStore().write(false);
    expect(await PreferencesRecoverySessionStore().read(), isFalse);
    await PreferencesRecoverySessionStore().rememberLink('fingerprint-only');
    expect(await PreferencesRecoverySessionStore().readHandledLinks(), [
      'fingerprint-only',
    ]);
  });

  Future<ProviderContainer> openRouter(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        passwordRecoveryProvider.overrideWith((ref) => recovery),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(goRouterProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<ProviderContainer> openResetPage(WidgetTester tester) async {
    await tester.runAsync(() async {
      await recovery.initialize();
      await recovery.handleLink(recoveryUri);
    });
    final container = await openRouter(tester);
    expect(find.text('Set New Password'), findsOneWidget);
    return container;
  }

  testWidgets(
    'upgrading with the stale saved flag opens Login, not the reset page',
    (tester) async {
      store.active = true;
      repository.signedIn = true;
      repository.invalidLink = true;
      await tester.runAsync(() async {
        recovery.dispose();
        recovery = create(initialLink: () async => recoveryUri);
        await recovery.initialize();
      });
      final container = await openRouter(tester);
      expect(
        container
            .read(goRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/login',
      );
      expect(find.text('Set New Password'), findsNothing);
      expect(repository.exchanges, 0);
    },
  );

  testWidgets('a newly expired link returns to Login with a useful message', (
    tester,
  ) async {
    repository.invalidLink = true;
    await tester.runAsync(() async {
      recovery.dispose();
      recovery = create(initialLink: () async => recoveryUri);
      await recovery.initialize();
    });
    final container = await openRouter(tester);
    expect(
      container.read(goRouterProvider).routeInformationProvider.value.uri.path,
      '/login',
    );
    expect(find.text('Set New Password'), findsNothing);
    expect(find.textContaining('expired or is invalid'), findsOneWidget);
    expect(store.active, isFalse);
  });

  testWidgets('toolbar Back signs out and replaces reset with Login', (
    tester,
  ) async {
    final container = await openResetPage(tester);
    await tester.tap(find.byTooltip('Cancel password reset'));
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(repository.signedIn, isFalse);
    expect(
      container.read(goRouterProvider).routeInformationProvider.value.uri.path,
      '/login',
    );
    expect(find.text('Set New Password'), findsNothing);
  });

  testWidgets('system Back signs out instead of popping into the app', (
    tester,
  ) async {
    final container = await openResetPage(tester);
    await tester.binding.handlePopRoute();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(repository.signedIn, isFalse);
    expect(
      container.read(goRouterProvider).routeInformationProvider.value.uri.path,
      '/login',
    );
  });

  testWidgets('unrelated auth-controller success cannot dismiss recovery', (
    tester,
  ) async {
    final container = await openResetPage(tester);
    await container
        .read(authControllerProvider.notifier)
        .requestPasswordReset('member@example.com');
    await tester.pumpAndSettle();
    expect(find.text('Set New Password'), findsOneWidget);
    expect(repository.signedIn, isTrue);
    expect(recovery.active, isTrue);
  });

  testWidgets('submitting the form signs out and returns to Login', (
    tester,
  ) async {
    final container = await openResetPage(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'new-password');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.ensureVisible(find.text('Update Password'));
    await tester.tap(find.text('Update Password'));
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(repository.password, 'new-password');
    expect(repository.signedIn, isFalse);
    expect(
      container.read(goRouterProvider).routeInformationProvider.value.uri.path,
      '/login',
    );
  });
}
