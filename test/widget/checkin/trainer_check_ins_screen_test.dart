import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/trainer_check_ins_provider.dart';
import 'package:zirofit_fl/features/checkin/screens/trainer_check_ins_screen.dart';
import '../../helpers/test_setup.dart';

class FakeTrainerCheckInsNotifier extends TrainerCheckInsNotifier {
  final TrainerCheckInsState _state;
  FakeTrainerCheckInsNotifier(this._state) : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  TrainerCheckInsState get state => _state;

  @override
  Future<void> fetchCheckIns({String? status}) async {}

  @override
  Future<void> fetchCheckInDetail(String id) async {}

  @override
  Future<void> submitReview({
    required String checkInId,
    required String responseText,
    String status = 'REVIEWED',
  }) async {}

  @override
  void clearError() {}

  @override
  void clearReviewError() {}
}

Widget buildApp(TrainerCheckInsState state) => ProviderScope(
      overrides: [
        trainerCheckInsProvider
            .overrideWith((ref) => FakeTrainerCheckInsNotifier(state)),
      ],
      child: const MaterialApp(home: TrainerCheckInsScreen()),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerCheckInsScreen', () {
    testWidgets('renders loading indicator when isLoading and empty list',
        (tester) async {
      await tester.pumpWidget(buildApp(const TrainerCheckInsState(isLoading: true)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state when error and empty list', (tester) async {
      await tester.pumpWidget(buildApp(const TrainerCheckInsState(error: 'Network error')));
      await tester.pump();
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('renders empty state when no check-ins', (tester) async {
      await tester.pumpWidget(buildApp(const TrainerCheckInsState()));
      await tester.pump();
      expect(find.text('No check-ins yet'), findsOneWidget);
      expect(find.text('Check-ins from your clients will appear here'), findsOneWidget);
    });

    testWidgets('renders pending and reviewed sections with check-ins', (tester) async {
      final now = DateTime.now();
      final dateFormat = DateFormat('MMM d, yyyy');
      final pendingCheckIn = CheckIn(
        id: 'ci-1',
        clientId: 'c1',
        date: now,
        weight: 75.5,
        status: 'SUBMITTED',
        createdAt: now,
        updatedAt: now,
      );
      final reviewedCheckIn = CheckIn(
        id: 'ci-2',
        clientId: 'c1',
        date: now.subtract(const Duration(days: 1)),
        weight: 74.0,
        status: 'REVIEWED',
        createdAt: now,
        updatedAt: now,
      );
      final state = TrainerCheckInsState(
        checkIns: [pendingCheckIn, reviewedCheckIn],
      );
      await tester.pumpWidget(buildApp(state));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Reviewed'), findsOneWidget);
      expect(find.text('Check-in ${dateFormat.format(now)}'), findsOneWidget);
      expect(find.text('75.5 kg'), findsOneWidget);
      expect(find.text('SUBMITTED'), findsOneWidget);
      expect(find.text('74.0 kg'), findsOneWidget);
      expect(find.text('REVIEWED'), findsOneWidget);
    });

    testWidgets('refresh button exists', (tester) async {
      await tester.pumpWidget(buildApp(const TrainerCheckInsState()));
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}