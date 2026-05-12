# Workout Sheet Overlay - Learnings

## Created
- `lib/features/workout/widgets/workout_sheet_overlay.dart` (83 lines)

## Key Patterns
- `ConsumerStatefulWidget` wrapping `EnhancedActiveWorkoutScreen` in a `Stack` with `AnimatedPositioned` for slide-up/down animation
- Controlled entirely by `sessionOverlayProvider` (StateNotifierProvider) — no local state for visibility
- Backdrop only rendered when `overlayState == SessionOverlayState.full`
- Sheet height set to `0` when not visible (slides down), `screenHeight * 0.9` when full
- `AnimatedPositioned` duration 350ms with `Curves.easeOutCubic` for smooth animation
- `ClipRRect` with `BorderRadius.vertical(top: Radius.circular(24))` for the sheet's top corners

## Callback Mapping
- `onMinimize` → `sessionOverlayProvider.notifier.showMini()`
- `onFinish` → `sessionOverlayProvider.notifier.hide()` + `widget.onFinishWorkout?.call()`
- `onCancel` → `sessionOverlayProvider.notifier.hide()` + `widget.onCancelWorkout?.call()`

## Constraints Met
- ✅ No `showModalBottomSheet` or `DraggableScrollableSheet`
- ✅ No existing files modified
- ✅ No new dependencies
- ✅ No duplicate state management (relies on existing provider)
