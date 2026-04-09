import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';

class NotificationIntent {
  const NotificationIntent({
    required this.module,
    required this.type,
    required this.entity,
    required this.content,
    required this.action,
    required this.schedule,
    required this.delivery,
    required this.dedupeKey,
    required this.userId,
    required this.source,
    this.traceId,
    this.notificationId,
  });

  final NotificationModule module;
  final String type;
  final NotificationEntityRef entity;
  final NotificationContent content;
  final NotificationAction action;
  final NotificationSchedule schedule;
  final NotificationDelivery delivery;
  final String dedupeKey;
  final String userId;
  final String source;
  final String? traceId;
  final String? notificationId;
}

