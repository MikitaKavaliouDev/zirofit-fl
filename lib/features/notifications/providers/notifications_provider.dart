import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/notification_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class NotificationsState {
  final List<Notification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<Notification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount:
          unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiClient _api;

  NotificationsNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const NotificationsState());

  /// GET /api/notifications
  ///
  /// Optionally filters by [notificationTypes] (comma-separated).
  Future<void> fetchNotifications({List<String>? notificationTypes}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{};
      if (notificationTypes != null && notificationTypes.isNotEmpty) {
        queryParams['types'] = notificationTypes.join(',');
      }

      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.notifications,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      final rawList = result['data'] as List<dynamic>? ?? [];
      final notifications = rawList
          .map((e) => Notification.fromJson(e as Map<String, dynamic>))
          .toList();
      final unreadCount =
          notifications.where((n) => !n.readStatus).length;

      state = NotificationsState(
        notifications: notifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// PUT /api/notifications/[id]
  Future<void> markRead(String id) async {
    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.notificationMarkRead(id),
      );

      // Update locally
      final updated = state.notifications.map((n) {
        if (n.id == id && !n.readStatus) {
          final json = n.toJson();
          json['read_status'] = true;
          return Notification.fromJson(json);
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updated,
        unreadCount: updated.where((n) => !n.readStatus).length,
      );
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }
  }

  /// POST /api/trainer/clients/{clientId}/accept
  ///
  /// Accepts a client link request and removes the notification from the list.
  Future<void> acceptLinkRequest(String clientId) async {
    try {
      await _api.post<Map<String, dynamic>>(
        ApiConstants.trainerClientAccept(clientId),
      );
      _removeNotificationsForClient(clientId);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }
  }

  /// POST /api/trainer/clients/{clientId}/decline
  ///
  /// Declines a client link request and removes the notification from the list.
  Future<void> declineLinkRequest(String clientId) async {
    try {
      await _api.post<Map<String, dynamic>>(
        ApiConstants.trainerClientDecline(clientId),
      );
      _removeNotificationsForClient(clientId);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }
  }

  /// Removes all notifications for a given client from the local list.
  void _removeNotificationsForClient(String clientId) {
    final updated = state.notifications.where((n) {
      final meta = n.metadata;
      if (meta == null) return true;
      return meta['client_id'] != clientId;
    }).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.readStatus).length,
    );
  }

  /// Clears any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

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

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final notificationsProvider = StateNotifierProvider<
    NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
