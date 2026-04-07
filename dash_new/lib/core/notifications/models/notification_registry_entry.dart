import 'package:mi_dashboard_personal/core/notifications/models/notification_envelope.dart';

enum NotificationLifecycleStatus {
  created,
  scheduled,
  opened,
  cancelled,
  failed,
  skippedDuplicate,
}

class NotificationRegistryEntry {
  const NotificationRegistryEntry({
    required this.notificationId,
    required this.dedupeKey,
    required this.status,
    required this.updatedAtUtc,
    required this.envelope,
    this.reason,
  });

  final String notificationId;
  final String dedupeKey;
  final NotificationLifecycleStatus status;
  final DateTime updatedAtUtc;
  final NotificationEnvelope envelope;
  final String? reason;
}
