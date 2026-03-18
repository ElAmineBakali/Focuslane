import 'package:cloud_firestore/cloud_firestore.dart';

enum CalendarType { task, study, gym, finance, food, other }

enum CalendarPriority { low, normal, high }

enum CalendarSourceModule { planner, task, study, gym, food, finance, habit }

class CalendarDeepLink {
  final String routeName;
  final Map<String, dynamic> arguments;

  const CalendarDeepLink({required this.routeName, this.arguments = const {}});
}

class CalendarItemEditPolicy {
  final bool editable;
  final bool movable;
  final bool resizable;
  final bool deletable;

  const CalendarItemEditPolicy({
    required this.editable,
    required this.movable,
    required this.resizable,
    required this.deletable,
  });

  static const planner = CalendarItemEditPolicy(
    editable: true,
    movable: true,
    resizable: true,
    deletable: true,
  );

  static const readOnly = CalendarItemEditPolicy(
    editable: false,
    movable: false,
    resizable: false,
    deletable: false,
  );
}

class CalendarItem {
  final String id;
  final CalendarSourceModule sourceModule;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime? endAt;
  final bool isAllDay;
  final String timezone;
  final String displayColorKey;
  final CalendarDeepLink deepLink;
  final CalendarItemEditPolicy editPolicy;
  final CalendarType type;
  final CalendarPriority priority;
  final bool? completed;
  final String? relatedActionId;
  final String? relatedTxId;
  final String? dedupeKey;

  const CalendarItem({
    required this.id,
    required this.sourceModule,
    required this.title,
    required this.startAt,
    required this.deepLink,
    this.description,
    this.endAt,
    this.isAllDay = false,
    this.timezone = 'local',
    this.displayColorKey = 'primary',
    this.editPolicy = CalendarItemEditPolicy.readOnly,
    this.type = CalendarType.other,
    this.priority = CalendarPriority.normal,
    this.completed,
    this.relatedActionId,
    this.relatedTxId,
    this.dedupeKey,
  });

  bool get isEditable => editPolicy.editable;

  CalendarEvent toEvent() {
    return CalendarEvent(
      id: id,
      title: title,
      type: type,
      priority: priority,
      start: startAt,
      end: endAt,
      allDay: isAllDay,
      notes: description,
      relatedActionId: relatedActionId,
      relatedTxId: relatedTxId,
      dedupeKey: dedupeKey,
      completed: completed,
    );
  }

  static CalendarItem fromEvent(
    CalendarEvent event, {
    CalendarSourceModule sourceModule = CalendarSourceModule.planner,
    CalendarDeepLink? deepLink,
    CalendarItemEditPolicy editPolicy = CalendarItemEditPolicy.planner,
    String timezone = 'local',
    String displayColorKey = 'primary',
  }) {
    return CalendarItem(
      id: event.id,
      sourceModule: sourceModule,
      title: event.title,
      description: event.notes,
      startAt: event.start,
      endAt: event.end,
      isAllDay: event.allDay,
      timezone: timezone,
      displayColorKey: displayColorKey,
      deepLink:
          deepLink ??
          CalendarDeepLink(
            routeName: '/calendar',
            arguments: {'eventId': event.id},
          ),
      editPolicy: editPolicy,
      type: event.type,
      priority: event.priority,
      completed: event.completed,
      relatedActionId: event.relatedActionId,
      relatedTxId: event.relatedTxId,
      dedupeKey: event.dedupeKey,
    );
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final CalendarType type;
  final CalendarPriority priority;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String? notes;
  final String? relatedActionId;
  final String? relatedTxId;
  final String? dedupeKey;

  final bool? completed;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.start,
    this.end,
    this.allDay = false,
    this.notes,
    this.relatedActionId,
    this.relatedTxId,
    this.dedupeKey,
    this.completed,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'type': type.name,
    'priority': priority.name,
    'start': Timestamp.fromDate(start),
    if (end != null) 'end': Timestamp.fromDate(end!),
    'allDay': allDay,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
    if (relatedActionId != null) 'relatedActionId': relatedActionId,
    if (relatedTxId != null) 'relatedTxId': relatedTxId,
    if (dedupeKey != null) 'dedupeKey': dedupeKey,
    if (completed != null) 'completed': completed,
  };

  static CalendarEvent fromSnap(DocumentSnapshot s) {
    final m = (s.data() as Map<String, dynamic>? ?? {});
    return CalendarEvent(
      id: s.id,
      title: (m['title'] ?? '') as String,
      type: _enumParse(CalendarType.values, m['type'], CalendarType.other),
      priority: _enumParse(
        CalendarPriority.values,
        m['priority'],
        CalendarPriority.normal,
      ),
      start: (m['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      end: (m['end'] as Timestamp?)?.toDate(),
      allDay: (m['allDay'] ?? false) as bool,
      notes: m['notes'] as String?,
      relatedActionId: m['relatedActionId'] as String?,
      relatedTxId: m['relatedTxId'] as String?,
      dedupeKey: m['dedupeKey'] as String?,
      completed: m['completed'] as bool?,
    );
  }

  static T _enumParse<T>(List<T> values, Object? raw, T fallback) {
    final n = (raw ?? '').toString();
    for (final v in values) {
      if (v.toString().split('.').last == n) return v;
    }
    return fallback;
  }
}

class Timetable {
  final String id;
  final String name;
  final bool isDefault;
  final List<String> days;
  final String startHour;
  final String endHour;
  final int slotMinutes;
  final String? colorHex;

  Timetable({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.days,
    required this.startHour,
    required this.endHour,
    required this.slotMinutes,
    this.colorHex,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'isDefault': isDefault,
    'days': days,
    'startHour': startHour,
    'endHour': endHour,
    'slotMinutes': slotMinutes,
    'colorHex': colorHex,
  };

  static Timetable fromSnap(DocumentSnapshot s) {
    final m = (s.data() as Map<String, dynamic>? ?? {});
    return Timetable(
      id: s.id,
      name: m['name'] ?? '',
      isDefault: m['isDefault'] ?? false,
      days:
          (m['days'] as List?)?.map((e) => e.toString()).toList() ??
          const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      startHour: (m['startHour'] ?? '07:00') as String,
      endHour: (m['endHour'] ?? '22:00') as String,
      slotMinutes: (m['slotMinutes'] ?? 60) as int,
      colorHex: m['colorHex'] as String?,
    );
  }
}

class TimetableSlot {
  final String id;
  final String day;
  final String start;
  final String end;
  final String title;
  final CalendarType type;
  final String? note;
  final String? colorHex;

  TimetableSlot({
    required this.id,
    required this.day,
    required this.start,
    required this.end,
    required this.title,
    required this.type,
    this.note,
    this.colorHex,
  });

  Map<String, dynamic> toMap() => {
    'day': day,
    'start': start,
    'end': end,
    'title': title,
    'type': type.name,
    'note': note,
    'colorHex': colorHex,
  };

  static TimetableSlot fromSnap(DocumentSnapshot s) {
    final m = (s.data() as Map<String, dynamic>? ?? {});
    return TimetableSlot(
      id: s.id,
      day: m['day'] ?? 'Mon',
      start: m['start'] ?? '09:00',
      end: m['end'] ?? '10:00',
      title: m['title'] ?? '',
      type: CalendarEvent._enumParse(
        CalendarType.values,
        m['type'],
        CalendarType.other,
      ),
      note: m['note'],
      colorHex: m['colorHex'],
    );
  }
}

class PlannerPrefs {
  final Set<CalendarType> enabled;
  final bool highOnly;
  final String? defaultTimetableId;

  PlannerPrefs({
    required this.enabled,
    this.highOnly = false,
    this.defaultTimetableId,
  });

  Map<String, dynamic> toMap() => {
    'enabled': enabled.map((e) => e.name).toList(),
    'highOnly': highOnly,
    'defaultTimetableId': defaultTimetableId,
  };

  static PlannerPrefs fromSnap(DocumentSnapshot s) {
    final m = (s.data() as Map<String, dynamic>? ?? {});
    final list =
        (m['enabled'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final enabled = <CalendarType>{};
    for (final n in list) {
      for (final v in CalendarType.values) {
        if (v.name == n) enabled.add(v);
      }
    }
    if (enabled.isEmpty) {
      enabled.addAll(CalendarType.values);
    }
    return PlannerPrefs(
      enabled: enabled,
      highOnly: (m['highOnly'] ?? false) as bool,
      defaultTimetableId: m['defaultTimetableId'] as String?,
    );
  }
}
