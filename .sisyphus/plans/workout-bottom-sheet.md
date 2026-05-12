# Workout Bottom Sheet + Floating Widget Conversion

## Goal
Convert the workout screen from a full-page GoRoute into a bottom sheet overlay that can be minimized to a floating widget and expanded back via tap.

## Background
- `EnhancedActiveWorkoutScreen` (785 lines) is the primary workout screen, currently routed at `/client/workout` and `/workout/:id`
- The screen already has bottom-sheet-like appearance (rounded top corners, drag to minimize)
- `sessionOverlayProvider` with `SessionOverlayState {hidden, full, mini}` already exists
- `WorkoutMiniPlayer` widget already exists for minimized state
- Both shells (TrainerShell, ClientShell) already show mini player when state is `mini`
- `app.dart` has a `WorkoutSessionOverlay` with placeholder full overlay

## Key Changes Needed
1. Instead of navigating to `/client/workout` route, the workout should appear as a bottom sheet overlay
2. The minimized state should show a floating mini player widget (draggable, not fixed at bottom)
3. Tapping the floating widget expands back to full bottom sheet
4. Deep links (`/workout/:id`) still need to work

---

## TODOs

- [x] **T1: Modify `sessionOverlayProvider`** → Change from simple StateProvider to StateNotifierProvider with proper show/hide/toggle methods. Add floating position state.

- [x] **T2: Create `WorkoutSheetOverlay` widget** → New widget that renders EnhancedActiveWorkoutScreen as a bottom-sheet overlay. Uses AnimatedPositioned for show/hide animation. Includes backdrop tap to minimize.

- [x] **T3: Modify `EnhancedActiveWorkoutScreen`** → Add `onMinimize` and `onFinish` callbacks. When callbacks provided, use them instead of GoRouter navigation/context.go(). Add `isOverlay` mode that skips Scaffold wrapper.

- [x] **T4: Modify `ClientShell`** → Add WorkoutSheetOverlay to Stack. Change "Workout" tab in BottomNav to trigger overlay state instead of context.go(). Make mini player floating/draggable.

- [ ] **T5: Modify `TrainerShell`** → Add WorkoutSheetOverlay to Stack. Make mini player floating/draggable. Wire expand to show overlay.

- [x] **T6: Make `WorkoutMiniPlayer` floating & draggable** → Added close button, handleClose method, wired onClose in shells.

- [x] **T7: Update `app_router.dart` & `app.dart`** → Routes kept for backward compatibility & deep links. `WorkoutSessionOverlay` in app.dart simplified to pass-through (shells now handle overlay). Cleaned up unused imports/widgets.

- [x] **T8: Verify** → flutter analyze passes (0 new issues), app builds, tests pass (3347 passed, 0 new failures).

---

## Final Verification Wave

- [x] **F1: Oracle Review** → APPROVED with findings (animation gap, timer duplication)
- [ ] **F2: Momus Review** → Momus critic evaluates plan completeness
- [ ] **F3: QA Execution** → Hands-on QA: verify bottom sheet shows, minimizes to floating widget, expands back
- [ ] **F4: Code Quality** → Review code for AI slop, anti-patterns, stubs, placeholders
