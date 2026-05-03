import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/chat/providers/chat_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ChatNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = ChatNotifier(api: mockApiClient);
  });

  group('ChatNotifier', () {
    test('initial state has empty messages, conversations, not loading', () {
      final state = notifier.state;
      expect(state.messages, isEmpty);
      expect(state.conversations, isEmpty);
      expect(state.isLoading, false);
      expect(state.isSending, false);
      expect(state.error, isNull);
      expect(state.activeConversationId, isNull);
    });

    test('fetchConversations sets loading true before completion', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.chat,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      final future = notifier.fetchConversations();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchConversations populates list on success', () async {
      final mockData = <String, dynamic>{
        'data': [
          {
            'id': 'conv-1',
            'trainer_id': 'trainer-1',
            'client_id': 'client-1',
            'last_message_at': 1700000000000,
            'created_at': 1700000000000,
            'updated_at': 1700000000000,
          },
          {
            'id': 'conv-2',
            'trainer_id': 'trainer-1',
            'client_id': 'client-2',
            'last_message_at': 1700001000000,
            'created_at': 1700000000000,
            'updated_at': 1700001000000,
          },
        ],
      };
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.chat,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => mockData);

      await notifier.fetchConversations();

      final state = notifier.state;
      expect(state.conversations.length, 2);
      expect(state.conversations[0].id, 'conv-1');
      expect(state.conversations[1].id, 'conv-2');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchConversations sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.chat,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.chat),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.chat),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Failed to load conversations'},
          },
        ),
      ));

      await notifier.fetchConversations();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Failed to load conversations');
      expect(state.conversations, isEmpty);
      expect(state.hasError, isTrue);
    });

    test('fetchMessages populates messages on success', () async {
      final mockData = <String, dynamic>{
        'data': [
          {
            'id': 'msg-1',
            'conversation_id': 'conv-1',
            'sender_id': 'user-1',
            'content': 'Hello!',
            'is_system_message': false,
            'created_at': 1700000000000,
          },
          {
            'id': 'msg-2',
            'conversation_id': 'conv-1',
            'sender_id': 'user-2',
            'content': 'Hi there!',
            'is_system_message': false,
            'created_at': 1700001000000,
          },
        ],
      };
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.chat,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => mockData);

      await notifier.fetchMessages('conv-1');

      final state = notifier.state;
      expect(state.messages.length, 2);
      expect(state.messages[0].content, 'Hello!');
      expect(state.messages[1].content, 'Hi there!');
      expect(state.activeConversationId, 'conv-1');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchMessages sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.chat,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: ApiConstants.chat),
      ));

      await notifier.fetchMessages('conv-1');

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Connection timeout. Please try again.');
      expect(state.messages, isEmpty);
    });

    test('sendMessage appends message and clears sending state', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.chat,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'msg-new',
              'conversation_id': 'conv-1',
              'sender_id': 'user-1',
              'content': 'New message',
              'is_system_message': false,
              'created_at': 1700002000000,
            },
          });

      // Pre-populate active conversation
      notifier = ChatNotifier(api: mockApiClient);
      notifier.state = notifier.state.copyWith(
        activeConversationId: 'conv-1',
      );

      await notifier.sendMessage(
        conversationId: 'conv-1',
        content: 'New message',
      );

      final state = notifier.state;
      expect(state.isSending, false);
      expect(state.error, isNull);
      expect(state.messages.length, 1);
      expect(state.messages[0].content, 'New message');
      expect(state.messages[0].id, 'msg-new');
    });

    test('sendMessage sets error on failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.chat,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.chat),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.chat),
          statusCode: 400,
          data: <String, dynamic>{
            'message': 'Bad request',
          },
        ),
      ));

      // Pre-populate active conversation
      notifier.state = notifier.state.copyWith(
        activeConversationId: 'conv-1',
      );

      await notifier.sendMessage(
        conversationId: 'conv-1',
        content: 'Failing message',
      );

      final state = notifier.state;
      expect(state.isSending, false);
      expect(state.error, 'Bad request');
    });

    test('clearError clears the error', () {
      notifier.state = notifier.state.copyWith(error: 'Some error');
      expect(notifier.state.hasError, isTrue);

      notifier.clearError();

      expect(notifier.state.error, isNull);
    });

    test('sendMessage creates optimistic message when server has no data', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.chat,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            // No 'data' key — simulates empty response
          });

      notifier.state = notifier.state.copyWith(
        activeConversationId: 'conv-1',
      );

      await notifier.sendMessage(
        conversationId: 'conv-1',
        content: 'Optimistic message',
      );

      final state = notifier.state;
      expect(state.isSending, false);
      expect(state.messages.length, 1);
      expect(state.messages[0].content, 'Optimistic message');
      // id should be a timestamp string
      expect(state.messages[0].id, isNotEmpty);
    });
  });
}
