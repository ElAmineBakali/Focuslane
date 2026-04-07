abstract class NotificationLogger {
  void info(String message, {Map<String, Object?> data = const {}});
  void warning(String message, {Map<String, Object?> data = const {}});
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, Object?> data = const {}});
}

class DebugPrintNotificationLogger implements NotificationLogger {
  @override
  void info(String message, {Map<String, Object?> data = const {}}) {
    // ignore: avoid_print
    print('[Notifications][INFO] $message data=$data');
  }

  @override
  void warning(String message, {Map<String, Object?> data = const {}}) {
    // ignore: avoid_print
    print('[Notifications][WARN] $message data=$data');
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, Object?> data = const {}}) {
    // ignore: avoid_print
    print('[Notifications][ERROR] $message error=$error data=$data');
  }
}
