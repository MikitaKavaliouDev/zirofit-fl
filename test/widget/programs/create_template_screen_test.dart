import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/enums/step_type.dart';
import 'package:zirofit_fl/data/models/template_exercise.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';
import 'package:zirofit_fl/features/programs/screens/create_template_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Finds a DropdownButtonFormField by widget type.
///
/// Uses [find.byWidgetPredicate] with a type check that works around
/// generic type matching issues in Flutter 3.41+.
Finder get _dropdownFinder => find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString().startsWith('DropdownButtonFormField'),
    );

/// Finds the "Create Template" [FilledButton].
Finder get _createButtonFinder =>
    find.widgetWithText(FilledButton, 'Create Template');

/// Taps the program dropdown and selects a program by [name].
Future<void> selectProgram(WidgetTester tester, String name) async {
  await tester.tap(_dropdownFinder);
  await tester.pump();
  await tester.pump();
  await tester.tap(find.text(name).last);
  await tester.pump();
}

/// Completes the "create template" flow: enters name, selects a program,
/// and taps "Create Template".
Future<void> completeCreateFlow(
  WidgetTester tester, {
  String name = 'Test Template',
  String programName = 'Program A',
}) async {
  await tester.enterText(find.byType(TextField).first, name);
  await selectProgram(tester, programName);
  await tester.tap(find.widgetWithText(FilledButton, 'Create Template'));
  await tester.pump();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Fake ProgramsNotifier – controllable behavior for all template operations
// ---------------------------------------------------------------------------

class FakeProgramsNotifier extends ProgramsNotifier {
  bool succeedCreate = true;
  bool succeedDelete = true;
  String? errorMessage = 'Operation failed';

  bool createTemplateCalled = false;
  bool startEditingTemplateCalled = false;
  bool deleteExerciseStepCalled = false;

  String? capturedName;
  String? capturedDescription;
  String? capturedProgramId;
  String? capturedStepId;

  List<TemplateExercise> _steps = [];

  FakeProgramsNotifier({
    List<WorkoutProgram> programs = const [],
  }) : super(apiClient: ApiClient.instance) {
    super.state = ProgramsState(
      userPrograms: programs,
      isLoading: false,
    );
  }

  /// Pre-populate steps that will be returned from [startEditingTemplate].
  void setSteps(List<TemplateExercise> steps) {
    _steps = steps;
  }

  @override
  Future<WorkoutTemplate?> createTemplate({
    required String name,
    String? description,
    required String programId,
  }) async {
    createTemplateCalled = true;
    capturedName = name;
    capturedDescription = description;
    capturedProgramId = programId;

    if (succeedCreate) {
      final template = WorkoutTemplate(
        id: 'template-1',
        name: name,
        description: description,
        programId: programId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        editingTemplateId: template.id,
        editingProgramId: programId,
        isLoading: false,
      );
      return template;
    } else {
      state = state.copyWith(isLoading: false, error: errorMessage);
      return null;
    }
  }

  @override
  Future<void> startEditingTemplate(
      String templateId, String programId) async {
    startEditingTemplateCalled = true;
    state = state.copyWith(
      editingTemplateId: templateId,
      editingProgramId: programId,
      templateExercises: _steps,
      isLoading: false,
    );
  }

  @override
  Future<bool> deleteExerciseStep(String stepId) async {
    deleteExerciseStepCalled = true;
    capturedStepId = stepId;

    if (succeedDelete) {
      _steps = _steps.where((s) => s.id != stepId).toList();
      state = state.copyWith(templateExercises: _steps, isLoading: false);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Test app builders
// ---------------------------------------------------------------------------

/// Wraps [CreateTemplateScreen] in a [ProviderScope] with the given fake
/// notifier and a plain [MaterialApp].
Widget buildApp({required ProgramsNotifier notifier}) {
  return ProviderScope(
    overrides: [programsProvider.overrideWith((ref) => notifier)],
    child: const MaterialApp(home: CreateTemplateScreen()),
  );
}

/// Wraps [CreateTemplateScreen] with a [GoRouter] so that `context.pop()`
/// (called on successful finish) completes without throwing.
Widget buildAppWithRouter({required ProgramsNotifier notifier}) {
  final router = GoRouter(
    initialLocation: '/create-template',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const SizedBox.shrink(),
        routes: [
          GoRoute(
            path: 'create-template',
            builder: (_, _) => const CreateTemplateScreen(),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [programsProvider.overrideWith((ref) => notifier)],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('CreateTemplateScreen', () {
    final now = DateTime.now();

    final testProgram = WorkoutProgram(
      id: 'p1',
      name: 'Program A',
      createdAt: now,
      updatedAt: now,
    );

    // -----------------------------------------------------------------------
    // Creating phase
    // -----------------------------------------------------------------------

    testWidgets('renders creating phase with name, description, program picker',
        (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram]);
      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      expect(find.text('New Template'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // name + description
      expect(_dropdownFinder, findsOneWidget);
      expect(_createButtonFinder, findsOneWidget);
    });

    testWidgets('create button disabled when name is empty', (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram]);
      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      final button = tester.widget<FilledButton>(_createButtonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'create button disabled when no program selected even with name',
        (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram]);
      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'My Template');
      await tester.pump();

      final button = tester.widget<FilledButton>(_createButtonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('creates template and transitions to editing phase',
        (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram])
        ..succeedCreate = true;

      await tester.pumpWidget(buildAppWithRouter(notifier: notifier));
      await tester.pump();

      await completeCreateFlow(tester);

      // Verify createTemplate was called correctly
      expect(notifier.createTemplateCalled, isTrue);
      expect(notifier.capturedName, 'Test Template');
      expect(notifier.capturedProgramId, 'p1');

      // Verify startEditingTemplate was called
      expect(notifier.startEditingTemplateCalled, isTrue);

      // Should now be in editing phase
      expect(find.text('Edit Template'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Add Exercise'), findsOneWidget);
      expect(find.text('Add Rest'), findsOneWidget);
    });

    testWidgets('shows error snackbar when create fails', (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram])
        ..succeedCreate = false
        ..errorMessage = 'Failed to create';

      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      await completeCreateFlow(tester);

      await tester.pump(const Duration(milliseconds: 500));

      // Verify error shown (inline error text + SnackBar may both display it)
      expect(find.text('Failed to create'), findsAtLeast(1));

      // Verify we stayed in creating phase
      expect(find.text('New Template'), findsOneWidget);
      expect(find.text('Edit Template'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Editing phase – steps display
    // -----------------------------------------------------------------------

    testWidgets('renders exercise step with tempo and reps in editing phase',
        (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram]);
      notifier.setSteps([
        TemplateExercise(
          id: 's1',
          templateId: 'template-1',
          type: StepType.exercise,
          exerciseId: 'ex1',
          tempo: '3010',
          targetReps: '8-12',
          targetSets: 3,
          enableRpe: true,
          order: 0,
          createdAt: now,
          updatedAt: now,
        ),
        TemplateExercise(
          id: 's2',
          templateId: 'template-1',
          type: StepType.rest,
          durationSeconds: 90,
          order: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildAppWithRouter(notifier: notifier));
      await tester.pump();

      await completeCreateFlow(tester);

      // Verify exercise step tile renders with tempo badge
      expect(find.text('3010'), findsOneWidget);
      expect(find.text('8-12 reps'), findsOneWidget);
      expect(find.text('3 sets'), findsOneWidget);
      expect(find.text('RPE'), findsOneWidget);

      // Verify rest step tile
      expect(find.text('Rest 90s'), findsOneWidget);

      // Step count badge
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows empty state when editing with no steps',
        (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram]);

      await tester.pumpWidget(buildAppWithRouter(notifier: notifier));
      await tester.pump();

      await completeCreateFlow(tester);

      expect(find.text('Add exercises and rest steps'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Delete step
    // -----------------------------------------------------------------------

    testWidgets('deletes a step and removes it from the list', (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram])
        ..succeedDelete = true;
      notifier.setSteps([
        TemplateExercise(
          id: 's1',
          templateId: 'template-1',
          type: StepType.exercise,
          exerciseId: 'ex1',
          order: 0,
          createdAt: now,
          updatedAt: now,
        ),
        TemplateExercise(
          id: 's2',
          templateId: 'template-1',
          type: StepType.exercise,
          exerciseId: 'ex2',
          order: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildAppWithRouter(notifier: notifier));
      await tester.pump();

      await completeCreateFlow(tester);

      // Two steps rendered
      expect(find.byIcon(Icons.line_weight), findsNWidgets(2));
      expect(find.text('2'), findsOneWidget);

      // Delete the first step (tap its close icon)
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();
      await tester.pump();

      // Verify deleteExerciseStep was called
      expect(notifier.deleteExerciseStepCalled, isTrue);
      expect(notifier.capturedStepId, 's1');

      // Step count should be 1 now
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows error snackbar when delete fails', (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram])
        ..succeedDelete = false
        ..errorMessage = 'Delete failed';
      notifier.setSteps([
        TemplateExercise(
          id: 's1',
          templateId: 'template-1',
          type: StepType.exercise,
          exerciseId: 'ex1',
          order: 0,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildAppWithRouter(notifier: notifier));
      await tester.pump();

      await completeCreateFlow(tester);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Delete failed'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Reorder steps
    // -----------------------------------------------------------------------

    testWidgets('reorders steps when drag handle is moved', (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram]);
      notifier.setSteps([
        TemplateExercise(
          id: 's1',
          templateId: 'template-1',
          type: StepType.exercise,
          exerciseId: 'ex1',
          order: 0,
          createdAt: now,
          updatedAt: now,
        ),
        TemplateExercise(
          id: 's2',
          templateId: 'template-1',
          type: StepType.exercise,
          exerciseId: 'ex2',
          order: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildAppWithRouter(notifier: notifier));
      await tester.pump();

      await completeCreateFlow(tester);

      // Verify ReorderableListView is present
      expect(find.byType(ReorderableListView), findsOneWidget);

      // Drag first item downward by ~100px to trigger reorder
      final handles = find.byIcon(Icons.line_weight);
      expect(handles, findsNWidgets(2));

      await tester.drag(handles.first, const Offset(0, 100));
      await tester.pump();
      await tester.pump();

      // After reorder, verify step count is still 2 (no steps lost/gained)
      expect(find.byIcon(Icons.line_weight), findsNWidgets(2));
      expect(find.text('2'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Program picker
    // -----------------------------------------------------------------------

    testWidgets('shows programs in dropdown', (tester) async {
      final programs = [
        testProgram,
        WorkoutProgram(
          id: 'p2',
          name: 'Program B',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final notifier = FakeProgramsNotifier(programs: programs);

      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      // Open dropdown
      await tester.tap(_dropdownFinder);
      await tester.pump();
      await tester.pump();

      // Both programs should be in the dropdown
      expect(find.text('Program A'), findsAtLeast(1));
      expect(find.text('Program B'), findsAtLeast(1));
    });

    testWidgets('handles programId passed through constructor',
        (tester) async {
      // Create screen with pre-selected programId
      final notifier = FakeProgramsNotifier(programs: [testProgram]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [programsProvider.overrideWith((ref) => notifier)],
          child: const MaterialApp(
            home: CreateTemplateScreen(programId: 'p1'),
          ),
        ),
      );
      await tester.pump();

      // Program should be pre-selected — "Program A" text should be visible
      // (not just as hint but as the selected value)
      expect(find.text('Program A'), findsAtLeast(1));

      // With program selected, only name is needed to enable create button
      await tester.enterText(find.byType(TextField).first, 'My Template');
      await tester.pump();

      final button = tester.widget<FilledButton>(_createButtonFinder);
      expect(button.onPressed, isNotNull);
    });

    // -----------------------------------------------------------------------
    // Done / finish flow
    // -----------------------------------------------------------------------

    testWidgets('Done button navigates back with snackbar', (tester) async {
      final notifier = FakeProgramsNotifier(programs: [testProgram])
        ..succeedCreate = true;

      await tester.pumpWidget(buildAppWithRouter(notifier: notifier));
      await tester.pump();

      await completeCreateFlow(tester);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pump();

      // SnackBar should show
      expect(find.text('Template saved'), findsOneWidget);

      // Route should pop
      await tester.pumpAndSettle();
      expect(find.byType(CreateTemplateScreen), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Loading / disabled state
    // -----------------------------------------------------------------------

    testWidgets('shows loading overlay during async operations',
        (tester) async {
      final completer = Completer<WorkoutTemplate?>();
      final notifier = _CompleterProgramsNotifier(
        programs: [testProgram],
        createTemplateCompleter: completer,
      );

      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'My Template');
      await tester.tap(_dropdownFinder);
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Program A').last);
      await tester.pump();

      // Tap Create
      await tester.tap(find.widgetWithText(FilledButton, 'Create Template'));
      await tester.pump();

      // Loading overlay should be visible
      expect(find.text('Saving...'), findsOneWidget);

      // Complete the operation
      completer.complete(null);
      await tester.pump();
      await tester.pump();

      // Loading overlay should be gone
      expect(find.text('Saving...'), findsNothing);
    });
  });
}

// ---------------------------------------------------------------------------
// Fake with completers for testing loading states
// ---------------------------------------------------------------------------

class _CompleterProgramsNotifier extends ProgramsNotifier {
  final Completer<WorkoutTemplate?> createTemplateCompleter;
  final List<WorkoutProgram> programs;

  _CompleterProgramsNotifier({
    required this.programs,
    required this.createTemplateCompleter,
  }) : super(apiClient: ApiClient.instance) {
    super.state = ProgramsState(
      userPrograms: programs,
      isLoading: false,
    );
  }

  @override
  Future<WorkoutTemplate?> createTemplate({
    required String name,
    String? description,
    required String programId,
  }) async {
    state = state.copyWith(isLoading: true);
    return createTemplateCompleter.future;
  }

  @override
  Future<void> startEditingTemplate(
      String templateId, String programId) async {
    state = state.copyWith(
      editingTemplateId: templateId,
      editingProgramId: programId,
      templateExercises: [],
      isLoading: false,
    );
  }

  @override
  Future<bool> deleteExerciseStep(String stepId) async => true;
}
