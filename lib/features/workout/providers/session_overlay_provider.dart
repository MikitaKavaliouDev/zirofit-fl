import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// States for the workout session overlay.
enum SessionOverlayState { hidden, full, mini }

/// Manages the workout session overlay visibility/mode state.
///
/// Provides [showFull], [showMini], [hide], and [toggle] methods
/// for controlling the overlay across the app.
class SessionOverlayNotifier extends StateNotifier<SessionOverlayState> {
  SessionOverlayNotifier() : super(SessionOverlayState.hidden);

  /// Shows the overlay in full-size mode.
  void showFull() => state = SessionOverlayState.full;

  /// Shows the overlay in mini-player mode.
  void showMini() => state = SessionOverlayState.mini;

  /// Hides the overlay entirely.
  void hide() => state = SessionOverlayState.hidden;

  /// Toggles between full and mini modes.
  /// If hidden, defaults to full.
  void toggle() {
    state = switch (state) {
      SessionOverlayState.full => SessionOverlayState.mini,
      SessionOverlayState.mini => SessionOverlayState.full,
      SessionOverlayState.hidden => SessionOverlayState.full,
    };
  }
}

/// Provider for the workout session overlay state.
final sessionOverlayProvider =
    StateNotifierProvider<SessionOverlayNotifier, SessionOverlayState>(
  (ref) => SessionOverlayNotifier(),
);

/// Provider for the floating mini overlay position on screen.
final workoutOverlayPositionProvider = StateProvider<Offset>(
  (ref) => const Offset(16, 100),
);