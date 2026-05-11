import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/trainer_assessment.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_assessments_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_assessments_screen.dart';
import '../../helpers/test_setup.dart';

class FakeAssessmentsNotifier extends TrainerAssessmentsNotifier {
  TrainerAssessmentsState _s;
  FakeAssessmentsNotifier(this._s)
      : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  TrainerAssessmentsState get state => _s;

  void emit(TrainerAssessmentsState ns) {
    _s = ns;
    super.state = ns;
  }

  @override
  Future<void> fetchAssessments() async {}

  @override
  Future<TrainerAssessment?> createAssessment(Map<String, dynamic> data) async {
    final assessment = TrainerAssessment(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      unit: data['unit'] as String? ?? 'kg',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    emit(state.copyWith(assessments: [...state.assessments, assessment]));
    return assessment;
  }

  @override
  Future<TrainerAssessment?> updateAssessment(
      String id, Map<String, dynamic> data) async {
    final updated = state.assessments.map((a) {
      if (a.id == id) {
        return a.copyWith(
          name: data['name'] as String? ?? a.name,
          description: data['description'] as String? ?? a.description,
          unit: data['unit'] as String? ?? a.unit,
        );
      }
      return a;
    }).toList();
    emit(state.copyWith(assessments: updated));
    return updated.firstWhere((a) => a.id == id);
  }

  @override
  Future<void> deleteAssessment(String id) async {
    emit(state.copyWith(
      assessments: state.assessments.where((a) => a.id != id).toList(),
    ));
  }
}

Widget buildTestApp(TrainerAssessmentsState state) => ProviderScope(
      overrides: [
        trainerAssessmentsProvider
            .overrideWith((ref) => FakeAssessmentsNotifier(state)),
      ],
      child: const MaterialApp(
        home: TrainerAssessmentsScreen(),
      ),
    );

TrainerAssessment makeAssessment({
  String id = '1',
  String name = 'Body Fat',
  String? description,
  String unit = 'kg',
}) =>
    TrainerAssessment(
      id: id,
      name: name,
      description: description,
      unit: unit,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerAssessmentsScreen', () {
    testWidgets('Test 1: Shows existing assessments', (tester) async {
      final assessments = [
        makeAssessment(
          id: '1',
          name: 'Body Fat',
          unit: 'cm',
          description: 'Body measurement',
        ),
        makeAssessment(
          id: '2',
          name: 'Weight',
          unit: 'kg',
        ),
      ];
      final state = TrainerAssessmentsState(
        assessments: assessments,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Body Fat'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('cm'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
      expect(find.text('Assessment Templates'), findsOneWidget);
    });

    testWidgets('Test 2: Add form validates + creates', (tester) async {
      const state = TrainerAssessmentsState(assessments: [], isLoading: false);
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Shows empty state
      expect(find.text('No assessment templates yet'), findsOneWidget);

      // Tap the Add button in the AppBar
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Add Template'), findsAtLeastNWidgets(1));

      // Try submitting without filling anything
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // Should still show the dialog (validation prevents closing)
      expect(find.text('Add Template'), findsAtLeastNWidgets(1));

      // Fill name but leave unit as default ('kg')
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name *'),
        'Test Assessment',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // Dialog should close and assessment should be added
      // (the fake notifier handles it synchronously)
      // Verify we're back on the list
      expect(find.text('Test Assessment'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
    });

    testWidgets('Test 3: Edit modifies assessment', (tester) async {
      final assessments = [
        makeAssessment(
          id: '1',
          name: 'Body Fat',
          unit: 'kg',
          description: 'Original description',
        ),
      ];
      final state = TrainerAssessmentsState(
        assessments: assessments,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Find the popup menu button
      final menuButtons = find.byType(PopupMenuButton<String>);
      expect(menuButtons, findsOneWidget);

      // Tap the popup menu
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Edit dialog should appear
      expect(find.text('Edit Template'), findsAtLeastNWidgets(1));

      // Change the name
      final nameField = find.widgetWithText(TextFormField, 'Name *');
      await tester.enterText(nameField, 'Updated Assessment');

      // Save
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Dialog should close and assessment name should be updated
      expect(find.text('Updated Assessment'), findsOneWidget);
    });

    testWidgets('Test 4: Delete confirms and removes', (tester) async {
      final assessments = [
        makeAssessment(id: '1', name: 'Body Fat', unit: 'cm'),
        makeAssessment(id: '2', name: 'Weight', unit: 'kg'),
      ];
      final state = TrainerAssessmentsState(
        assessments: assessments,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Find the popup menu buttons
      final menuButtons = find.byType(PopupMenuButton<String>);
      expect(menuButtons, findsNWidgets(2));

      // Tap the popup menu on the first card
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Template'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete "Body Fat"?'),
        findsOneWidget,
      );

      // Confirm deletion
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Item should be removed - only "Weight" should remain
      expect(find.text('Weight'), findsOneWidget);
    });

    testWidgets('Test 5: Empty state', (tester) async {
      const state = TrainerAssessmentsState(assessments: [], isLoading: false);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('No assessment templates yet'), findsOneWidget);
      expect(
        find.text('Create templates to track client progress'),
        findsOneWidget,
      );
      expect(find.text('Add Template'), findsAtLeastNWidgets(1));
    });
  });
}
