import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/constants/client_environment.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/notifications/notification_navigation.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/community/presentation/providers/community_providers.dart';
import 'features/prayer_times/presentation/providers/prayer_times_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone
  tz.initializeTimeZones();

  // Load .env (gracefully handle missing file)
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }

  validateClientEnvironment(dotenv.env);

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      // Adjust in production (e.g. 0.2) to control tracing volume.
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      // Supabase
      await Supabase.initialize(
        url: SupabaseConstants.url,
        publishableKey: SupabaseConstants.anonKey,
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );

      // OneSignal
      final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
      if (oneSignalAppId.isNotEmpty) {
        pushNotifications.initialize(oneSignalAppId);
      } else {
        debugPrint('Warning: ONESIGNAL_APP_ID not set in .env');
      }

      // Hide system UI for immersive experience
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      runApp(const ProviderScope(child: MyApp()));
    },
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pushNotificationServiceProvider).setTapHandler((data) {
        ref.invalidate(todayPrayerTimeProvider);
        ref.invalidate(jummahConfigProvider);
        ref.invalidate(eventsProvider);
        ref.invalidate(announcementsProvider);
        ref.read(notificationNavigationProvider).open(data);
      });
      _synchronizePush();
    });
  }

  void _synchronizePush() {
    final recovery = ref.read(passwordRecoveryProvider);
    final userId = recovery.active || recovery.initializing
        ? null
        : Supabase.instance.client.auth.currentUser?.id;
    final profile = ref.read(profileProvider).valueOrNull;
    final enabled = userId == null
        ? false
        : profile?.id == userId
        ? profile!.notificationsEnabled
        : null;
    unawaited(
      ref
          .read(pushNotificationServiceProvider)
          .synchronize(userId, enabled: enabled)
          .catchError((Object _) {
            debugPrint(
              'Notification synchronization needs attention. Check phone permission and connectivity.',
            );
          }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(profileProvider);
      _synchronizePush();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(pushNotificationServiceProvider).setTapHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      if (next.hasValue) _synchronizePush();
    });
    ref.listen(profileProvider, (_, next) {
      if (next.hasValue) _synchronizePush();
    });
    ref.listen(passwordRecoveryProvider, (_, next) => _synchronizePush());
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'OYC Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
