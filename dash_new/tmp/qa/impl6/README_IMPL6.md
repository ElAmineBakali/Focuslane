# Implementation 6 — QA Evidence

## Sync pulido + UI reactiva discreta (SIN pantallas nuevas, SIN hub)

### What was changed

| File | Change |
|------|--------|
| `lib/screens/study/services/study_tasks_sync_service.dart` | **BUG FIX**: `_tasksRoot` → `_tasksCol`. Path was `users/{uid}/tasks/root/items/{id}` (wrong) → `users/{uid}/tasks/{id}` (correct). All imperative study↔task syncs were silently failing. |
| `lib/core/services/core_sync_service.dart` | **DEBUG_SYNC_LOGS flag**: `kCoreSyncDebug` now uses `bool.fromEnvironment('DEBUG_SYNC_LOGS', defaultValue: kDebugMode)`. Pass `--dart-define=DEBUG_SYNC_LOGS=false` to mute or `=true` to force in release. |
| `lib/screens/food/screens/food_planner_screen.dart` | Added `debugPrint('[FoodPlanner][statusBar] ...')` logging to `_buildRealtimeStatusBar()`. |

### What was already working (confirmed by audit)

- **FoodDashboard `_buildAlerts()`** — StreamBuilder on `streamAlerts()` rendering proteinLow / extremeDeficit / overBudget cards.
- **FoodPlanner `_buildRealtimeStatusBar()`** — nested StreamBuilders for targets + alerts.
- **GymDashboard `_buildAlerts()`** — direct Firestore snapshot listeners for `config/alerts` + `alerts/subscription`.
- **Calendar** — reactive multi-source aggregation via `CalendarAggregatorService.combined()`.
- **CoreSyncService** — all 7 listeners + 6 side-effect writes fully implemented.

### Sync path verification

| Path | Write (CoreSync) | Read (Dashboard) | Status |
|------|-------------------|-------------------|--------|
| A) Finance→Food overBudget | `users/{uid}/food/root/config/alerts` | `FoodFirestoreService.streamAlerts()` | ✅ MATCH |
| B) Finance→Gym dueSoon | `users/{uid}/gym/root/alerts/subscription` | `GymDashboard subscriptionAlert$` | ✅ MATCH |
| C) Gym→Food targets | `users/{uid}/food/root/config/targets` + `/alerts` | `streamGlobalTargets()` + `streamAlerts()` | ✅ MATCH |
| D) Study↔Tasks | `users/{uid}/tasks/{id}` ↔ `users/{uid}/study/root/tasks/{id}` | `CoreSync mirror methods` | ✅ MATCH |

### QA scripts

```bash
cd tmp/qa/impl6
npm install
node check_impl6_sync.js
```

**Prerequisites:**
- Flutter web app running: `flutter run -d chrome --dart-define=CORE_SYNC_CUSTOM_TOKEN=<token>`
- `GOOGLE_APPLICATION_CREDENTIALS` env var or `backend/service-account.json` present

### Evidence files

| File | Description |
|------|-------------|
| `evidence_A_overBudget.png` | Food dashboard showing overBudget alert card |
| `evidence_B_dueSoon.png` | Gym dashboard showing "Pago próximo" alert |
| `evidence_C_gymToFood.png` | Food dashboard showing proteinLow/extremeDeficit after gym session |
| `evidence_D_studyTasks.png` | App state after study↔task mirror |
| `result_impl6.json` | JSON with pass/fail per scenario + evidence strings |
| `sync_console_logs.txt` | All `[CoreSync]` / `[FoodDashboard]` / `[GymDashboard]` console output |

### DEBUG_SYNC_LOGS usage

```bash
# Enable in release/profile:
flutter run --release --dart-define=DEBUG_SYNC_LOGS=true

# Disable in debug:
flutter run --dart-define=DEBUG_SYNC_LOGS=false

# Default: on in debug, off in release
flutter run   # logs enabled
```
