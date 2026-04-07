enum NotificationModule {
  tasks,
  habits,
  calendar,
  finance,
  study,
  food,
  gym,
  notes,
  system,
}

class NotificationEntityRef {
  const NotificationEntityRef({
    required this.module,
    required this.kind,
    required this.id,
  });

  final NotificationModule module;
  final String kind;
  final String id;

  Map<String, dynamic> toMap() => {
    'module': module.name,
    'kind': kind,
    'id': id,
  };

  factory NotificationEntityRef.fromMap(Map<String, dynamic> map) {
    return NotificationEntityRef(
      module: NotificationModule.values.firstWhere(
        (m) => m.name == (map['module'] ?? 'system'),
        orElse: () => NotificationModule.system,
      ),
      kind: (map['kind'] ?? '').toString(),
      id: (map['id'] ?? '').toString(),
    );
  }
}
