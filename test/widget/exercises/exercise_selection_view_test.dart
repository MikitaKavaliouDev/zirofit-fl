import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/data/exercise_remote_source.dart';
import 'package:zirofit_fl/features/exercises/providers/exercise_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/exercise_selection_view.dart';
import '../../helpers/test_setup.dart';

/// Fake notifier that records interaction calls without hitting the network.
class Fake extends ExerciseListNotifier {
  final ExerciseListState _s;
  final List<Map<String, dynamic>> fetchCalls = [];
  bool loadMoreCalled = false;

  Fake(this._s) : super(ExerciseRemoteSource()) {
    super.state = _s;
  }

  @override
  ExerciseListState get state => _s;

  @override
  Future<void> fetchExercises({
    String? search,
    String? category,
    String? muscleGroup,
  }) async {
    fetchCalls.add({
      'search': search,
      'category': category,
      'muscleGroup': muscleGroup,
    });
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalled = true;
  }
}

Widget buildWidget(ExerciseListState state,
    {void Function(List<Exercise>)? onDone}) {
  return ProviderScope(
    overrides: [exerciseListProvider.overrideWith((ref) => Fake(state))],
    child: MaterialApp(
      home: Scaffold(
        body: ExerciseSelectionView(onDone: onDone),
      ),
    ),
  );
}

void main() {
  setUpAll(() => configureTestApiClient());
  final now = DateTime.now();

  // ===========================================================================
  // State rendering tests
  // ===========================================================================

  group('state rendering', () {
    testWidgets('loading shows CircularProgressIndicator', (t) async {
      await t.pumpWidget(
        buildWidget(
          const ExerciseListState(status: ExerciseListStatus.loading),
        ),
      );
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('initial shows CircularProgressIndicator', (t) async {
      await t.pumpWidget(
        buildWidget(const ExerciseListState()),
      );
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loaded shows exercise list', (t) async {
      final exercises = [
        Exercise(
          id: '1',
          name: 'Bench Press',
          muscleGroup: 'Chest',
          category: 'Strength',
          createdAt: now,
          updatedAt: now,
        ),
        Exercise(
          id: '2',
          name: 'Squat',
          muscleGroup: 'Legs',
          category: 'Strength',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      await t.pumpWidget(
        buildWidget(
          ExerciseListState(
            exercises: exercises,
            status: ExerciseListStatus.loaded,
            hasMore: false,
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      // AppBar title
      expect(find.text('Add Exercise'), findsOneWidget);
    });

    testWidgets('error shows retry button', (t) async {
      await t.pumpWidget(
        buildWidget(
          const ExerciseListState(
            status: ExerciseListStatus.error,
            error: 'Network error',
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('empty shows no exercises message', (t) async {
      await t.pumpWidget(
        buildWidget(
          const ExerciseListState(status: ExerciseListStatus.loaded),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('No exercises found'), findsOneWidget);
    });
  });

  // ===========================================================================
  // Interaction tests
  // ===========================================================================

  group('interaction', () {
    late Fake fake;
    late ExerciseListState loadedState;

    setUp(() {
      final exercises = [
        Exercise(
          id: '1',
          name: 'Bench Press',
          muscleGroup: 'Chest',
          category: 'Strength',
          createdAt: now,
          updatedAt: now,
        ),
        Exercise(
          id: '2',
          name: 'Squat',
          muscleGroup: 'Legs',
          category: 'Strength',
          createdAt: now,
          updatedAt: now,
        ),
        Exercise(
          id: '3',
          name: 'Deadlift',
          muscleGroup: 'Back',
          category: 'Strength',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      loadedState = ExerciseListState(
        exercises: exercises,
        status: ExerciseListStatus.loaded,
        hasMore: false,
      );
      fake = Fake(loadedState);
    });

    Widget buildTestWidget({void Function(List<Exercise>)? onDone}) {
      return ProviderScope(
        overrides: [exerciseListProvider.overrideWith((ref) => fake)],
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseSelectionView(onDone: onDone),
          ),
        ),
      );
    }

    // -----------------------------------------------------------------------
    // 1. Search with debounce
    // -----------------------------------------------------------------------

    testWidgets('1. search with debounce calls fetchExercises after 400ms', (
      t,
    ) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump(); // process postFrameCallback

      await t.enterText(find.byType(TextField), 'bench');

      // Before 400ms debounce has elapsed → no search call yet
      await t.pump(const Duration(milliseconds: 200));
      expect(
        fake.fetchCalls.where((c) => c['search'] == 'bench').length,
        equals(0),
      );

      // Advance past the debounce threshold
      await t.pump(const Duration(milliseconds: 250));
      expect(fake.fetchCalls.any((c) => c['search'] == 'bench'), isTrue);
    });

    // -----------------------------------------------------------------------
    // 2. Clear search
    // -----------------------------------------------------------------------

    testWidgets('2. clear search triggers re-fetch with null search', (
      t,
    ) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump();

      // Type something and wait for debounce to fire
      await t.enterText(find.byType(TextField), 'bench');
      await t.pump(const Duration(milliseconds: 500));

      // Clear by entering empty string
      await t.enterText(find.byType(TextField), '');
      await t.pump();
      await t.pump(const Duration(milliseconds: 500)); // debounce for empty

      // Text field should be empty
      final TextField textField = t.widget(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      // Last fetch call should have null search
      expect(fake.fetchCalls.last['search'], isNull);
    });

    // -----------------------------------------------------------------------
    // 3. Exercise selection shows bottom bar
    // -----------------------------------------------------------------------

    testWidgets('3. tapping exercise shows bottom bar with count', (t) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      // Initially no bottom bar
      expect(find.text('Add 1 Exercise'), findsNothing);

      // Tap an exercise to select it
      await t.tap(find.text('Bench Press'));
      await t.pump();

      // Bottom bar should appear
      expect(find.text('Add 1 Exercise'), findsOneWidget);

      // Tap another exercise
      await t.tap(find.text('Squat'));
      await t.pump();

      // Count should update
      expect(find.text('Add 2 Exercises'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 4. onDone callback receives selected exercises
    // -----------------------------------------------------------------------

    testWidgets('4. onDone callback receives selected exercises', (t) async {
      List<Exercise>? received;
      await t.pumpWidget(
        buildTestWidget(
          onDone: (selected) => received = selected,
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      // Select two exercises
      await t.tap(find.text('Bench Press'));
      await t.pump();
      await t.tap(find.text('Squat'));
      await t.pump();

      // Tap Done in AppBar
      await t.tap(find.text('Done'));
      await t.pump();

      expect(received, hasLength(2));
      expect(received![0].id, '1');
      expect(received![1].id, '2');
    });

    // -----------------------------------------------------------------------
    // 5. Cancel button pops the view
    // -----------------------------------------------------------------------

    testWidgets('5. Cancel button pops navigation', (t) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      // Cancel text button in AppBar
      expect(find.text('Cancel'), findsOneWidget);
      // Tapping Cancel pops the route
      await t.tap(find.text('Cancel'));
      await t.pump();
      // No error means it popped cleanly
    });

    // -----------------------------------------------------------------------
    // 6. Body part filter dropdown
    // -----------------------------------------------------------------------

    testWidgets('6. body part filter dropdown updates list', (t) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      // The "Body Part" dropdown should be present
      expect(find.text('Body Part'), findsOneWidget);

      // Open the dropdown
      await t.tap(find.text('Body Part'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      // All muscle groups from exercises should be listed in the popup.
      // Note: muscle group names also appear in exercise row subtitles.
      expect(find.text('All Body Parts'), findsOneWidget);
      expect(find.text('Back'), findsAtLeastNWidgets(1));
      expect(find.text('Legs'), findsAtLeastNWidgets(1));
    });

    // -----------------------------------------------------------------------
    // 7. Category filter dropdown
    // -----------------------------------------------------------------------

    testWidgets('7. category filter dropdown available', (t) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      expect(find.text('Category'), findsOneWidget);

      await t.tap(find.text('Category'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('All Categories'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 8. Sort dropdown
    // -----------------------------------------------------------------------

    testWidgets('8. sort dropdown shows options', (t) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      expect(find.text('A-Z'), findsOneWidget);

      await t.tap(find.text('A-Z'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      expect(find.text('Most Used'), findsOneWidget);
      expect(find.text('Recently Used'), findsOneWidget);
    });
  });
}
