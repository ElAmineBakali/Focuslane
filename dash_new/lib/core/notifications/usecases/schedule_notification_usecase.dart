import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_result.dart';
import 'package:focuslane/core/notifications/notification_manager.dart';

class ScheduleNotificationUseCase {
  const ScheduleNotificationUseCase(this._manager);

  final NotificationManager _manager;

  Future<NotificationResult> call(NotificationIntent intent) {
    return _manager.scheduleIntent(intent);
  }
}

