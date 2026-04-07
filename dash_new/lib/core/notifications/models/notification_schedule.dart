enum NotificationScheduleKind {
  immediate,
  oneShot,
  daily,
  weekly,
}

class NotificationSchedule {
  const NotificationSchedule({
    required this.kind,
    this.scheduledAtUtc,
    this.timezone,
    this.hour,
    this.minute,
    this.weekdays = const [],
  });

  final NotificationScheduleKind kind;
  final DateTime? scheduledAtUtc;
  final String? timezone;
  final int? hour;
  final int? minute;
  final List<int> weekdays;

  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'scheduledAtUtc': scheduledAtUtc?.toUtc().toIso8601String(),
    'timezone': timezone,
    'hour': hour,
    'minute': minute,
    'weekdays': weekdays,
  };

  factory NotificationSchedule.fromMap(Map<String, dynamic> map) {
    return NotificationSchedule(
      kind: NotificationScheduleKind.values.firstWhere(
        (k) => k.name == (map['kind'] ?? 'immediate'),
        orElse: () => NotificationScheduleKind.immediate,
      ),
      scheduledAtUtc: map['scheduledAtUtc'] == null
          ? null
          : DateTime.tryParse(map['scheduledAtUtc'].toString())?.toUtc(),
      timezone: map['timezone']?.toString(),
      hour: (map['hour'] as num?)?.toInt(),
      minute: (map['minute'] as num?)?.toInt(),
      weekdays: (map['weekdays'] is List)
          ? List<int>.from((map['weekdays'] as List).map((e) => (e as num).toInt()))
          : const [],
    );
  }
}
