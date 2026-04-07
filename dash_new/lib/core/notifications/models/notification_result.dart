class NotificationResult {
  const NotificationResult({
    required this.ok,
    required this.notificationId,
    this.code,
    this.message,
  });

  final bool ok;
  final String notificationId;
  final String? code;
  final String? message;

  factory NotificationResult.success(String notificationId) {
    return NotificationResult(ok: true, notificationId: notificationId);
  }

  factory NotificationResult.failure(
    String notificationId, {
    String? code,
    String? message,
  }) {
    return NotificationResult(
      ok: false,
      notificationId: notificationId,
      code: code,
      message: message,
    );
  }
}
