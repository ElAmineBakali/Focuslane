import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:focuslane/core/config/firebase_options.dart';
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/config/supabase_config.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:focuslane/core/notifications/notifications_bootstrap.dart';
import 'package:focuslane/core/notifications/push/notification_diagnostics_service.dart';
import 'package:focuslane/core/notifications/router/notification_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> _handlePushTap(RemoteMessage msg) async {
  await NotificationDiagnosticsService.I.recordPushReceived(msg, source: 'tap');
  if (msg.data.isEmpty) return;
  final payload = jsonEncode(msg.data);
  await NotificationsBootstrap.instance.manager.handleTapPayload(
    payload,
    source: NotificationTapSource.push,
  );
}

Future<void> bootstrapApp() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationsBootstrap.instance.init();

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  } catch (_) {
    // App Check can fail in web/dev setups; the app should still boot.
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  if (!kIsWeb) {
    try {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) async {
        await _handlePushTap(msg);
      });

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        await _handlePushTap(initialMessage);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
        await NotificationDiagnosticsService.I.recordPushReceived(
          msg,
          source: 'foreground',
        );
        final notification = msg.notification;
        if (notification == null) {
          return;
        }
        final now = DateTime.now();
        final epoch = now.toUtc().millisecondsSinceEpoch;
        await NotificationsFacade.I.scheduleIntent(
          NotificationIntent(
            module: NotificationModule.system,
            type: 'FCM_FOREGROUND_MESSAGE',
            entity: const NotificationEntityRef(
              module: NotificationModule.system,
              kind: 'fcm_message',
              id: 'foreground',
            ),
            content: NotificationContent(
              title: notification.title ?? 'Mensaje',
              body: notification.body ?? '',
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
            dedupeKey: 'system:fcm:foreground:$epoch',
            userId: 'system',
            source: 'app.bootstrap.onMessage',
            notificationId: 'ntf_system_fcm_foreground_$epoch',
          ),
        );
      });
    } catch (_) {
      // FCM may not be available in certain contexts.
    }
  }

  try {
    if (kIsWeb) {
      await fb_auth.FirebaseAuth.instance.setPersistence(
        fb_auth.Persistence.LOCAL,
      );
    }
  } catch (_) {}

  try {
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (_) {}
}
