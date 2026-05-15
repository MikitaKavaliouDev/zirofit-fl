import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/features/dashboard/providers/daily_target_provider.dart';
import '../../helpers/mock_api_client.dart';

void main() {
  group('DailyTarget', () {
    test('fromJson and toJson round-trip', () {
      final now = DateTime.now();
      final target = DailyTarget(
        id: '1',
        title: 'Drink Water',
        description: 'Drink 8 glasses',
        type: 'water',
        targetValue: 8,
        currentValue: 3,
        unit: 'glasses',
        date: now,
        isCompleted: false,
      );

      final json = target.toJson();
      final restored = DailyTarget.fromJson(json);

      expect(restored, equals(target));
    });

    test('copyWith creates updated copy', () {
      final target = DailyTarget(
        id: '1',
        title: 'Steps',
        type: 'steps',
        targetValue: 10000,
        unit: 'steps',
        date: DateTime.now(),
      );

      final updated = target.copyWith(currentValue: 5000, isCompleted: true);

      expect(updated.id, target.id);
      expect(updated.currentValue, 5000);
      expect(updated.isCompleted, true);
      expect(updated.title, target.title);
    });
  });

  group('DailyTargetNotifier', () {
    late DailyTargetNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifier = DailyTargetNotifier();
    });

    test('initial state has empty targets and not loading', () {
      expect(notifier.state.targets, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('addTarget adds target to state', () async {
      final target = DailyTarget(
        id: '1',
        title: 'Walk',
        type: 'steps',
        targetValue: 10000,
        unit: 'steps',
        date: DateTime.now(),
      );

      await notifier.addTarget(target);

      expect(notifier.state.targets.length, 1);
      expect(notifier.state.targets.first.id, '1');
    });

    test('addTarget persists and loads correctly', () async {
      final today = DateTime.now();
      final target = DailyTarget(
        id: '1',
        title: 'Water',
        type: 'water',
        targetValue: 8,
        unit: 'glasses',
        date: today,
      );

      await notifier.addTarget(target);
      expect(notifier.state.targets.length, 1);

      // Load targets for today
      await notifier.loadTargets(today);
      expect(notifier.state.targets.length, 1);
      expect(notifier.state.targets.first.id, '1');

      // Load targets for a different date should return empty
      final otherDate = today.add(const Duration(days: 1));
      await notifier.loadTargets(otherDate);
      expect(notifier.state.targets, isEmpty);
    });

    test('updateProgress updates current value', () async {
      final target = DailyTarget(
        id: '1',
        title: 'Steps',
        type: 'steps',
        targetValue: 10000,
        unit: 'steps',
        date: DateTime.now(),
      );

      await notifier.addTarget(target);
      await notifier.updateProgress('1', 5000);

      expect(notifier.state.targets.first.currentValue, 5000);
    });

    test('toggleCompleted toggles isCompleted', () async {
      final target = DailyTarget(
        id: '1',
        title: 'Read',
        type: 'custom',
        targetValue: 1,
        unit: 'session',
        date: DateTime.now(),
      );

      await notifier.addTarget(target);
      expect(notifier.state.targets.first.isCompleted, false);

      await notifier.toggleCompleted('1');
      expect(notifier.state.targets.first.isCompleted, true);

      await notifier.toggleCompleted('1');
      expect(notifier.state.targets.first.isCompleted, false);
    });

    test('removeTarget removes target from state', () async {
      final target = DailyTarget(
        id: '1',
        title: 'Workout',
        type: 'workout',
        targetValue: 1,
        unit: 'session',
        date: DateTime.now(),
      );

      await notifier.addTarget(target);
      expect(notifier.state.targets.length, 1);

      await notifier.removeTarget('1');
      expect(notifier.state.targets, isEmpty);
    });

    test('calculateProgress returns correct ratio', () async {
      final target = DailyTarget(
        id: '1',
        title: 'Calories',
        type: 'calories',
        targetValue: 2000,
        unit: 'kcal',
        date: DateTime.now(),
      );

      await notifier.addTarget(target);
      await notifier.updateProgress('1', 500);

      expect(notifier.calculateProgress('1'), closeTo(0.25, 0.01));
    });

    test('calculateProgress clamps to 1.0', () async {
      final target = DailyTarget(
        id: '1',
        title: 'Steps',
        type: 'steps',
        targetValue: 10000,
        unit: 'steps',
        date: DateTime.now(),
      );

      await notifier.addTarget(target);
      await notifier.updateProgress('1', 15000);

      expect(notifier.calculateProgress('1'), 1.0);
    });

    test('calculateProgress returns 0 for zero target value', () async {
      final target = DailyTarget(
        id: '1',
        title: 'Custom',
        type: 'custom',
        targetValue: 0,
        unit: 'x',
        date: DateTime.now(),
      );

      await notifier.addTarget(target);

      expect(notifier.calculateProgress('1'), 0.0);
    });

    test('loadTargets handles empty storage', () async {
      await notifier.loadTargets(DateTime.now());

      expect(notifier.state.targets, isEmpty);
      expect(notifier.state.isLoading, false);
    });
  });

  group('DailyTargetNotifier with API', () {
    late DailyTargetNotifier notifier;
    late MockApiClient mockApiClient;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockApiClient = MockApiClient();
      notifier = DailyTargetNotifier(apiClient: mockApiClient);
    });

    test('loadTargets with apiClient calls GET /client/daily-targets', () async {
      final today = DateTime.now();

      final apiTarget = DailyTarget(
        id: 'api-1',
        title: 'API Steps',
        type: 'steps',
        targetValue: 10000,
        currentValue: 5000,
        unit: 'steps',
        date: today,
      );

      mockApiClient.mockGet(
        ApiConstants.dailyTargets,
        response: {
          'targets': [apiTarget.toJson()],
          'streak': 3,
        },
      );

      await notifier.loadTargets(today);

      verify(
        () => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.dailyTargets,
          queryParams: any(named: 'queryParams'),
        ),
      ).called(1);

      expect(notifier.state.targets.length, 1);
      expect(notifier.state.targets.first.id, 'api-1');
      expect(notifier.state.targets.first.title, 'API Steps');
      expect(notifier.state.streak, 3);
      expect(notifier.state.isLoading, false);
    });

    test('loadTargets when API fails falls back to SharedPreferences', () async {
      final today = DateTime.now();

      // Add a target via the notifier (persists to SharedPrefs)
      final localTarget = DailyTarget(
        id: 'local-1',
        title: 'Local Water',
        type: 'water',
        targetValue: 8,
        unit: 'glasses',
        date: today,
      );
      await notifier.addTarget(localTarget);
      expect(notifier.state.targets.length, 1);

      // Make the API call fail
      mockApiClient.mockError(
        ApiConstants.dailyTargets,
        DioExceptionType.badResponse,
        method: 'GET',
      );

      // Load — should fall back to SharedPrefs
      await notifier.loadTargets(today);

      expect(notifier.state.targets.length, 1);
      expect(notifier.state.targets.first.id, 'local-1');
      expect(notifier.state.targets.first.title, 'Local Water');
      expect(notifier.state.isLoading, false);
    });
  });
}
