# PROJECT KNOWLEDGE BASE

**Generated:** 2026-05-10
**Commit:** 3dfff96
**Branch:** main

## OVERVIEW
Ziro Fit - Flutter mobile app for fitness business management. Offline-first with Supabase auth, Drift local DB, Riverpod state, GoRouter navigation.

## STRUCTURE
```
lib/
├── core/           # Infrastructure: network, DB, router, theme, utils
├── data/           # Data layer: models (68), sync engine
├── domain/         # Business logic: repository interfaces
├── features/       # 27 feature modules (UI + providers)
└── shared/        # Reusable widgets, extensions
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Auth flow | `features/auth/` | Supabase + secure storage |
| Workout tracking | `features/workout/` | 23 files, active/summary/history |
| Client management | `features/clients/` | 18 files, detail/list/measurements |
| Progress analytics | `features/progress/` | 24 files, charts/widgets |
| Trainer profile | `features/trainer/` | 19 files, branding/settings |
| Local database | `core/database/` | Drift tables, migrations |
| API client | `core/network/` | Dio with interceptors |
| Sync engine | `data/sync/` | Offline queue, conflict resolution |

## CONVENTIONS
- **State management**: Riverpod with `@riverpod` annotation + code generation
- **Navigation**: GoRouter with ShellRoute for role-based navigation
- **Data models**: Freezed immutable classes with `json_serializable`
- **Linting**: `flutter_lints` (NOT `very_good_analysis` despite docs)
- **Testing**: mocktail for mocking, pattern: `*_test.dart`

## ANTI-PATTERNS (THIS PROJECT)
- DO NOT use `very_good_analysis` - config uses `flutter_lints` only
- DO NOT skip code generation - all providers/models need `.g.dart` files
- DO NOT use manual state management - always use Riverpod providers
- DO NOT bypass sync queue for offline mutations

## UNIQUE STYLES
- **Role-based shells**: TrainerShell, ClientShell with separate bottom nav
- **Offline-first**: Local Drift DB + sync queue for pending mutations
- **Voice features**: Voice input/feedback in workout (TTS, speech-to-text)
- **Live Activities**: iOS live activity for active workout tracking

## COMMANDS
```bash
flutter pub get          # Install dependencies
flutter build apk        # Build Android
flutter analyze         # Run linter
flutter test            # Run tests
dart run build_runner build  # Generate .g.dart files
```

## NOTES
- Run `build_runner` after any provider/model changes
- Sync engine handles offline mutations automatically
- Role guards in router redirect based on user role