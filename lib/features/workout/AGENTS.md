# lib/features/workout

**Parent:** Root AGENTS.md covers features overview.

## OVERVIEW
Workout tracking & execution. 23 Dart files with voice features and live activities.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Active workout | `screens/active_workout_screen.dart` | In-session UI |
| Workout history | `screens/workout_history_screen.dart` | Past sessions |
| Summary | `screens/workout_summary_screen.dart` | Post-workout review |
| Voice services | `services/voice_*.dart` | TTS + speech-to-text |
| Live activity | `services/live_activity_*.dart` | iOS lock screen |

## CONVENTIONS
- StateNotifier pattern for active workout state
- Timer via `workout_timer_provider.dart`
- Exercise selection via `exercise_selection_view.dart`

## UNIQUE STYLES
- Voice input overlay for hands-free logging
- Plate calculator for barbell math
- RPE (Rate of Perceived Exertion) picker
- Superset grouping indicators

## COMMANDS
```bash
flutter test test/widget/workout/  # Workout-specific tests
```

## ANTI-PATTERNS
- DO NOT bypass active_workout_provider for state
- DO NOT use print() for debugging - use logger