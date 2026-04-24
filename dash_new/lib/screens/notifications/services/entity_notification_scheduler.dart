import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:focuslane/screens/notifications/models/entity_notification_config.dart';

class EntityNotificationScheduler {
  EntityNotificationScheduler._();
  static final EntityNotificationScheduler I = EntityNotificationScheduler._();

  String get _uid => fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';

  Future<void> apply({
    required EntityNotificationConfig config,
    required String title,
    required String body,
    required String route,
    DateTime? referenceAtLocal,
  }) async {
    final entity = NotificationEntityRef(
      module: config.module,
      kind: config.entityKind,
      id: config.entityId,
    );

    await NotificationsFacade.I.cancelByEntity(entity);

    if (!config.enabled) {
      return;
    }

    DateTime? whenLocal;
    if (config.scheduleMode == EntityNotificationScheduleMode.absolute) {
      whenLocal = config.absoluteAtUtc?.toLocal();
    } else {
      final ref = referenceAtLocal;
      final minutes = config.minutesBefore;
      if (ref == null || minutes == null || minutes < 0) {
        return;
      }
      whenLocal = ref.subtract(Duration(minutes: minutes));
    }

    if (whenLocal == null) {
      return;
    }

    final now = DateTime.now();
    if (!whenLocal.isAfter(now.add(const Duration(seconds: 3)))) {
      return;
    }

    final whenUtc = whenLocal.toUtc();
    final epoch = whenUtc.millisecondsSinceEpoch;

    await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: config.module,
        type: config.notificationType,
        entity: entity,
        content: NotificationContent(title: title, body: body),
        action: NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: route,
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.oneShot,
          scheduledAtUtc: whenUtc,
          timezone: whenLocal.timeZoneName,
        ),
        delivery: NotificationDelivery(
          kind: NotificationDeliveryKind.localOnly,
          channel: _channelFor(config.module),
          priority: NotificationPriority.high,
        ),
        dedupeKey:
            'custom:${config.module.name}:${config.entityKind}:${config.entityId}:${config.notificationType}:$epoch',
        userId: _uid,
        source: 'notifications.global_customization',
        notificationId:
            'ntf_custom_${config.module.name}_${config.entityKind}_${config.entityId}_$epoch',
      ),
    );
  }

  Future<void> cancel(EntityNotificationConfig config) {
    return NotificationsFacade.I.cancelByEntity(
      NotificationEntityRef(
        module: config.module,
        kind: config.entityKind,
        id: config.entityId,
      ),
    );
  }

  String _channelFor(NotificationModule module) {
    switch (module) {
      case NotificationModule.tasks:
        return AndroidChannelCatalog.tasksReminders;
      case NotificationModule.study:
        return AndroidChannelCatalog.studyReminders;
      case NotificationModule.calendar:
        return AndroidChannelCatalog.calendarReminders;
      case NotificationModule.finance:
        return AndroidChannelCatalog.financeReminders;
      case NotificationModule.food:
        return AndroidChannelCatalog.foodReminders;
      case NotificationModule.gym:
        return AndroidChannelCatalog.gymReminders;
      case NotificationModule.habits:
        return AndroidChannelCatalog.habitsReminders;
      case NotificationModule.notes:
        return AndroidChannelCatalog.defaultChannel;
      case NotificationModule.system:
        return AndroidChannelCatalog.defaultChannel;
    }
  }
}
