import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/core/services/notification_service.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_model.dart';
import 'package:mi_dashboard_personal/screens/tasks/task_model.dart';
import 'package:mi_dashboard_personal/screens/gym/models/gym_models.dart';

class ReminderService {
  ReminderService._();
  static final ReminderService I = ReminderService._();

  Future<void> scheduleHabitReminder(
    Habit habit, {
    Habit? previous,
    bool globalEnabled = true,
    bool habitsEnabled = true,
  }) async {
    final id = 'habit_${habit.id}';
    final timeStr = habit.reminderTime.trim();

    if (!globalEnabled ||
        !habitsEnabled ||
        !habit.isActive ||
        timeStr.isEmpty) {
      await NotificationService.I.cancelNotificationById(id);
      return;
    }

    final changed =
        previous != null && previous.reminderTime != habit.reminderTime;
    if (changed) {
      await NotificationService.I.cancelNotificationById(id);
    }

    if (!changed && previous != null) {
      return;
    }

    final time = _parseHHmm(timeStr);
    if (time == null) {
      await NotificationService.I.cancelNotificationById(id);
      return;
    }

    await NotificationService.I.scheduleDailyReminder(
      id: id,
      title: habit.name.isEmpty ? 'Hábito' : habit.name,
      body: 'Registra tu progreso',
      time: time,
      payload: '/habits/${habit.id}',
    );
  }

  Future<void> cancelHabitReminder(String habitId) async {
    await NotificationService.I.cancelNotificationById('habit_$habitId');
  }

  Future<void> scheduleTaskReminder(
    Task task, {
    Task? previous,
    bool globalEnabled = true,
    bool tasksEnabled = true,
  }) async {
    final id = 'task_${task.id}';
    if (!globalEnabled || !tasksEnabled || task.completed != false) {
      await NotificationService.I.cancelNotificationById(id);
      return;
    }

    DateTime? target = task.remindAt;

    if (target == null || target.isBefore(DateTime.now())) {
      await NotificationService.I.cancelNotificationById(id);
      return;
    }

    final prevTarget = _extractTaskPrevTarget(previous);
    final changed = prevTarget == null || prevTarget != target;
    if (changed) {
      await NotificationService.I.cancelNotificationById(id);
      await NotificationService.I.scheduleOneTimeNotification(
        id: id,
        title: task.title.isEmpty ? 'Tarea' : task.title,
        body: 'Revisa esta tarea pendiente',
        scheduledTime: target,
        payload: '/tasks/${task.id}',
      );
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await NotificationService.I.cancelNotificationById('task_$taskId');
  }

  DateTime? _extractTaskPrevTarget(Task? t) {
    if (t == null) return null;
    return t.remindAt;
  }

  Future<void> scheduleGymReminder(
    Routine routine, {
    Routine? previous,
    TimeOfDay? previousTime,
    TimeOfDay? time,
    bool globalEnabled = true,
    bool gymEnabled = true,
  }) async {
    final id = 'gym_${routine.id}';
    if (!globalEnabled || !gymEnabled || time == null) {
      await NotificationService.I.cancelNotificationById(id);
      return;
    }

    final timeChanged =
        previousTime == null ||
        (previousTime.hour != time.hour || previousTime.minute != time.minute);
    final changed =
        previous == null || previous.name != routine.name || timeChanged;
    if (!changed) return;

    await NotificationService.I.cancelNotificationById(id);
    await NotificationService.I.scheduleDailyReminder(
      id: id,
      title: 'Gym: ${routine.name}',
      body: 'Hora de entrenar',
      time: time,
      payload: '/gym/routines',
    );
  }

  Future<void> cancelGymReminder(String routineId) async {
    await NotificationService.I.cancelNotificationById('gym_$routineId');
  }

  TimeOfDay? _parseHHmm(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> cancelAllHabits() =>
      NotificationService.I.cancelAllNotificationsForModule('habit');
  Future<void> cancelAllTasks() =>
      NotificationService.I.cancelAllNotificationsForModule('task');
  Future<void> cancelAllGym() =>
      NotificationService.I.cancelAllNotificationsForModule('gym');
}

