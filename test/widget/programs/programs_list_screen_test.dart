import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';
import 'package:zirofit_fl/features/programs/screens/programs_list_screen.dart';
import '../../helpers/test_setup.dart';

class FakeProgramsNotifier extends ProgramsNotifier {
  ProgramsState _state;
  FakeProgramsNotifier(this._state) : super(apiClient: ApiClient.instance) { super.state = _state; }
  @override
  ProgramsState get state => _state;
  void emit(ProgramsState s) { _state = s; super.state = s; }
  @override
  Future<void> fetchPrograms() async {}
  @override
  Future<WorkoutProgram?> createProgram(String name, String? description) async => null;
}

Widget buildApp(ProgramsState state) {
  return ProviderScope(
    overrides: [
      programsProvider.overrideWith(
        (ref) => FakeProgramsNotifier(state),
      ),
    ],
    child: const MaterialApp(
      home: ProgramsListScreen(),
    ),
  );
}

void main() {
  setUpAll(() => configureTestApiClient());

  group('ProgramsListScreen', () {
    final now = DateTime.now();

    testWidgets('shows loading indicator when isLoading and programs empty',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const ProgramsState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        buildApp(const ProgramsState(error: 'Something went wrong', isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows empty state when no programs', (tester) async {
      await tester.pumpWidget(
        buildApp(const ProgramsState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No programs yet'), findsOneWidget);
      expect(find.textContaining('Create your first workout program'), findsOneWidget);
    });

    testWidgets('shows list of programs in data state', (tester) async {
      final programs = [
        WorkoutProgram(
          id: '1',
          name: 'Beginner Full Body',
          description: 'A great start',
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutProgram(
          id: '2',
          name: 'Advanced Split',
          description: 'For experienced lifters',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ProgramsState(userPrograms: programs, isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beginner Full Body'), findsOneWidget);
      expect(find.text('Advanced Split'), findsOneWidget);
      expect(find.text('A great start'), findsOneWidget);
      expect(find.text('For experienced lifters'), findsOneWidget);
    });

    testWidgets('shows FAB for creating programs', (tester) async {
      await tester.pumpWidget(
        buildApp(const ProgramsState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows programs without description gracefully', (tester) async {
      final programs = [
        WorkoutProgram(
          id: '3',
          name: 'Minimal Program',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ProgramsState(userPrograms: programs, isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minimal Program'), findsOneWidget);
      // ListTile should not have a subtitle since description is null
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNull);
    });
  });
}
