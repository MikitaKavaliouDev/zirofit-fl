import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/plate_calculation.dart';

void main() {
  group('PlateSet', () {
    test('constructor assigns fields correctly', () {
      final plate = PlateSet(weight: 25, count: 1);
      expect(plate.weight, 25);
      expect(plate.count, 1);
    });

    test('equality works correctly', () {
      final a = PlateSet(weight: 20, count: 2);
      final b = PlateSet(weight: 20, count: 2);
      expect(a, equals(b));
    });

    test('inequality detects different weight', () {
      final a = PlateSet(weight: 20, count: 2);
      final b = PlateSet(weight: 25, count: 2);
      expect(a, isNot(equals(b)));
    });

    test('inequality detects different count', () {
      final a = PlateSet(weight: 20, count: 2);
      final b = PlateSet(weight: 20, count: 1);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent', () {
      final plate = PlateSet(weight: 25, count: 1);
      expect(plate.hashCode, equals(plate.hashCode));
    });

    test('toString contains weight and count', () {
      final plate = PlateSet(weight: 10, count: 2);
      expect(plate.toString(), contains('weight: 10.0'));
      expect(plate.toString(), contains('count: 2'));
    });
  });

  group('PlateCalculation', () {
    test('weightPerSide calculates correctly', () {
      // 100 kg total, 20 kg bar = 80 kg / 2 = 40 kg per side
      final calc = PlateCalculation(
        totalWeight: 100,
        platesPerSide: [
          PlateSet(weight: 25, count: 1),
          PlateSet(weight: 15, count: 1),
        ],
      );
      expect(calc.weightPerSide, 40.0);
    });

    test('weightPerSide with custom bar weight', () {
      // 60 kg total, 15 kg women's bar = 45 kg / 2 = 22.5 kg per side
      final calc = PlateCalculation(
        totalWeight: 60,
        barWeight: 15,
        platesPerSide: [
          PlateSet(weight: 20, count: 1),
          PlateSet(weight: 2.5, count: 1),
        ],
      );
      expect(calc.weightPerSide, 22.5);
    });

    test('formatted returns weight string', () {
      final calc = PlateCalculation(
        totalWeight: 100,
        platesPerSide: [],
      );
      expect(calc.formatted, '100 kg');
    });

    test('equality works correctly', () {
      final a = PlateCalculation(
        totalWeight: 100,
        platesPerSide: [PlateSet(weight: 25, count: 1)],
      );
      final b = PlateCalculation(
        totalWeight: 100,
        platesPerSide: [PlateSet(weight: 25, count: 1)],
      );
      expect(a, equals(b));
    });

    test('inequality detects different platesPerSide', () {
      final a = PlateCalculation(
        totalWeight: 100,
        platesPerSide: [PlateSet(weight: 25, count: 1)],
      );
      final b = PlateCalculation(
        totalWeight: 100,
        platesPerSide: [PlateSet(weight: 20, count: 2)],
      );
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent', () {
      final calc = PlateCalculation(
        totalWeight: 100,
        platesPerSide: [PlateSet(weight: 25, count: 1)],
      );
      expect(calc.hashCode, equals(calc.hashCode));
    });

    test('toString contains totalWeight and barWeight', () {
      final calc = PlateCalculation(
        totalWeight: 100,
        platesPerSide: [],
      );
      expect(calc.toString(), contains('totalWeight: 100.0'));
      expect(calc.toString(), contains('barWeight: 20.0'));
    });
  });

  group('calculatePlates', () {
    test('returns empty list when target is less than bar weight', () {
      expect(calculatePlates(10), isEmpty);
      expect(calculatePlates(19), isEmpty);
    });

    test('returns empty list when target equals bar weight', () {
      expect(calculatePlates(20), isEmpty);
    });

    test('calculates 100 kg correctly: 1x25 + 1x15 per side', () {
      // 100 - 20 = 80 / 2 = 40 per side
      // 40 = 25 + 15
      final plates = calculatePlates(100);
      expect(plates, [
        PlateSet(weight: 25, count: 1),
        PlateSet(weight: 15, count: 1),
      ]);
    });

    test('calculates 60 kg correctly: 1x20 per side', () {
      // 60 - 20 = 40 / 2 = 20 per side
      final plates = calculatePlates(60);
      expect(plates, [
        PlateSet(weight: 20, count: 1),
      ]);
    });

    test('calculates 140 kg correctly: 2x25 + 1x10 per side', () {
      // 140 - 20 = 120 / 2 = 60 per side
      // 60 = 25 + 25 + 10
      final plates = calculatePlates(140);
      expect(plates, [
        PlateSet(weight: 25, count: 2),
        PlateSet(weight: 10, count: 1),
      ]);
    });

    test('calculates 50 kg correctly: 1x15 per side', () {
      // 50 - 20 = 30 / 2 = 15 per side
      final plates = calculatePlates(50);
      expect(plates, [
        PlateSet(weight: 15, count: 1),
      ]);
    });

    test('handles fractional plates (2.5, 1.25)', () {
      // 45 kg total: 45 - 20 = 25 / 2 = 12.5 per side
      // 12.5 = 10 + 2.5 (since no 12.5 plate)
      final plates = calculatePlates(45);
      expect(plates, [
        PlateSet(weight: 10, count: 1),
        PlateSet(weight: 2.5, count: 1),
      ]);
    });

    test('handles smallest possible increment over bar weight', () {
      // 22.5 kg total: 22.5 - 20 = 2.5 / 2 = 1.25 per side
      final plates = calculatePlates(22.5);
      expect(plates, [
        PlateSet(weight: 1.25, count: 1),
      ]);
    });

    test('uses multiple of same plate when needed', () {
      // 180 kg: 180 - 20 = 160 / 2 = 80 per side
      // 80 = 25 + 25 + 25 + 5
      final plates = calculatePlates(180);
      expect(plates, [
        PlateSet(weight: 25, count: 3),
        PlateSet(weight: 5, count: 1),
      ]);
    });

    test('sorts heaviest to lightest', () {
      final plates = calculatePlates(100);
      for (var i = 1; i < plates.length; i++) {
        expect(plates[i].weight, lessThanOrEqualTo(plates[i - 1].weight));
      }
    });

    test('custom bar weight works correctly', () {
      // 50 kg total, 15 kg women's bar = 35 / 2 = 17.5 per side
      // 17.5 = 15 + 2.5
      final plates = calculatePlates(50, barWeight: 15);
      expect(plates, [
        PlateSet(weight: 15, count: 1),
        PlateSet(weight: 2.5, count: 1),
      ]);
    });

    test('returns empty for zero remaining after bar', () {
      expect(calculatePlates(20), isEmpty);
    });
  });
}
