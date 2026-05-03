import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/clients/screens/my_trainer_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('renders without crashing', (tester) async {
    await tester.pumpApp(const MyTrainerScreen());
    // Use pump with zero duration to avoid timer issues
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
