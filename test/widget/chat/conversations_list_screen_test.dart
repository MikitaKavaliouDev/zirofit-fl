import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/conversation.dart';
import 'package:zirofit_fl/features/chat/providers/chat_provider.dart';
import 'package:zirofit_fl/features/chat/screens/conversations_list_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeChatNotifier extends ChatNotifier {
  final ChatState _overriddenState;

  FakeChatNotifier(this._overriddenState)
      : super(api: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  ChatState get state => _overriddenState;

  @override
  Future<void> fetchConversations() async {}

  @override
  Future<void> fetchMessages(String conversationId) async {}

  @override
  Future<void> sendMessage(
      {required String conversationId, required String content}) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Conversation _createConversation({
  String id = 'conv-1',
  String trainerId = 'trainer-1',
  String clientId = 'client-1',
  DateTime? lastMessageAt,
}) {
  return Conversation(
    id: id,
    trainerId: trainerId,
    clientId: clientId,
    lastMessageAt: lastMessageAt ?? DateTime(2024, 1, 15),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 15),
  );
}

Widget buildTestApp(ChatState state) {
  return ProviderScope(
    overrides: [
      chatProvider.overrideWith((ref) => FakeChatNotifier(state)),
    ],
    child: const MaterialApp(
      home: ConversationsListScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading and no conversations',
      (tester) async {
    await tester.pumpWidget(buildTestApp(
      const ChatState(isLoading: true, conversations: []),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows conversation list when loaded', (tester) async {
    final conversations = [
      _createConversation(id: 'conv-1', clientId: 'Alice'),
      _createConversation(id: 'conv-2', clientId: 'Bob'),
    ];

    await tester.pumpWidget(buildTestApp(
      ChatState(conversations: conversations, isLoading: false),
    ));
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Tap to open chat'), findsNWidgets(2));
  });

  testWidgets('shows empty state when no conversations', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const ChatState(conversations: [], isLoading: false),
    ));
    await tester.pump();

    expect(find.text('No conversations yet'), findsOneWidget);
    expect(find.text('Start a conversation with your trainer or client'),
        findsOneWidget);
  });

  testWidgets('shows error state with retry button', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const ChatState(
          conversations: [],
          isLoading: false,
          error: 'Network error'),
    ));
    await tester.pump();

    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}