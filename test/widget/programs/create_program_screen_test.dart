import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';
import 'package:zirofit_fl/features/programs/screens/create_program_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake ProgramsNotifier – controllable createProgram behavior
// ---------------------------------------------------------------------------

class FakeProgramsNotifier extends ProgramsNotifier {
  /// Whether [createProgram] should return a valid [WorkoutProgram].
  bool succeedCreate = true;

  /// Error message set on state when [succeedCreate] is `false`.
  String? errorMessage = 'Creation failed';

  /// When non-null, [createProgram] awaits this completer before returning.
  Completer<void>? createCompleter;

  /// Set to `true` after [createProgram] is invoked.
  bool createProgramCalled = false;

  /// Captured arguments from the last [createProgram] call.
  String? capturedName;
  String? capturedDescription;

  FakeProgramsNotifier() : super(apiClient: ApiClient.instance) {
    super.state = const ProgramsState();
  }

  @override
  Future<WorkoutProgram?> createProgram(
    String name,
    String? description,
  ) async {
    createProgramCalled = true;
    capturedName = name;
    capturedDescription = description;
    state = state.copyWith(isLoading: true, clearError: true);

    if (createCompleter != null) {
      await createCompleter!.future;
    }

    if (succeedCreate) {
      final program = WorkoutProgram(
        id: 'new-1',
        name: name,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      state = ProgramsState(programs: [program], isLoading: false);
      return program;
    } else {
      state = state.copyWith(isLoading: false, error: errorMessage);
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Test app builders
// ---------------------------------------------------------------------------

/// Wraps [CreateProgramScreen] in a [ProviderScope] with the given fake
/// notifier and a plain [MaterialApp]. Suitable for tests that do not invoke
/// `context.pop()` (validations, error path, disabled button).
Widget buildApp({required FakeProgramsNotifier notifier}) {
  return ProviderScope(
    overrides: [programsProvider.overrideWith((ref) => notifier)],
    child: const MaterialApp(home: CreateProgramScreen()),
  );
}

/// Wraps [CreateProgramScreen] with a [GoRouter] so that `context.pop()`
/// (called on successful creation) completes without throwing. Use this for
/// the success-path test where navigation is verified.
Widget buildAppWithRouter({required FakeProgramsNotifier notifier}) {
  final router = GoRouter(
    initialLocation: '/create',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SizedBox(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, __) => const CreateProgramScreen(),
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

  group('CreateProgramScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpApp(const CreateProgramScreen());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows error message when name field is empty on submit', (
      tester,
    ) async {
      final notifier = FakeProgramsNotifier();
      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      // Leave name empty and tap submit
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // Validator should fire and show the error text
      expect(find.text('Please enter a program name'), findsOneWidget);
    });

    testWidgets('shows error message when name is only whitespace', (
      tester,
    ) async {
      final notifier = FakeProgramsNotifier();
      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      // Enter whitespace-only value
      await tester.enterText(find.byType(TextFormField).first, '   ');

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // Validator should reject whitespace
      expect(find.text('Please enter a program name'), findsOneWidget);
    });

    testWidgets('creates program successfully with valid data', (tester) async {
      final notifier = FakeProgramsNotifier()..succeedCreate = true;

      await tester.pumpWidget(buildAppWithRouter(notifier: notifier));
      await tester.pump();

      // Fill in name and description
      await tester.enterText(find.byType(TextFormField).first, 'My Program');
      await tester.enterText(find.byType(TextFormField).last, 'Test desc');

      // Submit
      await tester.tap(find.byType(FilledButton));
      // First pump: process the tap, _submit() runs fully (Fake completes
      // immediately), calls showSnackBar + context.pop(). The SnackBar is
      // queued into the overlay; the route pop is also started this frame.
      await tester.pump();

      // The SnackBar content widget is already in the tree (it was built
      // during the same frame). Check it before the route transition removes
      // the Scaffold the SnackBar is attached to.
      expect(find.text('Program "My Program" created'), findsOneWidget);

      // Let the route transition settle so the popped screen is removed.
      await tester.pumpAndSettle();

      // Verify createProgram was called with the correct arguments
      expect(notifier.createProgramCalled, isTrue);
      expect(notifier.capturedName, 'My Program');
      expect(notifier.capturedDescription, 'Test desc');

      // Navigation: screen should no longer be in the tree after pop
      expect(find.byType(CreateProgramScreen), findsNothing);
    });

    testWidgets('shows error snackbar when create fails', (tester) async {
      final notifier = FakeProgramsNotifier()
        ..succeedCreate = false
        ..errorMessage = 'Network error';

      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      // Enter valid name
      await tester.enterText(find.byType(TextFormField).first, 'My Program');

      // Submit – no pop happens on failure, only SnackBar
      await tester.tap(find.byType(FilledButton));
      await tester.pump(); // process tap, run _submit() fully
      await tester.pump(
        const Duration(milliseconds: 500),
      ); // animate SnackBar in

      // Verify error message in SnackBar
      expect(find.text('Network error'), findsOneWidget);

      // Verify SnackBar has error background color
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, ThemeData().colorScheme.error);
    });

    testWidgets('submit button disabled while submitting', (tester) async {
      final completer = Completer<void>();
      final notifier = FakeProgramsNotifier()
        ..succeedCreate = false
        ..errorMessage = 'fail'
        ..createCompleter = completer;

      await tester.pumpWidget(buildApp(notifier: notifier));
      await tester.pump();

      // Enter valid name
      await tester.enterText(find.byType(TextFormField).first, 'My Program');

      // Tap submit – _submit() sets _isSubmitting = true synchronously,
      // then awaits createProgram which hangs on the uncompleted completer.
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // Button should be disabled with a progress indicator
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // "Create Program" text is still in the AppBar title, but should NOT
      // appear inside the FilledButton itself.
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text('Create Program'),
        ),
        findsNothing,
      );

      // Complete the creation to avoid leaking the pending async work
      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
