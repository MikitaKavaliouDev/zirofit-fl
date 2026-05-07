import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_provider.dart';
import 'package:zirofit_fl/features/progress/widgets/recovery_widget.dart';

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fake notifier so we can inject controlled lastCheckIn data
// ---------------------------------------------------------------------------

class FakeCheckInNotifier extends CheckInNotifier {
  FakeCheckInNotifier() : super(apiClient: MockApiClient());

  void setLastCheckIn(CheckIn? checkIn) {
    state = CheckInState(lastCheckIn: checkIn);
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

CheckIn createCheckIn({
  double? sleepHours = 8.0,
  int? energyLevel = 8,
  int? stressLevel = 3,
}) {
  final now = DateTime(2025, 6, 1);
  return CheckIn(
    id: 'ci-test',
    clientId: 'client-1',
    date: now,
    sleepHours: sleepHours,
    energyLevel: energyLevel,
    stressLevel: stressLevel,
    createdAt: now,
    updatedAt: now,
  );
}

extension PumpRecoveryWidget on WidgetTester {
  Future<void> pumpRecoveryWidget({CheckIn? checkIn}) async {
    final notifier = FakeCheckInNotifier();
    if (checkIn != null) {
      notifier.setLastCheckIn(checkIn);
    }

    await pumpWidget(
      ProviderScope(
        overrides: [
          checkInProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecoveryWidget(),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    registerFallbackValue(MockApiClient());
  });

  group('RecoveryWidget', () {
    testWidgets('shows empty state when no check-in data', (tester) async {
      await tester.pumpRecoveryWidget();
      await tester.pump();

      expect(
        find.text(
          'Complete a check-in to see\nyour recovery readiness.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    });

    testWidgets('shows readiness score with data', (tester) async {
      final checkIn = createCheckIn(
        sleepHours: 8.0,
        energyLevel: 8,
        stressLevel: 3,
      );
      await tester.pumpRecoveryWidget(checkIn: checkIn);
      await tester.pump();

      // Readiness score should be displayed
      // Sleep: 8h → 10.0, Energy: 8 → 8.0, Stress inverted: 11-3=8 → 8.0
      // Avg = (10+8+8)/3 = 8.67 → displayed as "8.7"
      expect(find.text('8.7'), findsOneWidget);
      expect(find.text('Readiness'), findsOneWidget);
    });

    testWidgets('shows sleep, energy, and stress bars', (tester) async {
      final checkIn = createCheckIn(
        sleepHours: 7.5,
        energyLevel: 9,
        stressLevel: 2,
      );
      await tester.pumpRecoveryWidget(checkIn: checkIn);
      await tester.pump();

      // Labels
      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('Energy'), findsOneWidget);
      expect(find.text('Stress'), findsOneWidget);

      // Display values
      expect(find.text('7.5h'), findsOneWidget);
      expect(find.text('9/10'), findsOneWidget);
      expect(find.text('2/10'), findsOneWidget);
    });

    testWidgets('colors change with values - green for high (>=7)',
        (tester) async {
      final checkIn = createCheckIn(
        sleepHours: 9.0, // score = 10.0 → green
        energyLevel: 8, // score = 8.0 → green
        stressLevel: 1, // inverted = 10.0 → green
      );
      await tester.pumpRecoveryWidget(checkIn: checkIn);
      await tester.pump();

      // avg = (10+8+10)/3 = 9.33 → "9.3" displayed in green
      expect(find.text('9.3'), findsOneWidget);
    });

    testWidgets('colors change with values - amber for medium (4-6)',
        (tester) async {
      final checkIn = createCheckIn(
        sleepHours: 4.0, // score = 5.0 → amber
        energyLevel: 5, // score = 5.0 → amber
        stressLevel: 6, // inverted = 5.0 → amber
      );
      await tester.pumpRecoveryWidget(checkIn: checkIn);
      await tester.pump();

      // avg = (5+5+5)/3 = 5.0
      expect(find.text('5.0'), findsOneWidget);
    });

    testWidgets('colors change with values - red for low (<4)',
        (tester) async {
      final checkIn = createCheckIn(
        sleepHours: 1.0, // score = 1.25 → red
        energyLevel: 2, // score = 2.0 → red
        stressLevel: 10, // inverted = 1.0 → red
      );
      await tester.pumpRecoveryWidget(checkIn: checkIn);
      await tester.pump();

      // avg = (1.25+2+1)/3 = 1.42 → displayed as "1.4"
      expect(find.text('1.4'), findsOneWidget);
    });

    testWidgets('uses last check-in data from provider', (tester) async {
      final now = DateTime(2025, 6, 1);
      final checkIn = CheckIn(
        id: 'ci-latest',
        clientId: 'client-1',
        date: now,
        sleepHours: 6.5,
        energyLevel: 6,
        stressLevel: 4,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpRecoveryWidget(checkIn: checkIn);
      await tester.pump();

      expect(find.text('6.5h'), findsOneWidget);
      expect(find.text('6/10'), findsOneWidget);
      expect(find.text('4/10'), findsOneWidget);
    });

    testWidgets('handles null sleep hours gracefully', (tester) async {
      final checkIn = createCheckIn(
        sleepHours: null,
        energyLevel: 7,
        stressLevel: 3,
      );
      await tester.pumpRecoveryWidget(checkIn: checkIn);
      await tester.pump();

      expect(find.text('—h'), findsOneWidget);
      expect(find.text('7/10'), findsOneWidget);
      expect(find.text('3/10'), findsOneWidget);
    });

    testWidgets('handles null energy gracefully', (tester) async {
      final checkIn = createCheckIn(
        sleepHours: 7.0,
        energyLevel: null,
        stressLevel: 3,
      );
      await tester.pumpRecoveryWidget(checkIn: checkIn);
      await tester.pump();

      expect(find.text('7.0h'), findsOneWidget);
      expect(find.text('—/10'), findsOneWidget);
      expect(find.text('3/10'), findsOneWidget);
    });

    testWidgets('handles null stress gracefully', (tester) async {
      final checkIn = createCheckIn(
        sleepHours: 7.0,
        energyLevel: 7,
        stressLevel: null,
      );
      await tester.pumpRecoveryWidget(checkIn: checkIn);
      await tester.pump();

      expect(find.text('7.0h'), findsOneWidget);
      expect(find.text('7/10'), findsOneWidget);
      expect(find.text('—/10'), findsOneWidget);
    });
  });
}
