import 'package:flutter/material.dart';

enum StudyItemType { task, exam }

enum Priority { low, normal, high }

enum TaskStatus { todo, doing, done }

enum StudyMethod { pomodoro, flowtime, timeboxing, simple }

Color? _hex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  try {
    final v = int.parse(
      hex.startsWith('0x') ? hex.substring(2) : hex,
      radix: 16,
    );
    return Color(v);
  } catch (_) {
    return null;
  }
}

class Course {
  final String id;
  final String name;
  final String? colorHex;
  final String? teacher;
  final double? credits;
  final double? goalHours;
  final bool isArchived;
  final DateTime? createdAt;

  final double? attendanceRequired;

  const Course({
    required this.id,
    required this.name,
    this.colorHex,
    this.teacher,
    this.credits,
    this.goalHours,
    this.isArchived = false,
    this.createdAt,
    this.attendanceRequired,
  });

  Color? get color => _hex(colorHex);

  factory Course.fromMap(String id, Map<String, dynamic> m) {
    DateTime? parseCreatedAt(dynamic v) {
      try {
        if (v == null) return null;
        if (v is DateTime) return v;
        try {
          if (v.toString().contains('Timestamp')) {
            return v.toDate();
          }
        } catch (_) {}
        return DateTime.tryParse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return Course(
      id: id,
      name: m['name'] ?? '',
      colorHex: m['colorHex'],
      teacher: m['teacher'],
      credits: (m['credits'] as num?)?.toDouble(),
      goalHours: (m['goalHours'] as num?)?.toDouble(),
      isArchived: m['isArchived'] == true,
      createdAt: parseCreatedAt(m['createdAt']),
      attendanceRequired: (m['attendanceRequired'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (colorHex != null) 'colorHex': colorHex,
    if (teacher != null) 'teacher': teacher,
    if (credits != null) 'credits': credits,
    if (goalHours != null) 'goalHours': goalHours,
    if (attendanceRequired != null) 'attendanceRequired': attendanceRequired,
    'isArchived': isArchived,
  };
}

class StudyTask {
  final String id;
  final String courseId;
  final String title;
  final StudyItemType type;
  final DateTime? due;
  final Priority priority;
  final TaskStatus status;
  final String? notes;
  final DateTime? createdAt;

  final String? syncedTaskId;

  const StudyTask({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    this.due,
    this.priority = Priority.normal,
    this.status = TaskStatus.todo,
    this.notes,
    this.createdAt,
    this.syncedTaskId,
  });

  factory StudyTask.fromMap(String id, Map<String, dynamic> m) {
    DateTime? parseTs(dynamic v) {
      if (v == null) return null;
      try {
        if (v is DateTime) return v;
        if (v is String) return DateTime.tryParse(v);
        final asString = v.toDate().toString();
        return DateTime.tryParse(asString);
      } catch (_) {
        return null;
      }
    }

    return StudyTask(
      id: id,
      courseId: m['courseId'] ?? '',
      title: m['title'] ?? '',
      type: (m['type'] == 'exam') ? StudyItemType.exam : StudyItemType.task,
      due: parseTs(m['due']),
      priority: Priority.values.firstWhere(
        (p) => p.name == (m['priority'] ?? 'normal'),
        orElse: () => Priority.normal,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == (m['status'] ?? 'todo'),
        orElse: () => TaskStatus.todo,
      ),
      notes: m['notes'],
      createdAt: parseTs(m['createdAt']),
      syncedTaskId: m['syncedTaskId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'courseId': courseId,
    'title': title,
    'type': type == StudyItemType.exam ? 'exam' : 'task',
    if (due != null) 'due': due!.toIso8601String(),
    'priority': priority.name,
    'status': status.name,
    if (notes != null) 'notes': notes,
    if (syncedTaskId != null) 'syncedTaskId': syncedTaskId,
  };
}

class TimerPreset {
  final String id;
  final String name;
  final StudyMethod method;
  final Map<String, dynamic> params;
  final String? courseId;
  const TimerPreset({
    required this.id,
    required this.name,
    required this.method,
    required this.params,
    this.courseId,
  });

  factory TimerPreset.fromMap(String id, Map<String, dynamic> m) {
    return TimerPreset(
      id: id,
      name: m['name'] ?? '',
      method: StudyMethod.values.firstWhere(
        (x) => x.name == (m['method'] ?? 'pomodoro'),
        orElse: () => StudyMethod.pomodoro,
      ),
      params: Map<String, dynamic>.from(m['params'] ?? const {}),
      courseId: m['courseId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'method': method.name,
    'params': params,
    if (courseId != null) 'courseId': courseId,
  };
}

class StudySession {
  final String id;
  final String courseId;
  final String? taskId;
  final StudyMethod method;
  final int minutes;
  final int? laps;
  final int? cycles;
  final Map<String, dynamic> configSnapshot;
  final String? notes;
  final DateTime date;

  const StudySession({
    required this.id,
    required this.courseId,
    this.taskId,
    required this.method,
    required this.minutes,
    this.laps,
    this.cycles,
    required this.configSnapshot,
    this.notes,
    required this.date,
  });

  factory StudySession.fromMap(String id, Map<String, dynamic> m) {
    DateTime parseDate(dynamic v) {
      try {
        if (v == null) return DateTime.now();
        if (v is DateTime) return v;
        if (v is String) return DateTime.parse(v);
        return DateTime.parse(v.toDate().toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return StudySession(
      id: id,
      courseId: m['courseId'] ?? '',
      taskId: m['taskId'],
      method: StudyMethod.values.firstWhere(
        (x) => x.name == (m['method'] ?? 'pomodoro'),
        orElse: () => StudyMethod.pomodoro,
      ),
      minutes: (m['minutes'] as num?)?.toInt() ?? 0,
      laps: (m['laps'] as num?)?.toInt(),
      cycles: (m['cycles'] as num?)?.toInt(),
      configSnapshot: Map<String, dynamic>.from(
        m['configSnapshot'] ?? const {},
      ),
      notes: m['notes'],
      date: parseDate(m['date']),
    );
  }

  Map<String, dynamic> toMap() => {
    'courseId': courseId,
    if (taskId != null) 'taskId': taskId,
    'method': method.name,
    'minutes': minutes,
    if (laps != null) 'laps': laps,
    if (cycles != null) 'cycles': cycles,
    'configSnapshot': configSnapshot,
    if (notes != null) 'notes': notes,
    'date': date.toIso8601String(),
  };
}

class StudyClassBlock {
  final String id;
  final String courseId;
  final List<int> daysOfWeek;
  final TimeOfDay start;
  final TimeOfDay end;
  final String? room;

  const StudyClassBlock({
    required this.id,
    required this.courseId,
    required this.daysOfWeek,
    required this.start,
    required this.end,
    this.room,
  });

  factory StudyClassBlock.fromMap(String id, Map<String, dynamic> m) {
    return StudyClassBlock(
      id: id,
      courseId: m['courseId'] ?? '',
      daysOfWeek: List<int>.from(m['daysOfWeek'] ?? const []),
      start: TimeOfDay(
        hour: (m['startHour'] as num?)?.toInt() ?? 0,
        minute: (m['startMinute'] as num?)?.toInt() ?? 0,
      ),
      end: TimeOfDay(
        hour: (m['endHour'] as num?)?.toInt() ?? 0,
        minute: (m['endMinute'] as num?)?.toInt() ?? 0,
      ),
      room: m['room'],
    );
  }

  Map<String, dynamic> toMap() => {
    'courseId': courseId,
    'daysOfWeek': daysOfWeek,
    'startHour': start.hour,
    'startMinute': start.minute,
    'endHour': end.hour,
    'endMinute': end.minute,
    if (room != null) 'room': room,
  };
}

class GradeEntry {
  final String id;
  final String taskId;
  final String courseId;
  final String? assessmentType;
  final double grade;
  final double? weight;
  final DateTime date;
  final String? notes;

  const GradeEntry({
    required this.id,
    required this.taskId,
    required this.courseId,
    this.assessmentType,
    required this.grade,
    this.weight,
    required this.date,
    this.notes,
  });

  factory GradeEntry.fromMap(String id, Map<String, dynamic> m) {
    DateTime parseDate(dynamic v) {
      try {
        if (v == null) return DateTime.now();
        if (v is DateTime) return v;
        if (v is String) return DateTime.parse(v);
        return DateTime.parse(v.toDate().toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return GradeEntry(
      id: id,
      taskId: m['taskId'] ?? '',
      courseId: m['courseId'] ?? '',
      assessmentType: m['assessmentType'] as String?,
      grade: (m['grade'] as num?)?.toDouble() ?? 0.0,
      weight: (m['weight'] as num?)?.toDouble(),
      date: parseDate(m['date']),
      notes: m['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
    'taskId': taskId,
    'courseId': courseId,
    if (assessmentType != null) 'assessmentType': assessmentType,
    'grade': grade,
    if (weight != null) 'weight': weight,
    'date': date.toIso8601String(),
    if (notes != null) 'notes': notes,
  };
}
