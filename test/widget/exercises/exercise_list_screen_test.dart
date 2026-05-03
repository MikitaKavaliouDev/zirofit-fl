import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/data/exercise_remote_source.dart';
import 'package:zirofit_fl/features/exercises/providers/exercise_provider.dart';
import 'package:zirofit_fl/features/exercises/screens/exercise_list_screen.dart';
import '../../helpers/test_setup.dart';

class Fake extends ExerciseListNotifier {
  final ExerciseListState _s;
  Fake(this._s) : super(ExerciseRemoteSource()) { super.state = _s; }
  @override ExerciseListState get state => _s;
  @override Future<void> fetchExercises({String? search, String? category, String? muscleGroup}) async {}
  @override Future<void> loadMore() async {}
}

Widget b(ExerciseListState s) => ProviderScope(overrides: [exerciseListProvider.overrideWith((ref) => Fake(s))], child: const MaterialApp(home: ExerciseListScreen()));

void main() {
  setUpAll(() => configureTestApiClient());
  final now = DateTime.now();
  testWidgets('loading', (t) async { await t.pumpWidget(b(const ExerciseListState(status: ExerciseListStatus.loading))); await t.pump(); expect(find.byType(CircularProgressIndicator), findsOneWidget); });
  testWidgets('data', (t) async {
    final es = [Exercise(id: '1', name: 'BP', category: 'Strength', createdAt: now, updatedAt: now)];
    await t.pumpWidget(b(ExerciseListState(exercises: es, status: ExerciseListStatus.loaded, hasMore: false)));
    await t.pump(); await t.pump(const Duration(milliseconds: 500));
    expect(find.text('BP'), findsOneWidget);
    // "Strength" appears both in the category chip AND as exercise trailing label
    expect(find.text('Strength'), findsAtLeastNWidgets(1));
  });
  testWidgets('error', (t) async {
    await t.pumpWidget(b(const ExerciseListState(status: ExerciseListStatus.error, error: 'err')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Try Again'), findsOneWidget);
  });
  testWidgets('empty', (t) async {
    await t.pumpWidget(b(const ExerciseListState(status: ExerciseListStatus.loaded)));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('No exercises found'), findsOneWidget);
  });
}
