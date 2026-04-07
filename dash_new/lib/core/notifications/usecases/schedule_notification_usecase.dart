import 'package:mi_dashboard_personal/core/notifications/models/notification_intent.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_result.dart';
import 'package:mi_dashboard_personal/core/notifications/notification_manager.dart';

class ScheduleNotificationUseCase {
  const ScheduleNotificationUseCase(this._manager);

  final NotificationManager _manager;

  Future<NotificationResult> call(NotificationIntent intent) {
    return _manager.scheduleIntent(intent);
  }
}
