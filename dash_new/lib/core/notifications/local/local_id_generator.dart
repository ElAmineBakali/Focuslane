import 'package:focuslane/core/notifications/models/notification_envelope.dart';

abstract class LocalIdGenerator {
  int generate(NotificationEnvelope envelope);
  int generateFromNotificationId(String notificationId);
}

class FnvLocalIdGenerator implements LocalIdGenerator {
  @override
  int generate(NotificationEnvelope envelope) {
    return generateFromNotificationId(envelope.notificationId);
  }

  @override
  int generateFromNotificationId(String notificationId) {
    const int fnvPrime = 16777619;
    const int fnvOffset = 2166136261;
    int hash = fnvOffset;
    final input = notificationId;
    for (int i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}

