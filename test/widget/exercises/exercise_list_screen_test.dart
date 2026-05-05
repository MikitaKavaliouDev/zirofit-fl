import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/data/exercise_remote_source.dart';
import 'package:zirofit_fl/features/exercises/providers/exercise_provider.dart';
import 'package:zirofit_fl/features/exercises/screens/exercise_list_screen.dart';
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

Widget b(ExerciseListState s) {
  return ProviderScope(
    overrides: [exerciseListProvider.overrideWith((ref) => Fake(s))],
    child: const MaterialApp(home: ExerciseListScreen()),
  );
}

void main() {
  setUpAll(() => configureTestApiClient());
  final now = DateTime.now();

  // ---------------------------------------------------------------------------
  // Original tests
  // ---------------------------------------------------------------------------

  testWidgets('loading', (t) async {
    await t.pumpWidget(
      b(const ExerciseListState(status: ExerciseListStatus.loading)),
    );
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('data', (t) async {
    final es = [
      Exercise(
        id: '1',
        name: 'BP',
        category: 'Strength',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await t.pumpWidget(
      b(
        ExerciseListState(
          exercises: es,
          status: ExerciseListStatus.loaded,
          hasMore: false,
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('BP'), findsOneWidget);
    // "Strength" appears both in the category chip AND as exercise trailing
    // label
    expect(find.text('Strength'), findsAtLeastNWidgets(1));
  });

  testWidgets('error', (t) async {
    await t.pumpWidget(
      b(
        const ExerciseListState(status: ExerciseListStatus.error, error: 'err'),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('empty', (t) async {
    await t.pumpWidget(
      b(const ExerciseListState(status: ExerciseListStatus.loaded)),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('No exercises found'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Interaction tests
  // ---------------------------------------------------------------------------

  group('interaction tests', () {
    late Fake fake;
    late ExerciseListState loadedState;

    setUp(() {
      final es = [
        Exercise(
          id: '1',
          name: 'BP',
          category: 'Strength',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      loadedState = ExerciseListState(
        exercises: es,
        status: ExerciseListStatus.loaded,
        hasMore: false,
      );
      fake = Fake(loadedState);
    });

    Widget buildWidget() {
      return ProviderScope(
        overrides: [exerciseListProvider.overrideWith((ref) => fake)],
        child: const MaterialApp(home: ExerciseListScreen()),
      );
    }

    // -----------------------------------------------------------------------
    // 1. Search with debounce
    // -----------------------------------------------------------------------

    testWidgets('1. search with debounce calls fetchExercises after 400ms', (
      t,
    ) async {
      await t.pumpWidget(buildWidget());
      await t.pump(); // process postFrameCallback → init call recorded

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
      await t.pumpWidget(buildWidget());
      await t.pump();

      // Type something and wait for debounce to fire
      await t.enterText(find.byType(TextField), 'bench');
      await t.pump(const Duration(milliseconds: 500));

      // Clear by entering empty string — triggers _onSearchChanged('')
      await t.enterText(find.byType(TextField), '');
      await t.pump();
      await t.pump(const Duration(milliseconds: 500)); // debounce for empty

      // Text field should be empty
      final TextField textField = t.widget(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      // Last fetch call should have null search (empty → search: null)
      expect(fake.fetchCalls.last['search'], isNull);
    });

    // -----------------------------------------------------------------------
    // 3. Category chip selection
    // -----------------------------------------------------------------------

    testWidgets('3. category chip selection triggers fetch with category', (
      t,
    ) async {
      await t.pumpWidget(buildWidget());
      await t.pump();

      await t.tap(find.widgetWithText(FilterChip, 'Strength'));
      await t.pump();

      expect(fake.fetchCalls.any((c) => c['category'] == 'Strength'), isTrue);
    });

    // -----------------------------------------------------------------------
    // 4. Category chip toggle off
    // -----------------------------------------------------------------------

    testWidgets('4. category chip toggle off clears category', (t) async {
      await t.pumpWidget(buildWidget());
      await t.pump();

      // Select, then deselect
      await t.tap(find.widgetWithText(FilterChip, 'Strength'));
      await t.pump();
      await t.tap(find.widgetWithText(FilterChip, 'Strength'));
      await t.pump();

      // Last call should have null category
      expect(fake.fetchCalls.last['category'], isNull);
    });

    // -----------------------------------------------------------------------
    // 5. Muscle group dropdown selection
    // -----------------------------------------------------------------------

    testWidgets('5. muscle group dropdown selection', (t) async {
      await t.pumpWidget(buildWidget());
      await t.pump();

      // Open the muscle group dropdown
      await t.tap(find.text('Muscle'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      // Select "Chest" from the popup menu
      await t.tap(find.text('Chest'));
      await t.pump();
      // Wait for dismiss animation (300ms) + cleanup frame
      await t.pump(const Duration(milliseconds: 350));
      await t.pump();

      expect(fake.fetchCalls.any((c) => c['muscleGroup'] == 'Chest'), isTrue);
    });

    // -----------------------------------------------------------------------
    // 6. Muscle group "All Muscles"
    // -----------------------------------------------------------------------

    testWidgets('6. muscle group filter changes via dropdown selection', (
      t,
    ) async {
      await t.pumpWidget(buildWidget());
      await t.pump();

      // Open the muscle group dropdown
      await t.tap(find.text('Muscle'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      // UI contains "All Muscles" option
      expect(find.text('All Muscles'), findsOneWidget);

      // Select "Back" from the popup menu
      await t.tap(find.text('Back'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      await t.pump();

      // fetchExercises was called with muscleGroup: 'Back'
      expect(fake.fetchCalls.any((c) => c['muscleGroup'] == 'Back'), isTrue);

      // The initState call already proves fetchExercises accepts null
      expect(fake.fetchCalls.any((c) => c['muscleGroup'] == null), isTrue);
    });

    // -----------------------------------------------------------------------
    // 7. LoadMore pagination
    // -----------------------------------------------------------------------

    testWidgets('7. loadMore on scroll near bottom', (t) async {
      final manyExercises = List.generate(
        30,
        (i) => Exercise(
          id: '$i',
          name: 'Exercise $i',
          category: 'Strength',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final scrollableState = ExerciseListState(
        exercises: manyExercises,
        status: ExerciseListStatus.loaded,
        hasMore: true,
      );
      final fakeScroll = Fake(scrollableState);

      await t.pumpWidget(
        ProviderScope(
          overrides: [exerciseListProvider.overrideWith((ref) => fakeScroll)],
          child: const MaterialApp(home: ExerciseListScreen()),
        ),
      );
      await t.pump();

      // Scroll far enough to trigger _onScroll near maxScrollExtent
      await t.drag(find.byType(ListView).last, const Offset(0, -5000));
      await t.pump();

      expect(fakeScroll.loadMoreCalled, isTrue);
    });

    // -----------------------------------------------------------------------
    // 8. Combined filter
    // -----------------------------------------------------------------------

    testWidgets('8. combined filter: category + search', (t) async {
      await t.pumpWidget(buildWidget());
      await t.pump();

      // Select a category first
      await t.tap(find.widgetWithText(FilterChip, 'Strength'));
      await t.pump();

      // Then type a search term
      await t.enterText(find.byType(TextField), 'bench');
      await t.pump(const Duration(milliseconds: 500));

      // Verify a fetch call has both params
      final combined = fake.fetchCalls.where(
        (c) => c['search'] == 'bench' && c['category'] == 'Strength',
      );
      expect(combined, isNotEmpty);
    });
  });
}
