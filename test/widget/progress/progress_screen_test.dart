import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/progress/screens/progress_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('Progress screen renders progress content', (tester) async {
    await tester.pumpApp(const ProgressScreen());
    await tester.pumpAndSettle();

    // Verify app bar title
    expect(find.text('Progress'), findsOneWidget);
    // Verify placeholder text
    expect(find.text('Progress Tracking — coming soon'), findsOneWidget);
  });
}