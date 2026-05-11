# lib/data/models

**Parent:** Root AGENTS.md covers data layer architecture.

## OVERVIEW
Freezed immutable data models. 68 Dart files with JSON serialization.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| User/Profile | `user.dart`, `profile.dart` | Auth models |
| Workout | `workout_session.dart`, `workout_set.dart` | Exercise logging |
| Client | `client.dart` | Client data |
| Programs | `workout_program.dart`, `workout_template.dart` | Program definitions |

## CONVENTIONS
- All models use `@freezed` annotation with `immutable: true`
- JSON serialization via `json_serializable` + `.fromJson()` / `.toJson()`
- Generated files: `*.g.dart`

## ANTI-PATTERNS
- DO NOT use `as any` type casting
- DO NOT skip code generation after model changes

## COMMANDS
```bash
dart run build_runner build  # Regenerate .g.dart files
```

## NOTES
- 68 models = largest code concentration in project
- All models have `.copyWith` via Freezed