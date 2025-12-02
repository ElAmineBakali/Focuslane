import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalStatus { planned, inProgress, paused, completed, abandoned }

class Goal {
  final String id;
  final String title;
  final String? description;
  final GoalStatus status;
  final DateTime? targetDate;

  /// progreso numérico (opcional): p.ej. minutos/h, %, unidades…
  final double? progress;        // actual
  final double? progressTarget;  // objetivo
  final String? unit;            // ej. "h", "%", "km"
  final List<String> tags;
  final String? colorHex;
  final int? order; // para persistir orden manual

  Goal({
    required this.id,
    required this.title,
    this.description,
    this.status = GoalStatus.planned,
    this.targetDate,
    this.progress,
    this.progressTarget,
    this.unit,
    this.tags = const [],
    this.colorHex,
    this.order,
  });

  Map<String, dynamic> toMap(String uid) => {
        'uid': uid,
        'title': title,
        'description': description,
        'status': status.name,
        'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
        'progress': progress,
        'progressTarget': progressTarget,
        'unit': unit,
        'tags': tags,
        'colorHex': colorHex,
      'order': order,
      };

  static Goal fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Goal(
      id: s.id,
      title: (d['title'] ?? '') as String,
      description: d['description'] as String?,
      status: GoalStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'planned'),
        orElse: () => GoalStatus.planned,
      ),
      targetDate: (d['targetDate'] as Timestamp?)?.toDate(),
      progress: (d['progress'] as num?)?.toDouble(),
      progressTarget: (d['progressTarget'] as num?)?.toDouble(),
      unit: d['unit'] as String?,
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      colorHex: d['colorHex'] as String?,
      order: (d['order'] as num?)?.toInt(),
    );
  }
}

/// ===== Sub-objetivo =====
/// Se guarda en: users/{uid}/goals/{goalId}/subgoals/{subId}
class SubGoal {
  final String id;
  final String title;
  final String? description;
  final GoalStatus status;         // reutilizamos enum
  final DateTime? dueDate;
  final double? progress;
  final double? progressTarget;
  final String? unit;
  final String? section;           // para agrupar en la vista
  final int order;

  const SubGoal({
    required this.id,
    required this.title,
    this.description,
    this.status = GoalStatus.planned,
    this.dueDate,
    this.progress,
    this.progressTarget,
    this.unit,
    this.section,
    this.order = 0,
  });

  bool get isDone => status == GoalStatus.completed;

  Map<String, dynamic> toMap() => {
        'title': title,
        if (description != null) 'description': description,
        'status': status.name,
        if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
        if (progress != null) 'progress': progress,
        if (progressTarget != null) 'progressTarget': progressTarget,
        if (unit != null) 'unit': unit,
        if (section != null) 'section': section,
        'order': order,
      };

  static SubGoal fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return SubGoal(
      id: s.id,
      title: (d['title'] ?? '') as String,
      description: d['description'] as String?,
      status: GoalStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'planned'),
        orElse: () => GoalStatus.planned,
      ),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      progress: (d['progress'] as num?)?.toDouble(),
      progressTarget: (d['progressTarget'] as num?)?.toDouble(),
      unit: d['unit'] as String?,
      section: d['section'] as String?,
      order: (d['order'] as num?)?.toInt() ?? 0,
    );
  }
}
