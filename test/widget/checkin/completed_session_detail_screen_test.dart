import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/checkin/screens/completed_session_detail_screen.dart';
import '../../helpers/test_setup.dart';

/// Installs a Dio interceptor that immediately resolves every request with
/// an empty response so that no real HTTP calls are made.
void _mockDioResponses() {
  final dio = ApiClient.instance.dio;
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      handler.resolve(
        Response(
          data: {'data': <String, dynamic>{}},
          requestOptions: options,
        ),
      );
    },
  ));
}

Widget buildApp({String sessionId = 'test-session-1'}) => ProviderScope(
      child: MaterialApp(
        home: CompletedSessionDetailScreen(sessionId: sessionId),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    configureTestApiClient();
    _mockDioResponses();
  });

  group('CompletedSessionDetailScreen', () {
    testWidgets('shows session details screen without crashing',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildApp());
        // Flush Dio's Future-based interceptor chain
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      });

      // After the interceptor resolves, _detail stays null (empty response).
      // The screen shows the fallback title.
      expect(find.text('Session Details'), findsOneWidget);
    });

    testWidgets('renders app bar with session details title',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildApp(sessionId: 'session-abc'));
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      });

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Session Details'), findsOneWidget);
    });
  });
}
