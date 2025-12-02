import 'package:cloud_firestore/cloud_firestore.dart';

enum SkillLevel { novice, intermediate, advanced, expert }
enum SessionMode { timer, pomodoro, manual }
enum ProjectState { idea, doing, blocked, done }

String skillLevelLabel(SkillLevel l) {
  switch (l) {
    case SkillLevel.novice: return 'Novato';
    case SkillLevel.intermediate: return 'Intermedio';
    case SkillLevel.advanced: return 'Avanzado';
    case SkillLevel.expert: return 'Experto';
  }
}

class Skill {
  final String id;
  final String name;
  final String description;
  final String motivation;
  final String desiredOutcome;
  final String context; // herramientas/recursos/bloqueos resumen
  final SkillLevel currentLevel;
  final SkillLevel targetLevel;
  final DateTime? targetDate;

  final double totalHours;
  final int streakDays;
  final List<String> tags;

  final Map<String, String> metricsConfig; // nombre -> unidad/ayuda

  final DateTime createdAt;
  final DateTime updatedAt;

  Skill({
    required this.id,
    required this.name,
    this.description = '',
    this.motivation = '',
    this.desiredOutcome = '',
    this.context = '',
    this.currentLevel = SkillLevel.novice,
    this.targetLevel = SkillLevel.intermediate,
    this.targetDate,
    this.totalHours = 0.0,
    this.streakDays = 0,
    this.tags = const [],
    this.metricsConfig = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'motivation': motivation,
        'desiredOutcome': desiredOutcome,
        'context': context,
        'currentLevel': currentLevel.name,
        'targetLevel': targetLevel.name,
        'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
        'totalHours': totalHours,
        'streakDays': streakDays,
        'tags': tags,
        'metricsConfig': metricsConfig,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static Skill fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    SkillLevel lv(String k, SkillLevel def) {
      final v = (d[k] ?? def.name).toString();
      return SkillLevel.values.firstWhere(
        (e) => e.name == v,
        orElse: () => def,
      );
    }

    return Skill(
      id: s.id,
      name: (d['name'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      motivation: (d['motivation'] ?? '') as String,
      desiredOutcome: (d['desiredOutcome'] ?? '') as String,
      context: (d['context'] ?? '') as String,
      currentLevel: lv('currentLevel', SkillLevel.novice),
      targetLevel: lv('targetLevel', SkillLevel.intermediate),
      targetDate: (d['targetDate'] as Timestamp?)?.toDate(),
      totalHours: ((d['totalHours'] ?? 0) as num).toDouble(),
      streakDays: (d['streakDays'] ?? 0) as int,
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      metricsConfig: (d['metricsConfig'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? const {},
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class SubSkill {
  final String id;
  final String name;
  final String? parentId;
  final bool unlocked;
  final int order;

  SubSkill({
    required this.id,
    required this.name,
    this.parentId,
    this.unlocked = false,
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'parentId': parentId,
        'unlocked': unlocked,
        'order': order,
      };

  static SubSkill fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return SubSkill(
      id: s.id,
      name: (d['name'] ?? '') as String,
      parentId: d['parentId'] as String?,
      unlocked: (d['unlocked'] ?? false) as bool,
      order: (d['order'] ?? 0) as int,
    );
  }
}

class PracticeSession {
  final String id;
  final String skillId;
  final String? subSkillId;
  final SessionMode mode;
  final DateTime start;
  final DateTime end;
  final int minutes;
  final String objective;
  final int difficulty; // 1..5
  final int energy;     // 1..5
  final String notes;
  final Map<String, num> metrics; // según config de la skill
  final Map<String, int> rubric;  // técnica, consistencia, creatividad, teoría, presentación
  final String? nextMicroTask;

  PracticeSession({
    required this.id,
    required this.skillId,
    this.subSkillId,
    this.mode = SessionMode.timer,
    required this.start,
    required this.end,
    required this.minutes,
    this.objective = '',
    this.difficulty = 3,
    this.energy = 3,
    this.notes = '',
    this.metrics = const <String, num>{},
    this.rubric  = const <String, int>{},
    this.nextMicroTask,
  });

  Map<String, dynamic> toMap() => {
    'skillId': skillId,
    'subSkillId': subSkillId,
    'mode': mode.name,
    'start': Timestamp.fromDate(start),
    'end': Timestamp.fromDate(end),
    'minutes': minutes,
    'objective': objective,
    'difficulty': difficulty,
    'energy': energy,
    'notes': notes,
    'metrics': metrics,
    'rubric': rubric,
    'nextMicroTask': nextMicroTask,
  };

  static PracticeSession fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return PracticeSession(
      id: s.id,
      skillId: (d['skillId'] ?? '') as String,
      subSkillId: d['subSkillId'] as String?,
      mode: SessionMode.values.firstWhere(
        (e) => e.name == (d['mode'] ?? 'timer'),
        orElse: () => SessionMode.timer,
      ),
      start: (d['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      end: (d['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
      minutes: ((d['minutes'] ?? 0) as num).toInt(),
      objective: (d['objective'] ?? '') as String,
      difficulty: (d['difficulty'] ?? 3) as int,
      energy: (d['energy'] ?? 3) as int,
      notes: (d['notes'] ?? '') as String,
      metrics: (d['metrics'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as num))) ??
              const <String, num>{},
      rubric: (d['rubric'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
              const <String, int>{},
      nextMicroTask: d['nextMicroTask'] as String?,
    );
  }
}


class Project {
  final String id;
  final String skillId;
  final String title;
  final String description;
  final ProjectState state;
  final DateTime? dueDate;
  final List<ChecklistItem> checklist;
  final List<String> evidenceUrls;

  Project({
    required this.id,
    required this.skillId,
    required this.title,
    this.description = '',
    this.state = ProjectState.idea,
    this.dueDate,
    this.checklist = const [],
    this.evidenceUrls = const [],
  });

  Map<String, dynamic> toMap() => {
        'skillId': skillId,
        'title': title,
        'description': description,
        'state': state.name,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'checklist': checklist.map((e) => e.toMap()).toList(),
        'evidenceUrls': evidenceUrls,
      };

  static Project fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return Project(
      id: s.id,
      skillId: (d['skillId'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      state: ProjectState.values.firstWhere(
        (e) => e.name == (d['state'] ?? 'idea'),
        orElse: () => ProjectState.idea,
      ),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      checklist: (d['checklist'] as List?)
              ?.map((e) => ChecklistItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      evidenceUrls:
          (d['evidenceUrls'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }
}

class ChecklistItem {
  final String text;
  final bool done;
  ChecklistItem({required this.text, this.done = false});
  Map<String, dynamic> toMap() => {'text': text, 'done': done};
  static ChecklistItem fromMap(Map<String, dynamic> m) =>
      ChecklistItem(text: (m['text'] ?? '') as String, done: (m['done'] ?? false) as bool);
}

class ResourceLink {
  final String id;
  final String title;
  final String url;
  final String? note;
  final String? subSkillId;
  ResourceLink({
    required this.id,
    required this.title,
    required this.url,
    this.note,
    this.subSkillId,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'url': url,
        'note': note,
        'subSkillId': subSkillId,
      };

  static ResourceLink fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return ResourceLink(
      id: s.id,
      title: (d['title'] ?? '') as String,
      url: (d['url'] ?? '') as String,
      note: d['note'] as String?,
      subSkillId: d['subSkillId'] as String?,
    );
  }
}
