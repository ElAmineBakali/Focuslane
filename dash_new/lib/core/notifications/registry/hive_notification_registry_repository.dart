import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mi_dashboard_personal/core/notifications/contracts/notification_repository.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_envelope.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_entity_ref.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_registry_entry.dart';

class HiveNotificationRegistryRepository implements NotificationRegistryRepository {
  HiveNotificationRegistryRepository(this._box);

  static const String boxName = 'notification_registry_v1';

  final Box<dynamic> _box;
  final _stream = StreamController<NotificationRegistryEntry>.broadcast();

  static Future<HiveNotificationRegistryRepository> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return HiveNotificationRegistryRepository(box);
  }

  @override
  Future<void> upsert(NotificationRegistryEntry entry) async {
    await _box.put(entry.notificationId, _toRecord(entry));
    _stream.add(entry);
  }

  @override
  Future<NotificationRegistryEntry?> findByNotificationId(String notificationId) async {
    final raw = _box.get(notificationId);
    if (raw is! Map) return null;
    return _fromRecord(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<NotificationRegistryEntry>> findByEntity(NotificationEntityRef entity) async {
    return _allEntries()
        .where((e) =>
            e.envelope.entity.module == entity.module &&
            e.envelope.entity.kind == entity.kind &&
            e.envelope.entity.id == entity.id)
        .toList(growable: false);
  }

  @override
  Future<List<NotificationRegistryEntry>> findByDedupeKey(String dedupeKey) async {
    return _allEntries().where((e) => e.dedupeKey == dedupeKey).toList(growable: false);
  }

  @override
  Future<List<NotificationRegistryEntry>> findByDedupePrefix(String dedupePrefix) async {
    return _allEntries().where((e) => e.dedupeKey.startsWith(dedupePrefix)).toList(growable: false);
  }

  @override
  Future<void> markOpened({required String notificationId, required DateTime openedAtUtc}) async {
    final current = await findByNotificationId(notificationId);
    if (current == null) return;
    await upsert(
      NotificationRegistryEntry(
        notificationId: current.notificationId,
        dedupeKey: current.dedupeKey,
        status: NotificationLifecycleStatus.opened,
        updatedAtUtc: openedAtUtc,
        envelope: current.envelope,
      ),
    );
  }

  @override
  Stream<NotificationRegistryEntry> watchLifecycle() => _stream.stream;

  List<NotificationRegistryEntry> _allEntries() {
    final out = <NotificationRegistryEntry>[];
    for (final dynamic raw in _box.values) {
      if (raw is! Map) continue;
      out.add(_fromRecord(Map<String, dynamic>.from(raw)));
    }
    return out;
  }

  Map<String, dynamic> _toRecord(NotificationRegistryEntry entry) {
    return {
      'notificationId': entry.notificationId,
      'dedupeKey': entry.dedupeKey,
      'status': entry.status.name,
      'updatedAtUtc': entry.updatedAtUtc.toUtc().toIso8601String(),
      'reason': entry.reason,
      'envelope': entry.envelope.toMap(),
    };
  }

  NotificationRegistryEntry _fromRecord(Map<String, dynamic> map) {
    return NotificationRegistryEntry(
      notificationId: (map['notificationId'] ?? '').toString(),
      dedupeKey: (map['dedupeKey'] ?? '').toString(),
      status: NotificationLifecycleStatus.values.firstWhere(
        (s) => s.name == (map['status'] ?? 'failed'),
        orElse: () => NotificationLifecycleStatus.failed,
      ),
      updatedAtUtc: DateTime.tryParse((map['updatedAtUtc'] ?? '').toString())?.toUtc() ?? DateTime.now().toUtc(),
      envelope: NotificationEnvelope.fromMap(
        Map<String, dynamic>.from(map['envelope'] as Map? ?? const {}),
      ),
      reason: map['reason']?.toString(),
    );
  }
}
