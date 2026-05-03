import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_provider.dart';
import 'package:zirofit_fl/features/checkin/screens/check_in_screen.dart';
import '../../helpers/test_setup.dart';

class Fake extends CheckInNotifier {
  final CheckInState _s;
  Fake(this._s) : super(apiClient: ApiClient.instance) { super.state = _s; }
  @override CheckInState get state => _s;
  @override Future<void> submitCheckIn({required DateTime date, required double weight, double? waistCm, double? sleepHours, int? energyLevel, int? stressLevel, int? hungerLevel, int? digestionLevel, String? nutritionCompliance, String? clientNotes, dynamic photo}) async {}
  @override Future<void> fetchLastCheckIn() async {}
  @override void reset() {}
  @override void clearError() {}
}

Widget b(CheckInState s) => ProviderScope(overrides: [checkInProvider.overrideWith((ref) => Fake(s))], child: const MaterialApp(home: CheckInScreen()));

void main() {
  setUpAll(() => configureTestApiClient());
  group('CheckInScreen', () {
    testWidgets('renders form', (t) async {
      await t.pumpWidget(b(const CheckInState()));
      await t.pump(); await t.pump(const Duration(milliseconds: 200));
      expect(find.text('Weekly Check-in'), findsOneWidget);
      expect(find.text('Weight (kg) *'), findsOneWidget);
      expect(find.text('Wellness Metrics'), findsOneWidget);
      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Submit Check-In'), findsOneWidget);
    });
    testWidgets('sliders', (t) async {
      await t.pumpWidget(b(const CheckInState()));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text('5'), findsNWidgets(4));
    });
    testWidgets('submitting', (t) async {
      await t.pumpWidget(b(const CheckInState(isSubmitting: true)));
      // Use pump() not pumpAndSettle() because CircularProgressIndicator never settles
      await t.pump();
      expect(find.text('Submitting...'), findsOneWidget);
    });
    testWidgets('last check-in', (t) async {
      final now = DateTime.now();
      await t.pumpWidget(b(CheckInState(
        lastCheckIn: CheckIn(id: 'ci-1', clientId: 'c1', date: now.subtract(const Duration(days: 7)), weight: 75.5, createdAt: now, updatedAt: now),
      )));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Last check-in:'), findsOneWidget);
      expect(find.textContaining('75.5'), findsOneWidget);
    });
  });
}
