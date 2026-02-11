import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import 'core_entity_ref.dart';

class CoreDailyStats {
  final String dayId;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int waterMl;
  final int workoutsCount;
  final int workoutMinutes;
  final double workoutVolumeKg;
  final double avgEnergy;
  final double avgFatigue;
  final double avgMotivation;
  final int studyMinutes;
  final int studySessionsCount;
  final int tasksDone;
  final int tasksTotal;
  final double financeSpentTotal;
  final double financeSpentFood;
  final double financeSpentGym;
  final double financeSpentStudy;
  final double financeIncomeTotal;
  final Timestamp updatedAt;
  final List<CoreEntityRef> sources;

  CoreDailyStats({
    required this.dayId,
    this.kcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.waterMl = 0,
    this.workoutsCount = 0,
    this.workoutMinutes = 0,
    this.workoutVolumeKg = 0,
    this.avgEnergy = 0,
    this.avgFatigue = 0,
    this.avgMotivation = 0,
    this.studyMinutes = 0,
    this.studySessionsCount = 0,
    this.tasksDone = 0,
    this.tasksTotal = 0,
    this.financeSpentTotal = 0,
    this.financeSpentFood = 0,
    this.financeSpentGym = 0,
    this.financeSpentStudy = 0,
    this.financeIncomeTotal = 0,
    this.sources = const [],
    Timestamp? updatedAt,
  }) : updatedAt = updatedAt ?? Timestamp.now();

  CoreDailyStats copyWith({
    String? dayId,
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? waterMl,
    int? workoutsCount,
    int? workoutMinutes,
    double? workoutVolumeKg,
    double? avgEnergy,
    double? avgFatigue,
    double? avgMotivation,
    int? studyMinutes,
    int? studySessionsCount,
    int? tasksDone,
    int? tasksTotal,
    double? financeSpentTotal,
    double? financeSpentFood,
    double? financeSpentGym,
    double? financeSpentStudy,
    double? financeIncomeTotal,
    List<CoreEntityRef>? sources,
    Timestamp? updatedAt,
  }) {
    return CoreDailyStats(
      dayId: dayId ?? this.dayId,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      waterMl: waterMl ?? this.waterMl,
      workoutsCount: workoutsCount ?? this.workoutsCount,
      workoutMinutes: workoutMinutes ?? this.workoutMinutes,
      workoutVolumeKg: workoutVolumeKg ?? this.workoutVolumeKg,
      avgEnergy: avgEnergy ?? this.avgEnergy,
      avgFatigue: avgFatigue ?? this.avgFatigue,
      avgMotivation: avgMotivation ?? this.avgMotivation,
      studyMinutes: studyMinutes ?? this.studyMinutes,
      studySessionsCount: studySessionsCount ?? this.studySessionsCount,
      tasksDone: tasksDone ?? this.tasksDone,
      tasksTotal: tasksTotal ?? this.tasksTotal,
      financeSpentTotal: financeSpentTotal ?? this.financeSpentTotal,
      financeSpentFood: financeSpentFood ?? this.financeSpentFood,
      financeSpentGym: financeSpentGym ?? this.financeSpentGym,
      financeSpentStudy: financeSpentStudy ?? this.financeSpentStudy,
      financeIncomeTotal: financeIncomeTotal ?? this.financeIncomeTotal,
      sources: sources ?? this.sources,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayId': dayId,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'waterMl': waterMl,
        'workoutsCount': workoutsCount,
        'workoutMinutes': workoutMinutes,
        'workoutVolumeKg': workoutVolumeKg,
        'avgEnergy': avgEnergy,
        'avgFatigue': avgFatigue,
        'avgMotivation': avgMotivation,
        'studyMinutes': studyMinutes,
        'studySessionsCount': studySessionsCount,
        'tasksDone': tasksDone,
        'tasksTotal': tasksTotal,
        'financeSpentTotal': financeSpentTotal,
        'financeSpentFood': financeSpentFood,
        'financeSpentGym': financeSpentGym,
        'financeSpentStudy': financeSpentStudy,
        'financeIncomeTotal': financeIncomeTotal,
        'updatedAt': updatedAt,
        'sources': sources.map((e) => e.toMap()).toList(),
      };

  factory CoreDailyStats.fromJson(Map<String, dynamic> m) {
    double d(String k) => (m[k] as num?)?.toDouble() ?? 0;
    int i(String k) => (m[k] as num?)?.toInt() ?? 0;
    return CoreDailyStats(
      dayId: m['dayId'] as String? ?? '',
      kcal: d('kcal'),
      protein: d('protein'),
      carbs: d('carbs'),
      fat: d('fat'),
      fiber: d('fiber'),
      waterMl: i('waterMl'),
      workoutsCount: i('workoutsCount'),
      workoutMinutes: i('workoutMinutes'),
      workoutVolumeKg: d('workoutVolumeKg'),
      avgEnergy: d('avgEnergy'),
      avgFatigue: d('avgFatigue'),
      avgMotivation: d('avgMotivation'),
      studyMinutes: i('studyMinutes'),
      studySessionsCount: i('studySessionsCount'),
      tasksDone: i('tasksDone'),
      tasksTotal: i('tasksTotal'),
      financeSpentTotal: d('financeSpentTotal'),
      financeSpentFood: d('financeSpentFood'),
      financeSpentGym: d('financeSpentGym'),
      financeSpentStudy: d('financeSpentStudy'),
      financeIncomeTotal: d('financeIncomeTotal'),
      updatedAt: m['updatedAt'] is Timestamp
          ? m['updatedAt'] as Timestamp
          : Timestamp.now(),
      sources:
          ((m['sources'] as List?) ?? const [])
              .map((e) => CoreEntityRef.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreDailyStats) return false;
    final listEq = const ListEquality<CoreEntityRef>();
    return other.dayId == dayId &&
        other.kcal == kcal &&
        other.protein == protein &&
        other.carbs == carbs &&
        other.fat == fat &&
        other.fiber == fiber &&
        other.waterMl == waterMl &&
        other.workoutsCount == workoutsCount &&
        other.workoutMinutes == workoutMinutes &&
        other.workoutVolumeKg == workoutVolumeKg &&
        other.avgEnergy == avgEnergy &&
        other.avgFatigue == avgFatigue &&
        other.avgMotivation == avgMotivation &&
        other.studyMinutes == studyMinutes &&
        other.studySessionsCount == studySessionsCount &&
        other.tasksDone == tasksDone &&
        other.tasksTotal == tasksTotal &&
        other.financeSpentTotal == financeSpentTotal &&
        other.financeSpentFood == financeSpentFood &&
        other.financeSpentGym == financeSpentGym &&
        other.financeSpentStudy == financeSpentStudy &&
        other.financeIncomeTotal == financeIncomeTotal &&
        listEq.equals(other.sources, sources);
  }

  @override
  int get hashCode => Object.hashAll([
        dayId,
        kcal,
        protein,
        carbs,
        fat,
        fiber,
        waterMl,
        workoutsCount,
        workoutMinutes,
        workoutVolumeKg,
        avgEnergy,
        avgFatigue,
        avgMotivation,
        studyMinutes,
        studySessionsCount,
        tasksDone,
        tasksTotal,
        financeSpentTotal,
        financeSpentFood,
        financeSpentGym,
        financeSpentStudy,
        financeIncomeTotal,
        const ListEquality<CoreEntityRef>().hash(sources),
      ]);
}