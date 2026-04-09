import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_registry_entry.dart';

abstract class NotificationRegistryRepository {
  Future<void> upsert(NotificationRegistryEntry entry);
  Future<NotificationRegistryEntry?> findByNotificationId(String notificationId);
  Future<List<NotificationRegistryEntry>> findByEntity(NotificationEntityRef entity);
  Future<List<NotificationRegistryEntry>> findByDedupeKey(String dedupeKey);
  Future<List<NotificationRegistryEntry>> findByDedupePrefix(String dedupePrefix);
  Future<void> markOpened({required String notificationId, required DateTime openedAtUtc});
  Stream<NotificationRegistryEntry> watchLifecycle();
}

