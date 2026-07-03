# RenewWise V1 — Project Health Report (Packet A)

Generated after Assistant Foundation architecture refactoring.

## Summary

| Metric | Count |
|--------|------:|
| Dart files (`lib/`) | 205 |
| Dart files (`test/`) | 4 |
| Asset files (`assets/`) | 19 |
| Production dependencies | 25 |
| Dev dependencies | 2 |

## Repository Structure

```
lib/
├── database/          1 file   SQLite schema (renewals only)
├── models/           27 files  Domain + analytics DTOs
├── repository/       15 files  Persistence boundaries (NEW in Packet A)
├── services/         22 files  Business logic + platform integration
├── screens/          37 files  UI routes
├── widgets/          53 files  Reusable UI
├── utils/            45 files  Engines, filters, helpers
├── theme/             4 files  Design system
└── main.dart          1 file   App bootstrap
```

## Largest Source Folders

1. **widgets/** — 53 files (presentation)
2. **utils/** — 45 files (pure logic engines)
3. **screens/** — 37 files (navigation destinations)
4. **models/** — 27 files
5. **services/** — 22 files

## Architecture Improvements (Packet A)

### Repository layer

| Repository | Implementation | Backed by |
|------------|----------------|-----------|
| `ReminderRepository` | `SqliteRenewalRepository`, `InMemoryRenewalRepository` | SQLite `renewals` |
| `RenewalRepository` | extends `ReminderRepository` (backward compatible) | Same |
| `ExpenseRepository` | `SharedPreferencesExpenseRepository` | `expense_records_v1` |
| `GoalPlannerRepository` | `SharedPreferencesGoalPlannerRepository` | `goal_planner_settings_v1` |
| `VaultRepository` | `SharedPreferencesVaultRepository` | `vault_documents_v2` |
| `HistoryRepository` | `SharedPreferencesHistoryRepository` | `reminder_history_v1` |
| `SettingsRepository` | `SharedPreferencesSettingsRepository` | Generic prefs wrapper (ready for V2) |

Services now delegate persistence to repositories. Widgets continue to use services only — no direct database or SharedPreferences access from UI.

### Model standardization

Added `RenewWiseEntityMetadata` / `RenewWiseRecordMeta` with backward-compatible optional fields:

- `ExpenseRecord` — `updatedAt`, `subCategory`, `version`
- `HistoryEntry` — `createdAt`, `updatedAt`, `subCategory`, `version`
- `EventDocument` — `updatedAt`, `version`; `createdAt`/`subCategory` accessors
- `GoalPlannerSettings` — `version`

Existing persisted JSON loads unchanged; new fields are omitted on save unless non-default.

### RenewWise Assistant foundation

`RenewWiseAssistantService` (no UI) attached at startup via `RenewWiseAssistantService.attach()`:

- `getReminders()`, `getExpenses()`, `getGoals()`, `getDocuments()`, `getHistory()`, `getInsights()`
- `answerQuestion()` — placeholder response only

### Stability guarantees

- No SQLite schema changes (still v4, single `renewals` table)
- No SharedPreferences key changes
- No UI, UX, navigation, notification, or reminder behaviour changes

## Remaining Technical Debt

1. **SettingsService** still reads/writes SharedPreferences directly (~680 lines). `SettingsRepository` exists but is not yet wired in — deferred for stability.
2. **Reminder state** (missed/snoozed metadata) still persisted inside `ReminderStateService`, not a dedicated repository.
3. **Event activity log** (vault activity) still persisted inside `EventExtrasService`.
4. **GoalPlannerService** instantiated both in `main.dart` (assistant) and in Smart Insights screens — duplicate instances share the same prefs key but separate in-memory caches.
5. **Business logic in widgets** — `goal_planner_card.dart` and `expense_tracking_section.dart` still contain orchestration logic; engines exist in `utils/` but full extraction deferred.
6. **No dependency injection framework** — manual constructor wiring in `main.dart`.
7. **Model metadata incomplete** on `Renewal` (no `subCategory`/`version` fields yet — already has id/createdAt/updatedAt/category).

## Recommendations Before Version 2

1. Wire `SettingsService` through `SettingsRepository` in a dedicated pass with regression tests.
2. Unify `GoalPlannerService` as a single app-scoped instance (like `ExpenseService`).
3. Add `ReminderStateRepository` for reminder metadata persistence.
4. Introduce an assistant context layer that composes read models from repositories (avoid passing six services).
5. Add unit tests for each repository implementation (in-memory fakes for CI).
6. Plan offline AI with a local index built from repository read APIs — do not query SharedPreferences/SQLite from assistant code directly.
7. Consider `get_it` or Riverpod for service location before voice commands add more wiring complexity.

## Restore Point

Git commit before Packet A changes:

```
Backup before Assistant Foundation Refactoring (e176a5c)
```
