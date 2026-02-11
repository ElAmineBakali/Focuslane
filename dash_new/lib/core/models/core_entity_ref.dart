import '../constants/core_routes.dart';

enum CoreEntityType {
  task,
  note,
  foodIntakeEntry,
  foodRecipe,
  foodFoodItem,
  gymSession,
  studySession,
  financeTransaction,
  calendarEvent,
}

class CoreEntityRef {
  final CoreEntityType type;
  final String id;
  final String module;
  final String dayId;
  final String routeName;
  final Map<String, dynamic> routeArgs;
  final String title;
  final String? subtitle;

  const CoreEntityRef({
    required this.type,
    required this.id,
    required this.module,
    required this.dayId,
    required this.routeName,
    this.routeArgs = const {},
    required this.title,
    this.subtitle,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'id': id,
        'module': module,
        'dayId': dayId,
        'routeName': routeName,
        'routeArgs': routeArgs,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
      };

  factory CoreEntityRef.fromMap(Map<String, dynamic> m) {
    CoreEntityType parseType(String raw) {
      return CoreEntityType.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => CoreEntityType.task,
      );
    }

    return CoreEntityRef(
      type: parseType(m['type']?.toString() ?? ''),
      id: m['id']?.toString() ?? '',
      module: m['module']?.toString() ?? '',
      dayId: m['dayId']?.toString() ?? '',
      routeName: m['routeName']?.toString() ?? CoreRoutes.home,
      routeArgs: Map<String, dynamic>.from(m['routeArgs'] ?? const {}),
      title: m['title']?.toString() ?? '',
      subtitle: m['subtitle']?.toString(),
    );
  }

  CoreEntityRef copyWith({
    CoreEntityType? type,
    String? id,
    String? module,
    String? dayId,
    String? routeName,
    Map<String, dynamic>? routeArgs,
    String? title,
    String? subtitle,
  }) {
    return CoreEntityRef(
      type: type ?? this.type,
      id: id ?? this.id,
      module: module ?? this.module,
      dayId: dayId ?? this.dayId,
      routeName: routeName ?? this.routeName,
      routeArgs: routeArgs ?? this.routeArgs,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  static CoreEntityRef forTask({
    required String id,
    required String dayId,
    required String title,
    String? subtitle,
  }) {
    return CoreEntityRef(
      type: CoreEntityType.task,
      id: id,
      module: 'tasks',
      dayId: dayId,
      routeName: CoreRoutes.tasks,
      routeArgs: {'highlightId': id},
      title: title,
      subtitle: subtitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreEntityRef) return false;
    return other.type == type &&
        other.id == id &&
        other.module == module &&
        other.dayId == dayId &&
        other.routeName == routeName &&
        _mapsEqual(other.routeArgs, routeArgs) &&
        other.title == title &&
        other.subtitle == subtitle;
  }

  @override
  int get hashCode => Object.hash(
        type,
        id,
        module,
        dayId,
        routeName,
        title,
        subtitle,
        routeArgs.entries
            .map((e) => e.key.hashCode ^ e.value.hashCode)
            .fold<int>(0, (a, b) => a ^ b),
      );

  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static CoreEntityRef forNote({
    required String id,
    required String title,
    String? subtitle,
  }) {
    return CoreEntityRef(
      type: CoreEntityType.note,
      id: id,
      module: 'notes',
      dayId: '',
      routeName: '/notes/editor',
      routeArgs: {'noteId': id},
      title: title,
      subtitle: subtitle,
    );
  }

  static CoreEntityRef forFoodIntake({
    required String entryId,
    required String dayId,
    required String name,
    String? subtitle,
  }) {
    return CoreEntityRef(
      type: CoreEntityType.foodIntakeEntry,
      id: entryId,
      module: 'food',
      dayId: dayId,
      routeName: CoreRoutes.foodDashboard,
      routeArgs: {'dayId': dayId},
      title: name,
      subtitle: subtitle,
    );
  }

  static CoreEntityRef forFoodRecipe({
    required String recipeId,
    required String title,
  }) {
    return CoreEntityRef(
      type: CoreEntityType.foodRecipe,
      id: recipeId,
      module: 'food',
      dayId: '',
      routeName: CoreRoutes.foodDashboard,
      routeArgs: {'recipeId': recipeId},
      title: title,
    );
  }

  static CoreEntityRef forFoodItem({
    required String foodId,
    required String title,
  }) {
    return CoreEntityRef(
      type: CoreEntityType.foodFoodItem,
      id: foodId,
      module: 'food',
      dayId: '',
      routeName: CoreRoutes.foodDashboard,
      routeArgs: {'foodId': foodId},
      title: title,
    );
  }

  static CoreEntityRef forGymSession({
    required String id,
    required String dayId,
    required String title,
    String? subtitle,
  }) {
    return CoreEntityRef(
      type: CoreEntityType.gymSession,
      id: id,
      module: 'gym',
      dayId: dayId,
      routeName: CoreRoutes.gymDashboard,
      routeArgs: {'sessionId': id},
      title: title,
      subtitle: subtitle,
    );
  }

  static CoreEntityRef forStudySession({
    required String id,
    required String dayId,
    required String title,
    String? subtitle,
  }) {
    return CoreEntityRef(
      type: CoreEntityType.studySession,
      id: id,
      module: 'study',
      dayId: dayId,
      routeName: CoreRoutes.studyDashboard,
      routeArgs: {'sessionId': id},
      title: title,
      subtitle: subtitle,
    );
  }

  static CoreEntityRef forFinanceTx({
    required String id,
    required String dayId,
    required String title,
    String? subtitle,
  }) {
    return CoreEntityRef(
      type: CoreEntityType.financeTransaction,
      id: id,
      module: 'finance',
      dayId: dayId,
      routeName: CoreRoutes.financeTransactions,
      routeArgs: {'txId': id},
      title: title,
      subtitle: subtitle,
    );
  }

  static CoreEntityRef forCalendarEvent({
    required String id,
    required String dayId,
    required String title,
    String? subtitle,
  }) {
    return CoreEntityRef(
      type: CoreEntityType.calendarEvent,
      id: id,
      module: 'calendar',
      dayId: dayId,
      routeName: '/calendar',
      routeArgs: {'eventId': id},
      title: title,
      subtitle: subtitle,
    );
  }
}
