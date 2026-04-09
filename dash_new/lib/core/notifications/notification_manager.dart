import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:focuslane/core/notifications/contracts/notification_clock.dart';
import 'package:focuslane/core/notifications/contracts/notification_logger.dart';
import 'package:focuslane/core/notifications/contracts/notification_repository.dart';
import 'package:focuslane/core/notifications/local/local_scheduler.dart';
import 'package:focuslane/core/notifications/mapping/intent_to_envelope_mapper.dart';
import 'package:focuslane/core/notifications/models/notification_envelope.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_registry_entry.dart';
import 'package:focuslane/core/notifications/models/notification_result.dart';
import 'package:focuslane/core/notifications/policies/dedupe_policy.dart';
import 'package:focuslane/core/notifications/policies/notification_policy_engine.dart';
import 'package:focuslane/core/notifications/router/notification_router.dart';

class NotificationManager {
  NotificationManager({
    required LocalScheduler localScheduler,
    required NotificationRegistryRepository registry,
    required NotificationPolicyEngine policyEngine,
    required DedupePolicy dedupePolicy,
    required IntentToEnvelopeMapper mapper,
    required NotificationRouter router,
    required NotificationClock clock,
    required NotificationLogger logger,
  })  : _localScheduler = localScheduler,
        _registry = registry,
        _policyEngine = policyEngine,
        _dedupePolicy = dedupePolicy,
        _mapper = mapper,
        _router = router,
        _clock = clock,
        _logger = logger;

  final LocalScheduler _localScheduler;
  final NotificationRegistryRepository _registry;
  final NotificationPolicyEngine _policyEngine;
  final DedupePolicy _dedupePolicy;
  final IntentToEnvelopeMapper _mapper;
  final NotificationRouter _router;
  final NotificationClock _clock;
  final NotificationLogger _logger;

  Future<void> init() async {
    await _localScheduler.initializeChannels();
  }

  Future<NotificationResult> scheduleIntent(NotificationIntent intent) async {
    final envelope = _mapper.map(intent);

    if (await _dedupePolicy.isDuplicate(envelope)) {
      await _registry.upsert(
        NotificationRegistryEntry(
          notificationId: envelope.notificationId,
          dedupeKey: envelope.dedupeKey,
          status: NotificationLifecycleStatus.skippedDuplicate,
          updatedAtUtc: _clock.nowUtc(),
          envelope: envelope,
          reason: 'duplicate_dedupe_key',
        ),
      );
      return NotificationResult.failure(
        envelope.notificationId,
        code: 'duplicate',
        message: 'Duplicate dedupeKey',
      );
    }

    final policy = await _policyEngine.evaluate(envelope);
    if (!policy.allowed) {
      await _registry.upsert(
        NotificationRegistryEntry(
          notificationId: envelope.notificationId,
          dedupeKey: envelope.dedupeKey,
          status: NotificationLifecycleStatus.failed,
          updatedAtUtc: _clock.nowUtc(),
          envelope: envelope,
          reason: policy.reasons.join(','),
        ),
      );
      return NotificationResult.failure(
        envelope.notificationId,
        code: 'policy_denied',
        message: policy.reasons.join(','),
      );
    }

    await _registry.upsert(
      NotificationRegistryEntry(
        notificationId: envelope.notificationId,
        dedupeKey: envelope.dedupeKey,
        status: NotificationLifecycleStatus.created,
        updatedAtUtc: _clock.nowUtc(),
        envelope: envelope,
      ),
    );

    await _localScheduler.schedule(policy.transformedEnvelope);

    await _registry.upsert(
      NotificationRegistryEntry(
        notificationId: envelope.notificationId,
        dedupeKey: envelope.dedupeKey,
        status: NotificationLifecycleStatus.scheduled,
        updatedAtUtc: _clock.nowUtc(),
        envelope: policy.transformedEnvelope,
      ),
    );

    _logger.info(
      'Scheduled notification',
      data: {'notificationId': envelope.notificationId, 'module': envelope.module.name},
    );

    return NotificationResult.success(envelope.notificationId);
  }

  Future<List<NotificationResult>> scheduleIntents(List<NotificationIntent> intents) async {
    final results = <NotificationResult>[];
    for (final intent in intents) {
      results.add(await scheduleIntent(intent));
    }
    return results;
  }

  Future<NotificationResult> cancelByNotificationId(String notificationId) async {
    await _localScheduler.cancelByNotificationId(notificationId);
    final entry = await _registry.findByNotificationId(notificationId);
    if (entry != null) {
      await _registry.upsert(
        NotificationRegistryEntry(
          notificationId: entry.notificationId,
          dedupeKey: entry.dedupeKey,
          status: NotificationLifecycleStatus.cancelled,
          updatedAtUtc: _clock.nowUtc(),
          envelope: entry.envelope,
        ),
      );
    }
    return NotificationResult.success(notificationId);
  }

  Future<int> cancelByEntity(NotificationEntityRef entity) async {
    final removed = await _localScheduler.cancelByEntity(entity);
    final entries = await _registry.findByEntity(entity);
    for (final entry in entries) {
      await _registry.upsert(
        NotificationRegistryEntry(
          notificationId: entry.notificationId,
          dedupeKey: entry.dedupeKey,
          status: NotificationLifecycleStatus.cancelled,
          updatedAtUtc: _clock.nowUtc(),
          envelope: entry.envelope,
        ),
      );
    }
    return removed;
  }

  Future<int> cancelByDedupeKey(String dedupeKey) async {
    final entries = await _registry.findByDedupeKey(dedupeKey);
    for (final entry in entries) {
      await cancelByNotificationId(entry.notificationId);
    }
    return entries.length;
  }

  Future<int> cancelByDedupePrefix(String dedupePrefix) async {
    final entries = await _registry.findByDedupePrefix(dedupePrefix);
    for (final entry in entries) {
      await cancelByNotificationId(entry.notificationId);
    }
    return entries.length;
  }

  Future<int> cancelByModule(NotificationModule module) {
    return _localScheduler.cancelByModule(module);
  }

  Future<NotificationResult> rescheduleIntent(NotificationIntent intent) async {
    final envelope = _mapper.map(intent);
    await cancelByDedupeKey(envelope.dedupeKey);
    return scheduleIntent(intent);
  }

  Future<void> handleTapPayload(String rawPayload) async {
    await _router.handleTap(rawPayload: rawPayload, source: NotificationTapSource.local);
    try {
      final map = Map<String, dynamic>.from(jsonDecode(rawPayload) as Map);
      NotificationEnvelope? envelope;
      if ((map['v'] as num?)?.toInt() == 1 && map['notificationId'] != null) {
        envelope = NotificationEnvelope.fromMap(map);
      } else {
        final nested = map['payload'];
        if (nested is String && nested.isNotEmpty) {
          envelope = NotificationEnvelope.fromJson(nested);
        }
      }
      if (envelope == null) {
        return;
      }
      await _registry.markOpened(
        notificationId: envelope.notificationId,
        openedAtUtc: _clock.nowUtc(),
      );
    } catch (_) {}
  }

  Stream<NotificationRegistryEntry> watchLifecycle() => _registry.watchLifecycle();

  void attachNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _router.attachNavigatorKey(navigatorKey);
  }
}

