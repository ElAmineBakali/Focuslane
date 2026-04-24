import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';

enum EntityNotificationScheduleMode {
  absolute,
  relative,
}

class EntityNotificationConfig {
  const EntityNotificationConfig({
    required this.module,
    required this.entityKind,
    required this.entityId,
    required this.entityLabel,
    required this.notificationType,
    required this.scheduleMode,
    required this.enabled,
    this.absoluteAtUtc,
    this.minutesBefore,
    this.updatedAtUtc,
  });

  final NotificationModule module;
  final String entityKind;
  final String entityId;
  final String entityLabel;
  final String notificationType;
  final EntityNotificationScheduleMode scheduleMode;
  final bool enabled;
  final DateTime? absoluteAtUtc;
  final int? minutesBefore;
  final DateTime? updatedAtUtc;

  String get key => '${module.name}|$entityKind|$entityId';

  NotificationEntityRef toEntityRef() {
    return NotificationEntityRef(
      module: module,
      kind: entityKind,
      id: entityId,
    );
  }

  EntityNotificationConfig copyWith({
    NotificationModule? module,
    String? entityKind,
    String? entityId,
    String? entityLabel,
    String? notificationType,
    EntityNotificationScheduleMode? scheduleMode,
    bool? enabled,
    DateTime? absoluteAtUtc,
    int? minutesBefore,
    DateTime? updatedAtUtc,
  }) {
    return EntityNotificationConfig(
      module: module ?? this.module,
      entityKind: entityKind ?? this.entityKind,
      entityId: entityId ?? this.entityId,
      entityLabel: entityLabel ?? this.entityLabel,
      notificationType: notificationType ?? this.notificationType,
      scheduleMode: scheduleMode ?? this.scheduleMode,
      enabled: enabled ?? this.enabled,
      absoluteAtUtc: absoluteAtUtc ?? this.absoluteAtUtc,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'module': module.name,
      'entityKind': entityKind,
      'entityId': entityId,
      'entityLabel': entityLabel,
      'notificationType': notificationType,
      'scheduleMode': scheduleMode.name,
      'enabled': enabled,
      'absoluteAtUtc': absoluteAtUtc?.toUtc().toIso8601String(),
      'minutesBefore': minutesBefore,
      'updatedAtUtc': updatedAtUtc?.toUtc().toIso8601String(),
    };
  }

  factory EntityNotificationConfig.fromMap(Map<String, dynamic> map) {
    return EntityNotificationConfig(
      module: NotificationModule.values.firstWhere(
        (value) => value.name == (map['module'] ?? '').toString(),
        orElse: () => NotificationModule.system,
      ),
      entityKind: (map['entityKind'] ?? '').toString(),
      entityId: (map['entityId'] ?? '').toString(),
      entityLabel: (map['entityLabel'] ?? '').toString(),
      notificationType: (map['notificationType'] ?? 'GENERIC').toString(),
      scheduleMode: EntityNotificationScheduleMode.values.firstWhere(
        (value) => value.name == (map['scheduleMode'] ?? '').toString(),
        orElse: () => EntityNotificationScheduleMode.absolute,
      ),
      enabled: map['enabled'] == true,
      absoluteAtUtc: DateTime.tryParse((map['absoluteAtUtc'] ?? '').toString())?.toUtc(),
      minutesBefore: (map['minutesBefore'] as num?)?.toInt(),
      updatedAtUtc: DateTime.tryParse((map['updatedAtUtc'] ?? '').toString())?.toUtc(),
    );
  }
}
