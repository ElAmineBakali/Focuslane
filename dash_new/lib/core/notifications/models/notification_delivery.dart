enum NotificationDeliveryKind {
  localOnly,
  pushOnly,
  hybrid,
}

enum NotificationPriority {
  low,
  normal,
  high,
}

class NotificationDelivery {
  const NotificationDelivery({
    required this.kind,
    required this.channel,
    this.priority = NotificationPriority.normal,
    this.ttlSeconds = 86400,
  });

  final NotificationDeliveryKind kind;
  final String channel;
  final NotificationPriority priority;
  final int ttlSeconds;

  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'channel': channel,
    'priority': priority.name,
    'ttlSeconds': ttlSeconds,
  };

  factory NotificationDelivery.fromMap(Map<String, dynamic> map) {
    return NotificationDelivery(
      kind: NotificationDeliveryKind.values.firstWhere(
        (k) => k.name == (map['kind'] ?? 'localOnly'),
        orElse: () => NotificationDeliveryKind.localOnly,
      ),
      channel: (map['channel'] ?? 'default').toString(),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == (map['priority'] ?? 'normal'),
        orElse: () => NotificationPriority.normal,
      ),
      ttlSeconds: (map['ttlSeconds'] as num?)?.toInt() ?? 86400,
    );
  }
}
