import 'package:mi_dashboard_personal/core/notifications/models/notification_delivery.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_envelope.dart';

class PushDispatchPlanner {
  const PushDispatchPlanner();

  bool shouldEnqueue(NotificationEnvelope envelope) {
    return envelope.delivery.kind == NotificationDeliveryKind.pushOnly ||
        envelope.delivery.kind == NotificationDeliveryKind.hybrid;
  }
}
