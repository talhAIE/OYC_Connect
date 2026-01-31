import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
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
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';

      // If not logged in and not navigating to login/register, redirect to login
      if (!isLoggedIn && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      // If logged in and navigating to login/register or root, redirect to home
      if (isLoggedIn &&
          (isLoggingIn || isRegistering || state.uri.path == '/')) {
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
