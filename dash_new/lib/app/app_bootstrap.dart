import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mi_dashboard_personal/core/config/firebase_options.dart';
import 'package:mi_dashboard_personal/core/notifications/local/android_channel_catalog.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_action.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_content.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_delivery.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_entity_ref.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_intent.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_schedule.dart';
import 'package:mi_dashboard_personal/core/config/supabase_config.dart';
import 'package:mi_dashboard_personal/core/notifications/notifications_facade.dart';
import 'package:mi_dashboard_personal/core/notifications/notifications_bootstrap.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> bootstrapApp() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await NotificationsBootstrap.instance.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
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
      await FirebaseFirestore.instance.enablePersistence();
      FirebaseFirestore.instance.settings = const Settings(
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (_) {}
}