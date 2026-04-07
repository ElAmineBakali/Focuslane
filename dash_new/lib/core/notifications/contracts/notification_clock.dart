abstract class NotificationClock {
  DateTime nowUtc();
}

class SystemNotificationClock implements NotificationClock {
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
