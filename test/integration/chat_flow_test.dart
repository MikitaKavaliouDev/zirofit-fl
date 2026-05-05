import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/chat/providers/chat_provider.dart';
import '../helpers/provider_utils.dart';
import '../helpers/response_fixture.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

const _testTimestamp = 1700000000000;

Map<String, dynamic> _conversationJson({
  String id = 'conv-1',
  String trainerId = 'trainer-1',
  String clientId = 'client-1',
}) {
  return {
    'id': id,
    'trainer_id': trainerId,
    'client_id': clientId,
    'last_message_at': _testTimestamp,
    'created_at': _testTimestamp,
    'updated_at': _testTimestamp,
  };
}

Map<String, dynamic> _messageJson({
  String id = 'msg-1',
  String conversationId = 'conv-1',
  String? senderId = 'user-1',
  String content = 'Hello!',
}) {
  return {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'is_system_message': false,
    'created_at': _testTimestamp,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  tearDown(() {
    container.dispose();
  });

  group('ChatNotifier — full flow', () {
    setUp(() {
      container = createTestContainer(overrides: [
        chatProvider.overrideWith(
          (ref) => ChatNotifier(api: mockApiClient),
        ),
      ]);
    });

    test('initial state has empty conversations and messages', () {
      final state = container.read(chatProvider);
      expect(state.conversations, isEmpty);
      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isSending, isFalse);
      expect(state.error, isNull);
      expect(state.activeConversationId, isNull);
    });

    test('load conversations → open one → send message → message appears',
        () async {
      // Arrange: mock conversations endpoint
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.chat,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              _conversationJson(id: 'conv-1', clientId: 'client-a'),
              _conversationJson(id: 'conv-2', clientId: 'client-b'),
            ],
          });

      // Act: fetch conversations
      await container.read(chatProvider.notifier).fetchConversations();

      // Assert: two conversations loaded
      var state = container.read(chatProvider);
      expect(state.conversations, hasLength(2));
      expect(state.conversations[0].id, 'conv-1');
      expect(state.conversations[1].id, 'conv-2');
      expect(state.isLoading, isFalse);

      // Arrange: mock messages endpoint for conv-1
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.chat,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              _messageJson(id: 'msg-1', content: 'Welcome!'),
              _messageJson(id: 'msg-2', content: 'How are you?'),
            ],
          });

      // Act: fetch messages for conv-1
      await container
          .read(chatProvider.notifier)
          .fetchMessages('conv-1');

      // Assert: messages loaded
      state = container.read(chatProvider);
      expect(state.messages, hasLength(2));
      expect(state.messages[0].content, 'Welcome!');
      expect(state.messages[1].content, 'How are you?');
      expect(state.activeConversationId, 'conv-1');

      // Arrange: mock send message endpoint
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.chat,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _messageJson(
              id: 'msg-3',
              content: 'I am good, thanks!',
            ),
          });

      // Act: send message
      await container.read(chatProvider.notifier).sendMessage(
            conversationId: 'conv-1',
            content: 'I am good, thanks!',
          );

      // Assert: message appended
      state = container.read(chatProvider);
      expect(state.messages, hasLength(3));
      expect(state.messages[2].content, 'I am good, thanks!');
      expect(state.isSending, isFalse);
      expect(state.error, isNull);
    });

    test('sendMessage sets error on failure', () async {
      // Arrange: mock a failing send
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.chat,
            body: any(named: 'body'),
          )).thenThrow(Exception('Failed to send'));

      // Act
      await container.read(chatProvider.notifier).sendMessage(
            conversationId: 'conv-1',
            content: 'Hello',
          );

      // Assert
      final state = container.read(chatProvider);
      expect(state.isSending, isFalse);
      expect(state.error, isNotNull);
      expect(state.messages, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Response shape verification
    // -------------------------------------------------------------------------

    test('fetchConversations handles empty list', () async {
      // Backend shape: GET /chat?type=conversations → {"data": [...]}
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.chat,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => dataListResponse(<dynamic>[]));

      await container.read(chatProvider.notifier).fetchConversations();

      final state = container.read(chatProvider);
      expect(state.conversations, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchConversations sets error on DioException with error envelope',
        () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.chat,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.chat),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.chat),
          statusCode: 403,
          data: errorResponse(message: 'Forbidden'),
        ),
        type: DioExceptionType.badResponse,
      ));

      await container.read(chatProvider.notifier).fetchConversations();

      final state = container.read(chatProvider);
      expect(state.error, contains('Forbidden'));
      expect(state.isLoading, isFalse);
    });

    test('fetchMessages handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.chat,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => dataListResponse(<dynamic>[]));

      await container
          .read(chatProvider.notifier)
          .fetchMessages('conv-empty');

      final state = container.read(chatProvider);
      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.activeConversationId, 'conv-empty');
    });

    test('sendMessage parses data envelope correctly', () async {
      // Backend shape: POST /chat → {"data": {"message": {...}}}
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.chat,
            body: any(named: 'body'),
          )).thenAnswer((_) async => dataResponse(
              _messageJson(id: 'msg-sent', content: 'Hello world')));

      await container.read(chatProvider.notifier).sendMessage(
            conversationId: 'conv-1',
            content: 'Hello world',
          );

      final state = container.read(chatProvider);
      expect(state.messages, hasLength(1));
      expect(state.messages[0].content, 'Hello world');
      expect(state.messages[0].id, 'msg-sent');
      expect(state.isSending, isFalse);
    });
  });
}
