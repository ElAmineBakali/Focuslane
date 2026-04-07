import 'package:mi_dashboard_personal/core/notifications/models/notification_entity_ref.dart';
import 'package:mi_dashboard_personal/core/notifications/notification_manager.dart';

class CancelNotificationUseCase {
  const CancelNotificationUseCase(this._manager);

  final NotificationManager _manager;

  Future<int> byEntity(NotificationEntityRef entity) {
    return _manager.cancelByEntity(entity);
  }

  Future<void> byNotificationId(String notificationId) async {
    await _manager.cancelByNotificationId(notificationId);
  }
}
