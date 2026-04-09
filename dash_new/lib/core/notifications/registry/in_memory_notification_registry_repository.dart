import 'dart:async';

import 'package:focuslane/core/notifications/contracts/notification_repository.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_registry_entry.dart';

class InMemoryNotificationRegistryRepository
    implements NotificationRegistryRepository {
  final Map<String, NotificationRegistryEntry> _store = {};
  final _stream = StreamController<NotificationRegistryEntry>.broadcast();

  @override
  Future<void> upsert(NotificationRegistryEntry entry) async {
    _store[entry.notificationId] = entry;
    _stream.add(entry);
  }

  @override
  Future<NotificationRegistryEntry?> findByNotificationId(String notificationId) async {
    return _store[notificationId];
  }

  @override
  Future<List<NotificationRegistryEntry>> findByEntity(NotificationEntityRef entity) async {
    return _store.values
        .where((e) =>
            e.envelope.entity.module == entity.module &&
            e.envelope.entity.kind == entity.kind &&
            e.envelope.entity.id == entity.id)
        .toList(growable: false);
  }

  @override
  Future<List<NotificationRegistryEntry>> findByDedupeKey(String dedupeKey) async {
    return _store.values.where((e) => e.dedupeKey == dedupeKey).toList(growable: false);
  }

  @override
  Future<List<NotificationRegistryEntry>> findByDedupePrefix(String dedupePrefix) async {
    return _store.values
        .where((e) => e.dedupeKey.startsWith(dedupePrefix))
        .toList(growable: false);
  }

  @override
  Future<void> markOpened({required String notificationId, required DateTime openedAtUtc}) async {
    final current = _store[notificationId];
    if (current == null) return;
    final updated = NotificationRegistryEntry(
      notificationId: current.notificationId,
      dedupeKey: current.dedupeKey,
      status: NotificationLifecycleStatus.opened,
      updatedAtUtc: openedAtUtc,
      envelope: current.envelope,
    );
    await upsert(updated);
  }

  @override
  Stream<NotificationRegistryEntry> watchLifecycle() => _stream.stream;
}

