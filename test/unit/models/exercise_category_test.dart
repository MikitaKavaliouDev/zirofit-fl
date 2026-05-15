import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/enums/exercise_category.dart';

void main() {
  group('ExerciseCategory', () {
    test('fromJson parses MAIN', () {
      expect(ExerciseCategory.fromJson('MAIN'), ExerciseCategory.main);
    });

    test('fromJson parses ASSISTANCE', () {
      expect(
        ExerciseCategory.fromJson('ASSISTANCE'),
        ExerciseCategory.assistance,
      );
    });

    test('fromJson parses ACCESSORY', () {
      expect(
        ExerciseCategory.fromJson('ACCESSORY'),
        ExerciseCategory.accessory,
      );
    });

    test('fromJson parses ADDITION', () {
      expect(
        ExerciseCategory.fromJson('ADDITION'),
        ExerciseCategory.addition,
      );
    });

    test('fromJson parses WARMUP', () {
      expect(ExerciseCategory.fromJson('WARMUP'), ExerciseCategory.warmup);
    });

    test('fromJson is case-insensitive', () {
      expect(ExerciseCategory.fromJson('main'), ExerciseCategory.main);
      expect(ExerciseCategory.fromJson('Main'), ExerciseCategory.main);
    });

    test('toJson returns uppercase wire value', () {
      expect(ExerciseCategory.main.toJson(), 'MAIN');
      expect(ExerciseCategory.assistance.toJson(), 'ASSISTANCE');
      expect(ExerciseCategory.accessory.toJson(), 'ACCESSORY');
      expect(ExerciseCategory.addition.toJson(), 'ADDITION');
      expect(ExerciseCategory.warmup.toJson(), 'WARMUP');
    });

    test('fromJson throws on unknown value', () {
      expect(
        () => ExerciseCategory.fromJson('UNKNOWN'),
        throwsA(isA<StateError>()),
      );
    });

    test('all values roundtrip through fromJson/toJson', () {
      for (final category in ExerciseCategory.values) {
        expect(
          ExerciseCategory.fromJson(category.toJson()),
          category,
        );
      }
    });
  });
}
