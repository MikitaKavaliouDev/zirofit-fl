import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/services/haptic_service.dart';

void main() {
  group('HapticService', () {
    late HapticService service;

    setUp(() {
      service = HapticService();
    });

    test('service can be instantiated', () {
      expect(service, isNotNull);
    });

    test('setEnabled toggles haptic feedback', () {
      service.setEnabled(true);
      service.setEnabled(false);
      // No error = pass
    });

    test('lightImpact returns Future', () async {
      final result = service.lightImpact();
      expect(result, isA<Future>());
      await result;
    });

    test('mediumImpact returns Future', () async {
      final result = service.mediumImpact();
      expect(result, isA<Future>());
      await result;
    });

    test('heavyImpact returns Future', () async {
      final result = service.heavyImpact();
      expect(result, isA<Future>());
      await result;
    });

    test('selection returns Future', () async {
      final result = service.selection();
      expect(result, isA<Future>());
      await result;
    });

    test('success returns Future', () async {
      final result = service.success();
      expect(result, isA<Future>());
      await result;
    });

    test('warning returns Future', () async {
      final result = service.warning();
      expect(result, isA<Future>());
      await result;
    });

    test('error returns Future', () async {
      final result = service.error();
      expect(result, isA<Future>());
      await result;
    });

    test('impact with HapticType returns Future', () async {
      for (final type in HapticType.values) {
        final result = service.impact(type);
        expect(result, isA<Future>());
        await result;
      }
    });
  });

  group('HapticType enum', () {
    test('all haptic types exist', () {
      expect(HapticType.values.length, 7);
      expect(HapticType.values.contains(HapticType.impactLight), true);
      expect(HapticType.values.contains(HapticType.impactMedium), true);
      expect(HapticType.values.contains(HapticType.impactHeavy), true);
      expect(HapticType.values.contains(HapticType.selection), true);
      expect(HapticType.values.contains(HapticType.success), true);
      expect(HapticType.values.contains(HapticType.warning), true);
      expect(HapticType.values.contains(HapticType.error), true);
    });
  });
}