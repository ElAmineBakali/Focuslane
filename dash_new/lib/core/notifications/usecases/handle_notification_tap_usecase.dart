import 'package:mi_dashboard_personal/core/notifications/notification_manager.dart';

class HandleNotificationTapUseCase {
  const HandleNotificationTapUseCase(this._manager);

  final NotificationManager _manager;

  Future<void> call(String rawPayload) {
    return _manager.handleTapPayload(rawPayload);
  }
}
