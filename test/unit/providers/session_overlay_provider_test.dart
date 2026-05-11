import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';

void main() {
  group('sessionOverlayProvider', () {
    test('initial state is hidden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(sessionOverlayProvider);
      expect(state, SessionOverlayState.hidden);
    });

    test('can transition to full', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sessionOverlayProvider.notifier).state = SessionOverlayState.full;
      expect(container.read(sessionOverlayProvider), SessionOverlayState.full);
    });

    test('can transition to mini from full', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sessionOverlayProvider.notifier).state = SessionOverlayState.full;
      container.read(sessionOverlayProvider.notifier).state = SessionOverlayState.mini;
      expect(container.read(sessionOverlayProvider), SessionOverlayState.mini);
    });

    test('can transition back to hidden from mini', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sessionOverlayProvider.notifier).state = SessionOverlayState.full;
      container.read(sessionOverlayProvider.notifier).state = SessionOverlayState.mini;
      container.read(sessionOverlayProvider.notifier).state = SessionOverlayState.hidden;
      expect(container.read(sessionOverlayProvider), SessionOverlayState.hidden);
    });
  });

  group('SessionOverlayState enum', () {
    test('has three states', () {
      expect(SessionOverlayState.values.length, 3);
      expect(SessionOverlayState.values, contains(SessionOverlayState.hidden));
      expect(SessionOverlayState.values, contains(SessionOverlayState.full));
      expect(SessionOverlayState.values, contains(SessionOverlayState.mini));
    });
  });
}