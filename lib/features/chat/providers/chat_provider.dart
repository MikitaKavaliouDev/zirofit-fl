import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/conversation.dart';
import 'package:zirofit_fl/data/models/message.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ChatState {
  final List<Message> messages;
  final List<Conversation> conversations;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final String? activeConversationId;

  const ChatState({
    this.messages = const [],
    this.conversations = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.activeConversationId,
  });

  ChatState copyWith({
    List<Message>? messages,
    List<Conversation>? conversations,
    bool? isLoading,
    bool? isSending,
    String? error,
    String? activeConversationId,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      activeConversationId:
          activeConversationId ?? this.activeConversationId,
    );
  }

  bool get hasError => error != null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiClient _api;
  final String? currentUserId;

  ChatNotifier({required ApiClient api, this.currentUserId}) : _api = api, super(const ChatState());

  /// Fetches the list of conversations for the current user.
  Future<void> fetchConversations() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.chat,
        queryParams: {'type': 'conversations'},
      );

      final List<Conversation> conversations;
      final rawData = response['data'];
      if (rawData is List) {
        conversations = rawData
            .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        conversations = [];
      }

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Fetches messages for a given [conversationId].
  Future<void> fetchMessages(String conversationId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      activeConversationId: conversationId,
    );

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.chat,
        queryParams: {
          'conversationId': conversationId,
          'type': 'messages',
        },
      );

      final List<Message> messages;
      final rawData = response['data'];
      if (rawData is List) {
        messages = rawData
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        messages = [];
      }

      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Sends a message in the given [conversationId] with [content].
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    state = state.copyWith(isSending: true, clearError: true);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chat,
        body: {
          'conversationId': conversationId,
          'content': content,
        },
      );

      final rawData = response['data'];
      Message sentMessage;
      if (rawData is Map<String, dynamic>) {
        sentMessage = Message.fromJson(rawData);
      } else {
        // Optimistic: create a local message if server doesn't echo
        sentMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          conversationId: conversationId,
          content: content,
          createdAt: DateTime.now(),
        );
      }

      state = state.copyWith(
        messages: [...state.messages, sentMessage],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Sends a message with optional media attachments.
  ///
  /// POSTs to [ApiConstants.chat] with [conversationId], [content],
  /// [mediaUrl] and [mediaType] so the backend can associate media with
  /// the message.
  Future<void> sendMessageWithMedia({
    required String conversationId,
    required String content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    state = state.copyWith(isSending: true, clearError: true);

    try {
      final body = <String, dynamic>{
        'conversationId': conversationId,
        'content': content,
      };
      if (mediaUrl != null) body['mediaUrl'] = mediaUrl;
      if (mediaType != null) body['mediaType'] = mediaType;

      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chat,
        body: body,
      );

      final rawData = response['data'];
      Message sentMessage;
      if (rawData is Map<String, dynamic>) {
        sentMessage = Message.fromJson(rawData);
      } else {
        sentMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          conversationId: conversationId,
          content: content,
          mediaUrl: mediaUrl,
          mediaType: mediaType,
          createdAt: DateTime.now(),
        );
      }

      state = state.copyWith(
        messages: [...state.messages, sentMessage],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Uploads a file at [filePath] to the server.
  ///
  /// POSTs to [ApiConstants.clientUpload] as [FormData] and returns the
  /// uploaded file URL on success.
  Future<String> uploadFile(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _api.dio.post<Map<String, dynamic>>(
      ApiConstants.clientUpload,
      data: formData,
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Upload returned empty response');
    }
    return (data['url'] ?? data['data']?['url'] ?? '') as String;
  }

  /// Clears any error in the state.
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
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final apiClient = ApiClient.instance;
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  return ChatNotifier(api: apiClient, currentUserId: userId);
});
