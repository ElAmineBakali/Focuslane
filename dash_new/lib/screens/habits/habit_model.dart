import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

 class HabitReminder {
  final String id;    final TimeOfDay time;    final List<int>
  daysOfWeek;    final bool enabled;  
  HabitReminder({
    required this.id,
    required this.time,
    List<int>? daysOfWeek,
    this.enabled = true,
  }) : daysOfWeek = daysOfWeek ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'daysOfWeek': daysOfWeek,
      'enabled': enabled,
    };
  }

  factory HabitReminder.fromMap(Map<String, dynamic> map) {
    return HabitReminder(
      id: map['id'] ?? '',
      time: TimeOfDay(
        hour: (map['hour'] as num?)?.toInt() ?? 0,
        minute: (map['minute'] as num?)?.toInt() ?? 0,
      ),
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? []),
      enabled: map['enabled'] ?? true,
    );
  }

  HabitReminder copyWith({
    String? id,
    TimeOfDay? time,
    List<int>? daysOfWeek,
    bool? enabled,
  }) {
    return HabitReminder(
      id: id ?? this.id,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      enabled: enabled ?? this.enabled,
    );
  }
}

class Habit {
  String id;
  String name;
  String description;
  String frequency;
  String reminderTime;
  String unit;
  bool isQuantitative;
  Map<String, dynamic> history;
  bool isActive;
  DateTime createdAt;
  List<String> completedDates;
  int order;
  bool daily;
  DateTime lastUpdated;
  String colorHex;  
     String? emoji;    String? iconCode;    List<String> tags;    List<HabitReminder> reminders;    int currentStreak;    int bestStreak;  
     var values;
  var textColor;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.reminderTime,
    required this.unit,
    required this.isQuantitative,
    required this.history,
    required this.isActive,
    required this.createdAt,
    required this.completedDates,
    required this.order,
    required this.daily,
    required this.lastUpdated,
    required this.colorHex,
    this.emoji,
    this.iconCode,
    List<String>? tags,
    List<HabitReminder>? reminders,
    this.currentStreak = 0,
    this.bestStreak = 0,
  }) : tags = tags ?? [],
       reminders = reminders ?? [];

  Color get color => Color(int.parse(colorHex));

  Map<String, dynamic> toMap() {
    return {
             'name': name,
      'description': description,
      'frequency': frequency,
      'reminderTime': reminderTime,
      'unit': unit,
      'isQuantitative': isQuantitative,
      'history': history,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedDates': completedDates,
      'order': order,
      'daily': daily,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'colorHex': colorHex,
             'emoji': emoji,
      'iconCode': iconCode,
      'tags': tags,
      'reminders': reminders.map((r) => r.toMap()).toList(),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.now();
    }

    List<HabitReminder> parseReminders(dynamic v) {
      if (v == null) return [];
      if (v is! List) return [];
      return v
          .map((e) {
            if (e is Map<String, dynamic>) {
              return HabitReminder.fromMap(e);
            }
            return null;
          })
          .whereType<HabitReminder>()
          .toList();
    }

    return Habit(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      frequency: map['frequency'] ?? 'Diario',
      reminderTime: map['reminderTime'] ?? '',
      unit: map['unit'] ?? '',
      isQuantitative: map['isQuantitative'] ?? false,
      history: Map<String, dynamic>.from(map['history'] ?? {}),
      isActive: map['isActive'] ?? true,
      createdAt: toDate(map['createdAt']),
      completedDates: List<String>.from(map['completedDates'] ?? []),
      order: (map['order'] as num?)?.toInt() ?? 0,
      daily: map['daily'] ?? true,
      lastUpdated: toDate(map['lastUpdated']),
      colorHex: map['colorHex'] ?? '0xFF000000',
             emoji: map['emoji'],
      iconCode: map['iconCode'],
      tags: List<String>.from(map['tags'] ?? []),
      reminders: parseReminders(map['reminders']),
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
    );
  }

  static Habit fromDoc(DocumentSnapshot doc) {
    final map = (doc.data() as Map<String, dynamic>? ?? {});
    return Habit.fromMap(map, doc.id);
  }

  factory Habit.empty() {
    final now = DateTime.now();
    return Habit(
      id: '',
      name: '',
      description: '',
      frequency: 'Diario',
      reminderTime: '',
      unit: '',
      isQuantitative: false,
      history: {},
      isActive: true,
      createdAt: now,
      completedDates: const [],
      order: 0,
      daily: true,
      lastUpdated: now,
      colorHex: '0xFF000000',
      emoji: null,
      iconCode: null,
      tags: const [],
      reminders: const [],
      currentStreak: 0,
      bestStreak: 0,
    );
  }

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? frequency,
    String? reminderTime,
    String? unit,
    bool? isQuantitative,
    Map<String, dynamic>? history,
    bool? isActive,
    DateTime? createdAt,
    List<String>? completedDates,
    int? order,
    bool? daily,
    DateTime? lastUpdated,
    String? colorHex,
    String? emoji,
    String? iconCode,
    List<String>? tags,
    List<HabitReminder>? reminders,
    int? currentStreak,
    int? bestStreak,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      unit: unit ?? this.unit,
      isQuantitative: isQuantitative ?? this.isQuantitative,
      history: history ?? this.history,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      order: order ?? this.order,
      daily: daily ?? this.daily,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      colorHex: colorHex ?? this.colorHex,
      emoji: emoji ?? this.emoji,
      iconCode: iconCode ?? this.iconCode,
      tags: tags ?? this.tags,
      reminders: reminders ?? this.reminders,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }
}
