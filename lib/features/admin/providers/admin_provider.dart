import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/blog_post.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/data/models/support_ticket.dart';
import 'package:zirofit_fl/data/models/system_error.dart';
import 'package:zirofit_fl/data/models/user.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AdminState {
  // Existing
  final Map<String, dynamic>? stats;
  final List<Event> pendingEvents;
  final List<BlogPost> blogPosts;
  final List<SupportTicket> tickets;

  // Users
  final List<User> users;
  final int totalUsers;
  final int usersPage;
  final int usersLimit;

  // Errors
  final List<SystemError> errors;
  final int totalErrors;
  final int errorsPage;
  final int errorsLimit;

  // Feature toggles
  final Map<String, dynamic>? featureToggles;

  final bool isLoading;
  final String? error;

  const AdminState({
    this.stats,
    this.pendingEvents = const [],
    this.blogPosts = const [],
    this.tickets = const [],
    this.users = const [],
    this.totalUsers = 0,
    this.usersPage = 1,
    this.usersLimit = 20,
    this.errors = const [],
    this.totalErrors = 0,
    this.errorsPage = 1,
    this.errorsLimit = 20,
    this.featureToggles,
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    Map<String, dynamic>? stats,
    List<Event>? pendingEvents,
    List<BlogPost>? blogPosts,
    List<SupportTicket>? tickets,
    List<User>? users,
    int? totalUsers,
    int? usersPage,
    int? usersLimit,
    List<SystemError>? errors,
    int? totalErrors,
    int? errorsPage,
    int? errorsLimit,
    Map<String, dynamic>? featureToggles,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearStats = false,
    bool clearFeatureToggles = false,
  }) {
    return AdminState(
      stats: clearStats ? null : (stats ?? this.stats),
      pendingEvents: pendingEvents ?? this.pendingEvents,
      blogPosts: blogPosts ?? this.blogPosts,
      tickets: tickets ?? this.tickets,
      users: users ?? this.users,
      totalUsers: totalUsers ?? this.totalUsers,
      usersPage: usersPage ?? this.usersPage,
      usersLimit: usersLimit ?? this.usersLimit,
      errors: errors ?? this.errors,
      totalErrors: totalErrors ?? this.totalErrors,
      errorsPage: errorsPage ?? this.errorsPage,
      errorsLimit: errorsLimit ?? this.errorsLimit,
      featureToggles:
          clearFeatureToggles ? null : (featureToggles ?? this.featureToggles),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final adminProvider =
    StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AdminNotifier extends StateNotifier<AdminState> {
  final ApiClient _api;

  AdminNotifier({required ApiClient apiClient})
      : _api = apiClient,
        super(const AdminState());

  /// GET /api/admin/stats
  Future<void> fetchStats() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.adminStats,
      );

      final data = result['data'] as Map<String, dynamic>? ?? result;

      state = state.copyWith(stats: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// GET /api/admin/events
  Future<void> fetchPendingEvents() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.adminEvents,
      );

      final rawList = result['data'] as List<dynamic>? ?? [];
      final events = rawList
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(pendingEvents: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// PATCH /api/admin/events/[id] — action: 'approve' or 'reject'
  Future<void> moderateEvent(String id, String action) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.patch<Map<String, dynamic>>(
        ApiConstants.adminEvent(id),
        body: {'action': action},
      );

      // Remove from pending list on success
      state = state.copyWith(
        pendingEvents: state.pendingEvents.where((e) => e.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// GET /api/admin/blog
  Future<void> fetchBlogPosts() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.adminBlog,
      );

      final rawList = result['data'] as List<dynamic>? ?? [];
      final posts = rawList
          .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(blogPosts: posts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// POST /api/admin/blog
  Future<void> createBlogPost(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.post<Map<String, dynamic>>(
        ApiConstants.adminBlog,
        body: data,
      );

      final post =
          BlogPost.fromJson(result['data'] as Map<String, dynamic>);

      state = state.copyWith(
        blogPosts: [...state.blogPosts, post],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// DELETE /api/admin/blog/[id]
  Future<void> deleteBlogPost(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.delete(ApiConstants.adminBlogPost(id));

      state = state.copyWith(
        blogPosts: state.blogPosts.where((p) => p.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// GET /api/admin/tickets
  Future<void> fetchTickets() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.adminTickets,
      );

      final rawList = result['data'] as List<dynamic>? ?? [];
      final tickets = rawList
          .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(tickets: tickets, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// PATCH /api/admin/tickets/[id]
  Future<void> updateTicketStatus(String id, String status) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.patch<Map<String, dynamic>>(
        ApiConstants.adminTicket(id),
        body: {'status': status},
      );

      // Update the ticket in the list
      state = state.copyWith(
        tickets: state.tickets.map((t) {
          if (t.id == id) {
            return SupportTicket(
              id: t.id,
              userId: t.userId,
              category: t.category,
              message: t.message,
              appVersion: t.appVersion,
              osVersion: t.osVersion,
              status: status,
              createdAt: t.createdAt,
              updatedAt: t.updatedAt,
            );
          }
          return t;
        }).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  /// GET /api/admin/users?page=&limit=&role=
  Future<void> fetchUsers({
    int page = 1,
    int limit = 20,
    String? role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (role != null) {
        queryParams['role'] = role;
      }

      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.adminUsers,
        queryParams: queryParams,
      );

      final data = result['data'] as Map<String, dynamic>? ?? result;
      final rawList = data['users'] as List<dynamic>? ?? [];
      final users =
          rawList.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();

      state = state.copyWith(
        users: users,
        totalUsers: (data['total'] as num?)?.toInt() ?? 0,
        usersPage: (data['page'] as num?)?.toInt() ?? page,
        usersLimit: (data['limit'] as num?)?.toInt() ?? limit,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Errors
  // ---------------------------------------------------------------------------

  /// GET /api/admin/errors?page=&limit=&severity=
  Future<void> fetchErrors({
    int page = 1,
    int limit = 20,
    String? severity,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (severity != null) {
        queryParams['severity'] = severity;
      }

      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.adminErrors,
        queryParams: queryParams,
      );

      final data = result['data'] as Map<String, dynamic>? ?? result;
      final rawList = data['errors'] as List<dynamic>? ?? [];
      final errors = rawList
          .map((e) => SystemError.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        errors: errors,
        totalErrors: (data['total'] as num?)?.toInt() ?? 0,
        errorsPage: (data['page'] as num?)?.toInt() ?? page,
        errorsLimit: (data['limit'] as num?)?.toInt() ?? limit,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Feature Toggles
  // ---------------------------------------------------------------------------

  /// GET /api/admin/feature-toggles
  Future<void> fetchFeatureToggles() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.adminFeatureToggles,
      );

      final data = result['data'] as Map<String, dynamic>? ?? result;

      state = state.copyWith(
        featureToggles: Map<String, dynamic>.from(data),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// PUT /api/admin/feature-toggles
  Future<void> updateFeatureToggle(String key, String value) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.adminFeatureToggles,
        body: {'key': key, 'value': value},
      );

      // Update local state
      final updated = Map<String, dynamic>.from(
        state.featureToggles ?? {},
      );
      updated[key] = value == 'true';

      state = state.copyWith(
        featureToggles: updated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Clears any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final errorData = error.response!.data as Map;
        if (errorData['error'] is Map) {
          return (errorData['error'] as Map)['message'] as String? ??
              'An error occurred';
        }
        if (errorData['message'] is String) {
          return errorData['message'] as String;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          break;
      }
      return 'Something went wrong. Please try again.';
    }
    return error.toString();
  }
}
