import 'dart:convert';

import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';

class NotificationEnvelope {
  const NotificationEnvelope({
    required this.v,
    required this.notificationId,
    required this.dedupeKey,
    required this.module,
    required this.type,
    required this.entity,
    required this.content,
    required this.action,
    required this.schedule,
    required this.delivery,
    required this.userId,
    required this.source,
    required this.createdAtUtc,
    required this.traceId,
  });

  final int v;
  final String notificationId;
  final String dedupeKey;
  final NotificationModule module;
  final String type;
  final NotificationEntityRef entity;
  final NotificationContent content;
  final NotificationAction action;
  final NotificationSchedule schedule;
  final NotificationDelivery delivery;
  final String userId;
  final String source;
  final DateTime createdAtUtc;
  final String traceId;

  Map<String, dynamic> toMap() => {
    'v': v,
    'notificationId': notificationId,
    'dedupeKey': dedupeKey,
    'module': module.name,
    'type': type,
    'entity': entity.toMap(),
    'content': content.toMap(),
    'action': action.toMap(),
    'schedule': schedule.toMap(),
    'delivery': delivery.toMap(),
    'meta': {
      'userId': userId,
      'source': source,
      'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
      'traceId': traceId,
    },
  };

  String toJson() => jsonEncode(toMap());

  factory NotificationEnvelope.fromMap(Map<String, dynamic> map) {
    final meta = (map['meta'] is Map)
        ? Map<String, dynamic>.from(map['meta'] as Map)
        : const <String, dynamic>{};

    return NotificationEnvelope(
      v: (map['v'] as num?)?.toInt() ?? 1,
      notificationId: (map['notificationId'] ?? '').toString(),
      dedupeKey: (map['dedupeKey'] ?? '').toString(),
      module: NotificationModule.values.firstWhere(
        (m) => m.name == (map['module'] ?? 'system'),
        orElse: () => NotificationModule.system,
      ),
      type: (map['type'] ?? '').toString(),
      entity: NotificationEntityRef.fromMap(
        Map<String, dynamic>.from(map['entity'] as Map? ?? const {}),
      ),
      content: NotificationContent.fromMap(
        Map<String, dynamic>.from(map['content'] as Map? ?? const {}),
      ),
      action: NotificationAction.fromMap(
        Map<String, dynamic>.from(map['action'] as Map? ?? const {}),
      ),
      schedule: NotificationSchedule.fromMap(
        Map<String, dynamic>.from(map['schedule'] as Map? ?? const {}),
      ),
      delivery: NotificationDelivery.fromMap(
        Map<String, dynamic>.from(map['delivery'] as Map? ?? const {}),
      ),
      userId: (meta['userId'] ?? '').toString(),
      source: (meta['source'] ?? '').toString(),
      createdAtUtc: DateTime.tryParse((meta['createdAtUtc'] ?? '').toString())?.toUtc() ??
          DateTime.now().toUtc(),
      traceId: (meta['traceId'] ?? '').toString(),
    );
  }

  factory NotificationEnvelope.fromJson(String json) {
    return NotificationEnvelope.fromMap(
      Map<String, dynamic>.from(jsonDecode(json) as Map),
    );
  }
}

