import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/message.dart';
import 'package:zirofit_fl/features/chat/providers/chat_provider.dart';
import 'package:zirofit_fl/features/chat/screens/chat_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// FakeNotifier for ChatScreen widget tests
// ---------------------------------------------------------------------------

class FakeChatNotifier extends ChatNotifier {
  ChatState _state;

  FakeChatNotifier(this._state)
      : super(api: ApiClient.instance) {
    super.state = _state;
  }

  @override
  ChatState get state => _state;

  void emit(ChatState newState) {
    _state = newState;
    super.state = newState;
  }

  @override
  Future<void> fetchMessages(String conversationId) async {}

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {}

  @override
  void clearError() {}
}

// ---------------------------------------------------------------------------
// Test helper
// ---------------------------------------------------------------------------

Widget buildTestWidget(ChatState state) {
  return ProviderScope(
    overrides: [
      chatProvider.overrideWith((ref) => FakeChatNotifier(state)),
    ],
    child: const MaterialApp(
      home: ChatScreen(conversationId: 'test-conv-1'),
    ),
  );
}

void main() {
  setUpAll(() => configureTestApiClient());

  group('ChatScreen', () {
    testWidgets('shows loading indicator when loading and no messages',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ChatState(isLoading: true)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays messages in the list', (tester) async {
      final messages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'user-1',
          content: 'Hello from the other side',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        ),
        Message(
          id: 'msg-2',
          conversationId: 'conv-1',
          content: 'Reply from me',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1700001000000),
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(ChatState(
          messages: messages,
          activeConversationId: 'conv-1',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello from the other side'), findsOneWidget);
      expect(find.text('Reply from me'), findsOneWidget);
    });

    testWidgets('shows empty state when no messages', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ChatState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No messages yet'), findsOneWidget);
      expect(
        find.text('Send a message to start the conversation'),
        findsOneWidget,
      );
    });

    testWidgets('has an input bar and send button', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ChatState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('typing in the text field works', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ChatState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test message');
      await tester.pumpAndSettle();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('shows error banner when there is an error', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ChatState(
          isLoading: false,
          error: 'Something went wrong',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
