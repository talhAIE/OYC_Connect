import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';

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

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      // Adjust in production (e.g. 0.2) to control tracing volume.
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      // Stripe
      Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
      Stripe.merchantIdentifier = 'merchant.com.ouryouthcenter1881.oycconnect';

      // Supabase
      await Supabase.initialize(
        url: SupabaseConstants.url,
        anonKey: SupabaseConstants.anonKey,
      );

      // OneSignal
      final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
      if (oneSignalAppId.isNotEmpty) {
        OneSignal.initialize(oneSignalAppId);
        OneSignal.Notifications.requestPermission(true);
      } else {
        debugPrint('Warning: ONESIGNAL_APP_ID not set in .env');
      }

      // Hide system UI for immersive experience
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      runApp(const ProviderScope(child: MyApp()));
    },
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'OYC Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
