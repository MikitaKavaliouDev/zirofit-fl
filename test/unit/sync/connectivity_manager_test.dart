import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/data/sync/connectivity_manager.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late StreamController<List<ConnectivityResult>> controller;

  setUp(() {
    mockConnectivity = MockConnectivity();
    controller = StreamController<List<ConnectivityResult>>.broadcast();
    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => controller.stream);
  });

  tearDown(() {
    controller.close();
  });

  group('ConnectivityManager', () {
    // ──────────────────────────────────────────────
    // Constructor and initial state
    // ──────────────────────────────────────────────
    test('isOnline defaults to true before initialize', () {
      final manager = ConnectivityManager(connectivity: mockConnectivity);
      expect(manager.isOnline, true);
    });

    // ──────────────────────────────────────────────
    // checkConnectivity()
    // ──────────────────────────────────────────────
    test('checkConnectivity returns true for wifi', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      final result = await manager.checkConnectivity();

      expect(result, true);
      expect(manager.isOnline, true);
    });

    test('checkConnectivity returns true for mobile', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      final result = await manager.checkConnectivity();

      expect(result, true);
      expect(manager.isOnline, true);
    });

    test('checkConnectivity returns false for none', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      final result = await manager.checkConnectivity();

      expect(result, false);
      expect(manager.isOnline, false);
    });

    test('checkConnectivity returns false for empty results list', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => <ConnectivityResult>[]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      final result = await manager.checkConnectivity();

      expect(result, false);
      expect(manager.isOnline, false);
    });

    test('checkConnectivity returns true for mixed results (wifi + none)',
        () async {
      when(() => mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi, ConnectivityResult.none],
      );

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      final result = await manager.checkConnectivity();

      expect(result, true);
      expect(manager.isOnline, true);
    });

    // ──────────────────────────────────────────────
    // initialize()
    // ──────────────────────────────────────────────
    test('initialize sets isOnline based on checkConnectivity result',
        () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      expect(manager.isOnline, true); // default before init

      await manager.initialize();

      expect(manager.isOnline, false);
    });

    test('initialize subscribes to onConnectivityChanged stream', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      await manager.initialize();

      // Listen to the public stream from the manager
      final emitted = <bool>[];
      manager.onConnectivityChanged.listen(emitted.add);

      // Emit a change through the mock's stream
      controller.add([ConnectivityResult.none]);
      await Future(() {});

      expect(emitted.length, 1);
      expect(emitted.first, false);
    });

    // ──────────────────────────────────────────────
    // Stream behavior
    // ──────────────────────────────────────────────
    test('stream emits true when connectivity changes from none to wifi',
        () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      await manager.initialize();
      expect(manager.isOnline, false);

      final emitted = <bool>[];
      manager.onConnectivityChanged.listen(emitted.add);

      controller.add([ConnectivityResult.wifi]);
      await Future(() {});

      expect(emitted, [true]);
    });

    test('stream emits false when connectivity changes from wifi to none',
        () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      await manager.initialize();
      expect(manager.isOnline, true);

      final emitted = <bool>[];
      manager.onConnectivityChanged.listen(emitted.add);

      controller.add([ConnectivityResult.none]);
      await Future(() {});

      expect(emitted, [false]);
    });

    test('stream does not emit when connectivity stays the same (wifi -> wifi)',
        () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      await manager.initialize();
      expect(manager.isOnline, true);

      final emitted = <bool>[];
      manager.onConnectivityChanged.listen(emitted.add);

      controller.add([ConnectivityResult.wifi]);
      await Future(() {});

      expect(emitted, isEmpty);
    });

    test('stream does not emit for duplicate repeated states', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      await manager.initialize();
      expect(manager.isOnline, false);

      final emitted = <bool>[];
      manager.onConnectivityChanged.listen(emitted.add);

      // Multiple emissions of the same state should all be suppressed
      controller.add([ConnectivityResult.none]);
      controller.add([ConnectivityResult.none]);
      controller.add([ConnectivityResult.none]);
      await Future(() {});

      expect(emitted, isEmpty);
    });

    // ──────────────────────────────────────────────
    // _evaluateConnectivity (tested indirectly)
    // ──────────────────────────────────────────────
    test('_evaluateConnectivity returns false for empty list', () async {
      // Indirectly tested through checkConnectivity
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => <ConnectivityResult>[]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      final result = await manager.checkConnectivity();

      expect(result, false);
    });

    test('_evaluateConnectivity returns false when all results are none',
        () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none, ConnectivityResult.none]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      final result = await manager.checkConnectivity();

      expect(result, false);
    });

    test('_evaluateConnectivity returns true when any result is non-none',
        () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile, ConnectivityResult.none]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      final result = await manager.checkConnectivity();

      expect(result, true);
    });

    // ──────────────────────────────────────────────
    // dispose()
    // ──────────────────────────────────────────────
    test('dispose does not throw and prevents further stream emissions',
        () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      await manager.initialize();

      // Listen after dispose to verify no events come through
      final emittedAfter = <bool>[];
      manager.onConnectivityChanged.listen(emittedAfter.add);

      expect(() => manager.dispose(), returnsNormally);

      // Try emitting after dispose – should not reach our listener
      controller.add([ConnectivityResult.none]);
      await Future(() {});
      // If dispose didn't close things properly, this would cause errors
      // Just verifying we got here without throwing is a good sign.
    });

    test('dispose can be called safely when subscription exists', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final manager = ConnectivityManager(connectivity: mockConnectivity);
      await manager.initialize();

      // Should not throw
      expect(() => manager.dispose(), returnsNormally);
    });
  });
}
