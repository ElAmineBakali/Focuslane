import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:focuslane/screens/tasks/models/task_model.dart';

class ReminderService {
  ReminderService._();
  static final ReminderService I = ReminderService._();

  Future<void> scheduleTaskReminder(
    Task task, {
    Task? previous,
    bool globalEnabled = true,
    bool tasksEnabled = true,
  }) async {
    final entity = NotificationEntityRef(
      module: NotificationModule.tasks,
      kind: 'task',
      id: task.id,
    );

    if (!globalEnabled || !tasksEnabled || task.completed != false) {
      await NotificationsFacade.I.cancelByEntity(entity);
      return;
    }

    final target = task.remindAt;

    if (target == null || target.isBefore(DateTime.now())) {
      await NotificationsFacade.I.cancelByEntity(entity);
      return;
    }

    final prevTarget = _extractTaskPrevTarget(previous);
    final changed = prevTarget == null || prevTarget != target;
    if (changed) {
      await NotificationsFacade.I.cancelByEntity(entity);

      final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';
      final epoch = target.toUtc().millisecondsSinceEpoch;
      final intent = NotificationIntent(
        module: NotificationModule.tasks,
        type: 'TASK_REMINDER',
        entity: entity,
        content: NotificationContent(
          title: task.title.isEmpty ? 'Tarea' : task.title,
          body: 'Revisa esta tarea pendiente',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/tasks',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.oneShot,
          scheduledAtUtc: target.toUtc(),
          timezone: target.timeZoneName,
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.pushOnly,
          channel: AndroidChannelCatalog.tasksReminders,
          priority: NotificationPriority.high,
        ),
        dedupeKey: 'tasks:${task.id}:$epoch',
        userId: uid,
        source: 'tasks.reminder_service',
        notificationId: 'ntf_tasks_${task.id}_$epoch',
      );
      await NotificationsFacade.I.scheduleIntent(intent);
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await NotificationsFacade.I.cancelByEntity(
      NotificationEntityRef(
        module: NotificationModule.tasks,
        kind: 'task',
        id: taskId,
      ),
    );
  }

  DateTime? _extractTaskPrevTarget(Task? t) {
    if (t == null) return null;
    return t.remindAt;
  }
  Future<void> cancelAllTasks() =>
      NotificationsFacade.I.cancelByModule(NotificationModule.tasks);
}



