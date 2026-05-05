import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';
import 'package:zirofit_fl/features/programs/screens/my_routines_screen.dart';
import 'package:zirofit_fl/features/programs/screens/routine_builder_screen.dart';
import '../../helpers/test_setup.dart';

class FakeClientProgramsNotifier extends ClientProgramsNotifier {
  ClientProgramsState _state;
  int fetchProgramsCallCount = 0;

  FakeClientProgramsNotifier(this._state)
      : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  ClientProgramsState get state => _state;

  void emit(ClientProgramsState s) {
    _state = s;
    super.state = s;
  }

  @override
  Future<void> fetchPrograms() async {
    fetchProgramsCallCount++;
  }
}

Widget buildApp(ClientProgramsState state) {
  return ProviderScope(
    overrides: [
      clientProgramsProvider.overrideWith(
        (ref) => FakeClientProgramsNotifier(state),
      ),
    ],
    child: const MaterialApp(
      home: MyRoutinesScreen(),
    ),
  );
}

void main() {
  setUpAll(() => configureTestApiClient());

  group('MyRoutinesScreen', () {
    final now = DateTime.now();

    testWidgets('renders app bar with My Routines title', (tester) async {
      await tester.pumpWidget(
        buildApp(const ClientProgramsState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Routines'), findsOneWidget);
    });

    testWidgets('shows empty state when no routines exist', (tester) async {
      await tester.pumpWidget(
        buildApp(const ClientProgramsState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No routines yet'), findsOneWidget);
      expect(find.text('Create your first routine!'), findsOneWidget);
      expect(find.text('Create Routine'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
    });

    testWidgets('displays list of routines when data exists', (tester) async {
      final programs = [
        WorkoutProgram(
          id: '1',
          name: 'Morning Stretch',
          description: 'A gentle start to the day',
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutProgram(
          id: '2',
          name: 'Evening Wind Down',
          description: 'Relax and recover',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ClientProgramsState(programs: programs, isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Morning Stretch'), findsOneWidget);
      expect(find.text('Evening Wind Down'), findsOneWidget);
      expect(find.text('A gentle start to the day'), findsOneWidget);
      expect(find.text('Relax and recover'), findsOneWidget);
    });

    testWidgets('tapping create button navigates to builder', (tester) async {
      await tester.pumpWidget(
        buildApp(const ClientProgramsState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      // Tap the FAB to navigate to RoutineBuilderScreen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify navigation to RoutineBuilderScreen
      expect(find.byType(RoutineBuilderScreen), findsOneWidget);
    });

    testWidgets('pull to refresh triggers data reload', (tester) async {
      final programs = [
        WorkoutProgram(
          id: '1',
          name: 'Full Body Workout',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Build inline to capture the notifier reference
      final notifier = FakeClientProgramsNotifier(
        ClientProgramsState(programs: programs, isLoading: false),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientProgramsProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: MyRoutinesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify data is rendered
      expect(find.text('Full Body Workout'), findsOneWidget);

      // Pull down to trigger refresh
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(notifier.fetchProgramsCallCount, equals(1));
    });
  });
}
