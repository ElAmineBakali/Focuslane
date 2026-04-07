import 'package:flutter/widgets.dart';
import 'package:mi_dashboard_personal/core/notifications/notification_manager.dart';
import 'package:mi_dashboard_personal/core/notifications/notifications_bootstrap.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_entity_ref.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_intent.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_result.dart';

class NotificationsFacade {
  NotificationsFacade._();

  static final NotificationsFacade I = NotificationsFacade._();

  NotificationManager get _manager => NotificationsBootstrap.instance.manager;

  Future<void> init() => NotificationsBootstrap.instance.init();

  Future<NotificationResult> scheduleIntent(NotificationIntent intent) {
    return _manager.scheduleIntent(intent);
  }

  Future<NotificationResult> cancelByNotificationId(String notificationId) {
    return _manager.cancelByNotificationId(notificationId);
  }

  Future<int> cancelByDedupeKey(String dedupeKey) {
    return _manager.cancelByDedupeKey(dedupeKey);
  }

  Future<int> cancelByDedupePrefix(String dedupePrefix) {
    return _manager.cancelByDedupePrefix(dedupePrefix);
  }

  Future<int> cancelByModule(NotificationModule module) {
    return _manager.cancelByModule(module);
  }

  Future<int> cancelByEntity(NotificationEntityRef entity) {
    return _manager.cancelByEntity(entity);
  }

  void attachNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _manager.attachNavigatorKey(navigatorKey);
  }
}
