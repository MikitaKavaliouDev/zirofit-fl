import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/features/programs/providers/template_picker_provider.dart';
import 'package:zirofit_fl/features/programs/screens/routine_builder_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake TemplatePickerNotifier – controllable template list
// ---------------------------------------------------------------------------

class FakeTemplatePickerNotifier extends TemplatePickerNotifier {
  final TemplatePickerState _state;

  FakeTemplatePickerNotifier(this._state)
      : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  TemplatePickerState get state => _state;

  @override
  Future<void> loadTemplates() async {}

  @override
  void search(String query) {}
}

// ---------------------------------------------------------------------------
// Test app builder
// ---------------------------------------------------------------------------

Widget buildApp({TemplatePickerState? templatePickerState}) {
  return ProviderScope(
    overrides: [
      if (templatePickerState != null)
        templatePickerProvider.overrideWith(
          (ref) => FakeTemplatePickerNotifier(templatePickerState),
        ),
    ],
    child: const MaterialApp(home: RoutineBuilderScreen()),
  );
}

// ---------------------------------------------------------------------------
// Shared template data
// ---------------------------------------------------------------------------

final _now = DateTime.now();

final _templates = [
  WorkoutTemplate(
    id: 't1',
    name: 'Full Body',
    programId: 'p1',
    createdAt: _now,
    updatedAt: _now,
  ),
  WorkoutTemplate(
    id: 't2',
    name: 'Upper / Lower Split',
    programId: 'p1',
    createdAt: _now,
    updatedAt: _now,
  ),
];

final _templatePickerState = TemplatePickerState(
  templates: _templates,
  isLoading: false,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('RoutineBuilderScreen', () {
    testWidgets('renders with New Routine title', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('New Routine'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows name and description fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Routine Name'), findsOneWidget);
      expect(find.text('Description (optional)'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Empty-state placeholder
      expect(find.text('Add your first workout template'), findsOneWidget);
    });

    testWidgets('add workout button shows template picker', (tester) async {
      await tester.pumpWidget(buildApp(templatePickerState: _templatePickerState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap "Add Workout"
      await tester.tap(find.text('Add Workout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Template picker bottom sheet should appear
      expect(find.text('Choose Template'), findsOneWidget);
      expect(find.text('Full Body'), findsOneWidget);
      expect(find.text('Upper / Lower Split'), findsOneWidget);
    });

    testWidgets('can edit day labels', (tester) async {
      await tester.pumpWidget(buildApp(templatePickerState: _templatePickerState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Add a workout slot via the picker
      await tester.tap(find.text('Add Workout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Full Body'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Slot added with default label "Day 1"
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('1 session'), findsOneWidget);

      // Edit the day label
      final labelField = find.byType(TextField).first;
      await tester.enterText(labelField, 'Push Day');
      await tester.pump();

      // Verify the text field contains the new label
      final textField = tester.widget<TextField>(labelField);
      expect(textField.controller?.text, 'Push Day');
    });

    testWidgets('can remove template slots', (tester) async {
      await tester.pumpWidget(buildApp(templatePickerState: _templatePickerState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Add a workout slot
      await tester.tap(find.text('Add Workout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Full Body'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Slot is visible
      expect(find.text('Full Body'), findsOneWidget);
      expect(find.text('1 session'), findsOneWidget);

      // Tap the delete icon button
      await tester.tap(find.byTooltip('Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Slot should be removed and empty placeholder restored
      expect(find.text('Full Body'), findsNothing);
      expect(find.text('Add your first workout template'), findsOneWidget);
      expect(find.text('0 sessions'), findsNothing);
    });

    testWidgets('save button persists routine', (tester) async {
      final navKey = GlobalKey<NavigatorState>();

      // Start with a plain root route so we can push the builder on top
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            navigatorKey: navKey,
            home: const Scaffold(),
          ),
        ),
      );

      Map<String, dynamic>? savedResult;

      // Push the RoutineBuilderScreen and capture the pop result
      navKey.currentState!
          .push<Map<String, dynamic>>(
            MaterialPageRoute(
              builder: (_) => const RoutineBuilderScreen(),
            ),
          )
          .then((r) => savedResult = r);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Fill in name and description
      await tester.enterText(find.byType(TextFormField).at(0), 'My Routine');
      await tester.enterText(find.byType(TextFormField).at(1), 'A great routine');

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the result was captured from Navigator.pop
      expect(savedResult, isNotNull);
      expect(savedResult!['name'], 'My Routine');
      expect(savedResult!['description'], 'A great routine');
      expect(savedResult!['slots'], isA<List>());
      expect((savedResult!['slots'] as List).length, 0);

      // Screen should be popped off the stack
      expect(find.byType(RoutineBuilderScreen), findsNothing);
    });
  });
}
