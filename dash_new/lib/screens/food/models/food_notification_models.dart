import 'package:flutter/material.dart';

class FoodReminderTrigger {
  final String type;
  final int? hour;
  final int? minute;
  final int? intervalMinutes;
  final Map<String, dynamic>? eventData;

  const FoodReminderTrigger({
    required this.type,
    this.hour,
    this.minute,
    this.intervalMinutes,
    this.eventData,
  });

  TimeOfDay? get timeOfDay {
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour!, minute: minute!);
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'hour': hour,
      'minute': minute,
      'intervalMinutes': intervalMinutes,
      'eventData': eventData,
    }..removeWhere((_, v) => v == null);
  }

  factory FoodReminderTrigger.fromMap(Map<String, dynamic> map) {
    return FoodReminderTrigger(
      type: (map['type'] as String?) ?? 'daily_time',
      hour: (map['hour'] as num?)?.toInt(),
      minute: (map['minute'] as num?)?.toInt(),
      intervalMinutes: (map['intervalMinutes'] as num?)?.toInt(),
      eventData: map['eventData'] is Map
          ? Map<String, dynamic>.from(map['eventData'] as Map)
          : null,
    );
  }
}

class FoodReminderDefinition {
  final String id;
  final String title;
  final String description;
  final bool enabled;
  final String channel;
  final FoodReminderTrigger trigger;
  final Map<String, dynamic> payload;

  const FoodReminderDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
    required this.channel,
    required this.trigger,
    required this.payload,
  });

  FoodReminderDefinition copyWith({
    String? id,
    String? title,
    String? description,
    bool? enabled,
    String? channel,
    FoodReminderTrigger? trigger,
    Map<String, dynamic>? payload,
  }) {
    return FoodReminderDefinition(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      channel: channel ?? this.channel,
      trigger: trigger ?? this.trigger,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'enabled': enabled,
      'notification_channel': channel,
      'trigger': trigger.toMap(),
      'payload': payload,
    };
  }

  factory FoodReminderDefinition.fromMap(Map<String, dynamic> map) {
    return FoodReminderDefinition(
      id: map['id'] as String? ?? 'food_recordatorio',
      title: map['title'] as String? ?? 'Recordatorio',
      description: map['description'] as String? ?? '',
      enabled: map['enabled'] as bool? ?? true,
      channel: map['notification_channel'] as String? ?? 'food',
      trigger: map['trigger'] is Map
          ? FoodReminderTrigger.fromMap(
              Map<String, dynamic>.from(map['trigger'] as Map),
            )
          : const FoodReminderTrigger(type: 'daily_time', hour: 9, minute: 0),
      payload: map['payload'] is Map
          ? Map<String, dynamic>.from(map['payload'] as Map)
          : const {'route': '/food', 'args': {}},
    );
  }
}
