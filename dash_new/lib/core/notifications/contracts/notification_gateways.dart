import 'package:focuslane/core/notifications/models/notification_envelope.dart';

abstract class PushNotificationGateway {
  Future<void> enqueue(NotificationEnvelope envelope);
}

