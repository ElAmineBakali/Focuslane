import 'dart:convert';

import 'package:mi_dashboard_personal/core/notifications/local/local_id_generator.dart';
import 'package:mi_dashboard_personal/core/notifications/local/local_notification_gateway.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_envelope.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_entity_ref.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_schedule.dart';

abstract class LocalScheduler {
  Future<void> initializeChannels();
  Future<void> schedule(NotificationEnvelope envelope);
  Future<void> cancelByNotificationId(String notificationId);
  Future<int> cancelByEntity(NotificationEntityRef entity);
  Future<int> cancelByModule(NotificationModule module);
  Future<List<String>> pendingNotificationIds();
}

class DefaultLocalScheduler implements LocalScheduler {
  DefaultLocalScheduler({
    required LocalNotificationGateway gateway,
    required LocalIdGenerator idGenerator,
  })  : _gateway = gateway,
        _idGenerator = idGenerator;

  final LocalNotificationGateway _gateway;
  final LocalIdGenerator _idGenerator;

  @override
  Future<void> initializeChannels() => _gateway.init();

  @override
  Future<void> schedule(NotificationEnvelope envelope) async {
    final localId = _idGenerator.generate(envelope);
    final repeatRule = _repeatFromSchedule(envelope.schedule.kind);

    if (envelope.schedule.kind == NotificationScheduleKind.immediate) {
      await _gateway.showNow(
        localId: localId,
        title: envelope.content.title,
        body: envelope.content.body,
        payload: envelope.toJson(),
        channel: envelope.delivery.channel,
      );
      return;
    }

    final whenUtc = envelope.schedule.scheduledAtUtc?.toUtc() ?? DateTime.now().toUtc();
    await _gateway.zonedSchedule(
      localId: localId,
      whenUtc: whenUtc,
      title: envelope.content.title,
      body: envelope.content.body,
      payload: envelope.toJson(),
      channel: envelope.delivery.channel,
      allowWhileIdle: true,
      repeatRule: repeatRule,
      weekdays: envelope.schedule.weekdays,
    );
  }

  LocalRepeatRule _repeatFromSchedule(NotificationScheduleKind kind) {
    switch (kind) {
      case NotificationScheduleKind.daily:
        return LocalRepeatRule.daily;
      case NotificationScheduleKind.weekly:
        return LocalRepeatRule.weekly;
      case NotificationScheduleKind.immediate:
      case NotificationScheduleKind.oneShot:
        return LocalRepeatRule.none;
    }
  }

  @override
  Future<void> cancelByNotificationId(String notificationId) async {
    final localId = _idGenerator.generateFromNotificationId(notificationId);
    await _gateway.cancel(localId);
  }

  @override
  Future<int> cancelByEntity(NotificationEntityRef entity) async {
    final pending = await _gateway.pending();
    int removed = 0;
    for (final item in pending) {
      final envelope = _tryParseEnvelope(item.payload);
      if (envelope == null) continue;
      if (envelope.entity.module == entity.module &&
          envelope.entity.kind == entity.kind &&
          envelope.entity.id == entity.id) {
        await _gateway.cancel(item.localId);
        removed++;
      }
    }
    return removed;
  }

  @override
  Future<int> cancelByModule(NotificationModule module) async {
    final pending = await _gateway.pending();
    int removed = 0;
    for (final item in pending) {
      final envelope = _tryParseEnvelope(item.payload);
      if (envelope == null) continue;
      if (envelope.module == module) {
        await _gateway.cancel(item.localId);
        removed++;
      }
    }
    return removed;
  }

  NotificationEnvelope? _tryParseEnvelope(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(rawPayload) as Map);
      if ((map['v'] as num?)?.toInt() == 1 && map['notificationId'] != null) {
        return NotificationEnvelope.fromMap(map);
      }
      final nested = map['payload'];
      if (nested is String && nested.isNotEmpty) {
        return NotificationEnvelope.fromJson(nested);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<String>> pendingNotificationIds() async {
    final pending = await _gateway.pending();
    final ids = <String>[];
    for (final item in pending) {
      final envelope = _tryParseEnvelope(item.payload);
      if (envelope != null) {
        ids.add(envelope.notificationId);
      }
    }
    return ids;
  }
}
