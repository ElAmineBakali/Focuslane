import 'package:collection/collection.dart';

import 'core_entity_ref.dart';

enum CoreRecommendationSeverity { low, med, high }

enum CoreActionType {
  createTask,
  createCalendarEvent,
  addShoppingItem,
  addMealPlanSlot,
  createFinanceTransactionDraft,
  createStudySessionPreset,
}

class CoreAction {
  final String id;
  final String label;
  final CoreActionType type;
  final Map<String, dynamic> payload;
  final bool confirmRequired;

  const CoreAction({
    required this.id,
    required this.label,
    required this.type,
    this.payload = const {},
    this.confirmRequired = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'type': type.name,
        'payload': payload,
        'confirmRequired': confirmRequired,
      };

  factory CoreAction.fromMap(Map<String, dynamic> m) {
    CoreActionType parseType(String raw) {
      return CoreActionType.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => CoreActionType.createTask,
      );
    }

    return CoreAction(
      id: m['id']?.toString() ?? '',
      label: m['label']?.toString() ?? '',
      type: parseType(m['type']?.toString() ?? ''),
      payload: Map<String, dynamic>.from(m['payload'] ?? const {}),
      confirmRequired: m['confirmRequired'] == true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreAction) return false;
    return other.id == id &&
        other.label == label &&
        other.type == type &&
        const MapEquality<String, dynamic>().equals(other.payload, payload) &&
        other.confirmRequired == confirmRequired;
  }

  @override
  int get hashCode => Object.hash(
        id,
        label,
        type,
        const MapEquality<String, dynamic>().hash(payload),
        confirmRequired,
      );
}

class CoreRecommendation {
  final String id;
  final String dayId;
  final String title;
  final String message;
  final CoreRecommendationSeverity severity;
  final List<CoreEntityRef> references;
  final List<CoreAction> actions;
  final String? actionRoute;
  final String? actionLabel;

  const CoreRecommendation({
    required this.id,
    required this.dayId,
    required this.title,
    required this.message,
    required this.severity,
    this.references = const [],
    this.actions = const [],
    this.actionRoute,
    this.actionLabel,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'dayId': dayId,
        'title': title,
        'message': message,
        'severity': severity.name,
        'references': references.map((e) => e.toMap()).toList(),
        'actions': actions.map((e) => e.toMap()).toList(),
        'actionRoute': actionRoute,
        'actionLabel': actionLabel,
      };

  factory CoreRecommendation.fromMap(Map<String, dynamic> m) {
    final refs = ((m['references'] as List?) ?? const [])
        .map((e) => CoreEntityRef.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final acts = ((m['actions'] as List?) ?? const [])
        .map((e) => CoreAction.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return CoreRecommendation(
      id: m['id']?.toString() ?? '',
      dayId: m['dayId']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      message: m['message']?.toString() ?? '',
      severity: CoreRecommendationSeverity.values.firstWhere(
        (e) => e.name == (m['severity'] ?? 'low'),
        orElse: () => CoreRecommendationSeverity.low,
      ),
      references: refs,
      actions: acts,
      actionRoute: m['actionRoute'] as String?,
      actionLabel: m['actionLabel'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreRecommendation) return false;
    final listEqRef = const ListEquality<CoreEntityRef>();
    final listEqAct = const ListEquality<CoreAction>();
    return other.id == id &&
        other.dayId == dayId &&
        other.title == title &&
        other.message == message &&
        other.severity == severity &&
        listEqRef.equals(other.references, references) &&
        listEqAct.equals(other.actions, actions) &&
        other.actionRoute == actionRoute &&
        other.actionLabel == actionLabel;
  }

  @override
  int get hashCode => Object.hash(
        id,
        dayId,
        title,
        message,
        severity,
        const ListEquality<CoreEntityRef>().hash(references),
        const ListEquality<CoreAction>().hash(actions),
        actionRoute,
        actionLabel,
      );
}