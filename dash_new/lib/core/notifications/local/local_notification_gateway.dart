enum LocalRepeatRule {
  none,
  daily,
  weekly,
}

class PendingLocalNotification {
  const PendingLocalNotification({
    required this.localId,
    required this.payload,
  });

  final int localId;
  final String? payload;
}

abstract class LocalNotificationGateway {
  Future<void> init();

  Future<void> showNow({
    required int localId,
    required String title,
    required String body,
    required String payload,
    required String channel,
  });

  Future<void> zonedSchedule({
    required int localId,
    required DateTime whenUtc,
    required String title,
    required String body,
    required String payload,
    required String channel,
    required bool allowWhileIdle,
    required LocalRepeatRule repeatRule,
    List<int> weekdays = const [],
  });

  Future<void> cancel(int localId);
  Future<List<PendingLocalNotification>> pending();
}
