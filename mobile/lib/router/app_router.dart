import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../router/route_guards.dart';
import '../screens/auth/account_pending_screen.dart';
import '../screens/auth/faculty_register_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/directory/alumni_detail_screen.dart';
import '../screens/directory/directory_screen.dart';
import '../screens/events/create_event_screen.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/fundraisers/create_fundraiser_screen.dart';
import '../screens/fundraisers/fundraiser_detail_screen.dart';
import '../screens/fundraisers/fundraisers_screen.dart';
import '../screens/jobs/applicant_tracking_screen.dart';
import '../screens/jobs/job_detail_screen.dart';
import '../screens/jobs/jobs_screen.dart';
import '../screens/jobs/post_job_screen.dart';
import '../screens/profile/admin_approval_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shell/home_shell.dart';
import '../screens/stories/create_story_screen.dart';
import '../screens/stories/stories_screen.dart';
import '../screens/stories/story_detail_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorDirectory =
    GlobalKey<NavigatorState>(debugLabel: 'directoryShell');
final _shellNavigatorJobs = GlobalKey<NavigatorState>(debugLabel: 'jobsShell');
final _shellNavigatorStories =
    GlobalKey<NavigatorState>(debugLabel: 'storiesShell');
final _shellNavigatorFundraisers =
    GlobalKey<NavigatorState>(debugLabel: 'fundraisersShell');
final _shellNavigatorEvents =
    GlobalKey<NavigatorState>(debugLabel: 'eventsShell');

/// GoRouter Provider with Auth State Listener and Role Route Guards
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/directory',
    debugLogDiagnostics: false,
    refreshListenable: _AuthStateListenable(ref),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      final isAuth = authState.isAuthenticated;
      final location = state.uri.path;

      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/register/faculty' ||
          location == '/account-pending';

      // If still bootstrapping session on startup, don't redirect yet
      if (authState.isLoading) return null;

      // Unauthenticated users trying to access protected routes -> redirect to /login
      if (!isAuth && !isAuthRoute) {
        return '/login';
      }

      // Authenticated users trying to access login/register -> redirect to /directory
      if (isAuth &&
          (location == '/login' ||
              location == '/register' ||
              location == '/register/faculty')) {
        return '/directory';
      }

      // Role guard for posting jobs (alumni or admin only)
      if (location == '/jobs/post') {
        final canPost = RouteGuards.canPostJob(authState.user?.role);
        if (!canPost) {
          return '/jobs';
        }
      }

      // Role guard for writing stories (alumni, faculty, or admin only)
      if (location == '/stories/create') {
        final canCreate = RouteGuards.canCreateStory(authState.user?.role);
        if (!canCreate) {
          return '/stories';
        }
      }

      // Role guard for admin approvals portal
      if (location == '/profile/admin-approvals') {
        final isAdmin = RouteGuards.isAdmin(authState.user?.role);
        if (!isAdmin) {
          return '/profile';
        }
      }

      return null;
    },
    routes: [
      // Auth Routes (outside shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/register/faculty',
        builder: (context, state) => const FacultyRegisterScreen(),
      ),
      GoRoute(
        path: '/account-pending',
        builder: (context, state) {
          final typeParam = state.uri.queryParameters['type'];
          final type = (typeParam == 'faculty')
              ? AccountPendingType.faculty
              : AccountPendingType.alumni;
          return AccountPendingScreen(type: type);
        },
      ),

      // Profile & Admin Routes (outside shell)
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'admin-approvals',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const AdminApprovalScreen(),
          ),
        ],
      ),

      // 5-Tab Persistent Stateful Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Directory
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDirectory,
            routes: [
              GoRoute(
                path: '/directory',
                builder: (context, state) => const DirectoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return AlumniDetailScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Jobs
          StatefulShellBranch(
            navigatorKey: _shellNavigatorJobs,
            routes: [
              GoRoute(
                path: '/jobs',
                builder: (context, state) => const JobsScreen(),
                routes: [
                  GoRoute(
                    path: 'post',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const PostJobScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return JobDetailScreen(id: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'applications',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return ApplicantTrackingScreen(jobId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Stories
          StatefulShellBranch(
            navigatorKey: _shellNavigatorStories,
            routes: [
              GoRoute(
                path: '/stories',
                builder: (context, state) => const StoriesScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const CreateStoryScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return StoryDetailScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 4: Fundraisers
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFundraisers,
            routes: [
              GoRoute(
                path: '/fundraisers',
                builder: (context, state) => const FundraisersScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        const CreateFundraiserScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return FundraiserDetailScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 5: Events
          StatefulShellBranch(
            navigatorKey: _shellNavigatorEvents,
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const CreateEventScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return EventDetailScreen(id: id);
                    },
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

/// Listenable adapter converting Riverpod auth changes into GoRouter refreshes
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}
