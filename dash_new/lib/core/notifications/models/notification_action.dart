enum NotificationActionKind {
  openRoute,
  none,
}

class NotificationAction {
  const NotificationAction({
    required this.kind,
    this.route,
    this.params = const {},
  });

  final NotificationActionKind kind;
  final String? route;
  final Map<String, String> params;

  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'route': route,
    'params': params,
  };

  factory NotificationAction.fromMap(Map<String, dynamic> map) {
    return NotificationAction(
      kind: NotificationActionKind.values.firstWhere(
        (k) => k.name == (map['kind'] ?? 'none'),
        orElse: () => NotificationActionKind.none,
      ),
      route: map['route']?.toString(),
      params: (map['params'] is Map)
          ? Map<String, String>.from(map['params'] as Map)
          : const {},
    );
  }
}
