class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://www.ziro.fit/api';
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

  // Sync
  static const String syncPull = '/sync/pull';
  static const String syncPush = '/sync/push';

  // Workout Sessions
  static const String workoutStart = '/workout-sessions/start';
  static const String workoutFinish = '/workout-sessions/finish';
  static const String workoutLive = '/workout-sessions/live';
  static const String workoutHistory = '/workout-sessions/history';
  static const String workoutRestStart = '/workout-sessions/rest/start';
  static const String workoutRestEnd = '/workout-sessions/rest/end';
  static const String workoutCancel = '/workout-sessions/cancel';

  // Clients
  static const String clients = '/clients';
  static const String exercises = '/exercises';

  // Explore
  static const String exploreFeatured = '/explore/featured';

  // Bookings & Events
  static const String bookings = '/bookings';
  static String bookingConfirm(String id) => '/bookings/$id/confirm';
  static String bookingDecline(String id) => '/bookings/$id/decline';
  static const String events = '/events';
  static String eventDetail(String id) => '/events/$id';
  static String eventJoin(String id) => '/events/$id/join';
  static const String trainerEvents = '/trainer/events';
  static String trainerEventCrud(String id) => '/trainer/events/$id';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationMarkRead(String id) => '/notifications/$id';

  // Habits
  static const String clientHabits = '/client/habits';
  static String logHabit(String id) => '/client/habits/$id/log';
  static String trainerClientHabits(String cId) => '/trainer/clients/$cId/habits';

  // Check-Ins
  static const String clientCheckIn = '/client/check-in';
  static const String trainerCheckIns = '/trainer/check-ins';

  /// Builds the trainer check-in detail path.
  static String trainerCheckInDetail(String id) =>
      '/trainer/check-ins/$id';

  /// Builds the trainer check-in review path.
  static String trainerCheckInReview(String id) =>
      '/trainer/check-ins/$id/review';

  // Programs & Templates
  static const String trainerPrograms = '/trainer/programs';

  // Nutrition / Recipes
  static const String trainerRecipes = '/trainer/recipes';
  static String trainerRecipe(String id) => '/trainer/recipes/$id';
  static String templateExercises(String tId) => '/trainer/programs/templates/$tId/exercises';
  static String templateCopy(String tId) => '/trainer/programs/templates/$tId/copy';

  // Chat
  static const String chat = '/chat';

  // Profile
  static const String profileMe = '/profile/me';
  static const String profileMeTextContent = '/profile/me/text-content';
  static const String profileMeServices = '/profile/me/services';
  static const String profileMePackages = '/profile/me/packages';
  static const String profileMeTestimonials = '/profile/me/testimonials';
  static const String profileMeBenefits = '/profile/me/benefits';

  // Trainer Settings
  static const String trainerSettings = '/trainer/settings';

  // Resource Vault
  static const String trainerResourceVault = '/trainer/resource-vault';
  static String trainerResource(String id) => '/trainer/resource-vault/$id';
  static String assignResource(String id) => '/trainer/resource-vault/$id/assign';

  // Billing
  static const String createCheckoutSession = '/checkout/session';
  static const String billingSubscription = '/billing/subscription';
  static const String billingPortal = '/billing/portal';

  // Blog
  static const String blog = '/blog';
  static String blogPost(String slug) => '/blog/$slug';

  // System / Config
  static const String systemConfig = '/system/config';

  // Calendar & Scheduling
  static const String trainerCalendar = '/trainer/calendar';
  static String calendarSession(String id) => '/trainer/calendar/$id';
  static String sessionRemind(String id) => '/trainer/calendar/sessions/$id/remind';
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

  // AI Coach
  static const String aiCoachGenerate = '/mobile/ai-coach/generate';
  static const String aiCoachRefine = '/mobile/ai-coach/refine';

  // Support Tickets
  static const String supportTickets = '/support/tickets';

  // Custom Domains
  static const String domainAdd = '/domain/add';
  static const String domainVerify = '/domain/verify';
}
