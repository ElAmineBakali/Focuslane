import 'package:mi_dashboard_personal/core/notifications/contracts/notification_repository.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_envelope.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_registry_entry.dart';

class DedupePolicy {
  DedupePolicy(this._registry);

  final NotificationRegistryRepository _registry;

  Future<bool> isDuplicate(NotificationEnvelope envelope) async {
    final entries = await _registry.findByDedupeKey(envelope.dedupeKey);
    return entries.any((e) =>
        e.status == NotificationLifecycleStatus.created ||
        e.status == NotificationLifecycleStatus.scheduled);
  }
}
