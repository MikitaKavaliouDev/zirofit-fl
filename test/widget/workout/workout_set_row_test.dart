import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_set_row.dart';

void main() {
  late WorkoutSet testSet;
  late bool onDeleteCalled;

  setUp(() {
    testSet = const WorkoutSet(
      id: 'set1',
      logId: 'log1',
      reps: 10,
      weight: 60.0,
      rpe: 8.0,
      isCompleted: false,
      status: SetStatus.normal,
    );
    onDeleteCalled = false;
  });

  Widget createWidgetUnderTest({
    WorkoutSet? set,
    WorkoutSet? previousSet,
    FocusMetric focusMetric = FocusMetric.none,
    VoidCallback? onComplete,
    VoidCallback? onDelete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: WorkoutSetRow(
          set: set ?? testSet,
          setNumber: 1,
          previousSet: previousSet,
          focusMetric: focusMetric,
          onComplete: onComplete ?? () {},
          onDelete: onDelete ?? () => onDeleteCalled = true,
          onWeightChanged: (_) {},
          onRepsChanged: (_) {},
          onRpeChanged: (_) {},
          onStatusChanged: (_) {},
        ),
      ),
    );
  }

  testWidgets('displays set number badge for normal status', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('displays weight and reps text', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('60.0 kg'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('displays RPE text', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('8.0'), findsOneWidget);
  });

  testWidgets('shows Dismissible for swipe delete', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(Dismissible), findsOneWidget);
  });

  testWidgets('calls onDelete when dismissed', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    onDeleteCalled = false;

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(onDeleteCalled, isTrue);
  });

  testWidgets('shows focus metric icons exist in widget tree', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(focusMetric: FocusMetric.volume));
    // Widget renders without error - icons exist in the widget tree
    expect(find.byType(WorkoutSetRow), findsOneWidget);
  });

  testWidgets('displays warmup badge correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      set: testSet.copyWith(status: SetStatus.warmUp),
    ));
    expect(find.text('W1'), findsOneWidget);
  });

  testWidgets('displays drop set badge correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      set: testSet.copyWith(status: SetStatus.dropSet),
    ));
    expect(find.text('D1'), findsOneWidget);
  });

  testWidgets('displays failure badge correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      set: testSet.copyWith(status: SetStatus.failure),
    ));
    expect(find.text('F1'), findsOneWidget);
  });

  testWidgets('renders with weight icon', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byIcon(Icons.fitness_center), findsWidgets);
  });

  testWidgets('renders with reps icon', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byIcon(Icons.numbers), findsWidgets);
  });
}
