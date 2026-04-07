# Notifications Blueprint v1 (Implementation Plan)

## Scope
- Build a new centralized notification system.
- Reuse only low-level useful infrastructure.
- Remove duplicated notification orchestration and legacy payload formats.
- Priority now: Android local notifications done correctly.
- Keep architecture ready for future FCM + Cloud Functions.
- This document is blueprint-only, no module migration implementation yet.

## 1) Target Folder Structure

lib/
  core/
    notifications/
      notification_manager.dart
      notifications_bootstrap.dart
      notifications_facade.dart
      models/
        notification_intent.dart
        notification_envelope.dart
        notification_action.dart
        notification_schedule.dart
        notification_content.dart
        notification_entity_ref.dart
        notification_delivery.dart
        notification_registry_entry.dart
        notification_result.dart
      contracts/
        notification_gateways.dart
        notification_repository.dart
        notification_clock.dart
        notification_logger.dart
      local/
        local_notification_gateway.dart
        flutter_local_notification_gateway.dart
        local_scheduler.dart
        local_id_generator.dart
        android_channel_catalog.dart
      router/
        notification_router.dart
        route_resolver.dart
        route_intent.dart
      policies/
        notification_policy_engine.dart
        dedupe_policy.dart
        quiet_hours_policy.dart
        permission_policy.dart
      usecases/
        schedule_notification_usecase.dart
        cancel_notification_usecase.dart
        handle_notification_tap_usecase.dart
      mapping/
        intent_to_envelope_mapper.dart
      push/
        push_notification_gateway.dart
        push_dispatch_planner.dart
        device_token_repository.dart
      registry/
        notification_registry_repository.dart
        in_memory_notification_registry_repository.dart

Notes:
- push/ remains mostly stubbed for now; contracts are finalized now.
- Existing core service remains during migration bridge only.

## 2) File Responsibilities (Exact)

notification_manager.dart
- Single orchestration entrypoint for all modules.
- Applies policy engine.
- Chooses delivery strategy (local now, push-ready later).
- Writes registry lifecycle.

notifications_bootstrap.dart
- Initializes manager, gateway, scheduler, router listeners.
- Replaces ad-hoc initialization in app startup once migration reaches cutover.

notifications_facade.dart
- Slim static access point for feature modules.
- Prevents direct dependency spread of concrete manager wiring.

models/notification_intent.dart
- Domain request from modules before scheduling details are finalized.

models/notification_envelope.dart
- Canonical payload contract used for local payload and future FCM data payload.

models/notification_action.dart
- Defines notification tap action semantics (open route, open tab, custom action id).

models/notification_schedule.dart
- Defines schedule mode and timing metadata.

models/notification_content.dart
- User-visible content + optional localization keys.

models/notification_entity_ref.dart
- Stable reference to module + entity type + entity id.

models/notification_delivery.dart
- Delivery target and options (local, push, hybrid).

models/notification_registry_entry.dart
- Persisted lifecycle of one notification record.

models/notification_result.dart
- Return type for schedule/cancel operations.

contracts/notification_gateways.dart
- Interfaces for local and push gateways.

contracts/notification_repository.dart
- Interface for registry read/write and query operations.

contracts/notification_clock.dart
- Injectable clock for deterministic tests.

contracts/notification_logger.dart
- Structured logging interface.

local/local_notification_gateway.dart
- Interface wrapping plugin operations.

local/flutter_local_notification_gateway.dart
- Concrete implementation using flutter_local_notifications + timezone.

local/local_scheduler.dart
- Pure scheduling adapter. Converts schedule model to gateway calls.

local/local_id_generator.dart
- Deterministic ID generation from envelope fields.

local/android_channel_catalog.dart
- Declares all Android channel IDs, names, importance, vibration/sound policy.

router/notification_router.dart
- Single tap entrypoint for local and future push-tap.
- Parses envelope and delegates route intent.

router/route_resolver.dart
- Maps envelope action/entity to route intent.

router/route_intent.dart
- Navigation-agnostic route request object.

policies/notification_policy_engine.dart
- Runs all policies and returns allow/deny + reasons + transformed schedule.

policies/dedupe_policy.dart
- Prevents duplicate schedule by dedupeKey and time window.

policies/quiet_hours_policy.dart
- Applies local notification quiet-hours behavior.

policies/permission_policy.dart
- Blocks if notification permission is absent/disabled.

usecases/schedule_notification_usecase.dart
- Pipeline for schedule: validate -> map -> policy -> schedule -> registry.

usecases/cancel_notification_usecase.dart
- Pipeline for cancellation by notificationId/entity/dedupe.

usecases/handle_notification_tap_usecase.dart
- Pipeline for open event handling and opened-state registry update.

mapping/intent_to_envelope_mapper.dart
- Deterministic mapper from module intents to canonical envelope.

push/push_notification_gateway.dart
- Push interface contract (future). No sending in phase now.

push/push_dispatch_planner.dart
- Decides when an envelope should be mirrored to push flow (future).

device_token_repository.dart
- Contract for storing/retrieving user device tokens.

registry/notification_registry_repository.dart
- Registry persistence contract.

registry/in_memory_notification_registry_repository.dart
- Temporary implementation to support pilot before persistent store integration.

## 3) Interfaces and Method Signatures

### 3.1 NotificationManager (core)

class NotificationManager {
  Future<void> init();

  Future<NotificationResult> scheduleIntent(
    NotificationIntent intent,
  );

  Future<List<NotificationResult>> scheduleIntents(
    List<NotificationIntent> intents,
  );

  Future<NotificationResult> cancelByNotificationId(
    String notificationId,
  );

  Future<int> cancelByEntity(
    NotificationEntityRef entity,
  );

  Future<int> cancelByDedupeKey(
    String dedupeKey,
  );

  Future<int> cancelByModule(
    NotificationModule module,
  );

  Future<NotificationResult> rescheduleIntent(
    NotificationIntent intent,
  );

  Future<void> handleTapPayload(
    String rawPayload,
  );

  Stream<NotificationRegistryEntry> watchLifecycle();
}

### 3.2 Router

abstract class NotificationRouter {
  Future<void> handleTap({
    required String rawPayload,
    required NotificationTapSource source,
  });

  Future<void> handleEnvelope(NotificationEnvelope envelope);
}

abstract class RouteResolver {
  RouteIntent resolve(NotificationEnvelope envelope);
}

class RouteIntent {
  final String route;
  final Map<String, String> pathParams;
  final Map<String, String> queryParams;
  final bool replace;
}

### 3.3 Local Scheduling

abstract class LocalScheduler {
  Future<void> initializeChannels();

  Future<void> schedule(NotificationEnvelope envelope);

  Future<void> cancelByNotificationId(String notificationId);

  Future<int> cancelByEntity(NotificationEntityRef entity);

  Future<int> cancelByModule(NotificationModule module);

  Future<List<String>> pendingNotificationIds();
}

abstract class LocalNotificationGateway {
  Future<void> init();

  Future<void> showNow({
    required int localId,
    required String title,
    required String body,
    required String payload,
    required AndroidChannelKey channel,
  });

  Future<void> zonedSchedule({
    required int localId,
    required DateTime whenUtc,
    required String title,
    required String body,
    required String payload,
    required AndroidChannelKey channel,
    required bool allowWhileIdle,
    required LocalRepeatRule repeatRule,
  });

  Future<void> cancel(int localId);

  Future<List<PendingLocalNotification>> pending();
}

abstract class LocalIdGenerator {
  int generate(NotificationEnvelope envelope);
}

### 3.4 Policy and Mapping

abstract class NotificationPolicyEngine {
  Future<PolicyDecision> evaluate(NotificationEnvelope envelope);
}

class PolicyDecision {
  final bool allowed;
  final List<String> reasons;
  final NotificationEnvelope transformedEnvelope;
}

abstract class IntentToEnvelopeMapper {
  NotificationEnvelope map(NotificationIntent intent);
}

### 3.5 Registry

abstract class NotificationRegistryRepository {
  Future<void> upsert(NotificationRegistryEntry entry);

  Future<NotificationRegistryEntry?> findByNotificationId(String notificationId);

  Future<List<NotificationRegistryEntry>> findByEntity(NotificationEntityRef entity);

  Future<List<NotificationRegistryEntry>> findByDedupeKey(String dedupeKey);

  Future<void> markOpened({
    required String notificationId,
    required DateTime openedAtUtc,
  });

  Stream<NotificationRegistryEntry> watchLifecycle();
}

### 3.6 Push-ready Contracts (Not implemented now)

abstract class PushNotificationGateway {
  Future<void> enqueue(NotificationEnvelope envelope);
}

abstract class DeviceTokenRepository {
  Future<void> upsertToken({
    required String userId,
    required String deviceId,
    required String token,
    required String platform,
    required String appVersion,
    required String timezone,
    required DateTime updatedAtUtc,
  });

  Future<void> revokeToken({
    required String userId,
    required String deviceId,
  });
}

## 4) NotificationEnvelope v1 (Final Contract)

All local payloads and future push data payloads MUST use this exact JSON schema.

{
  "v": 1,
  "notificationId": "ntf_01J...",
  "dedupeKey": "tasks:task_123:due_30m",
  "module": "tasks",
  "type": "TASK_DUE_SOON",
  "entity": {
    "kind": "task",
    "id": "task_123"
  },
  "content": {
    "title": "Task due soon",
    "body": "Project submission in 30 minutes"
  },
  "action": {
    "kind": "OPEN_ROUTE",
    "route": "/tasks/detail",
    "params": {
      "taskId": "task_123"
    }
  },
  "schedule": {
    "kind": "ONE_SHOT",
    "scheduledAtUtc": "2026-04-07T20:30:00Z",
    "timezone": "America/Bogota"
  },
  "delivery": {
    "kind": "LOCAL_ONLY",
    "channel": "tasks_reminders",
    "priority": "high",
    "ttlSeconds": 86400
  },
  "meta": {
    "userId": "uid_abc",
    "source": "tasks.create_or_update",
    "createdAtUtc": "2026-04-07T20:00:00Z",
    "traceId": "trace_01J..."
  }
}

Rules:
- Required keys: v, notificationId, dedupeKey, module, type, entity, content, action, schedule, delivery, meta.
- v fixed to 1 for this phase.
- notificationId globally unique string, never int/hashCode.
- dedupeKey deterministic per business case.
- scheduledAtUtc always UTC ISO-8601.
- timezone always IANA string.
- route must be canonical app route, no ad-hoc payload tokens.
- No legacy payload wrappers and no mixed shapes.

## 5) Migration Strategy by Phases

Phase 0 - Foundations
- Create all new core/notifications files and contracts.
- Implement bootstrap wiring only for the new manager and local gateway behind feature flag.
- Keep legacy system operational in parallel, no module migrated yet.

Acceptance:
- App boots with new manager initialized.
- No behavior change in modules still on legacy.
- New manager can parse and route test envelope in isolation.

Phase 1 - Tasks Pilot
- Replace all scheduling/cancel points in tasks to call NotificationManager.
- Use NotificationIntent for task reminder and due-date cases.
- Remove tasks payload legacy strings.

Acceptance:
- Create/edit/delete task reminders schedule/cancel correctly.
- Tap opens correct task detail screen through NotificationRouter.
- No duplicate notifications for same dedupeKey.
- Registry shows created -> scheduled -> opened/cancelled transitions.

Phase 2 - Calendar Planner
- Migrate planner scheduling to manager.
- Standardize planner payload/action mapping to route intents.

Acceptance:
- Planner reminders trigger at expected times with correct timezone.
- Tap opens calendar target context accurately.

Phase 3 - Finance Subscriptions
- Migrate subscription reminder scheduling/cancel logic.
- Normalize recurrence policies through schedule model.

Acceptance:
- Subscription reminders are deterministic and cancel cleanly on update/delete.

Phase 4 - Study
- Migrate class/task/session reminders to manager intents.
- Remove fixed-offset hidden logic from module services into explicit policy config.

Acceptance:
- Study reminders respect configured advance values and route correctly.

Phase 5 - Food
- Migrate daily and advanced trigger reminders from food settings.
- Ensure all trigger kinds map into schedule model.

Acceptance:
- Daily and non-daily supported triggers schedule correctly.
- Tap action routes to expected food screen context.

Phase 6 - Gym
- Migrate inactivity, routine, and measurement reminders.
- Remove screen-embedded scheduling calls.

Acceptance:
- No notification scheduling code remains in gym UI widgets/screens.
- All gym reminders pass through manager.

Phase 7 - Habits
- Migrate habits reminders and toggle behaviors.
- Remove direct calls to old core notification APIs.

Acceptance:
- Habit reminder on/off and time changes are reflected reliably.

Phase 8 - Legacy Cutover and Cleanup
- Remove legacy listeners/payload handling and duplicate services.
- Remove bridge layer feature flag.

Acceptance:
- All modules operate exclusively on manager + envelope v1.
- No references to deprecated services remain.

## 6) Legacy Services to Deprecate and Remove

Deprecate first (bridge period), then delete:
- screens/tasks/services/reminder_service.dart
- screens/gym/services/gym_notification_service.dart
- screens/study/services/study_notifications.dart
- screens/food/screens/food_settings_notifications_screen.dart (embedded scheduler section only)
- screens/gym/gym_home_screen.dart (embedded scheduling blocks only)
- screens/gym/widgets/rest_timer.dart (embedded scheduling blocks only)
- screens/gym/session/live_session_screen.dart (direct notification scheduling calls only)
- core/services/notification_service.dart (after full cutover)
- main.dart payload listener branch that parses legacy payload tokens

Deprecate payload formats:
- OPEN_* string payloads
- route-only payload strings like /tasks/{id}
- custom delimited payloads like GYM_ROUTINE|...
- mixed wrapped payload json where payload is nested string

## 7) Acceptance Criteria per Cross-Cutting Capability

Scheduling correctness
- All scheduled times use UTC + IANA timezone.
- No hashCode-based IDs in scheduling path.
- Repeat rules deterministic after app restart.

Routing correctness
- Every delivered notification opens expected screen via router.
- No module-specific tap parsing outside NotificationRouter.

Deduplication
- Same dedupeKey in active window does not create duplicates.
- Reschedule updates existing notification identity predictably.

Observability
- Registry lifecycle is queryable for each notification.
- Failures include reason codes (permission_denied, schedule_invalid, duplicate, unknown).

Isolation
- Modules only emit NotificationIntent.
- Modules never call plugin/gateway directly.

Android quality gate (current priority)
- Channels created exactly once.
- Permission states respected.
- Background/terminated tap handling remains consistent.

## 8) Push and Cloud Functions Preparedness (Future)

Data model now
- users/{uid}/devices/{deviceId}
  - token, platform, timezone, appVersion, notificationsEnabled, updatedAtUtc, lastSeenAtUtc

Future flow
- App emits envelope intent to manager.
- Manager schedules local now and optionally enqueues push dispatch plan.
- Backend/Cloud Function consumes envelope.
- FCM data payload carries envelope v1 unchanged.
- Tap still handled by same NotificationRouter path.

Cutover principle
- Local and push must share envelope parser and route resolver.
- Push introduction must not require module-level changes.

## 9) Definition of Done for Blueprint Completion

- File/folder target structure approved.
- Interfaces and signatures approved.
- NotificationEnvelope v1 approved and frozen.
- Migration phase order approved.
- Legacy deprecation list approved.
- Acceptance criteria approved.

After approval, implementation starts from Phase 0 and Phase 1 (Tasks pilot).
