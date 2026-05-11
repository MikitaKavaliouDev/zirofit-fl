# lib/features/progress

**Parent:** Root AGENTS.md covers features overview.

## OVERVIEW
Progress analytics & tracking. 24 Dart files - largest feature module.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Progress screen | `screens/progress_screen.dart` | Main analytics view |
| Charts | `widgets/muscle_focus_chart.dart`, `widgets/weight_history_chart.dart` | fl_chart usage |
| Goals | `screens/goal_setting_screen.dart`, `widgets/goal_card.dart` | Goal tracking |
| Widget management | `screens/manage_widgets_screen.dart` | Dashboard customization |

## CONVENTIONS
- fl_chart for all visualizations
- Widget-based dashboard with customizable cards
- Provider pattern: `progressProvider`, `goalProvider`

## UNIQUE STYLES
- Heat map calendar for activity tracking
- Personal records (PR) tracking with milestone badges
- Performance summary with volume/reps/weight aggregates

## ANTI-PATTERNS
- DO NOT use hardcoded chart colors - use `AppColors`
- DO NOT skip shimmer placeholders during loading