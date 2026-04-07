class NotificationContent {
  const NotificationContent({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
  };

  factory NotificationContent.fromMap(Map<String, dynamic> map) {
    return NotificationContent(
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
    );
  }
}
