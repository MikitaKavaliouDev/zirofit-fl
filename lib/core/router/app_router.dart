import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/admin/screens/admin_blog_screen.dart';
import 'package:zirofit_fl/features/admin/screens/admin_dashboard_screen.dart';
import 'package:zirofit_fl/features/admin/screens/admin_events_screen.dart';
import 'package:zirofit_fl/features/admin/screens/admin_tickets_screen.dart';
import 'package:zirofit_fl/features/admin/widgets/admin_shell.dart';
import 'package:zirofit_fl/features/ai_coach/screens/ai_coach_screen.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/auth/screens/delete_account_screen.dart';
import 'package:zirofit_fl/features/auth/screens/forgot_password_screen.dart';
import 'package:zirofit_fl/features/auth/screens/auth_callback_screen.dart';
import 'package:zirofit_fl/features/auth/screens/login_screen.dart';
import 'package:zirofit_fl/features/auth/screens/register_screen.dart';
import 'package:zirofit_fl/features/calendar/screens/calendar_screen.dart';
import 'package:zirofit_fl/features/checkin/screens/check_in_history_screen.dart';
import 'package:zirofit_fl/features/checkin/screens/check_in_screen.dart';
import 'package:zirofit_fl/features/checkin/screens/trainer_check_ins_screen.dart';
import 'package:zirofit_fl/features/clients/screens/client_detail_screen.dart';
import 'package:zirofit_fl/features/clients/screens/client_history_screen.dart';
import 'package:zirofit_fl/features/clients/screens/client_list_screen.dart';
import 'package:zirofit_fl/features/clients/screens/invite_client_screen.dart';
import 'package:zirofit_fl/features/clients/screens/my_trainer_screen.dart';
import 'package:zirofit_fl/features/dashboard/screens/client_dashboard_screen.dart';
import 'package:zirofit_fl/features/dashboard/screens/daily_target_screen.dart';
import 'package:zirofit_fl/features/dashboard/screens/trainer_dashboard_screen.dart';
import 'package:zirofit_fl/features/dashboard/widgets/client_shell.dart';
import 'package:zirofit_fl/features/dashboard/widgets/trainer_shell.dart';
import 'package:zirofit_fl/features/onboarding/screens/onboarding_screen.dart';
import 'package:zirofit_fl/features/programs/screens/create_program_screen.dart';
import 'package:zirofit_fl/features/programs/screens/program_detail_screen.dart';
import 'package:zirofit_fl/features/programs/screens/programs_list_screen.dart';
import 'package:zirofit_fl/features/progress/screens/progress_screen.dart';
import 'package:zirofit_fl/features/trainer/screens/edit_profile_text_screen.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_profile_screen.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_services_screen.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_packages_screen.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_testimonials_screen.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_transformation_photos_screen.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_external_links_screen.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_social_links_screen.dart';
import 'package:zirofit_fl/features/trainer/screens/custom_exercises_screen.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_assessments_screen.dart';
import 'package:zirofit_fl/features/settings/screens/data_sharing_screen.dart';
import 'package:zirofit_fl/features/settings/screens/settings_screen.dart';
import 'package:zirofit_fl/features/events/screens/client_event_detail_screen.dart';
import 'package:zirofit_fl/features/exercises/screens/exercise_list_screen.dart';
import 'package:zirofit_fl/features/workout/screens/active_workout_screen.dart';
import 'package:zirofit_fl/features/workout/screens/workout_history_screen.dart';
import 'package:zirofit_fl/features/chat/screens/conversations_list_screen.dart';
import 'package:zirofit_fl/features/chat/screens/chat_screen.dart';
import 'package:zirofit_fl/features/notifications/screens/notifications_screen.dart';
import 'package:zirofit_fl/features/billing/screens/revenue_screen.dart';
import 'package:zirofit_fl/features/explore/screens/explore_screen.dart';
import 'package:zirofit_fl/features/explore/screens/trainer_discovery_screen.dart';
import 'package:zirofit_fl/features/explore/screens/trainer_map_screen.dart';
import 'package:zirofit_fl/features/explore/screens/public_trainer_profile_screen.dart';
import 'package:zirofit_fl/features/bookings/screens/booking_management_screen.dart';
import 'package:zirofit_fl/features/bookings/screens/client_booking_screen.dart';
import 'package:zirofit_fl/data/models/profile.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/auth/login',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isUpdatePassword = state.matchedLocation == '/auth/update-password';

      // Not logged in → auth routes only
      if (!isLoggedIn && !isAuthRoute) return '/auth/login';

      // Logged in but on an auth route → dashboard (except update-password)
      if (isLoggedIn && isAuthRoute && !isUpdatePassword) {
        return _getDefaultRoute(authState.role);
      }

      // Pending role → onboarding (unless already there)
      if (isLoggedIn && authState.isPending && !isOnboarding) {
        return '/onboarding';
      }

      // Role-based guard: ensure user stays in the correct route prefix.
      // Mode (trainer/personal) is a DISPLAY preference only — it does NOT
      // change which role's routes are accessible. A trainer always stays in
      // /trainer/*, a client always stays in /client/*.
      if (isLoggedIn && !isOnboarding) {
        final location = state.matchedLocation;
        final expectedPrefix = _getRolePrefix(authState.role);

        // Allow shared routes and sub-routes of the expected prefix
        if (!location.startsWith(expectedPrefix) &&
            !location.startsWith('/auth') &&
            location != '/onboarding' &&
            location != '/exercises' &&
            location != '/ai-coach' &&
            !location.startsWith('/events/') &&
            !location.startsWith('/workout/') &&
            !location.startsWith('/public-trainer/') &&
            !location.startsWith('/settings/')) {
          return _getDefaultRoute(authState.role);
        }
      }

      return null;
    },
    routes: [
      // -- Public / Auth routes --
      GoRoute(
        path: '/auth/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (_, state) => AuthCallbackScreen(
          queryParams: state.uri.queryParameters,
        ),
      ),

      // -- Onboarding --
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),

      // -- Exercise library (standalone, can be navigated from any role) --
      GoRoute(
        path: '/exercises',
        builder: (_, _) => const ExerciseListScreen(),
      ),

      // -- AI Coach (standalone, can be navigated from any authenticated role) --
      GoRoute(
        path: '/ai-coach',
        builder: (_, _) => const AiCoachScreen(),
      ),

      // -- Delete Account (standalone, accessible to any authenticated user) --
      GoRoute(
        path: '/delete-account',
        builder: (_, _) => const DeleteAccountScreen(),
      ),

      // -- Data Sharing (standalone, accessible to clients from settings) --
      GoRoute(
        path: '/settings/data-sharing',
        builder: (_, _) => const DataSharingScreen(),
      ),

      // -- Admin routes --
      ShellRoute(
        builder: (_, _, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, _) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/events',
            builder: (_, _) => const AdminEventsScreen(),
          ),
          GoRoute(
            path: '/admin/blog',
            builder: (_, _) => const AdminBlogScreen(),
          ),
          GoRoute(
            path: '/admin/tickets',
            builder: (_, _) => const AdminTicketsScreen(),
          ),
        ],
      ),

      // -- Trainer routes --
      ShellRoute(
        builder: (_, _, child) => TrainerShell(child: child),
        routes: [
          GoRoute(
            path: '/trainer/dashboard',
            builder: (_, _) => const TrainerDashboardScreen(),
          ),
          GoRoute(
            path: '/trainer/clients',
            builder: (_, _) => const ClientListScreen(),
            routes: [
              GoRoute(
                path: 'invite',
                builder: (_, _) => const InviteClientScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => ClientDetailScreen(
                  id: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'sessions',
                    builder: (_, state) => ClientHistoryScreen(
                      clientId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/trainer/calendar',
            builder: (_, _) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/trainer/bookings',
            builder: (_, _) => const BookingManagementScreen(),
          ),
          GoRoute(
            path: '/trainer/check-ins',
            builder: (_, _) => const TrainerCheckInsScreen(),
          ),
          GoRoute(
            path: '/trainer/programs',
            builder: (_, _) => const ProgramsListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, _) => const CreateProgramScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => ProgramDetailScreen(
                  programId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/trainer/exercises',
            builder: (_, _) => const ExerciseListScreen(),
            routes: [
              GoRoute(
                path: 'custom',
                builder: (_, _) => const CustomExercisesScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/trainer/notifications',
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/trainer/revenue',
            builder: (_, _) => const RevenueScreen(),
          ),
          GoRoute(
            path: '/trainer/chat',
            builder: (_, _) => const ConversationsListScreen(),
            routes: [
              GoRoute(
                path: ':conversationId',
                builder: (_, state) => ChatScreen(
                  conversationId: state.pathParameters['conversationId']!,
                  title: 'Chat',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/trainer/profile',
            builder: (_, _) => const TrainerProfileScreen(),
            routes: [
              GoRoute(
                path: 'services',
                builder: (_, _) => const TrainerServicesScreen(),
              ),
              GoRoute(
                path: 'packages',
                builder: (_, _) => const TrainerPackagesScreen(),
              ),
              GoRoute(
                path: 'testimonials',
                builder: (_, _) => const TrainerTestimonialsScreen(),
              ),
              GoRoute(
                path: 'transformations',
                builder: (_, _) => const TrainerTransformationPhotosScreen(),
              ),
              GoRoute(
                path: 'external-links',
                builder: (_, _) => const TrainerExternalLinksScreen(),
              ),
              GoRoute(
                path: 'edit-text',
                builder: (_, _) => const EditProfileTextScreen(),
              ),
              GoRoute(
                path: 'social-links',
                builder: (_, _) => const TrainerSocialLinksScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/trainer/assessments',
            builder: (_, _) => const TrainerAssessmentsScreen(),
          ),
          GoRoute(
            path: '/trainer/settings',
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),

      // -- Client routes --
      ShellRoute(
        builder: (_, _, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: '/client/dashboard',
            builder: (_, _) => const ClientDashboardScreen(),
          ),
          GoRoute(
            path: '/client/daily-targets',
            builder: (_, _) => const DailyTargetScreen(),
          ),
          GoRoute(
            path: '/client/workout',
            builder: (_, _) => const ActiveWorkoutScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (_, _) => const WorkoutHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/client/progress',
            builder: (_, _) => const PersonalAnalyticsScreen(),
          ),
          GoRoute(
            path: '/client/trainer',
            builder: (_, _) => const MyTrainerScreen(),
          ),
          GoRoute(
            path: '/client/events/:id',
            builder: (_, state) => ClientEventDetailScreen(
              eventId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/client/check-in',
            builder: (_, _) => const CheckInScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (_, _) => const CheckInHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/client/notifications',
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/client/explore',
            builder: (_, _) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/client/explore/discovery',
            builder: (_, _) => const TrainerDiscoveryScreen(),
          ),
          GoRoute(
            path: '/client/explore/map',
            builder: (_, _) => const TrainerMapScreen(),
          ),
          GoRoute(
            path: '/client/chat',
            builder: (_, _) => const ConversationsListScreen(),
            routes: [
              GoRoute(
                path: ':conversationId',
                builder: (_, state) => ChatScreen(
                  conversationId: state.pathParameters['conversationId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/client/bookings/:trainerId',
            builder: (_, state) => ClientBookingScreen(
              trainerId: state.pathParameters['trainerId']!,
            ),
          ),
        ],
      ),

      // -- Deep link routes (top-level, auth handled by redirect above) --
      GoRoute(
        path: '/events/:id',
        builder: (_, state) => ClientEventDetailScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/workout/:id',
        builder: (_, state) => ActiveWorkoutScreen(
          templateId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/public-trainer/:id',
        builder: (_, state) {
          final profile = state.extra as Profile?;
          if (profile != null) {
            return PublicTrainerProfileScreen(trainer: profile);
          }
          // Fallback when navigated without profile data (e.g. fetch failed)
          return const _TrainerProfileUnavailable();
        },
      ),
    ],
  );
});

/// Placeholder widget shown when a trainer profile cannot be loaded.
class _TrainerProfileUnavailable extends StatelessWidget {
  const _TrainerProfileUnavailable();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trainer Profile')),
      body: const Center(
        child: Text('Unable to load trainer profile. Please try again later.'),
      ),
    );
  }
}

String _getDefaultRoute(String? role) {
  switch (role) {
    case 'trainer':
      return '/trainer/dashboard';
    case 'client':
      return '/client/dashboard';
    case 'admin':
      return '/admin/dashboard';
    case 'pending':
      return '/onboarding';
    default:
      return '/auth/login';
  }
}

String _getRolePrefix(String? role) {
  switch (role) {
    case 'trainer':
      return '/trainer';
    case 'client':
      return '/client';
    case 'admin':
      return '/admin';
    default:
      return '/auth';
  }
}
