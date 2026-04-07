import 'package:mi_dashboard_personal/core/notifications/contracts/notification_gateways.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_envelope.dart';

class NoopPushNotificationGateway implements PushNotificationGateway {
  @override
  Future<void> enqueue(NotificationEnvelope envelope) async {}
}
