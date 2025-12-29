import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';

enum TaskGroup {
  overdue('Vencidas'),
  today('Hoy'),
  tomorrow('Mañana'),
  thisWeek('Esta semana'),
  later('Más adelante'),
  noDate('Sin fecha');

  final String label;
  const TaskGroup(this.label);
}

class TaskGrouper {
  static TaskGroup getGroup(Task task) {
    if (task.dueDate == null) return TaskGroup.noDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(Duration(days: 7 - today.weekday));

    final dueDay = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );

    if (dueDay.isBefore(today) && !task.completed) {
      return TaskGroup.overdue;
    } else if (dueDay.isAtSameMomentAs(today)) {
      return TaskGroup.today;
    } else if (dueDay.isAtSameMomentAs(tomorrow)) {
      return TaskGroup.tomorrow;
    } else if (dueDay.isAfter(tomorrow) &&
        dueDay.isBefore(endOfWeek.add(const Duration(days: 1)))) {
      return TaskGroup.thisWeek;
    } else {
      return TaskGroup.later;
    }
  }

  static Map<TaskGroup, List<Task>> groupTasks(List<Task> tasks) {
    final groups = <TaskGroup, List<Task>>{};
    for (final group in TaskGroup.values) {
      groups[group] = [];
    }

    for (final task in tasks) {
      final group = getGroup(task);
      groups[group]!.add(task);
    }

    return groups;
  }

  static List<Task> sortTasks(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0);
      }

      if (a.dueDate == null && b.dueDate == null) {
        final priorityComp = b.priority.index.compareTo(a.priority.index);
        if (priorityComp != 0) return priorityComp;
        return (a.order ?? 0).compareTo(b.order ?? 0);
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;

      final dateComp = a.dueDate!.compareTo(b.dueDate!);
      if (dateComp != 0) return dateComp;
      final priorityComp = b.priority.index.compareTo(a.priority.index);
      if (priorityComp != 0) return priorityComp;
      return (a.order ?? 0).compareTo(b.order ?? 0);
    });
    return sorted;
  }
}

class TaskFormatter {
  static String formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'Sin fecha';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDay.isAtSameMomentAs(today)) {
      return 'Hoy ${DateFormat('HH:mm').format(dueDate)}';
    } else if (dueDay.isAtSameMomentAs(tomorrow)) {
      return 'Mañana ${DateFormat('HH:mm').format(dueDate)}';
    } else if (dueDay.isBefore(today)) {
      return 'Vencida: ${DateFormat('dd/MM/yy HH:mm').format(dueDate)}';
    } else {
      return DateFormat('dd/MM/yy HH:mm').format(dueDate);
    }
  }

  static String formatReminderTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static IconData getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Icons.flag;
      case TaskPriority.medium:
        return Icons.flag_outlined;
      case TaskPriority.low:
        return Icons.outlined_flag;
    }
  }
}
