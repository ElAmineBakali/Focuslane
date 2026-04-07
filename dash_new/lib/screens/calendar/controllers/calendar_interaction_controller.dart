import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_dashboard_personal/core/notifications/local/android_channel_catalog.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_action.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_content.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_delivery.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_entity_ref.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_intent.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_schedule.dart';
import 'package:mi_dashboard_personal/core/notifications/notifications_facade.dart';
import 'package:mi_dashboard_personal/screens/calendar/models/calendar_models.dart';
import 'package:mi_dashboard_personal/screens/calendar/services/calendar_service.dart';
import 'package:mi_dashboard_personal/screens/study/services/study_tasks_sync_service.dart';

class CalendarInteractionController {
  CalendarInteractionController({
    CalendarService? service,
    FirebaseFirestore? firestore,
    StudyTasksSyncService? studySyncService,
  }) : _svc = service ?? CalendarService.I,
       _db = firestore ?? FirebaseFirestore.instance,
       _studySync = studySyncService ?? StudyTasksSyncService();

  static const String _studySessionPrefix = 'study-session-';
  static const String _financeSubPrefix = 'sub-';

  final CalendarService _svc;
  final FirebaseFirestore _db;
  final StudyTasksSyncService _studySync;

  bool canMoveItem(CalendarItem item) {
    if (item.sourceModule == CalendarSourceModule.planner) {
      return item.isEditable && item.editPolicy.movable;
    }
    return item.sourceModule == CalendarSourceModule.task ||
        item.sourceModule == CalendarSourceModule.study ||
        item.sourceModule == CalendarSourceModule.gym ||
        item.sourceModule == CalendarSourceModule.finance;
  }

  bool canResizeItem(CalendarItem item) {
    if (item.isAllDay) return false;
    if (item.sourceModule == CalendarSourceModule.planner) {
      return item.isEditable && item.editPolicy.resizable;
    }
    return _isStudySessionItem(item) ||
        item.sourceModule == CalendarSourceModule.gym;
  }

  int durationMinutes(CalendarItem item) {
    if (item.isAllDay) return 60;
    final end = item.endAt ?? item.startAt.add(const Duration(hours: 1));
    final duration = end.difference(item.startAt).inMinutes;
    return duration <= 0 ? 30 : duration;
  }

  Future<void> syncPlannerNotification(CalendarEvent event) {
    return _syncPlannerNotification(event);
  }

  Future<void> cancelPlannerNotification(String eventId) async {
    await NotificationsFacade.I.cancelByEntity(
      NotificationEntityRef(
        module: NotificationModule.calendar,
        kind: 'planner_event',
        id: eventId,
      ),
    );
  }

  Future<bool> moveItemToSlot(
    CalendarItem item,
    DateTime slot, {
    required void Function(String message) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (!canMoveItem(item)) return false;

    final slotDay = DateTime(slot.year, slot.month, slot.day);

    try {
      switch (item.sourceModule) {
        case CalendarSourceModule.planner:
          final src = item.toEvent();
          final duration = durationMinutes(item);
          final start = DateTime(slot.year, slot.month, slot.day, slot.hour);

          final updated = CalendarEvent(
            id: src.id,
            title: src.title,
            type: src.type,
            priority: src.priority,
            start: start,
            end: start.add(Duration(minutes: duration)),
            allDay: false,
            notes: src.notes,
            relatedActionId: src.relatedActionId,
            relatedTxId: src.relatedTxId,
            dedupeKey: src.dedupeKey,
            completed: src.completed,
          );

          await _svc.updateEvent(updated);
          await _syncPlannerNotification(updated);
          onSuccess('Evento reprogramado.');
          return true;
        case CalendarSourceModule.task:
          if (await _updateTaskDueDate(item.id, slotDay, onError: onError)) {
            onSuccess('Tarea reprogramada.');
            return true;
          }
          return false;
        case CalendarSourceModule.study:
          if (_isStudySessionItem(item)) {
            final sessionId = _studySessionDocId(item);
            if (sessionId == null) return false;
            final start = DateTime(
              slot.year,
              slot.month,
              slot.day,
              slot.hour,
              slot.minute,
            );
            if (await _updateStudySession(
              sessionId: sessionId,
              startAt: start,
              onError: onError,
            )) {
              onSuccess('Sesion de estudio reprogramada.');
              return true;
            }
          } else {
            if (await _updateStudyTaskDueDate(
              item.id,
              slotDay,
              onError: onError,
            )) {
              onSuccess('Tarea de estudio reprogramada.');
              return true;
            }
          }
          return false;
        case CalendarSourceModule.gym:
          final start = DateTime(
            slot.year,
            slot.month,
            slot.day,
            slot.hour,
            slot.minute,
          );
          if (await _updateGymSession(
            sessionId: item.id,
            startAt: start,
            onError: onError,
          )) {
            onSuccess('Sesion de gym reprogramada.');
            return true;
          }
          return false;
        case CalendarSourceModule.food:
          onError('Este elemento no se puede mover desde calendario.');
          return false;
        case CalendarSourceModule.finance:
          if (_isFinanceSubscriptionItem(item)) {
            final subId = _financeSubscriptionDocId(item);
            if (subId == null) return false;
            if (await _updateFinanceSubscriptionDueDate(
              subId,
              slotDay,
              onError: onError,
            )) {
              onSuccess('Suscripcion reprogramada.');
              return true;
            }
          } else {
            if (await _updateFinanceTransactionDueDate(
              item.id,
              slotDay,
              onError: onError,
            )) {
              onSuccess('Movimiento financiero reprogramado.');
              return true;
            }
          }
          return false;
        case CalendarSourceModule.habit:
          onError('Este elemento no se puede mover desde calendario.');
          return false;
      }
    } catch (_) {
      onError('No se pudo reprogramar el elemento.');
      return false;
    }
  }

  Future<bool> moveItemToDay(
    CalendarItem item,
    DateTime day, {
    required void Function(String message) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (!canMoveItem(item)) return false;

    final start = DateTime(day.year, day.month, day.day);

    try {
      switch (item.sourceModule) {
        case CalendarSourceModule.planner:
          final src = item.toEvent();

          final updated = CalendarEvent(
            id: src.id,
            title: src.title,
            type: src.type,
            priority: src.priority,
            start: start,
            end: DateTime(day.year, day.month, day.day, 23, 59),
            allDay: true,
            notes: src.notes,
            relatedActionId: src.relatedActionId,
            relatedTxId: src.relatedTxId,
            dedupeKey: src.dedupeKey,
            completed: src.completed,
          );

          await _svc.updateEvent(updated);
          await _syncPlannerNotification(updated);
          onSuccess('Evento movido al dia.');
          return true;
        case CalendarSourceModule.task:
          if (await _updateTaskDueDate(item.id, start, onError: onError)) {
            onSuccess('Tarea movida al dia.');
            return true;
          }
          return false;
        case CalendarSourceModule.study:
          if (_isStudySessionItem(item)) {
            final sessionId = _studySessionDocId(item);
            if (sessionId == null) return false;
            final sessionStart = DateTime(
              day.year,
              day.month,
              day.day,
              item.startAt.hour,
              item.startAt.minute,
            );
            if (await _updateStudySession(
              sessionId: sessionId,
              startAt: sessionStart,
              onError: onError,
            )) {
              onSuccess('Sesion de estudio movida al dia.');
              return true;
            }
          } else {
            if (await _updateStudyTaskDueDate(
              item.id,
              start,
              onError: onError,
            )) {
              onSuccess('Tarea de estudio movida al dia.');
              return true;
            }
          }
          return false;
        case CalendarSourceModule.gym:
          final sessionStart = DateTime(
            day.year,
            day.month,
            day.day,
            item.startAt.hour,
            item.startAt.minute,
          );
          if (await _updateGymSession(
            sessionId: item.id,
            startAt: sessionStart,
            onError: onError,
          )) {
            onSuccess('Sesion de gym movida al dia.');
            return true;
          }
          return false;
        case CalendarSourceModule.food:
          onError('Este elemento no se puede mover desde calendario.');
          return false;
        case CalendarSourceModule.finance:
          if (_isFinanceSubscriptionItem(item)) {
            final subId = _financeSubscriptionDocId(item);
            if (subId == null) return false;
            if (await _updateFinanceSubscriptionDueDate(
              subId,
              start,
              onError: onError,
            )) {
              onSuccess('Suscripcion movida al dia.');
              return true;
            }
          } else {
            if (await _updateFinanceTransactionDueDate(
              item.id,
              start,
              onError: onError,
            )) {
              onSuccess('Movimiento financiero movido al dia.');
              return true;
            }
          }
          return false;
        case CalendarSourceModule.habit:
          onError('Este elemento no se puede mover desde calendario.');
          return false;
      }
    } catch (_) {
      onError('No se pudo mover el elemento al dia.');
      return false;
    }
  }

  Future<bool> resizeItem(
    CalendarItem item,
    int deltaMinutes, {
    required void Function(String message) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (!canResizeItem(item)) return false;

    try {
      if (item.sourceModule == CalendarSourceModule.planner) {
        final src = item.toEvent();
        final start = src.start;
        final oldEnd = src.end ?? start.add(const Duration(hours: 1));
        var newEnd = oldEnd.add(Duration(minutes: deltaMinutes));
        final minEnd = start.add(const Duration(minutes: 30));
        if (newEnd.isBefore(minEnd)) newEnd = minEnd;

        final updated = CalendarEvent(
          id: src.id,
          title: src.title,
          type: src.type,
          priority: src.priority,
          start: start,
          end: newEnd,
          allDay: false,
          notes: src.notes,
          relatedActionId: src.relatedActionId,
          relatedTxId: src.relatedTxId,
          dedupeKey: src.dedupeKey,
          completed: src.completed,
        );

        await _svc.updateEvent(updated);
        await _syncPlannerNotification(updated);
        onSuccess('Duracion del evento actualizada.');
        return true;
      }

      if (_isStudySessionItem(item)) {
        final sessionId = _studySessionDocId(item);
        if (sessionId == null) return false;
        final nextMinutes = math.max(30, durationMinutes(item) + deltaMinutes);
        if (await _updateStudySession(
          sessionId: sessionId,
          minutes: nextMinutes,
          onError: onError,
        )) {
          onSuccess('Duracion de sesion de estudio actualizada.');
          return true;
        }
        return false;
      }

      if (item.sourceModule == CalendarSourceModule.gym) {
        final nextMinutes = math.max(30, durationMinutes(item) + deltaMinutes);
        if (await _updateGymSession(
          sessionId: item.id,
          durationMin: nextMinutes,
          onError: onError,
        )) {
          onSuccess('Duracion de sesion de gym actualizada.');
          return true;
        }
        return false;
      }

      return false;
    } catch (_) {
      onError('No se pudo ajustar la duracion.');
      return false;
    }
  }

  bool _isStudySessionItem(CalendarItem item) {
    return item.sourceModule == CalendarSourceModule.study &&
        item.id.startsWith(_studySessionPrefix);
  }

  String? _studySessionDocId(CalendarItem item) {
    if (!_isStudySessionItem(item)) return null;
    final raw = item.id.substring(_studySessionPrefix.length).trim();
    return raw.isEmpty ? null : raw;
  }

  bool _isFinanceSubscriptionItem(CalendarItem item) {
    return item.sourceModule == CalendarSourceModule.finance &&
        item.id.startsWith(_financeSubPrefix);
  }

  String? _financeSubscriptionDocId(CalendarItem item) {
    if (!_isFinanceSubscriptionItem(item)) return null;
    final raw = item.id.substring(_financeSubPrefix.length).trim();
    return raw.isEmpty ? null : raw;
  }

  String _safeId(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return '';
    return value;
  }

  String? _currentUid() => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> _updateTaskDueDate(
    String taskId,
    DateTime due, {
    required void Function(String message) onError,
  }) async {
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      onError('Inicia sesion para editar tareas.');
      return false;
    }

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId);
    final snap = await ref.get();
    if (!snap.exists) return false;

    final data = snap.data() ?? const <String, dynamic>{};
    await ref.update({'dueDate': Timestamp.fromDate(due)});

    final syncedStudyTaskId = _safeId(data['syncedStudyTaskId']);
    if (syncedStudyTaskId.isNotEmpty) {
      await _studySync.syncTaskDataToStudy(
        syncedStudyTaskId,
        null,
        null,
        due,
        null,
      );
    }
    return true;
  }

  Future<bool> _updateStudyTaskDueDate(
    String studyTaskId,
    DateTime due, {
    required void Function(String message) onError,
  }) async {
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      onError('Inicia sesion para editar tareas de estudio.');
      return false;
    }

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('tasks')
        .doc(studyTaskId);

    final snap = await ref.get();
    if (!snap.exists) return false;

    final data = snap.data() ?? const <String, dynamic>{};
    await ref.update({'due': due.toIso8601String()});

    final syncedTaskId = _safeId(data['syncedTaskId']);
    if (syncedTaskId.isNotEmpty) {
      await _studySync.syncStudyTaskDataToTasks(
        syncedTaskId,
        null,
        null,
        due,
        null,
      );
    }
    return true;
  }

  Future<bool> _updateStudySession({
    required String sessionId,
    DateTime? startAt,
    int? minutes,
    required void Function(String message) onError,
  }) async {
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      onError('Inicia sesion para editar sesiones de estudio.');
      return false;
    }

    final patch = <String, dynamic>{};
    if (startAt != null) patch['date'] = startAt.toIso8601String();
    if (minutes != null) patch['minutes'] = minutes;
    if (patch.isEmpty) return false;

    await _db
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('sessions')
        .doc(sessionId)
        .update(patch);
    return true;
  }

  Future<bool> _updateGymSession({
    required String sessionId,
    DateTime? startAt,
    int? durationMin,
    required void Function(String message) onError,
  }) async {
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      onError('Inicia sesion para editar sesiones de gym.');
      return false;
    }

    final patch = <String, dynamic>{};
    if (startAt != null) patch['date'] = startAt.toIso8601String();
    if (durationMin != null) patch['durationMin'] = durationMin;
    if (patch.isEmpty) return false;

    await _db
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root')
        .collection('sessions')
        .doc(sessionId)
        .update(patch);
    return true;
  }

  Future<bool> _updateFinanceTransactionDueDate(
    String txId,
    DateTime due, {
    required void Function(String message) onError,
  }) async {
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      onError('Inicia sesion para editar movimientos de finanzas.');
      return false;
    }

    final ref = _db.collection('finance_transactions').doc(txId);
    final snap = await ref.get();
    if (!snap.exists) return false;

    final data = snap.data() ?? const <String, dynamic>{};
    if ((data['userId'] ?? '').toString() != uid) return false;

    final nextDue = DateTime(due.year, due.month, due.day);
    await ref.update({'dueDate': Timestamp.fromDate(nextDue), 'planned': true});
    return true;
  }

  Future<bool> _updateFinanceSubscriptionDueDate(
    String subId,
    DateTime due, {
    required void Function(String message) onError,
  }) async {
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      onError('Inicia sesion para editar suscripciones.');
      return false;
    }

    final ref = _db.collection('finance_subscriptions').doc(subId);
    final snap = await ref.get();
    if (!snap.exists) return false;

    final data = snap.data() ?? const <String, dynamic>{};
    if ((data['userId'] ?? '').toString() != uid) return false;

    final nextDue = DateTime(due.year, due.month, due.day);
    final title = (data['title'] ?? data['name'] ?? 'Suscripcion').toString();
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final remindDaysBefore =
        (data['remindDaysBefore'] as num?)?.toInt() ??
        (data['reminderDays'] as num?)?.toInt() ??
        3;
    final reminderEnabled = data['reminderEnabled'] != false;

    await ref.update({
      'nextDue': Timestamp.fromDate(nextDue),
      'nextPaymentDate': Timestamp.fromDate(nextDue),
    });

    final entity = NotificationEntityRef(
      module: NotificationModule.finance,
      kind: 'subscription',
      id: subId,
    );
    await NotificationsFacade.I.cancelByEntity(entity);
    if (reminderEnabled && remindDaysBefore > 0) {
      final when = nextDue.subtract(Duration(days: remindDaysBefore));
      if (when.isAfter(DateTime.now())) {
        final epoch = when.toUtc().millisecondsSinceEpoch;
        await NotificationsFacade.I.scheduleIntent(
          NotificationIntent(
            module: NotificationModule.finance,
            type: 'SUBSCRIPTION_DUE_SOON',
            entity: entity,
            content: NotificationContent(
              title: 'Proximo pago: $title',
              body:
                  'Vence en $remindDaysBefore dias. Monto: ${amount.toStringAsFixed(2)}',
            ),
            action: const NotificationAction(
              kind: NotificationActionKind.openRoute,
              route: '/finance',
            ),
            schedule: NotificationSchedule(
              kind: NotificationScheduleKind.oneShot,
              scheduledAtUtc: when.toUtc(),
              timezone: when.timeZoneName,
            ),
            delivery: const NotificationDelivery(
              kind: NotificationDeliveryKind.localOnly,
              channel: AndroidChannelCatalog.financeReminders,
              priority: NotificationPriority.normal,
            ),
            dedupeKey: 'finance:subscription:$subId:$epoch',
            userId: uid,
            source: 'calendar.subscription_sync',
            notificationId: 'ntf_finance_subscription_${subId}_$epoch',
          ),
        );
      }
    }
    return true;
  }

  Future<void> _syncPlannerNotification(CalendarEvent event) async {
    final entity = NotificationEntityRef(
      module: NotificationModule.calendar,
      kind: 'planner_event',
      id: event.id,
    );
    await NotificationsFacade.I.cancelByEntity(entity);
    if (event.allDay) return;
    if (!event.start.isAfter(DateTime.now().add(const Duration(seconds: 1)))) {
      return;
    }
    final uid = _currentUid() ?? 'local';
    final epoch = event.start.toUtc().millisecondsSinceEpoch;
    await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.calendar,
        type: 'PLANNER_EVENT_REMINDER',
        entity: entity,
        content: NotificationContent(
          title: event.title,
          body: event.notes ?? 'Recordatorio',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/calendar',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.oneShot,
          scheduledAtUtc: event.start.toUtc(),
          timezone: event.start.timeZoneName,
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.localOnly,
          channel: AndroidChannelCatalog.calendarReminders,
          priority: NotificationPriority.normal,
        ),
        dedupeKey: 'calendar:event:${event.id}:$epoch',
        userId: uid,
        source: 'calendar.planner_sync',
        notificationId: 'ntf_calendar_event_${event.id}_$epoch',
      ),
    );
  }
}
