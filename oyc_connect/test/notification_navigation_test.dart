import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyc_connect/core/notifications/notification_navigation.dart';
import 'package:oyc_connect/core/router/router.dart';
import 'package:oyc_connect/features/auth/data/auth_repository.dart';
import 'package:oyc_connect/features/auth/data/password_recovery_controller.dart';
import 'package:oyc_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:oyc_connect/features/community/presentation/providers/community_providers.dart';
import 'package:oyc_connect/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotificationTestAuth extends AuthRepository {
  NotificationTestAuth()
    : super(SupabaseClient('https://example.com', 'public-test-key'));
  bool loggedIn = true;
  final changes = StreamController<AuthState>.broadcast(sync: true);

  @override
  User? get currentUser => loggedIn
      ? User(
          id: 'test-user',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-27T00:00:00Z',
        )
      : null;
  @override
  Stream<AuthState> get authStateChanges => changes.stream;

  void login() {
    loggedIn = true;
    changes.add(AuthState(AuthChangeEvent.signedIn, null));
  }

  @override
  Future<void> recoverSessionFromUrl(Uri uri) async => login();
  @override
  Future<void> signOutRecoverySession() async {
    loggedIn = false;
    changes.add(AuthState(AuthChangeEvent.signedOut, null));
  }
}

class NotificationTestRecoveryStore implements RecoverySessionStore {
  @override
  Future<List<String>> readHandledLinks() async => [];
  @override
  Future<void> rememberLink(String fingerprint) async {}
  @override
  Future<bool> read() async => false;
  @override
  Future<bool> readReady() async => false;
  @override
  Future<void> write(bool active, {bool ready = false}) async {}
}

void main() {
  late NotificationTestAuth auth;
  late PasswordRecoveryController recovery;
  late NotificationNavigation navigation;
  late ProviderContainer container;
  late Completer<Uri?> initialLink;

  setUp(() {
    tz.initializeTimeZones();
    auth = NotificationTestAuth();
    initialLink = Completer<Uri?>();
    recovery = PasswordRecoveryController(
      repository: auth,
      store: NotificationTestRecoveryStore(),
      initialLink: () => initialLink.future,
      links: const Stream.empty(),
    );
    navigation = NotificationNavigation();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        passwordRecoveryProvider.overrideWith((ref) => recovery),
        notificationNavigationProvider.overrideWithValue(navigation),
        eventsProvider.overrideWith((ref) async => []),
        announcementsProvider.overrideWith((ref) async => []),
        todayPrayerTimeProvider.overrideWith((ref) => Stream.value(null)),
        jummahConfigProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    recovery.dispose();
    navigation.dispose();
    await auth.changes.close();
  });

  Future<void> pumpApp(WidgetTester tester, {bool finishStartup = true}) async {
    await tester.runAsync(() async {
      final startup = recovery.initialize();
      if (finishStartup) {
        initialLink.complete(null);
        await startup;
      } else {
        await Future<void>.delayed(Duration.zero);
      }
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(goRouterProvider),
        ),
      ),
    );
    if (finishStartup) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  String getPath() =>
      container.read(goRouterProvider).routeInformationProvider.value.uri.path;

  testWidgets('cold-start community tap survives the launch-link check', (
    tester,
  ) async {
    navigation.open({'type': 'announcement'});
    await pumpApp(tester, finishStartup: false);
    expect(getPath(), '/');
    await tester.runAsync(() async {
      initialLink.complete(null);
      await recovery.initialize();
    });
    await tester.pumpAndSettle();
    expect(getPath(), '/community');
    expect(find.text('No notices.'), findsOneWidget);
  });

  testWidgets('logged-out tap opens Notices after normal login', (
    tester,
  ) async {
    auth.loggedIn = false;
    navigation.open({'type': 'event'});
    await pumpApp(tester);
    expect(getPath(), '/login');
    auth.login();
    await tester.pumpAndSettle();
    expect(getPath(), '/community');
    expect(find.text('No notices.'), findsOneWidget);
  });

  testWidgets(
    'repeat community tap resets an already cached Events tab to Notices',
    (tester) async {
      navigation.open({'type': 'community'});
      await pumpApp(tester);
      expect(find.text('No notices.'), findsOneWidget);
      await tester.tap(find.text('EVENTS'));
      await tester.pumpAndSettle();
      expect(find.text('No upcoming events.'), findsOneWidget);
      navigation.open({'type': 'announcement'});
      await tester.pumpAndSettle();
      expect(find.text('No notices.'), findsOneWidget);
    },
  );

  testWidgets('Namaz and Jummah taps navigate from Community to Home', (
    tester,
  ) async {
    navigation.open({'type': 'announcement'});
    await pumpApp(tester);
    navigation.open({'type': 'prayer'});
    await tester.pumpAndSettle();
    expect(getPath(), '/home');
    navigation.open({'type': 'announcement'});
    await tester.pumpAndSettle();
    navigation.open({'type': 'jummah'});
    await tester.pumpAndSettle();
    expect(getPath(), '/home');
  });

  testWidgets('notification tap never bypasses password recovery', (
    tester,
  ) async {
    await tester.runAsync(() async {
      initialLink.complete(
        Uri.parse('oycconnect://reset-password?code=fixture'),
      );
      await recovery.initialize();
    });
    navigation.open({'type': 'prayer'});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(goRouterProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(getPath(), '/set-new-password');
    expect(find.text('Set New Password'), findsOneWidget);
  });
}
