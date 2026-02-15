import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/set_new_password_page.dart';
import '../../features/auth/presentation/widgets/auth_wrapper.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/community/presentation/pages/community_page.dart';
import '../../features/donation/presentation/pages/donation_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/manage_prayer_times_page.dart';
import '../../features/admin/presentation/pages/manage_events_page.dart';
import '../../features/admin/presentation/pages/manage_announcements_page.dart';
import '../../features/admin/presentation/pages/jummah_settings_page.dart';
import '../../features/admin/presentation/pages/donation_history_page.dart';
import '../../features/admin/presentation/pages/manage_khateebs_page.dart';

import '../../features/prayer_times/presentation/pages/prayer_calendar_page.dart';
import '../../features/classes/presentation/pages/classes_schedule_page.dart';
import '../../features/classes/presentation/pages/manage_schedule_page.dart';
import '../../features/classes/presentation/pages/manage_classes_page.dart';
import '../../features/classes/presentation/pages/manage_teachers_page.dart';
import '../presentation/main_scaffold.dart';

// We need a provider for the router to listen to auth changes
// For simplicity in this step, we'll define the router here.
// Ideally, this should be in lib/core/router/router.dart

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' ||
          path == '/register' ||
          path == '/forgot-password' ||
          path == '/set-new-password';

      // If we just recovered session from password-reset link, send to set-new-password
      try {
        final container = ProviderScope.containerOf(context);
        if (container.read(recoveryPendingProvider)) {
          return '/set-new-password';
        }
      } catch (_) {}

      // If not logged in and not on an auth route, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // If logged in and on login/register/root (but not recovery), redirect to home
      if (isLoggedIn &&
          (path == '/login' || path == '/register' || path == '/')) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Root route for initial logic or splash
      GoRoute(path: '/', builder: (context, state) => const AuthWrapper()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/set-new-password',
        builder: (context, state) => const SetNewPasswordPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'prayer-calendar',
                    builder: (context, state) => const PrayerCalendarPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/donate',
                builder: (context, state) => const DonationPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/classes',
                builder: (context, state) => const ClassesSchedulePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (context, state) => const ChangePasswordPage(),
                  ),
                  GoRoute(
                    path: 'admin',
                    builder: (context, state) => const AdminDashboardPage(),
                    routes: [
                      GoRoute(
                        path: 'prayer-times',
                        builder: (context, state) =>
                            const ManagePrayerTimesPage(),
                      ),
                      GoRoute(
                        path: 'events',
                        builder: (context, state) => const ManageEventsPage(),
                      ),
                      GoRoute(
                        path: 'announcements',
                        builder: (context, state) =>
                            const ManageAnnouncementsPage(),
                      ),
                      GoRoute(
                        path: 'jummah-settings',
                        builder: (context, state) => const JummahSettingsPage(),
                      ),
                      GoRoute(
                        path: 'schedule',
                        builder: (context, state) => const ManageSchedulePage(),
                      ),
                      GoRoute(
                        path: 'classes',
                        builder: (context, state) => const ManageClassesPage(),
                      ),
                      GoRoute(
                        path: 'teachers',
                        builder: (context, state) => const ManageTeachersPage(),
                      ),
                      GoRoute(
                        path: 'donations',
                        builder: (context, state) =>
                            const DonationHistoryPage(),
                      ),
                      GoRoute(
                        path: 'khateebs',
                        builder: (context, state) => const ManageKhateebsPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
