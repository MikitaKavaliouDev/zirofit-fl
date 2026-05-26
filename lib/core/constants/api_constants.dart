import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// Root website URL for legal links (Terms, Privacy).
  static const String webUrl = 'https://ziro.fit';

  static const bool useLocal = bool.fromEnvironment(
    'LOCAL',
    defaultValue: false,
  );
  static const String _prodUrl = 'https://www.ziro.fit/api';

  static String get baseUrl {
    if (useLocal) {
      // Android emulators see the host loopback at 10.0.2.2
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:3321/api';
      }
      return 'http://localhost:3321/api';
    }
    return const String.fromEnvironment('API_BASE_URL', defaultValue: _prodUrl);
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String signout = '/auth/signout';
  static const String me = '/auth/me';
  static const String syncUser = '/auth/sync-user';
  static const String forgotPassword = '/auth/forgot-password';
  static const String updatePassword = '/auth/update-password';
  static const String completeOnboarding = '/auth/complete-onboarding';
  static const String resendVerification = '/auth/resend-verification';
  static const String deleteAccount = '/auth/delete-account';
  static const String mobileSignin = '/auth/mobile-signin';

  // Sync
  static const String syncPull = '/sync/pull';
  static const String syncPush = '/sync/push';

  // Workout Sessions
  static const String workoutStart = '/workout-sessions/start';
  static const String workoutFinish = '/workout-sessions/finish';
  static const String workoutLive = '/workout-sessions/live';
  static const String workoutHistory = '/workout-sessions/history';
  static String workoutRestStart(String id) =>
      '/workout-sessions/$id/rest/start';
  static String workoutRestEnd(String id) => '/workout-sessions/$id/rest/end';
  static String workoutCancel(String id) => '/workout-sessions/$id/cancel';
  // TODO: endpoint not yet implemented in backend (zirofit-next)
  static String workoutBulkLog(String id) => '/workout-sessions/$id/bulk-log';
  static String workoutExercises(String id) => '/workout-sessions/$id/exercises';
  static String workoutExerciseLog(String sessionId, String logId) =>
      '/workout-sessions/$sessionId/exercises/$logId';
  static String workoutSummary(String id) => '/workout-sessions/$id/summary';
  static String workoutSessionDetail(String id) => '/workout-sessions/$id';
  static String workoutSaveAsTemplate(String id) =>
      '/workout-sessions/$id/save-as-template';

  // Custom Exercises
  static const String customExercises = '/exercises/custom';
  // TODO: endpoint not yet implemented in backend (zirofit-next)
  static const String trainerCustomExercises = '/trainer/exercises/custom';

  // Calendar
  static String calendarEvent(String id) => '/calendar/events/$id';

  // Programs & Templates
  static const String workoutPrograms = '/trainer/programs';
  static String createProgramTemplate(String pId) =>
      '/trainer/programs/$pId/templates';
  static String programExercises(String pId) =>
      '/trainer/programs/$pId/exercises';

  // Clients
  static const String clients = '/clients';
  static const String exercises = '/exercises';
  static const String clientDashboard = '/client/dashboard';
  static const String widgetConfig = '/client/widget-config';

  // Client Active Session
  static String clientActiveSession(String id) => '/clients/$id/session/active';

  // Client Active Program
  static String trainerClientActiveProgram(String id) =>
      '/trainer/clients/$id/program/active';
  static String clientCancelProgram(String clientId, String programId) =>
      '/trainer/clients/$clientId/program/$programId/cancel';
  static String clientPackages(String id) => '/clients/$id/packages';
  static String clientRequestCheckIn(String id) =>
      '/clients/$id/request-check-in';

  // Client Daily Targets
  static const String dailyTargets = '/client/daily-targets';

  // Client Analytics
  static const String clientAnalytics = '/client/analytics';

  // Explore
  static const String exploreFeatured = '/explore/featured';
  static const String exploreMetadata = '/explore/metadata';
  static const String exploreEvents = '/explore/events';

  // Trainers
  static const String trainersSearch = '/trainers';
  static const String trainersSpecialties = '/trainers/specialties';

  // Bookings & Events
  static const String bookings = '/bookings';
  static const String trainerBookings = '/trainer/bookings';
  static String bookingConfirm(String id) => '/bookings/$id/confirm';
  static String bookingDecline(String id) => '/bookings/$id/decline';
  static String bookingApprove(String id) => '/bookings/$id/approve';
  static const String events = '/events';
  static String eventDetail(String id) => '/events/$id';
  static String eventJoin(String id) => '/events/$id/join';
  static const String trainerEvents = '/trainer/events';
  static String trainerEventCrud(String id) => '/trainer/events/$id';
  static const String clientEvents = '/client/events';
  static String clientEventCancel(String bookingId) => '/client/events/$bookingId/cancel';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationMarkRead(String id) => '/notifications/$id';
  static const String registerDeviceToken = '/notifications/device-token';
  static const String unregisterDeviceToken = '/notifications/device-token';

  // Habits
  static const String clientHabits = '/client/habits';
  static String logHabit(String id) => '/client/habits/$id/log';
  static String trainerClientHabits(String cId) =>
      '/trainer/clients/$cId/habits';

  // Check-Ins
  static const String clientCheckIn = '/client/check-in';
  static const String clientCheckIns = '/client/check-ins';
  static const String trainerCheckIns = '/trainer/check-ins';

  /// Builds the trainer check-in detail path.
  static String trainerCheckInDetail(String id) => '/trainer/check-ins/$id';

  /// Builds the trainer check-in review path.
  static String trainerCheckInReview(String id) =>
      '/trainer/check-ins/$id/review';

  // Programs & Templates
  static const String trainerPrograms = '/trainer/programs';
  static const String trainerWorkoutTemplates = '/trainer/workout-templates';
  static const String clientPrograms = '/client/programs';
  static const String clientProgramTemplates = '/client/programs/templates';
  static String clientTemplateExercises(String tId) =>
      '/client/programs/templates/$tId/exercises';
  static String clientTemplateExerciseStep(String tId, String stepId) =>
      '/client/programs/templates/$tId/exercises/$stepId';
  static String clientTemplateRest(String tId) =>
      '/client/programs/templates/$tId/rest';
  static String clientTemplateCopy(String tId) =>
      '/client/programs/templates/$tId/copy';
  static const String clientActiveProgram = '/client/program/active';

  // Nutrition / Recipes
  static const String trainerRecipes = '/trainer/recipes';
  static String trainerRecipe(String id) => '/trainer/recipes/$id';
  static const String trainerProgramTemplates =
      '/trainer/programs/templates';
  static String templateExercises(String tId) =>
      '/trainer/programs/templates/$tId/exercises';
  static String templateExerciseStep(String tId, String stepId) =>
      '/trainer/programs/templates/$tId/exercises/$stepId';
  static String templateRest(String tId) =>
      '/trainer/programs/templates/$tId/rest';
  static String templateCopy(String tId) =>
      '/trainer/programs/templates/$tId/copy';
  static String programAssign(String programId) =>
      '/trainer/programs/$programId/assign';

  // Chat
  static const String chat = '/chat';

  // Client Booking
  static String trainerSchedule(String trainerId) => '/trainers/$trainerId/schedule';
  static String bookingCancel(String id) => '/bookings/$id/cancel';

  // Profile
  static const String profileMe = '/profile/me';
  static const String profileMeTextContent = '/profile/me/text-content';
  static const String profileMeServices = '/profile/me/services';
  static const String profileMePackages = '/profile/me/packages';
  static const String profileMeTestimonials = '/profile/me/testimonials';
  static const String profileMeBenefits = '/profile/me/benefits';
  static const String profileMeTransformations = '/profile/me/transformations';
  static const String profileMeExternalLinks = '/profile/me/external-links';
  static const String profileMeSocialLinks = '/profile/me/social-links';

  // Trainer Branding
  static const String trainerProfileAvatar = '/trainer/profile/avatar';
  static const String trainerProfileBanner = '/trainer/profile/banner';
  static const String trainerProfileBranding = '/trainer/profile/branding';

  // Trainer Settings
  static const String trainerSettings = '/trainer/settings';
  static const String trainerBookingSettings = '/trainer/booking/settings';
  static const String trainerAvailability = '/trainer/availability';

  // Resource Vault
  static const String trainerResourceVault = '/trainer/resource-vault';
  static String trainerResource(String id) => '/trainer/resource-vault/$id';
  static String assignResource(String id) =>
      '/trainer/resource-vault/$id/assign';

  // Billing
  static const String createCheckoutSession = '/checkout/session';
  static const String billingSubscription = '/billing/subscription';
  static const String billingPortal = '/billing/portal';
  static const String billingPayouts = '/billing/payouts';
  static const String billingRevenue = '/billing/revenue';
  static const String billingTransactions = '/billing/transactions';
  static const String billingStripeStatus = '/billing/stripe-status';
  static const String billingStripeOnboarding = '/billing/stripe-onboarding';

  // Trainer Stripe Connect
  static const String trainerStripeStatus = '/trainer/stripe/status';
  static const String trainerStripeOnboarding = '/trainer/stripe/onboarding';

  // Trainer Storefront
  static const String trainerStorefront = '/trainer/storefront';
  static const String trainerStorefrontVisibility = '/trainer/storefront/visibility';

  // Blog
  static const String blog = '/blog';
  static String blogPost(String slug) => '/blog/$slug';

  // System / Config
  static const String systemConfig = '/system/config';

  // Calendar & Scheduling
  static const String trainerCalendar = '/trainer/calendar';
  static String calendarSession(String id) => '/trainer/calendar/$id';
  static String sessionRemind(String id) =>
      '/trainer/calendar/sessions/$id/remind';
  static const String clientsSummary = '/trainer/calendar/clients-summary';
  static const String sessionCreationData = '/trainer/session-creation-data';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminEvents = '/admin/events';
  static String adminEvent(String id) => '/admin/events/$id';
  static const String adminBlog = '/admin/blog';
  static String adminBlogPost(String id) => '/admin/blog/$id';
  static const String adminUpload = '/admin/upload';
  static const String adminTickets = '/admin/tickets';
  static String adminTicket(String id) => '/admin/tickets/$id';
  static const String adminUsers = '/admin/users';
  static const String adminErrors = '/admin/errors';
  static const String adminFeatureToggles = '/admin/feature-toggles';

  // AI Coach & Mobile
  static const String aiCoachGenerate = '/mobile/ai-coach/generate';
  static const String aiCoachRefine = '/mobile/ai-coach/refine';
  static const String aiVoice = '/ai-trainer/voice';

  // Voice Coach / ElevenLabs
  static const String aiTrainerVoices = '/ai-trainer/voices';
  static const String aiTrainerTtsStream = '/ai-trainer/tts/stream';
  static const String userVoiceSettings = '/user/voice-settings';

  static const String mobileHome = '/mobile/home';

  // Upload
  static const String clientUpload = '/client/upload';

  // Support Tickets
  static const String supportTickets = '/support/tickets';
  static const String supportFeedback = '/support/feedback';

  // Client Progress
  static const String clientProgress = '/client/progress';

  // Assessments
  static const String trainerAssessments = '/trainer/assessments';
  static String clientAssessments(String id) => '/clients/$id/assessments';

  // Custom Domains
  static const String domainAdd = '/domain/add';
  static const String domainVerify = '/domain/verify';

  // Preferences
  static const String userPreferences = '/users/preferences';

  // Client Data Sharing
  static const String clientSharing = '/client/sharing';

  // Trainer Client Link Requests
  static String trainerClientAccept(String id) => '/trainer/clients/$id/accept';
  static String trainerClientDecline(String id) => '/trainer/clients/$id/decline';

  // Public Trainer Profile
  static String trainerPublicProfile(String username) => '/trainers/$username';

  // Client Connect Requests
  static String clientConnectTrainer(String trainerId) => '/client/trainers/$trainerId/connect';

  // Fitness Goals
  static const String fitnessGoals = '/client/fitness-goals';
  static String fitnessGoal(String id) => '/client/fitness-goals/$id';

  // Body measurements
  static String clientBodyMeasurements(String id) => '/clients/$id/body-measurements';
  static String clientBodyMeasurement(String clientId, String measurementId) =>
    '/clients/$clientId/body-measurements/$measurementId';
}
