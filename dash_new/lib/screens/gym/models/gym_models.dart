import 'package:flutter/material.dart';

class Routine {
  final String id;
  final String name;
  final String? description;
  final bool isDefault;
  final String splitType; // 'PPL' | 'UL' | 'FB' | 'Custom'
  final int restSecDefault;
  final String? colorHex;

  const Routine({
    required this.id,
    required this.name,
    this.description,
    this.isDefault = false,
    this.splitType = 'Custom',
    this.restSecDefault = 90,
    this.colorHex,
  });

  Color get color => Color(int.tryParse(colorHex ?? '') ?? Colors.blue.value);

  static Routine fromMap(String id, Map<String, dynamic> m) {
    return Routine(
      id: id,
      name: (m['name'] ?? '') as String,
      description: m['description'] as String?,
      isDefault: (m['isDefault'] ?? false) as bool,
      splitType: (m['splitType'] ?? 'Custom') as String,
      restSecDefault: (m['restSecDefault'] ?? 90) as int,
      colorHex: m['colorHex'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (description != null) 'description': description,
    'isDefault': isDefault,
    'splitType': splitType,
    'restSecDefault': restSecDefault,
    if (colorHex != null) 'colorHex': colorHex,
  };

  Routine copyWith({
    String? name,
    String? description,
    bool? isDefault,
    String? splitType,
    int? restSecDefault,
    String? colorHex,
  }) {
    return Routine(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      splitType: splitType ?? this.splitType,
      restSecDefault: restSecDefault ?? this.restSecDefault,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

class RoutineDay {
  final String id;
  final String name;
  final int order;
  final String? icon;

  const RoutineDay({
    required this.id,
    required this.name,
    required this.order,
    this.icon,
  });

  static RoutineDay fromMap(String id, Map<String, dynamic> m) {
    return RoutineDay(
      id: id,
      name: (m['name'] ?? '') as String,
      order: (m['order'] ?? 0) as int,
      icon: m['icon'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'order': order,
    if (icon != null) 'icon': icon,
  };
}

class RoutineExercise {
  final String id;
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final String category;
  final int targetSets;
  final int targetReps;
  final int? restSec;
  final int order;
  final String? tempo; // ej. "3-1-1"
  final double? targetRPE;
  final double? targetPercent1RM;
  final String? notes;
  
  // 🔥 Nuevos campos para progresiones automáticas
  final bool autoProgressionEnabled;
  final String? progressionType; // 'weight' | 'reps' | 'rpe'
  final double? progressionIncrement; // ej: 2.5 kg por semana
  final int? progressionWeeks; // cada cuántas semanas aplicar

  const RoutineExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.category,
    required this.targetSets,
    required this.targetReps,
    required this.order,
    this.restSec,
    this.tempo,
    this.targetRPE,
    this.targetPercent1RM,
    this.notes,
    this.autoProgressionEnabled = false,
    this.progressionType,
    this.progressionIncrement,
    this.progressionWeeks,
  });

  static RoutineExercise fromMap(String id, Map<String, dynamic> m) {
    return RoutineExercise(
      id: id,
      exerciseId: (m['exerciseId'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      muscleGroup: (m['muscleGroup'] ?? (m['group'] ?? '')) as String,
      category: (m['category'] ?? '') as String,
      targetSets: (m['targetSets'] ?? 3) as int,
      targetReps: (m['targetReps'] ?? 10) as int,
      restSec: (m['restSec'] as num?)?.toInt(),
      order: (m['order'] ?? 0) as int,
      tempo: m['tempo'] as String?,
      targetRPE:
          (m['targetRPE'] ?? m['rpeTarget']) == null
              ? null
              : (m['targetRPE'] ?? m['rpeTarget'] as num).toDouble(),
      targetPercent1RM: (m['targetPercent1RM'] as num?)?.toDouble(),
      notes: m['notes'] as String?,
      autoProgressionEnabled: (m['autoProgressionEnabled'] ?? false) as bool,
      progressionType: m['progressionType'] as String?,
      progressionIncrement: (m['progressionIncrement'] as num?)?.toDouble(),
      progressionWeeks: (m['progressionWeeks'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'exerciseId': exerciseId,
    'name': name,
    'muscleGroup': muscleGroup,
    'category': category,
    'targetSets': targetSets,
    'targetReps': targetReps,
    'restSec': restSec,
    'order': order,
    'autoProgressionEnabled': autoProgressionEnabled,
    if (progressionType != null) 'progressionType': progressionType,
    if (progressionIncrement != null) 'progressionIncrement': progressionIncrement,
    if (progressionWeeks != null) 'progressionWeeks': progressionWeeks,
    if (tempo != null) 'tempo': tempo,
    if (targetRPE != null) 'targetRPE': targetRPE,
    if (targetPercent1RM != null) 'targetPercent1RM': targetPercent1RM,
    if (notes != null) 'notes': notes,
  };
}

class SessionSet {
  final double weight;
  final int reps;
  final double? rpe;

  const SessionSet({required this.weight, required this.reps, this.rpe});

  double get e1rm => weight * (1 + reps / 30.0);

  static SessionSet fromMap(Map<String, dynamic> m) {
    return SessionSet(
      weight: (m['weight'] as num).toDouble(),
      reps: (m['reps'] as num).toInt(),
      rpe: (m['rpe'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'weight': weight,
    'reps': reps,
    if (rpe != null) 'rpe': rpe,
  };
}

class PerformedExercise {
  final String name;
  final String? exerciseId;
  final List<SessionSet> sets;

  const PerformedExercise({
    required this.name,
    this.exerciseId,
    required this.sets,
  });

  double get volumeKg =>
      sets.fold<double>(0, (a, s) => a + (s.weight * s.reps));

  double? get bestE1rm =>
      sets.isEmpty
          ? null
          : sets.map((s) => s.e1rm).reduce((a, b) => a > b ? a : b);

  static PerformedExercise fromMap(Map<String, dynamic> m) {
    final sets =
        (m['sets'] as List?)?.map((e) => SessionSet.fromMap(e)).toList() ?? [];
    return PerformedExercise(
      name: (m['name'] ?? '') as String,
      exerciseId: m['exerciseId'] as String?,
      sets: sets.cast<SessionSet>(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (exerciseId != null) 'exerciseId': exerciseId,
    'sets': sets.map((s) => s.toMap()).toList(),
  };
}

class SessionDoc {
  final String id;
  final String routineId;
  final String routineName;
  final String dayId;
  final String dayName;
  final DateTime date;
  final String? notes;
  final int? durationMin;
  final double volumeKg;
  final List<String> prList; // nombres de ejercicios con PR
  final List<PerformedExercise> exercises;
  
  // 🧠 Sensaciones post-entreno
  final int? feelingEnergy; // 1-5
  final int? feelingFatigue; // 1-5
  final int? feelingMotivation; // 1-5

  const SessionDoc({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.dayId,
    required this.dayName,
    required this.date,
    required this.exercises,
    this.notes,
    this.durationMin,
    this.volumeKg = 0,
    this.prList = const [],
    this.feelingEnergy,
    this.feelingFatigue,
    this.feelingMotivation,
  });

  static SessionDoc fromMap(String id, Map<String, dynamic> m) {
    final ex =
        (m['exercises'] as List? ?? [])
            .map((e) => PerformedExercise.fromMap(e as Map<String, dynamic>))
            .toList();
    return SessionDoc(
      id: id,
      routineId: (m['routineId'] ?? '') as String,
      routineName: (m['routineName'] ?? '') as String,
      dayId: (m['dayId'] ?? '') as String,
      feelingEnergy: (m['feelingEnergy'] as num?)?.toInt(),
      feelingFatigue: (m['feelingFatigue'] as num?)?.toInt(),
      feelingMotivation: (m['feelingMotivation'] as num?)?.toInt(),
      dayName: (m['dayName'] ?? '') as String,
      date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
      notes: m['notes'] as String?,
      durationMin: (m['durationMin'] as num?)?.toInt(),
      volumeKg: (m['volumeKg'] as num?)?.toDouble() ?? 0,
      prList:
          (m['prList'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      exercises: ex,
    );
  }

  Map<String, dynamic> toMap() => {
    'routineId': routineId,
    'routineName': routineName,
    'dayId': dayId,
    'dayName': dayName,
    'date': date.toIso8601String(),
    if (notes != null) 'notes': notes,
    if (durationMin != null) 'durationMin': durationMin,
    if (feelingEnergy != null) 'feelingEnergy': feelingEnergy,
    if (feelingFatigue != null) 'feelingFatigue': feelingFatigue,
    if (feelingMotivation != null) 'feelingMotivation': feelingMotivation,
    'volumeKg': volumeKg,
    'prList': prList,
    'exercises': exercises.map((e) => e.toMap()).toList(),
  };
}

class BodyWeightEntry {
  final String id;
  final DateTime date;
  final double weight;
  final double? trend7;

  const BodyWeightEntry({
    required this.id,
    required this.date,
    required this.weight,
    this.trend7,
  });

  static BodyWeightEntry fromMap(String id, Map<String, dynamic> m) {
    return BodyWeightEntry(
      id: id,
      date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
      weight: (m['weight'] as num).toDouble(),
      trend7: (m['trend7'] as num?)?.toDouble(),
    );
  }
}

class MeasurementEntry {
  final String id;
  final DateTime date;
  final String muscle;
  final double valueCm;
  final String? site; // 'left' | 'right' | 'avg'

  const MeasurementEntry({
    required this.id,
    required this.date,
    required this.muscle,
    required this.valueCm,
    this.site,
  });

  static MeasurementEntry fromMap(String id, Map<String, dynamic> m) {
    return MeasurementEntry(
      id: id,
      date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
      muscle: (m['muscle'] ?? '') as String,
      valueCm: (m['valueCm'] as num).toDouble(),
      site: m['site'] as String?,
    );
  }
}

class GymGoals {
  final double? bodyWeightTarget;

  const GymGoals({this.bodyWeightTarget});

  static GymGoals fromMap(Map<String, dynamic> m) {
    return GymGoals(
      bodyWeightTarget: (m['bodyWeightTarget'] as num?)?.toDouble(),
    );
  }
}

// 🏋️ Rutinas predefinidas famosas
class PresetRoutine {
  final String id;
  final String name;
  final String description;
  final String goal; // 'strength' | 'mass' | 'endurance' | 'general'
  final String level; // 'beginner' | 'intermediate' | 'advanced'
  final String? imageAsset;
  final IconData icon;
  final List<PresetDay> days;

  const PresetRoutine({
    required this.id,
    required this.name,
    required this.description,
    required this.goal,
    required this.level,
    required this.days,
    this.imageAsset,
    this.icon = Icons.fitness_center,
  });
}

class PresetDay {
  final String name;
  final String? icon;
  final List<PresetExercise> exercises;

  const PresetDay({
    required this.name,
    required this.exercises,
    this.icon,
  });
}

class PresetExercise {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final String category;
  final int targetSets;
  final int targetReps;
  final int? restSec;
  final String? tempo;
  final double? targetRPE;
  final String? notes;

  const PresetExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.category,
    required this.targetSets,
    required this.targetReps,
    this.restSec,
    this.tempo,
    this.targetRPE,
    this.notes,
  });
}
