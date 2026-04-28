import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationDiagnosticsSnapshot {
  const NotificationDiagnosticsSnapshot({
    required this.permissionGranted,
    required this.permissionLabel,
    required this.fcmTokenRegistered,
    required this.activeTokenCount,
    required this.lastPushReceived,
    required this.lastError,
    required this.exactAlarmsAvailable,
    required this.explanation,
  });

  final bool permissionGranted;
  final String permissionLabel;
  final bool fcmTokenRegistered;
  final int? activeTokenCount;
  final String? lastPushReceived;
  final String? lastError;
  final bool? exactAlarmsAvailable;
  final String explanation;
}

class NotificationDiagnosticsService {
  NotificationDiagnosticsService._();

  static final NotificationDiagnosticsService I =
      NotificationDiagnosticsService._();

  static const MethodChannel _exactAlarmChannel =
      MethodChannel('exact_alarm_channel');
  static const String _lastPushKey = 'notifications_diag_last_push_v1';
  static const String _lastErrorKey = 'notifications_diag_last_error_v1';

  Future<NotificationDiagnosticsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await _notificationSettings();
    final token = await _safeFcmToken();
    final activeTokens = await _activeTokenCount();
    final exact = await _exactAlarmStatus();
    final granted = settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    return NotificationDiagnosticsSnapshot(
      permissionGranted: granted,
      permissionLabel: _permissionLabel(settings.authorizationStatus),
      fcmTokenRegistered: token != null && token.trim().isNotEmpty,
      activeTokenCount: activeTokens,
      lastPushReceived: prefs.getString(_lastPushKey),
      lastError: prefs.getString(_lastErrorKey),
      exactAlarmsAvailable: exact,
      explanation: _explanation(
        permissionGranted: granted,
        tokenRegistered: token != null && token.trim().isNotEmpty,
      ),
    );
  }

  Future<void> recordPushReceived(
    RemoteMessage message, {
    required String source,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final notification = message.notification;
    final title = notification?.title ??
        message.data['title']?.toString() ??
        message.data['notificationId']?.toString() ??
        'Push recibido';
    await prefs.setString(
      _lastPushKey,
      '${_fmt(now)} · $source · $title',
    );
  }

  Future<void> recordError(Object error) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastErrorKey, '${_fmt(DateTime.now())} · $error');
  }

  Future<void> sendTestPush() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null || user.uid.isEmpty) {
      final error = StateError('Inicia sesión para enviar un push de prueba.');
      await recordError(error);
      throw error;
    }

    final now = DateTime.now().toUtc();
    final epoch = now.millisecondsSinceEpoch;
    final envelope = {
      'v': 1,
      'notificationId': 'ntf_diag_push_test_$epoch',
      'dedupeKey': 'diagnostics:push_test:$epoch',
      'module': 'system',
      'type': 'DIAGNOSTIC_PUSH_TEST',
      'entity': {
        'module': 'system',
        'kind': 'diagnostic',
        'id': 'push_test',
      },
      'content': {
        'title': 'FocusLane · push de prueba',
        'body': 'FCM está entregando notificaciones correctamente.',
      },
      'action': {
        'kind': 'openRoute',
        'route': '/notifications',
        'params': <String, String>{},
      },
      'schedule': {
        'kind': 'immediate',
        'scheduledAtUtc': now.toIso8601String(),
        'timezone': DateTime.now().timeZoneName,
        'weekdays': <int>[],
      },
      'delivery': {
        'kind': 'pushOnly',
        'channel': AndroidChannelCatalog.defaultChannel,
        'priority': 'high',
        'ttlSeconds': 3600,
      },
      'meta': {
        'userId': user.uid,
        'source': 'notifications.diagnostics',
        'createdAtUtc': now.toIso8601String(),
        'traceId': 'trace_diag_push_$epoch',
      },
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notification_outbox')
        .doc('diag_push_test_$epoch')
        .set({
      'status': 'queued',
      'kind': 'diagnostic_push_test',
      'envelope': envelope,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendLocalTest() async {
    final userId = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';
    final now = DateTime.now();
    final epoch = now.toUtc().millisecondsSinceEpoch;
    final result = await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.system,
        type: 'DIAGNOSTIC_LOCAL_TEST',
        entity: const NotificationEntityRef(
          module: NotificationModule.system,
          kind: 'diagnostic',
          id: 'local_test',
        ),
        content: const NotificationContent(
          title: 'FocusLane · prueba local',
          body: 'La notificación local inmediata funciona.',
        ),
        action: const NotificationAction(kind: NotificationActionKind.none),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.immediate,
          scheduledAtUtc: now.toUtc(),
          timezone: now.timeZoneName,
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.localOnly,
          channel: AndroidChannelCatalog.defaultChannel,
          priority: NotificationPriority.normal,
        ),
        dedupeKey: 'diagnostics:local_test:$epoch',
        userId: userId,
        source: 'notifications.diagnostics',
        notificationId: 'ntf_diag_local_test_$epoch',
      ),
    );
    if (!result.ok) {
      final error = StateError(result.message ?? result.code ?? 'local_test_failed');
      await recordError(error);
      throw error;
    }
  }

  Future<NotificationSettings> _notificationSettings() async {
    try {
      return FirebaseMessaging.instance.getNotificationSettings();
    } catch (e) {
      await recordError(e);
      rethrow;
    }
  }

  Future<String?> _safeFcmToken() async {
    if (kIsWeb) return null;
    try {
      return FirebaseMessaging.instance.getToken();
    } catch (e) {
      await recordError(e);
      return null;
    }
  }

  Future<int?> _activeTokenCount() async {
    final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('push_tokens')
          .where('isActive', isEqualTo: true)
          .get();
      return snap.docs.length;
    } catch (e) {
      await recordError(e);
      return null;
    }
  }

  Future<bool?> _exactAlarmStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await _exactAlarmChannel.invokeMethod<bool>(
        'canScheduleExactAlarms',
      );
    } catch (e) {
      await recordError(e);
      return null;
    }
  }

  String _permissionLabel(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'Concedido';
      case AuthorizationStatus.provisional:
        return 'Provisional';
      case AuthorizationStatus.denied:
        return 'Denegado';
      case AuthorizationStatus.notDetermined:
        return 'Sin decidir';
    }
  }

  String _explanation({
    required bool permissionGranted,
    required bool tokenRegistered,
  }) {
    final missing = <String>[];
    if (!permissionGranted) {
      missing.add('permiso de notificaciones');
    }
    if (!tokenRegistered) {
      missing.add('token FCM');
    }
    if (missing.isEmpty) {
      return 'Los recordatorios importantes se entregan por FCM. Las alarmas exactas solo afectan a timers locales y pruebas.';
    }
    return 'Falta ${missing.join(' y ')}. Los recordatorios push necesitan ese estado activo; las alarmas exactas no son necesarias para tareas, calendario, estudio, finanzas, comida, hábitos o gym planificado.';
  }

  String _fmt(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
