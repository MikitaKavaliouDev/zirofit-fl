import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/trainer/providers/custom_exercises_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/custom_exercises_screen.dart';
import '../../helpers/test_setup.dart';

class FakeCustomExercisesNotifier extends TrainerCustomExercisesNotifier {
  TrainerCustomExercisesState _s;
  FakeCustomExercisesNotifier(this._s)
      : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  TrainerCustomExercisesState get state => _s;

  void emit(TrainerCustomExercisesState ns) {
    _s = ns;
    super.state = ns;
  }

  @override
  Future<void> fetchExercises() async {}

  @override
  Future<void> createExercise(Map<String, dynamic> data) async {
    final exercise = Exercise(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] as String? ?? '',
      muscleGroup: data['muscleGroup'] as String?,
      equipment: data['equipment'] as String?,
      description: data['description'] as String?,
      videoUrl: data['videoUrl'] as String?,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    emit(state.copyWith(exercises: [...state.exercises, exercise]));
  }

  @override
  Future<void> updateExercise(String id, Map<String, dynamic> data) async {
    final updated = state.exercises.map((e) {
      if (e.id == id) {
        return Exercise(
          id: e.id,
          name: data['name'] as String? ?? e.name,
          muscleGroup: data['muscleGroup'] as String? ?? e.muscleGroup,
          equipment: data['equipment'] as String? ?? e.equipment,
          description: data['description'] as String? ?? e.description,
          videoUrl: data['videoUrl'] as String? ?? e.videoUrl,
          createdAt: e.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return e;
    }).toList();
    emit(state.copyWith(exercises: updated));
  }

  @override
  Future<void> deleteExercise(String id) async {
    emit(state.copyWith(
      exercises: state.exercises.where((e) => e.id != id).toList(),
    ));
  }
}

Widget buildTestApp(TrainerCustomExercisesState state) => ProviderScope(
      overrides: [
        trainerCustomExercisesProvider
            .overrideWith((ref) => FakeCustomExercisesNotifier(state)),
      ],
      child: const MaterialApp(
        home: CustomExercisesScreen(),
      ),
    );

Exercise makeExercise({
  String id = '1',
  String name = 'Bench Press',
  String? muscleGroup = 'Chest',
  String? equipment = 'Barbell',
  String? description,
  String? videoUrl,
}) =>
    Exercise(
      id: id,
      name: name,
      muscleGroup: muscleGroup,
      equipment: equipment,
      description: description,
      videoUrl: videoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('CustomExercisesScreen', () {
    testWidgets('Test 1: Shows custom exercises with tags', (tester) async {
      final exercises = [
        makeExercise(
          id: '1',
          name: 'Bench Press',
          muscleGroup: 'Chest',
          equipment: 'Barbell',
        ),
        makeExercise(
          id: '2',
          name: 'Bulgarian Split Squat',
          muscleGroup: 'Legs',
          equipment: 'Dumbbell',
          description: 'Single leg exercise',
          videoUrl: 'https://youtube.com/watch?v=xyz',
        ),
      ];
      final state = TrainerCustomExercisesState(
        exercises: exercises,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Verify exercise names are shown
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Bulgarian Split Squat'), findsOneWidget);

      // Verify tags are shown
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Barbell'), findsAtLeastNWidgets(1));
      expect(find.text('Legs'), findsOneWidget);
      expect(find.text('Dumbbell'), findsOneWidget);

      // Verify video tag is shown for the second exercise
      expect(find.text('Video'), findsOneWidget);

      // Verify title
      expect(find.text('Custom Exercises'), findsOneWidget);
    });

    testWidgets('Test 2: Add form validates required fields', (tester) async {
      const state = TrainerCustomExercisesState(
        exercises: [],
        isLoading: false,
      );
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Shows empty state
      expect(find.text('No custom exercises yet'), findsOneWidget);

      // Tap the Add button in the AppBar
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Add Exercise'), findsAtLeastNWidgets(1));

      // Try submitting without filling anything
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // Should still show the dialog (validation prevents closing)
      expect(find.text('Add Exercise'), findsAtLeastNWidgets(1));

      // Fill name but leave muscle group (default is selected, so valid)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name *'),
        'Test Exercise',
      );

      // Submit
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // Dialog should close and exercise should be added (fake handles it)
      // In our fake notifier, createExercise adds to state synchronously
    });

    testWidgets('Test 3: Edit pre-fills form', (tester) async {
      final exercises = [
        makeExercise(
          id: '1',
          name: 'Push Up',
          muscleGroup: 'Chest',
          equipment: 'Bodyweight',
          description: 'Standard push up',
        ),
      ];
      final state = TrainerCustomExercisesState(
        exercises: exercises,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Find the popup menu button
      final menuButtons = find.byType(PopupMenuButton<String>);
      expect(menuButtons, findsOneWidget);

      // Open popup menu
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // Tap "Edit"
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Dialog should appear with pre-filled data
      expect(find.text('Edit Exercise'), findsAtLeastNWidgets(1));

      // Name field should be pre-filled
      final nameField = find.widgetWithText(TextFormField, 'Exercise Name *');
      expect(nameField, findsOneWidget);
      expect(
        (tester.widget(nameField) as TextFormField).controller?.text,
        'Push Up',
      );

      // Description should be pre-filled (appears in card and dialog field)
      expect(find.text('Standard push up'), findsAtLeastNWidgets(1));

      // Bodyweight chip should be visible (pre-selected, appears in card and dialog)
      expect(find.text('Bodyweight'), findsAtLeastNWidgets(1));
    });

    testWidgets('Test 4: Delete confirms', (tester) async {
      final exercises = [
        makeExercise(id: '1', name: 'Push Up', muscleGroup: 'Chest'),
        makeExercise(id: '2', name: 'Pull Up', muscleGroup: 'Back'),
      ];
      final state = TrainerCustomExercisesState(
        exercises: exercises,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Find the popup menu buttons (one per card)
      final menuButtons = find.byType(PopupMenuButton<String>);
      expect(menuButtons, findsNWidgets(2));

      // Tap the popup menu on the first card
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // Tap the "Delete" menu item
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Exercise'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete "Push Up"?'),
        findsOneWidget,
      );

      // Confirm deletion
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Note: In our fake notifier, deleteExercise removes from state synchronously
      // So the dialog closes and the item is removed
    });

    testWidgets('Test 5: Empty state', (tester) async {
      const state = TrainerCustomExercisesState(
        exercises: [],
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('No custom exercises yet'), findsOneWidget);
      expect(
        find.text('Create custom exercises for your clients'),
        findsOneWidget,
      );
      expect(find.text('Add Exercise'), findsAtLeastNWidgets(1));
    });
  });
}
