import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'study_firestore_service.dart';

class StudyNotifications {
  final StudyFirestoreService svc;
  StudyNotifications(this.svc);

  String get _uid => fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';

  Future<void> scheduleTodayClasses() async {
    final now = DateTime.now();
    final weekday = now.weekday;
    final blocks = await svc.streamSchedule().first;
    for (final b in blocks) {
      if (!b.daysOfWeek.contains(weekday)) continue;
      final startToday = DateTime(
        now.year,
        now.month,
        now.day,
        b.start.hour,
        b.start.minute,
      );
      final when = startToday.subtract(const Duration(minutes: 15));
      if (when.isAfter(now)) {
        final key = '${b.courseId}-${b.start.hour}:${b.start.minute}';
        final epoch = when.toUtc().millisecondsSinceEpoch;
        final entity = NotificationEntityRef(
          module: NotificationModule.study,
          kind: 'class_block',
          id: key,
        );
        await NotificationsFacade.I.cancelByEntity(entity);
        await NotificationsFacade.I.scheduleIntent(
          NotificationIntent(
            module: NotificationModule.study,
            type: 'CLASS_STARTING_SOON',
            entity: entity,
            content: NotificationContent(
              title: 'Clase próxima',
              body:
                  'Clase de ${b.courseId} en 15 minutos${b.room != null ? ' (${b.room})' : ''}',
            ),
            action: const NotificationAction(
              kind: NotificationActionKind.openRoute,
              route: '/study',
            ),
            schedule: NotificationSchedule(
              kind: NotificationScheduleKind.oneShot,
              scheduledAtUtc: when.toUtc(),
              timezone: when.timeZoneName,
            ),
            delivery: const NotificationDelivery(
              kind: NotificationDeliveryKind.pushOnly,
              channel: AndroidChannelCatalog.studyReminders,
              priority: NotificationPriority.normal,
            ),
            dedupeKey: 'study:class:$key:$epoch',
            userId: _uid,
            source: 'study.schedule_today_classes',
            notificationId: 'ntf_study_class_${key}_$epoch',
          ),
        );
      }
    }
  }

  Future<void> scheduleDueTasks() async {
    final tasks = await svc.streamTasks().first;
    for (final t in tasks) {
      if (t.due == null) continue;
      final due = DateTime(t.due!.year, t.due!.month, t.due!.day);
      final oneDayBefore = due.subtract(const Duration(days: 1));
      final sameDay = DateTime(due.year, due.month, due.day, 8, 0);
      final entity = NotificationEntityRef(
        module: NotificationModule.study,
        kind: 'study_task',
        id: t.id,
      );
      await NotificationsFacade.I.cancelByEntity(entity);

      if (oneDayBefore.isAfter(DateTime.now())) {
        final epoch = oneDayBefore.toUtc().millisecondsSinceEpoch;
        await NotificationsFacade.I.scheduleIntent(
          NotificationIntent(
            module: NotificationModule.study,
            type: 'TASK_DUE_TOMORROW',
            entity: entity,
            content: NotificationContent(
              title: 'Tarea próxima',
              body: 'Entrega de ${t.title} mañana',
            ),
            action: const NotificationAction(
              kind: NotificationActionKind.openRoute,
              route: '/study',
            ),
            schedule: NotificationSchedule(
              kind: NotificationScheduleKind.oneShot,
              scheduledAtUtc: oneDayBefore.toUtc(),
              timezone: oneDayBefore.timeZoneName,
            ),
            delivery: const NotificationDelivery(
              kind: NotificationDeliveryKind.pushOnly,
              channel: AndroidChannelCatalog.studyReminders,
              priority: NotificationPriority.normal,
            ),
            dedupeKey: 'study:task:${t.id}:day_before:$epoch',
            userId: _uid,
            source: 'study.schedule_due_tasks',
            notificationId: 'ntf_study_task_day_before_${t.id}_$epoch',
          ),
        );
      }
      if (sameDay.isAfter(DateTime.now())) {
        final epoch = sameDay.toUtc().millisecondsSinceEpoch;
        await NotificationsFacade.I.scheduleIntent(
          NotificationIntent(
            module: NotificationModule.study,
            type: 'TASK_DUE_TODAY',
            entity: entity,
            content: NotificationContent(
              title: 'Entrega hoy',
              body: 'Hoy vence ${t.title}',
            ),
            action: const NotificationAction(
              kind: NotificationActionKind.openRoute,
              route: '/study',
            ),
            schedule: NotificationSchedule(
              kind: NotificationScheduleKind.oneShot,
              scheduledAtUtc: sameDay.toUtc(),
              timezone: sameDay.timeZoneName,
            ),
            delivery: const NotificationDelivery(
              kind: NotificationDeliveryKind.pushOnly,
              channel: AndroidChannelCatalog.studyReminders,
              priority: NotificationPriority.normal,
            ),
            dedupeKey: 'study:task:${t.id}:same_day:$epoch',
            userId: _uid,
            source: 'study.schedule_due_tasks',
            notificationId: 'ntf_study_task_same_day_${t.id}_$epoch',
          ),
        );
      }
    }
  }

  Future<void> scheduleAll({bool classes = true, bool tasks = true}) async {
    if (classes) {
      await scheduleTodayClasses();
    }
    if (tasks) {
      await scheduleDueTasks();
    }
  }
}



