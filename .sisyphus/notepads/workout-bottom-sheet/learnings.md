## [2026-05-12] Timer Display Bug - StateNotifier State Type Fix

### Problem
When starting or resuming a workout, the timer displayed `00:00` instead of counting from the session's `startTime` (e.g., 2 hours prior). The API correctly returned `startTime`, and `_tick()` correctly computed elapsed time, but the UI never updated.

### Root Cause
`WorkoutTimerNotifier` extended `StateNotifier<WorkoutTimerState>` where the state was a mere **enum** (`idle/running/paused`). The `_tick()` method computed elapsed in a private `_elapsed` field but never emitted a new state object. Since `ref.watch(workoutTimerProvider)` only triggered rebuilds when the enum value changed (which stayed `running`), the UI froze showing `00:00`.

### Fix
1. Created `WorkoutTimerData` class with `state` (enum) + `elapsed` (Duration) fields
2. Changed `WorkoutTimerNotifier` → `StateNotifier<WorkoutTimerData>`
3. `_tick()` now emits `state = WorkoutTimerData(state: ..., elapsed: elapsed)` every second, triggering Riverpod listeners to rebuild
4. `start()` and `reset()` compute initial elapsed from `DateTime.now().difference(startTime)` so resumed sessions show correct time immediately
5. Removed redundant local timer in `WorkoutMiniPlayer` (it had its own `_elapsedTimer`, `_workoutStartTime`, `_elapsedSeconds` that were disconnected from the provider)

### Files Changed
- `workout_timer_provider.dart` - Core refactor
- `workout_session_header.dart` - Consumer updated
- `workout_session_controls.dart` - Consumer updated
- `workout_mini_player.dart` - Removed local timer, uses provider
- `workout_controls_bar.dart` - Consumer updated

### Verification
- `flutter analyze` — 0 errors, 0 warnings (only pre-existing info-level issues)
- `test/unit/providers/workout_timer_provider_test.dart` — 11/11 pass
