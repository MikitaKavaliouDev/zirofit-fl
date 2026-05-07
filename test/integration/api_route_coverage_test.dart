import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';

// ---------------------------------------------------------------------------
// Test helper
// ---------------------------------------------------------------------------

/// Verifies that a parameterized Flutter API path matches an expected backend
/// route pattern. Handles both exact matches and pattern matches for
/// dynamic segments (e.g. '/workout-sessions/abc/rest/start' matches
/// '/workout-sessions/{param}/rest/start').
void _expectParameterizedRoute(String flutterPath, Set<String> backendRoutes) {
  // Try direct match first (e.g. if the backend has the exact path)
  if (backendRoutes.contains(flutterPath)) return;

  // Convert the flutter path to a pattern and check again
  final pattern = flutterPath.replaceAll(
    RegExp(r'/test-id[^/]*|/[a-f0-9\-]{20,}'),
    '/{param}',
  );
  // Normalize to remove any trailing slashes
  final normalizedPattern = pattern.replaceAll(RegExp(r'/+$'), '');
  expect(
    backendRoutes,
    contains(normalizedPattern),
    reason:
        'Flutter path "$flutterPath" (pattern: "$normalizedPattern") '
        'does not match any backend route',
  );
}

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Backend route manifest
  //
  // All routes from ../zirofit-next/src/app/api/ — [param] segments have
  // been normalised to {param} for pattern matching.
  // -------------------------------------------------------------------------
  final backendRoutes = <String>{
    // Auth
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/me',
    '/auth/signout',
    '/auth/sync-user',
    '/auth/forgot-password',
    '/auth/update-password',
    '/auth/complete-onboarding',
    '/auth/mobile-signin',
    '/auth/resend-verification-email',

    // Sync
    '/sync/pull',
    '/sync/push',

    // Workout Sessions
    '/workout-sessions/start',
    '/workout-sessions/finish',
    '/workout-sessions/live',
    '/workout-sessions/history',
    '/workout-sessions/plan',
    '/workout-sessions/{param}',
    '/workout-sessions/{param}/cancel',
    '/workout-sessions/{param}/rest/start',
    '/workout-sessions/{param}/rest/end',
    '/workout-sessions/{param}/exercises',
    '/workout-sessions/{param}/exercises/{param}',
    '/workout-sessions/{param}/comments',
    '/workout-sessions/{param}/summary',
    '/workout-sessions/{param}/save-as-template',

    // Workout log & templates
    '/workout/log',
    '/workout-templates/{param}',

    // Clients
    '/clients',
    '/clients/{param}',
    '/clients/{param}/assessments',
    '/clients/{param}/assessments/{param}',
    '/clients/{param}/avatar',
    '/clients/{param}/dashboard',
    '/clients/{param}/exercise-logs',
    '/clients/{param}/insights',
    '/clients/{param}/measurements',
    '/clients/{param}/measurements/{param}',
    '/clients/{param}/packages',
    '/clients/{param}/photos',
    '/clients/{param}/photos/{param}',
    '/clients/{param}/program/active',
    '/clients/{param}/session/active',
    '/clients/{param}/sessions',
    '/clients/{param}/sessions/{param}',
    '/clients/invite',
    '/clients/request-link',

    // Exercises
    '/exercises',
    '/exercises/find-media',
    '/exercises/sync',

    // Explore
    '/explore/events',
    '/explore/featured',
    '/explore/metadata',

    // Profile
    '/profile/me',
    '/profile/me/assessments',
    '/profile/me/availability',
    '/profile/me/avatar',
    '/profile/me/benefits',
    '/profile/me/benefits/{param}',
    '/profile/me/benefits/order',
    '/profile/me/billing',
    '/profile/me/branding',
    '/profile/me/core-info',
    '/profile/me/exercises',
    '/profile/me/exercises/{param}',
    '/profile/me/external-links',
    '/profile/me/external-links/{param}',
    '/profile/me/packages',
    '/profile/me/packages/{param}',
    '/profile/me/push-token',
    '/profile/me/services',
    '/profile/me/services/{param}',
    '/profile/me/social-links',
    '/profile/me/social-links/{param}',
    '/profile/me/testimonials',
    '/profile/me/testimonials/{param}',
    '/profile/me/text-content',
    '/profile/me/transformation-photos',
    '/profile/me/transformation-photos/{param}',

    // Bookings & Events
    '/bookings',
    '/bookings/{param}/confirm',
    '/bookings/{param}/decline',
    '/events',
    '/events/{param}',
    '/events/{param}/join',

    // Trainer - Events
    '/trainer/events',
    '/trainer/events/{param}',
    '/trainer/events/upload',

    // Trainer - Programs & Templates
    '/trainer/programs',
    '/trainer/programs/templates',
    '/trainer/programs/templates/{param}/copy',
    '/trainer/programs/templates/{param}/exercises',
    '/trainer/programs/templates/{param}/exercises/{param}',
    '/trainer/programs/templates/{param}/rest',

    // Trainer - Check-ins
    '/trainer/check-ins',
    '/trainer/check-ins/{param}',
    '/trainer/check-ins/{param}/review',
    '/trainer/check-ins/pending',

    // Trainer - Calendar
    '/trainer/calendar',
    '/trainer/calendar/{param}',
    '/trainer/calendar/clients-summary',
    '/trainer/calendar/sessions/{param}/remind',

    // Trainer - Clients
    '/trainer/clients/{param}/assign-program',
    '/trainer/clients/{param}/habits',
    '/trainer/clients/{param}/habits/{param}',

    // Trainer - Other
    '/trainer/link-requests/{param}/accept',
    '/trainer/link-requests/{param}/decline',
    '/trainer/session-creation-data',
    '/trainer/settings',
    '/trainer/workout-templates',
    '/trainer/recipes',
    '/trainer/recipes/{param}',
    '/trainer/resource-vault',
    '/trainer/resource-vault/{param}',
    '/trainer/resource-vault/{param}/assign',
    '/trainer/resource-vault/{param}/unassign',
    '/trainer/assessments',

    // Notifications
    '/notifications',
    '/notifications/{param}',

    // Client - Check-in & Habits
    '/client/check-in',
    '/client/check-in/config',
    '/client/check-ins',
    '/client/check-ins/{param}',
    '/client/habits',
    '/client/habits/{param}/log',

    // Client - Other
    '/client/ai/generate',
    '/client/analytics',
    '/client/dashboard',
    '/client/events',
    '/client/events/{param}/cancel',
    '/client/program/active',
    '/client/programs',
    '/client/progress',
    '/client/resource-vault',
    '/client/sharing',
    '/client/statistics',
    '/client/stats/exercise',
    '/client/trainer',
    '/client/trainer/link',
    '/client/upload',

    // Blog
    '/blog',
    '/blog/{param}',

    // Billing
    '/billing/portal',
    '/billing/subscribe-new',
    '/billing/subscription',

    // Checkout
    '/checkout/session',

    // System
    '/system/config',

    // Domain
    '/domain/add',
    '/domain/verify',

    // Admin
    '/admin/blog',
    '/admin/blog/{param}',
    '/admin/events',
    '/admin/events/{param}',
    '/admin/stats',
    '/admin/tickets',
    '/admin/tickets/{param}',
    '/admin/upload',

    // AI Coach
    '/mobile/ai-coach/generate',
    '/mobile/ai-coach/refine',

    // Support
    '/support/feedback',
    '/support/tickets',

    // Chat
    '/chat',

    // Contact
    '/contact',

    // Dashboard
    '/dashboard',
    '/dashboard/insights',
    '/dashboard/summary',

    // Other
    '/onboarding/complete',
    '/user/delete',
    '/webhooks/stripe',
    '/openapi',
    '/public/workout-summary/{param}',
    '/mobile/home',
    '/mobile/pricing',
    '/cron/check-in-reminder',
    '/cron/trial-reminders',

    // Trainers (public)
    '/trainers',
    '/trainers/{param}',
    '/trainers/{param}/packages',
    '/trainers/{param}/public',
    '/trainers/{param}/schedule',
    '/trainers/{param}/testimonials',
    '/trainers/{param}/transformation-photos',
    '/trainers/specialties',
  };

  // ===========================================================================
  // Auth routes
  // ===========================================================================

  group('Auth routes', () {
    test('login', () {
      expect(backendRoutes, contains(ApiConstants.login));
    });
    test('register', () {
      expect(backendRoutes, contains(ApiConstants.register));
    });
    test('refresh', () {
      expect(backendRoutes, contains(ApiConstants.refresh));
    });
    test('signout', () {
      expect(backendRoutes, contains(ApiConstants.signout));
    });
    test('me', () {
      expect(backendRoutes, contains(ApiConstants.me));
    });
    test('syncUser', () {
      expect(backendRoutes, contains(ApiConstants.syncUser));
    });
    test('forgotPassword', () {
      expect(backendRoutes, contains(ApiConstants.forgotPassword));
    });
    test('updatePassword', () {
      expect(backendRoutes, contains(ApiConstants.updatePassword));
    });
    test('completeOnboarding', () {
      expect(backendRoutes, contains(ApiConstants.completeOnboarding));
    });
  });

  // ===========================================================================
  // Sync routes
  // ===========================================================================

  group('Sync routes', () {
    test('syncPull', () {
      expect(backendRoutes, contains(ApiConstants.syncPull));
    });
    test('syncPush', () {
      expect(backendRoutes, contains(ApiConstants.syncPush));
    });
  });

  // ===========================================================================
  // Workout Session routes  (CRITICAL — 3 recently fixed)
  // ===========================================================================

  group('Workout Session routes', () {
    test('workoutStart', () {
      expect(backendRoutes, contains(ApiConstants.workoutStart));
    });

    test('workoutFinish', () {
      expect(backendRoutes, contains(ApiConstants.workoutFinish));
    });

    test('workoutLive', () {
      expect(backendRoutes, contains(ApiConstants.workoutLive));
    });

    test('workoutHistory', () {
      expect(backendRoutes, contains(ApiConstants.workoutHistory));
    });

    // --- Recently fixed: session ID in path, NOT in body ---

    test('workoutRestStart — sessionId in path, no body', () {
      final path = ApiConstants.workoutRestStart('test-id');
      expect(path, '/workout-sessions/test-id/rest/start');
      _expectParameterizedRoute(path, backendRoutes);
    });

    test('workoutRestEnd — sessionId in path, no body', () {
      final path = ApiConstants.workoutRestEnd('test-id');
      expect(path, '/workout-sessions/test-id/rest/end');
      _expectParameterizedRoute(path, backendRoutes);
    });

    test('workoutCancel — sessionId in path, no body', () {
      final path = ApiConstants.workoutCancel('test-id');
      expect(path, '/workout-sessions/test-id/cancel');
      _expectParameterizedRoute(path, backendRoutes);
    });

    test('workoutSaveAsTemplate — sessionId in path, no body', () {
      final path = ApiConstants.workoutSaveAsTemplate('test-id');
      expect(path, '/workout-sessions/test-id/save-as-template');
      _expectParameterizedRoute(path, backendRoutes);
    });
  });

  // ===========================================================================
  // Client routes
  // ===========================================================================

  group('Client routes', () {
    test('clients', () {
      expect(backendRoutes, contains(ApiConstants.clients));
    });
  });

  // ===========================================================================
  // Exercise routes
  // ===========================================================================

  group('Exercise routes', () {
    test('exercises', () {
      expect(backendRoutes, contains(ApiConstants.exercises));
    });
  });

  // ===========================================================================
  // Explore routes
  // ===========================================================================

  group('Explore routes', () {
    test('exploreFeatured', () {
      expect(backendRoutes, contains(ApiConstants.exploreFeatured));
    });
  });

  // ===========================================================================
  // Booking / Event routes
  // ===========================================================================

  group('Booking & Event routes', () {
    test('bookings', () {
      expect(backendRoutes, contains(ApiConstants.bookings));
    });
    test('bookingConfirm', () {
      _expectParameterizedRoute(
        ApiConstants.bookingConfirm('test-id'),
        backendRoutes,
      );
    });
    test('bookingDecline', () {
      _expectParameterizedRoute(
        ApiConstants.bookingDecline('test-id'),
        backendRoutes,
      );
    });
    test('events', () {
      expect(backendRoutes, contains(ApiConstants.events));
    });
    test('eventDetail', () {
      _expectParameterizedRoute(
        ApiConstants.eventDetail('test-id'),
        backendRoutes,
      );
    });
    test('eventJoin', () {
      _expectParameterizedRoute(
        ApiConstants.eventJoin('test-id'),
        backendRoutes,
      );
    });
    test('trainerEvents', () {
      expect(backendRoutes, contains(ApiConstants.trainerEvents));
    });
    test('trainerEventCrud', () {
      _expectParameterizedRoute(
        ApiConstants.trainerEventCrud('test-id'),
        backendRoutes,
      );
    });
  });

  // ===========================================================================
  // Notification routes
  // ===========================================================================

  group('Notification routes', () {
    test('notifications', () {
      expect(backendRoutes, contains(ApiConstants.notifications));
    });
    test('notificationMarkRead', () {
      _expectParameterizedRoute(
        ApiConstants.notificationMarkRead('test-id'),
        backendRoutes,
      );
    });
  });

  // ===========================================================================
  // Habit routes
  // ===========================================================================

  group('Habit routes', () {
    test('clientHabits', () {
      expect(backendRoutes, contains(ApiConstants.clientHabits));
    });
    test('logHabit', () {
      _expectParameterizedRoute(
        ApiConstants.logHabit('test-id'),
        backendRoutes,
      );
    });
    test('trainerClientHabits', () {
      _expectParameterizedRoute(
        ApiConstants.trainerClientHabits('test-id'),
        backendRoutes,
      );
    });
  });

  // ===========================================================================
  // Check-In routes
  // ===========================================================================

  group('Check-In routes', () {
    test('clientCheckIn', () {
      expect(backendRoutes, contains(ApiConstants.clientCheckIn));
    });
    test('trainerCheckIns', () {
      expect(backendRoutes, contains(ApiConstants.trainerCheckIns));
    });
    test('trainerCheckInDetail', () {
      _expectParameterizedRoute(
        ApiConstants.trainerCheckInDetail('test-id'),
        backendRoutes,
      );
    });
    test('trainerCheckInReview', () {
      _expectParameterizedRoute(
        ApiConstants.trainerCheckInReview('test-id'),
        backendRoutes,
      );
    });
  });

  // ===========================================================================
  // Program / Template routes
  // ===========================================================================

  group('Program & Template routes', () {
    test('trainerPrograms', () {
      expect(backendRoutes, contains(ApiConstants.trainerPrograms));
    });
    test('templateExercises', () {
      _expectParameterizedRoute(
        ApiConstants.templateExercises('test-id'),
        backendRoutes,
      );
    });
    test('templateCopy', () {
      _expectParameterizedRoute(
        ApiConstants.templateCopy('test-id'),
        backendRoutes,
      );
    });
  });

  // ===========================================================================
  // Recipe routes
  // ===========================================================================

  group('Recipe routes', () {
    test('trainerRecipes', () {
      expect(backendRoutes, contains(ApiConstants.trainerRecipes));
    });
    test('trainerRecipe', () {
      _expectParameterizedRoute(
        ApiConstants.trainerRecipe('test-id'),
        backendRoutes,
      );
    });
  });

  // ===========================================================================
  // Chat
  // ===========================================================================

  group('Chat routes', () {
    test('chat', () {
      expect(backendRoutes, contains(ApiConstants.chat));
    });
  });

  // ===========================================================================
  // Profile routes
  // ===========================================================================

  group('Profile routes', () {
    test('profileMe', () {
      expect(backendRoutes, contains(ApiConstants.profileMe));
    });
    test('profileMeTextContent', () {
      expect(backendRoutes, contains(ApiConstants.profileMeTextContent));
    });
    test('profileMeServices', () {
      expect(backendRoutes, contains(ApiConstants.profileMeServices));
    });
    test('profileMePackages', () {
      expect(backendRoutes, contains(ApiConstants.profileMePackages));
    });
    test('profileMeTestimonials', () {
      expect(backendRoutes, contains(ApiConstants.profileMeTestimonials));
    });
    test('profileMeBenefits', () {
      expect(backendRoutes, contains(ApiConstants.profileMeBenefits));
    });
  });

  // ===========================================================================
  // Trainer Settings
  // ===========================================================================

  group('Trainer Settings routes', () {
    test('trainerSettings', () {
      expect(backendRoutes, contains(ApiConstants.trainerSettings));
    });
  });

  // ===========================================================================
  // Resource Vault routes
  // ===========================================================================

  group('Resource Vault routes', () {
    test('trainerResourceVault', () {
      expect(backendRoutes, contains(ApiConstants.trainerResourceVault));
    });
    test('trainerResource', () {
      _expectParameterizedRoute(
        ApiConstants.trainerResource('test-id'),
        backendRoutes,
      );
    });
    test('assignResource', () {
      _expectParameterizedRoute(
        ApiConstants.assignResource('test-id'),
        backendRoutes,
      );
    });
  });

  // ===========================================================================
  // Billing routes
  // ===========================================================================

  group('Billing routes', () {
    test('createCheckoutSession', () {
      expect(backendRoutes, contains(ApiConstants.createCheckoutSession));
    });
    test('billingSubscription', () {
      expect(backendRoutes, contains(ApiConstants.billingSubscription));
    });
    test('billingPortal', () {
      expect(backendRoutes, contains(ApiConstants.billingPortal));
    });
  });

  // ===========================================================================
  // Blog routes
  // ===========================================================================

  group('Blog routes', () {
    test('blog', () {
      expect(backendRoutes, contains(ApiConstants.blog));
    });
    test('blogPost', () {
      _expectParameterizedRoute(
        ApiConstants.blogPost('test-id'),
        backendRoutes,
      );
    });
  });

  // ===========================================================================
  // System routes
  // ===========================================================================

  group('System routes', () {
    test('systemConfig', () {
      expect(backendRoutes, contains(ApiConstants.systemConfig));
    });
  });

  // ===========================================================================
  // Calendar routes
  // ===========================================================================

  group('Calendar routes', () {
    test('trainerCalendar', () {
      expect(backendRoutes, contains(ApiConstants.trainerCalendar));
    });
    test('calendarSession', () {
      _expectParameterizedRoute(
        ApiConstants.calendarSession('test-id'),
        backendRoutes,
      );
    });
    test('sessionRemind', () {
      _expectParameterizedRoute(
        ApiConstants.sessionRemind('test-id'),
        backendRoutes,
      );
    });
    test('clientsSummary', () {
      expect(backendRoutes, contains(ApiConstants.clientsSummary));
    });
    test('sessionCreationData', () {
      expect(backendRoutes, contains(ApiConstants.sessionCreationData));
    });
  });

  // ===========================================================================
  // Admin routes
  // ===========================================================================

  group('Admin routes', () {
    test('adminStats', () {
      expect(backendRoutes, contains(ApiConstants.adminStats));
    });
    test('adminEvents', () {
      expect(backendRoutes, contains(ApiConstants.adminEvents));
    });
    test('adminEvent', () {
      _expectParameterizedRoute(
        ApiConstants.adminEvent('test-id'),
        backendRoutes,
      );
    });
    test('adminBlog', () {
      expect(backendRoutes, contains(ApiConstants.adminBlog));
    });
    test('adminBlogPost', () {
      _expectParameterizedRoute(
        ApiConstants.adminBlogPost('test-id'),
        backendRoutes,
      );
    });
    test('adminUpload', () {
      expect(backendRoutes, contains(ApiConstants.adminUpload));
    });
    test('adminTickets', () {
      expect(backendRoutes, contains(ApiConstants.adminTickets));
    });
    test('adminTicket', () {
      _expectParameterizedRoute(
        ApiConstants.adminTicket('test-id'),
        backendRoutes,
      );
    });
  });

  // ===========================================================================
  // AI Coach routes
  // ===========================================================================

  group('AI Coach routes', () {
    test('aiCoachGenerate', () {
      expect(backendRoutes, contains(ApiConstants.aiCoachGenerate));
    });
    test('aiCoachRefine', () {
      expect(backendRoutes, contains(ApiConstants.aiCoachRefine));
    });
  });

  // ===========================================================================
  // Mobile routes
  // ===========================================================================

  group('Mobile routes', () {
    test('mobileHome', () {
      expect(backendRoutes, contains(ApiConstants.mobileHome));
    });
    test('clientDashboard', () {
      expect(backendRoutes, contains(ApiConstants.clientDashboard));
    });
  });

  // ===========================================================================
  // Domain routes
  // ===========================================================================

  group('Domain routes', () {
    test('domainAdd', () {
      expect(backendRoutes, contains(ApiConstants.domainAdd));
    });
    test('domainVerify', () {
      expect(backendRoutes, contains(ApiConstants.domainVerify));
    });
  });

  // ===========================================================================
  // Support tickets
  // ===========================================================================

  group('Support routes', () {
    test('supportTickets', () {
      expect(backendRoutes, contains(ApiConstants.supportTickets));
    });
  });
}
