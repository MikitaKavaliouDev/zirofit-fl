# lib/core/database

**Parent:** Root AGENTS.md covers core infrastructure overview.

## OVERVIEW
Drift SQLite database layer. 22 Dart files defining tables, DAOs, and migrations.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Table definitions | `tables/` | User, Client, Workout, etc. |
| Migrations | `migrations/` | Schema versioning |
| Database class | `app_database.dart` | Main entry point |

## CONVENTIONS
- Tables extend `DriftTable` with `@DataClassName` annotation
- DAOs use `@DriftAccessor` with `@UseDao` annotation
- migrations/ contains versioned schema changes

## ANTI-PATTERNS
- DO NOT write raw SQL in repositories - use generated DAOs
- DO NOT skip migration files when adding tables

## NOTES
- Run `dart run build_runner build` after table changes
- Generated code goes to `app_database.g.dart`