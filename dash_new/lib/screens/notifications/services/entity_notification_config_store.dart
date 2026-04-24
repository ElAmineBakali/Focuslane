import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:focuslane/screens/notifications/models/entity_notification_config.dart';

class EntityNotificationConfigStore {
  EntityNotificationConfigStore._();
  static final EntityNotificationConfigStore I = EntityNotificationConfigStore._();

  static const String _prefsKey = 'global_entity_notification_configs_v1';

  Future<Map<String, EntityNotificationConfig>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, EntityNotificationConfig>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String, EntityNotificationConfig>{};
      }

      final entries = <String, EntityNotificationConfig>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        final config = EntityNotificationConfig.fromMap(Map<String, dynamic>.from(item));
        if (config.entityKind.isEmpty || config.entityId.isEmpty) continue;
        entries[config.key] = config;
      }
      return entries;
    } catch (_) {
      return <String, EntityNotificationConfig>{};
    }
  }

  Future<void> saveAll(Map<String, EntityNotificationConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final list = configs.values.map((value) => value.toMap()).toList(growable: false);
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  Future<void> upsert(EntityNotificationConfig config) async {
    final all = await loadAll();
    all[config.key] = config;
    await saveAll(all);
  }

  Future<void> remove(String key) async {
    final all = await loadAll();
    all.remove(key);
    await saveAll(all);
  }
}
