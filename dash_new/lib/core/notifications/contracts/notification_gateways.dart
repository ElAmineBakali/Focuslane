import 'package:mi_dashboard_personal/core/notifications/models/notification_envelope.dart';

abstract class PushNotificationGateway {
  Future<void> enqueue(NotificationEnvelope envelope);
}
