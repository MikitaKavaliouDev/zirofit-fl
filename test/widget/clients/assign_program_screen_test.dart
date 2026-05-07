import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/clients/screens/assign_program_screen.dart';
import 'package:zirofit_fl/features/programs/providers/program_assignment_provider.dart';
import '../../helpers/test_setup.dart';

class FakeProgramAssignmentNotifier extends ProgramAssignmentNotifier {
  ProgramAssignmentState _state;
  FakeProgramAssignmentNotifier(this._state)
      : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  ProgramAssignmentState get state => _state;

  void emit(ProgramAssignmentState s) {
    _state = s;
    super.state = s;
  }

  @override
  Future<void> fetchPrograms() async {}

  @override
  Future<String?> assignProgram({
    required String programId,
    required String clientId,
  }) async {
    return null;
  }

  @override
  void resetSuccess() {}
}

Widget buildApp(ProgramAssignmentState state) {
  return ProviderScope(
    overrides: [
      programAssignmentProvider.overrideWith(
        (ref) => FakeProgramAssignmentNotifier(state),
      ),
    ],
    child: const MaterialApp(
      home: AssignProgramScreen(
        clientId: 'test-client',
        clientName: 'Jane Doe',
      ),
    ),
  );
}

void main() {
  setUpAll(() => configureTestApiClient());

  group('AssignProgramScreen', () {
    final now = DateTime.now();

    testWidgets('shows loading indicator when isLoading and programs empty',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const ProgramAssignmentState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    testWidgets('shows client info header', (tester) async {
      await tester.pumpWidget(
        buildApp(const ProgramAssignmentState(
          programs: [],
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // Header shows client name and label
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Assigning program to'), findsOneWidget);
    });

    testWidgets('shows empty state when no programs', (tester) async {
      await tester.pumpWidget(
        buildApp(const ProgramAssignmentState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No programs available'), findsOneWidget);
      expect(
        find.textContaining('Create a workout program first'),
        findsOneWidget,
      );
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        buildApp(const ProgramAssignmentState(
          error: 'Something went wrong',
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows list of programs', (tester) async {
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
        buildApp(ProgramAssignmentState(
          programs: programs,
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beginner Full Body'), findsOneWidget);
      expect(find.text('Advanced Split'), findsOneWidget);
    });

    testWidgets('each program card has an Assign button', (tester) async {
      final programs = [
        WorkoutProgram(
          id: '1',
          name: 'Program A',
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutProgram(
          id: '2',
          name: 'Program B',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ProgramAssignmentState(
          programs: programs,
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // Two Assign buttons
      expect(find.text('Assign'), findsNWidgets(2));
    });

    testWidgets('tapping Assign shows confirmation dialog', (tester) async {
      final programs = [
        WorkoutProgram(
          id: '1',
          name: 'Program A',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ProgramAssignmentState(
          programs: programs,
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // Tap the Assign button
      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear ("Assign Program" appears in AppBar + dialog)
      expect(find.text('Assign Program'), findsNWidgets(2));
      expect(
        find.textContaining('Assign "Program A" to Jane Doe?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirmation dialog Cancel dismisses it', (tester) async {
      final programs = [
        WorkoutProgram(
          id: '1',
          name: 'Program A',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ProgramAssignmentState(
          programs: programs,
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();

      // Dialog is shown
      expect(find.text('Assign'), findsWidgets); // both button and title

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed, still on the screen
      expect(find.text('Program A'), findsOneWidget);
    });

    testWidgets('shows program without description gracefully',
        (tester) async {
      final programs = [
        WorkoutProgram(
          id: '3',
          name: 'Minimal Program',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ProgramAssignmentState(
          programs: programs,
          isLoading: false,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minimal Program'), findsOneWidget);
      // Should not crash
    });
  });
}
