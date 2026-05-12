import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_provider.dart';
import 'package:zirofit_fl/features/checkin/screens/check_in_screen.dart';
import '../../helpers/test_setup.dart';

class Fake extends CheckInNotifier {
  final CheckInState _s;
  Fake(this._s) : super(apiClient: ApiClient.instance) { super.state = _s; }
  @override CheckInState get state => _s;
  @override Future<void> submitCheckIn({required DateTime date, required double weight, double? waistCm, double? sleepHours, int? energyLevel, int? stressLevel, int? hungerLevel, int? digestionLevel, String? nutritionCompliance, String? clientNotes, XFile? frontPhoto, XFile? sidePhoto, XFile? backPhoto}) async {}
  @override Future<void> fetchLastCheckIn() async {}
  @override void reset() {}
  @override void clearError() {}
}

Widget b(CheckInState s) => ProviderScope(overrides: [checkInProvider.overrideWith((ref) => Fake(s))], child: const MaterialApp(home: CheckInScreen()));

void main() {
  setUpAll(() => configureTestApiClient());
  group('CheckInScreen', () {
    testWidgets('renders wizard step 1 (Body Metrics)', (t) async {
      await t.pumpWidget(b(const CheckInState()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      // AppBar
      expect(find.text('Weekly Check-in'), findsOneWidget);
      // Step indicator labels
      expect(find.text('Body Metrics'), findsOneWidget);
      expect(find.text('How You Feel'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      // Page 1 content
      expect(find.text('How did your body change?'), findsOneWidget);
      expect(find.text('Weight (kg) *'), findsOneWidget);
      // Bottom navigation
      expect(find.text('Next'), findsOneWidget);
      // No back button on step 1
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('navigates through all 4 steps', (t) async {
      await t.pumpWidget(b(const CheckInState()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      // Page 1: enter weight and tap Next
      await t.enterText(find.byType(TextFormField).first, '75.5');
      await t.pump();
      await t.tap(find.text('Next'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      // Now on page 2: How do you feel?
      expect(find.text('How do you feel?'), findsOneWidget);
      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next without selecting nutrition — should not advance
      await t.tap(find.text('Next'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      // Still on page 2
      expect(find.text('How do you feel?'), findsOneWidget);

      // Select nutrition compliance and tap Next
      final onTrack = find.text('On Track').last;
      await t.ensureVisible(onTrack);
      await t.pump();
      await t.tap(onTrack);
      await t.pump();
      await t.tap(find.text('Next'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      // Now on page 3: Photos
      expect(find.text('Progress Photos'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next
      await t.tap(find.text('Next'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      // Now on page 4: Notes
      expect(find.text('Weekly Notes'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('sliders show default values on step 2', (t) async {
      await t.pumpWidget(b(const CheckInState()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      // Navigate to step 2
      await t.enterText(find.byType(TextFormField).first, '75.5');
      await t.pump();
      await t.tap(find.text('Next'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      // All 4 sliders default to 5
      expect(find.text('5'), findsNWidgets(4));
    });

    testWidgets('submitting state shows loading indicator', (t) async {
      await t.pumpWidget(b(const CheckInState(isSubmitting: true)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      // On page 1, the Next button should be disabled when submitting
      // (We test the provider state directly; loading indicator in bottom nav)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('last check-in banner appears', (t) async {
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
