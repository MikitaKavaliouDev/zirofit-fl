# lib/features/clients

**Parent:** Root AGENTS.md covers features overview.

## OVERVIEW
Client management for trainers. 18 Dart files for client CRUD and tracking.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Client list | `screens/client_list_screen.dart` | Trainer's clients |
| Client detail | `screens/client_detail_screen.dart` | Full profile view |
| Measurements | `screens/measurements_screen.dart` | Body metrics |
| History | `screens/client_history_screen.dart` | Workout history |
| Invite | `screens/invite_client_screen.dart` | Client onboarding |

## CONVENTIONS
- Provider per domain: `clientListProvider`, `clientDetailProvider`, `measurementProvider`
- Role-gated: only trainers access client management

## UNIQUE STYLES
- Measurement tracking with history charts
- Assessment templates per client
- Program assignment to clients
- Client invite via email/phone

## ANTI-PATTERNS
- DO NOT allow clients to access other client data
- DO NOT skip permission checks in client detail routes