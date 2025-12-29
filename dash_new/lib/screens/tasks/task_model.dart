import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority {
  low('baja'),
  medium('media'),
  high('alta');

  final String label;
  const TaskPriority(this.label);

  static TaskPriority fromString(String s) {
    switch (s.toLowerCase()) {
      case 'alta':
        return TaskPriority.high;
      case 'media':
        return TaskPriority.medium;
      case 'baja':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  Color getColor() {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFEF5350);
      case TaskPriority.medium:
        return const Color(0xFFFFA726);
      case TaskPriority.low:
        return const Color(0xFF9E9E9E);
    }
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final String? category;
  final DateTime? dueDate;
  final TimeOfDay? reminderTime;
  final bool completed;
  final int? order;
  final List<String> tags;
  final DateTime? remindAt;
  final bool isPinned;
  final RepeatRule repeatRule;
  final List<Subtask> subtasks;
  final bool isCalendarVisible;
  final String? linkedNoteId;

  final String? linkedStudyCourseId;

  final String? syncedStudyTaskId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.category,
    this.dueDate,
    this.reminderTime,
    required this.completed,
    this.order,
    this.tags = const [],
    this.remindAt,
    this.isPinned = false,
    this.repeatRule = RepeatRule.none,
    this.subtasks = const [],
    this.isCalendarVisible = true,
    this.linkedNoteId,
    this.linkedStudyCourseId,
    this.syncedStudyTaskId,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    String? category,
    DateTime? dueDate,
    TimeOfDay? reminderTime,
    bool? completed,
    int? order,
    List<String>? tags,
    DateTime? remindAt,
    bool? isPinned,
    RepeatRule? repeatRule,
    List<Subtask>? subtasks,
    bool? isCalendarVisible,
    String? linkedNoteId,
    String? linkedStudyCourseId,
    String? syncedStudyTaskId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      completed: completed ?? this.completed,
      order: order ?? this.order,
      tags: tags ?? this.tags,
      remindAt: remindAt ?? this.remindAt,
      isPinned: isPinned ?? this.isPinned,
      repeatRule: repeatRule ?? this.repeatRule,
      subtasks: subtasks ?? this.subtasks,
      isCalendarVisible: isCalendarVisible ?? this.isCalendarVisible,
      linkedNoteId: linkedNoteId ?? this.linkedNoteId,
      linkedStudyCourseId: linkedStudyCourseId ?? this.linkedStudyCourseId,
      syncedStudyTaskId: syncedStudyTaskId ?? this.syncedStudyTaskId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority.label,
      'category': category,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'reminderTime':
          reminderTime != null
              ? {'hour': reminderTime!.hour, 'minute': reminderTime!.minute}
              : null,
      'completed': completed,
      'order': order,
      'tags': tags,
      'remindAt': remindAt != null ? Timestamp.fromDate(remindAt!) : null,
      'isPinned': isPinned,
      'repeatRule': repeatRule.name,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'isCalendarVisible': isCalendarVisible,
      'linkedNoteId': linkedNoteId,
      'linkedStudyCourseId': linkedStudyCourseId,
      'syncedStudyTaskId': syncedStudyTaskId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parsedReminderTime;
    final rtRaw = map['reminderTime'];
    if (rtRaw != null && rtRaw is Map) {
      final timeMap = Map<String, dynamic>.from(rtRaw);
      final h = timeMap['hour'];
      final m = timeMap['minute'];
      if (h is int && m is int) {
        parsedReminderTime = TimeOfDay(hour: h, minute: m);
      }
    }

    DateTime? parsedDueDate;
    final dd = map['dueDate'];
    if (dd is Timestamp) {
      parsedDueDate = dd.toDate();
    } else if (dd is int) {
      parsedDueDate = DateTime.fromMillisecondsSinceEpoch(dd);
    } else if (dd is String) {
      parsedDueDate = DateTime.tryParse(dd);
    }

    DateTime? parsedRemindAt;
    final ra = map['remindAt'];
    if (ra is Timestamp) {
      parsedRemindAt = ra.toDate();
    } else if (ra is int) {
      parsedRemindAt = DateTime.fromMillisecondsSinceEpoch(ra);
    } else if (ra is String) {
      parsedRemindAt = DateTime.tryParse(ra);
    }

    List<String> parsedTags = [];
    final tagsRaw = map['tags'];
    if (tagsRaw is List) {
      parsedTags = tagsRaw.map((e) => e.toString()).toList();
    }

    final subsRaw = map['subtasks'];
    List<Subtask> parsedSubs = [];
    if (subsRaw is List) {
      parsedSubs =
          subsRaw
              .map(
                (e) =>
                    e is Map<String, dynamic>
                        ? Subtask.fromMap(Map<String, dynamic>.from(e))
                        : Subtask.fromMap(
                          Map<String, dynamic>.from({
                            'id': (e['id'] ?? '').toString(),
                            'title': (e['title'] ?? '').toString(),
                            'isDone': (e['isDone'] ?? false) as bool,
                          }),
                        ),
              )
              .toList();
    }

    return Task(
      id: map['id'] as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      priority: TaskPriority.fromString(map['priority'] ?? 'media'),
      category: map['category'] as String?,
      dueDate: parsedDueDate,
      reminderTime: parsedReminderTime,
      completed: (map['completed'] ?? false) as bool,
      order: (map['order'] as num?)?.toInt(),
      tags: parsedTags,
      remindAt: parsedRemindAt,
      isPinned: (map['isPinned'] ?? false) as bool,
      repeatRule: RepeatRuleX.parse(map['repeatRule']),
      subtasks: parsedSubs,
      isCalendarVisible: (map['isCalendarVisible'] ?? true) as bool,
      linkedNoteId: map['linkedNoteId'] as String?,
      linkedStudyCourseId: map['linkedStudyCourseId'] as String?,
      syncedStudyTaskId: map['syncedStudyTaskId'] as String?,
    );
  }
}

enum RepeatRule { none, daily, weekly, monthly }

extension RepeatRuleX on RepeatRule {
  static RepeatRule parse(dynamic raw) {
    if (raw == null) return RepeatRule.none;
    final s = raw.toString().toLowerCase();
    switch (s) {
      case 'daily':
        return RepeatRule.daily;
      case 'weekly':
        return RepeatRule.weekly;
      case 'monthly':
        return RepeatRule.monthly;
      case 'none':
      default:
        return RepeatRule.none;
    }
  }

  String get label {
    switch (this) {
      case RepeatRule.daily:
        return 'Diaria';
      case RepeatRule.weekly:
        return 'Semanal';
      case RepeatRule.monthly:
        return 'Mensual';
      case RepeatRule.none:
        return 'Sin repetición';
    }
  }
}

class Subtask {
  final String id;
  final String title;
  final bool isDone;

  const Subtask({required this.id, required this.title, this.isDone = false});

  Subtask copyWith({String? id, String? title, bool? isDone}) => Subtask(
    id: id ?? this.id,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
  );

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'isDone': isDone};

  factory Subtask.fromMap(Map<String, dynamic> m) => Subtask(
    id: (m['id'] ?? '').toString(),
    title: (m['title'] ?? '').toString(),
    isDone: (m['isDone'] ?? false) as bool,
  );
}
