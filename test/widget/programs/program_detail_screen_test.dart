import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';
import 'package:zirofit_fl/features/programs/screens/program_detail_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

class FakeProgramsNotifier extends ProgramsNotifier {
  ProgramsState _state;
  FakeProgramsNotifier(this._state) : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  ProgramsState get state => _state;

  void emit(ProgramsState s) {
    _state = s;
    super.state = s;
  }

  @override
  Future<void> fetchPrograms() async {}

  @override
  Future<WorkoutProgram?> createProgram(
    String name,
    String? description,
  ) async => null;
}

void main() {
  setUpAll(() => configureTestApiClient());

  group('ProgramDetailScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpApp(
        const ProgramDetailScreen(programId: 'test'),
        overrides: [
          programsProvider.overrideWith(
            (ref) => FakeProgramsNotifier(
              const ProgramsState(programs: [], isLoading: false),
            ),
          ),
        ],
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets(
      'shows loading indicator when state isLoading and program not yet loaded',
      (tester) async {
        await tester.pumpApp(
          const ProgramDetailScreen(programId: '1'),
          overrides: [
            programsProvider.overrideWith(
              (ref) => FakeProgramsNotifier(
                const ProgramsState(programs: [], isLoading: true),
              ),
            ),
          ],
        );
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('shows program not found when program missing', (tester) async {
      await tester.pumpApp(
        const ProgramDetailScreen(programId: '1'),
        overrides: [
          programsProvider.overrideWith(
            (ref) => FakeProgramsNotifier(
              const ProgramsState(programs: [], isLoading: false),
            ),
          ),
        ],
      );
      await tester.pump();
      expect(find.text('Program not found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('displays program details correctly', (tester) async {
      final program = WorkoutProgram(
        id: '1',
        name: 'Test Program',
        description: 'Desc',
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      );
      final state = ProgramsState(programs: [program], isLoading: false);

      await tester.pumpApp(
        const ProgramDetailScreen(programId: '1'),
        overrides: [
          programsProvider.overrideWith((ref) => FakeProgramsNotifier(state)),
        ],
      );
      await tester.pumpAndSettle();

      // Program name appears in AppBar title and in the Card title
      expect(find.text('Test Program'), findsAtLeast(1));
      expect(find.text('Desc'), findsOneWidget);
      expect(find.text('Created 15/1/2026'), findsOneWidget);
    });

    testWidgets('templates section shows coming soon placeholder', (
      tester,
    ) async {
      final program = WorkoutProgram(
        id: '1',
        name: 'Test Program',
        description: 'Desc',
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      );
      final state = ProgramsState(programs: [program], isLoading: false);

      await tester.pumpApp(
        const ProgramDetailScreen(programId: '1'),
        overrides: [
          programsProvider.overrideWith((ref) => FakeProgramsNotifier(state)),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Templates coming soon'), findsOneWidget);
      expect(find.byIcon(Icons.library_books_outlined), findsOneWidget);
    });

    testWidgets('start workout button shows snackbar on tap', (tester) async {
      final program = WorkoutProgram(
        id: '1',
        name: 'Test Program',
        description: 'Desc',
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      );
      final state = ProgramsState(programs: [program], isLoading: false);

      await tester.pumpApp(
        const ProgramDetailScreen(programId: '1'),
        overrides: [
          programsProvider.overrideWith((ref) => FakeProgramsNotifier(state)),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Workout'));
      await tester.pump();

      expect(
        find.text('Starting a workout from a program is coming soon'),
        findsOneWidget,
      );
    });
  });
}
