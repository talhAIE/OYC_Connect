import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
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
import '../../features/admin/presentation/pages/notification_delivery_page.dart';
import '../../features/admin/presentation/pages/manage_prayer_times_page.dart';
import '../../features/admin/presentation/pages/manage_events_page.dart';
import '../../features/admin/presentation/pages/manage_announcements_page.dart';
import '../../features/admin/presentation/pages/jummah_settings_page.dart';
import '../../features/admin/presentation/pages/donation_history_page.dart';
import '../../features/admin/presentation/pages/manage_khateebs_page.dart';

import '../../features/prayer_times/presentation/pages/prayer_calendar_page.dart';
import '../../features/prayer_times/presentation/pages/qibla_page.dart';
import '../../features/classes/presentation/pages/classes_schedule_page.dart';
import '../../features/classes/presentation/pages/manage_schedule_page.dart';
import '../../features/classes/presentation/pages/manage_classes_page.dart';
import '../../features/classes/presentation/pages/manage_teachers_page.dart';
import '../presentation/main_scaffold.dart';
import '../notifications/notification_navigation.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Read rather than watch: refresh this router instead of recreating its
  // navigation stack on every recovery/auth event.
  final recovery = ref.read(passwordRecoveryProvider);
  final authRepository = ref.read(authRepositoryProvider);
  final notificationNavigation = ref.read(notificationNavigationProvider);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([recovery, notificationNavigation]),
    redirect: (context, state) {
      final loggedIn = authRepository.currentUser != null;
      if (!recovery.initializing && !recovery.active && loggedIn) {
        final pending = notificationNavigation.takePendingLocation();
        if (pending != null && pending != state.uri.toString()) return pending;
      }
      return recovery.redirect(state.uri.path, isLoggedIn: loggedIn);
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
                  GoRoute(
                    path: 'qibla',
                    builder: (context, state) => const QiblaPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final initialTab =
                      state.uri.queryParameters['tab'] == 'notices'
                      ? 1
                      : extra?['tab'] as int? ?? 0;
                  return CommunityPage(
                    key: ValueKey(state.uri.toString()),
                    initialTab: initialTab,
                  );
                },
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
                    redirect: (context, state) {
                      // Guard: only allow admin users
                      try {
                        final container = ProviderScope.containerOf(context);
                        final profile = container
                            .read(profileProvider)
                            .valueOrNull;
                        if (profile == null || profile.role != 'admin') {
                          return '/home';
                        }
                      } catch (_) {
                        return '/home';
                      }
                      return null;
                    },
                    routes: [
                      GoRoute(
                        path: 'notifications',
                        builder: (context, state) =>
                            const NotificationDeliveryPage(),
                      ),
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
  ref.onDispose(router.dispose);
  return router;
});
