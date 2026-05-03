import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/trainer/screens/domain_settings_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('renders without crashing', (tester) async {
    await tester.pumpApp(const DomainSettingsScreen());
    await tester.pump();
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
