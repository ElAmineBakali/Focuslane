import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import '../models/core_daily_stats.dart';
import '../models/core_entity_ref.dart';
import '../utils/date_utils.dart';

class CoreAggregationService {
  CoreAggregationService._();
  static final CoreAggregationService I = CoreAggregationService._();

  final _db = FirebaseFirestore.instance;

  Stream<CoreDailyStats> watchDay(String uid, String dayId) {
    if (uid.isEmpty) return Stream.value(CoreDailyStats(dayId: dayId));
    final food$ = _foodDay(uid, dayId);
    final gym$ = _gymDay(uid, dayId);
    final study$ = _studyDay(uid, dayId);
    final tasks$ = _tasksDay(uid, dayId);
    final finance$ = _financeDay(uid, dayId);

    return Rx.combineLatest5(
      food$,
      gym$,
      study$,
      tasks$,
      finance$,
      (f, g, s, t, fin) => _merge(dayId, f, g, s, t, fin),
    ).distinct((a, b) => a == b);
  }

  Future<CoreDailyStats> getDay(String uid, String dayId) async {
    if (uid.isEmpty) return CoreDailyStats(dayId: dayId);
    final results = await Future.wait([
      _foodDay(uid, dayId).first,
      _gymDay(uid, dayId).first,
      _studyDay(uid, dayId).first,
      _tasksDay(uid, dayId).first,
      _financeDay(uid, dayId).first,
    ]);
    return _merge(dayId, results[0], results[1], results[2], results[3], results[4]);
  }

  Stream<List<CoreDailyStats>> watchRange(String uid, DateTime from, DateTime to) {
    if (uid.isEmpty) return Stream.value(const []);
    final days = <String>[];
    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!cursor.isAfter(end)) {
      days.add(dayIdFromDateTime(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }

    final fromId = days.isEmpty ? dayIdFromDateTime(from) : days.first;
    final toId = days.isEmpty ? dayIdFromDateTime(to) : days.last;

    final food$ = _foodRange(uid, fromId, toId);
    final gym$ = _gymRange(uid, from, to);
    final study$ = _studyRange(uid, from, to);
    final tasks$ = _tasksRange(uid, from, to);
    final finance$ = _financeRange(uid, from, to);

    return Rx.combineLatest5(food$, gym$, study$, tasks$, finance$, (f, g, s, t, fin) {
      return days.map((dayId) {
        final foodDay = f[dayId] ?? CoreDailyStats(dayId: dayId);
        final gymDay = g[dayId] ?? CoreDailyStats(dayId: dayId);
        final studyDay = s[dayId] ?? CoreDailyStats(dayId: dayId);
        final taskDay = t[dayId] ?? CoreDailyStats(dayId: dayId);
        final finDay = fin[dayId] ?? CoreDailyStats(dayId: dayId);
        return _merge(dayId, foodDay, gymDay, studyDay, taskDay, finDay);
      }).toList()
        ..sort((a, b) => a.dayId.compareTo(b.dayId));
    }).distinct((a, b) => const DeepCollectionEquality().equals(a, b));
  }

  CoreDailyStats _merge(
    String dayId,
    CoreDailyStats food,
    CoreDailyStats gym,
    CoreDailyStats study,
    CoreDailyStats tasks,
    CoreDailyStats finance,
  ) {
    return CoreDailyStats(
      dayId: dayId,
      kcal: food.kcal,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      fiber: food.fiber,
      waterMl: food.waterMl,
      workoutsCount: gym.workoutsCount,
      workoutMinutes: gym.workoutMinutes,
      workoutVolumeKg: gym.workoutVolumeKg,
      avgEnergy: gym.avgEnergy,
      avgFatigue: gym.avgFatigue,
      avgMotivation: gym.avgMotivation,
      studyMinutes: study.studyMinutes,
      studySessionsCount: study.studySessionsCount,
      tasksDone: tasks.tasksDone,
      tasksTotal: tasks.tasksTotal,
      financeSpentTotal: finance.financeSpentTotal,
      financeSpentFood: finance.financeSpentFood,
      financeSpentGym: finance.financeSpentGym,
      financeSpentStudy: finance.financeSpentStudy,
      financeIncomeTotal: finance.financeIncomeTotal,
      sources: _combineSources([
        food.sources,
        gym.sources,
        study.sources,
        tasks.sources,
        finance.sources,
      ]),
      updatedAt: Timestamp.now(),
    );
  }

  List<CoreEntityRef> _combineSources(List<List<CoreEntityRef>> chunks) {
    final out = <CoreEntityRef>[];
    for (final list in chunks) {
      for (final item in list) {
        if (out.length >= 20) break;
        out.add(item);
      }
      if (out.length >= 20) break;
    }
    return out;
  }

  Stream<CoreDailyStats> _foodDay(String uid, String dayId) {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('food')
        .doc('root')
        .collection('intake')
        .doc(dayId);
    return ref.snapshots().map((d) {
      final data = d.data() ?? const {};
      final totals = Map<String, dynamic>.from(data['totals'] ?? const {});
      final entries = (data['entries'] as List?) ?? const [];
      final sources = <CoreEntityRef>[];
      for (var i = 0; i < entries.length && sources.length < 5; i++) {
        final e = Map<String, dynamic>.from(entries[i] as Map);
        final name = e['nameSnapshot']?.toString() ?? 'Entrada';
        final macros = Map<String, dynamic>.from(e['macrosSnapshot'] ?? const {});
        final kcal = (macros['kcal'] as num?)?.toDouble() ?? 0;
        final qty = (e['qty'] as num?)?.toDouble();
        final unit = e['unit']?.toString();
        final subtitle = [
          if (qty != null && unit != null) '${qty.toStringAsFixed(0)} $unit',
          if (kcal > 0) '${kcal.toStringAsFixed(0)} kcal',
        ].where((p) => p.isNotEmpty).join(' • ');
        sources.add(
          CoreEntityRef.forFoodIntake(
            entryId: '$dayId-$i',
            dayId: dayId,
            name: name,
            subtitle: subtitle.isEmpty ? null : subtitle,
          ),
        );
      }
      return CoreDailyStats(
        dayId: dayId,
        kcal: (totals['kcal'] as num?)?.toDouble() ?? 0,
        protein: (totals['protein'] as num?)?.toDouble() ?? 0,
        carbs: (totals['carbs'] as num?)?.toDouble() ?? 0,
        fat: (totals['fat'] as num?)?.toDouble() ?? 0,
        fiber: (totals['fiber'] as num?)?.toDouble() ?? 0,
        waterMl: (data['waterMl'] as num?)?.toInt() ?? 0,
        sources: sources,
      );
    }).onErrorReturn(CoreDailyStats(dayId: dayId));
  }

  Stream<CoreDailyStats> _gymDay(String uid, String dayId) {
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root')
        .collection('sessions')
        .orderBy('date', descending: true)
        .limit(120)
        .snapshots();
    return col.map((s) {
      int count = 0;
      int minutes = 0;
      double volume = 0;
      double energy = 0;
      double fatigue = 0;
      double motivation = 0;
      int feelingsCount = 0;
      final sources = <CoreEntityRef>[];
      for (final d in s.docs) {
        final m = d.data();
        final iso = (m['date'] ?? '') as String;
        if (dayIdFromIso(iso) != dayId) continue;
        count++;
        final minutesVal = (m['durationMin'] as num?)?.toInt() ?? 0;
        minutes += minutesVal;
        final volumeVal = (m['volumeKg'] as num?)?.toDouble() ?? 0;
        volume += volumeVal;

        final feelingsRaw = m['feelings'];
        final parsed = _parseFeelings(feelingsRaw, m);
        if (parsed['energy'] != null && parsed['fatigue'] != null && parsed['motivation'] != null) {
          energy += parsed['energy'] as double;
          fatigue += parsed['fatigue'] as double;
          motivation += parsed['motivation'] as double;
          feelingsCount++;
        }

        if (sources.length < 3) {
          final title = (m['routineName'] ?? 'Sesión') as String;
          final subtitle = [
            if (minutesVal > 0) '$minutesVal min',
            if (volumeVal > 0) '${volumeVal.toStringAsFixed(0)} kg',
          ].where((p) => p.isNotEmpty).join(' • ');
          sources.add(
            CoreEntityRef.forGymSession(
              id: d.id,
              dayId: dayId,
              title: title.isEmpty ? 'Entrenamiento' : title,
              subtitle: subtitle.isEmpty ? null : subtitle,
            ),
          );
        }
      }
      return CoreDailyStats(
        dayId: dayId,
        workoutsCount: count,
        workoutMinutes: minutes,
        workoutVolumeKg: volume,
        avgEnergy: feelingsCount == 0 ? 0 : energy / feelingsCount,
        avgFatigue: feelingsCount == 0 ? 0 : fatigue / feelingsCount,
        avgMotivation: feelingsCount == 0 ? 0 : motivation / feelingsCount,
        sources: sources,
      );
    }).onErrorReturn(CoreDailyStats(dayId: dayId));
  }

  Map<String, double?> _parseFeelings(dynamic feelings, Map<String, dynamic> raw) {
    if (feelings is Map) {
      return {
        'energy': (feelings['energy'] as num?)?.toDouble(),
        'fatigue': (feelings['fatigue'] as num?)?.toDouble(),
        'motivation': (feelings['motivation'] as num?)?.toDouble(),
      };
    }
    return {
      'energy': (raw['feelingEnergy'] as num?)?.toDouble(),
      'fatigue': (raw['feelingFatigue'] as num?)?.toDouble(),
      'motivation': (raw['feelingMotivation'] as num?)?.toDouble(),
    };
  }

  Stream<CoreDailyStats> _studyDay(String uid, String dayId) {
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('sessions')
        .orderBy('date', descending: true)
        .limit(120)
        .snapshots();
    return col.map((s) {
      int minutes = 0;
      int sessions = 0;
      final sources = <CoreEntityRef>[];
      for (final d in s.docs) {
        final m = d.data();
        final iso = (m['date'] ?? '') as String;
        if (dayIdFromIso(iso) != dayId) continue;
        sessions++;
        final mins = (m['minutes'] as num?)?.toInt() ?? 0;
        minutes += mins;
        if (sources.length < 3) {
          final title = (m['courseName'] ?? 'Estudio') as String? ?? 'Estudio';
          final subtitle = mins > 0 ? '$mins min' : null;
          sources.add(
            CoreEntityRef.forStudySession(
              id: d.id,
              dayId: dayId,
              title: title.isEmpty ? 'Sesión de estudio' : title,
              subtitle: subtitle,
            ),
          );
        }
      }
      return CoreDailyStats(
        dayId: dayId,
        studyMinutes: minutes,
        studySessionsCount: sessions,
        sources: sources,
      );
    }).onErrorReturn(CoreDailyStats(dayId: dayId));
  }

  Stream<CoreDailyStats> _tasksDay(String uid, String dayId) {
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('dueDate', isGreaterThanOrEqualTo: startOfDayTs(dayId))
        .where('dueDate', isLessThanOrEqualTo: endOfDayTs(dayId))
        .snapshots();
    final fallback = _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .orderBy('dueDate', descending: true)
        .limit(120)
        .snapshots();

    return col.switchMap((snapshot) {
      if (snapshot.docs.isEmpty) {
        return fallback.map((s) => _tasksFromSnapshot(dayId, s, includeSources: true));
      }
      return Stream.value(_tasksFromSnapshot(dayId, snapshot, includeSources: true));
    }).onErrorReturn(CoreDailyStats(dayId: dayId));
  }

  CoreDailyStats _tasksFromSnapshot(
    String dayId,
    QuerySnapshot snap, {
    bool includeSources = false,
  }) {
    int total = 0;
    int done = 0;
    final sources = <CoreEntityRef>[];
    for (final d in snap.docs) {
      final m = d.data() as Map<String, dynamic>;
      final due = m['dueDate'];
      String? dueDay;
      if (due is Timestamp) {
        dueDay = dayIdFromTimestamp(due);
      } else if (due is String) {
        dueDay = dayIdFromIso(due);
      }
      if (dueDay != null && dueDay == dayId) {
        total++;
        final isDone = m['completed'] == true;
        if (isDone) done++;
        if (includeSources && sources.length < 5) {
          final title = (m['title'] ?? 'Tarea') as String;
          final subtitle = isDone ? 'Completada' : 'Pendiente';
          sources.add(
            CoreEntityRef.forTask(
              id: d.id,
              dayId: dayId,
              title: title.isEmpty ? 'Tarea' : title,
              subtitle: subtitle,
            ),
          );
        }
      }
    }
    return CoreDailyStats(
      dayId: dayId,
      tasksDone: done,
      tasksTotal: total,
      sources: sources,
    );
  }

  Stream<CoreDailyStats> _financeDay(String uid, String dayId) {
    final start = startOfDayTs(dayId);
    final end = endOfDayTs(dayId);
    final col = _db
        .collection('finance_transactions')
        .where('userId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .limit(120)
        .snapshots();
    return col.map((s) {
      double spent = 0;
      double income = 0;
      double spentFood = 0;
      double spentGym = 0;
      double spentStudy = 0;
      final sources = <CoreEntityRef>[];
      for (final d in s.docs) {
        final m = d.data();
        final type = (m['type'] ?? 'expense').toString();
        final cat = (m['category'] ?? '') as String;
        final amount = (m['amount'] as num?)?.toDouble() ?? 0;
        if (type == 'income') {
          income += amount;
        } else {
          spent += amount;
          if (cat.toLowerCase() == 'food') spentFood += amount;
          if (cat.toLowerCase() == 'gym') spentGym += amount;
          if (cat.toLowerCase() == 'study') spentStudy += amount;
        }
        if (sources.length < 5) {
          final title = (m['title'] ?? 'Movimiento') as String;
          final subtitle = [
            type == 'income' ? 'Ingreso' : 'Gasto',
            if (cat.isNotEmpty) cat,
            if (amount != 0) amount.toStringAsFixed(2),
          ].where((e) => e.isNotEmpty).join(' • ');
          sources.add(
            CoreEntityRef.forFinanceTx(
              id: d.id,
              dayId: dayId,
              title: title.isEmpty ? 'Movimiento' : title,
              subtitle: subtitle,
            ),
          );
        }
      }
      return CoreDailyStats(
        dayId: dayId,
        financeSpentTotal: spent,
        financeSpentFood: spentFood,
        financeSpentGym: spentGym,
        financeSpentStudy: spentStudy,
        financeIncomeTotal: income,
        sources: sources,
      );
    }).onErrorReturn(CoreDailyStats(dayId: dayId));
  }

  Stream<Map<String, CoreDailyStats>> _foodRange(
    String uid,
    String fromDayId,
    String toDayId,
  ) {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('food')
        .doc('root')
        .collection('intake')
        .orderBy(FieldPath.documentId)
        .startAt([fromDayId])
        .endAt([toDayId]);
    return ref.snapshots().map((snap) {
      final map = <String, CoreDailyStats>{};
      for (final d in snap.docs) {
        final data = d.data();
        final totals = Map<String, dynamic>.from(data['totals'] ?? const {});
        final entries = (data['entries'] as List?) ?? const [];
        final sources = <CoreEntityRef>[];
        for (var i = 0; i < entries.length && sources.length < 5; i++) {
          final e = Map<String, dynamic>.from(entries[i] as Map);
          final name = e['nameSnapshot']?.toString() ?? 'Entrada';
          final macros = Map<String, dynamic>.from(e['macrosSnapshot'] ?? const {});
          final kcal = (macros['kcal'] as num?)?.toDouble() ?? 0;
          final qty = (e['qty'] as num?)?.toDouble();
          final unit = e['unit']?.toString();
          final subtitle = [
            if (qty != null && unit != null) '${qty.toStringAsFixed(0)} $unit',
            if (kcal > 0) '${kcal.toStringAsFixed(0)} kcal',
          ].where((p) => p.isNotEmpty).join(' • ');
          sources.add(
            CoreEntityRef.forFoodIntake(
              entryId: '${d.id}-$i',
              dayId: d.id,
              name: name,
              subtitle: subtitle.isEmpty ? null : subtitle,
            ),
          );
        }
        map[d.id] = CoreDailyStats(
          dayId: d.id,
          kcal: (totals['kcal'] as num?)?.toDouble() ?? 0,
          protein: (totals['protein'] as num?)?.toDouble() ?? 0,
          carbs: (totals['carbs'] as num?)?.toDouble() ?? 0,
          fat: (totals['fat'] as num?)?.toDouble() ?? 0,
          fiber: (totals['fiber'] as num?)?.toDouble() ?? 0,
          waterMl: (data['waterMl'] as num?)?.toInt() ?? 0,
          sources: sources,
        );
      }
      return map;
    }).onErrorReturn({});
  }

  Stream<Map<String, CoreDailyStats>> _gymRange(String uid, DateTime from, DateTime to) {
    final startIso = DateTime(from.year, from.month, from.day).toIso8601String();
    final endIso = DateTime(to.year, to.month, to.day, 23, 59, 59).toIso8601String();
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root')
        .collection('sessions')
        .orderBy('date')
        .where('date', isGreaterThanOrEqualTo: startIso)
        .where('date', isLessThanOrEqualTo: endIso)
        .snapshots();

    return col.map((snap) {
      final map = <String, Map<String, dynamic>>{};
      for (final d in snap.docs) {
        final m = d.data();
        final iso = (m['date'] ?? '') as String;
        final dayId = dayIdFromIso(iso);
        final agg = map.putIfAbsent(dayId, () => {
              'count': 0,
              'minutes': 0,
              'volume': 0.0,
              'energy': 0.0,
              'fatigue': 0.0,
              'motivation': 0.0,
              'feelingsCount': 0,
              'sources': <CoreEntityRef>[],
            });
        agg['count'] = (agg['count'] as int) + 1;
        final mins = (m['durationMin'] as num?)?.toInt() ?? 0;
        final vol = (m['volumeKg'] as num?)?.toDouble() ?? 0;
        agg['minutes'] = (agg['minutes'] as int) + mins;
        agg['volume'] = (agg['volume'] as double) + vol;

        final feelings = _parseFeelings(m['feelings'], m);
        if (feelings['energy'] != null && feelings['fatigue'] != null && feelings['motivation'] != null) {
          agg['energy'] = (agg['energy'] as double) + (feelings['energy'] as double);
          agg['fatigue'] = (agg['fatigue'] as double) + (feelings['fatigue'] as double);
          agg['motivation'] = (agg['motivation'] as double) + (feelings['motivation'] as double);
          agg['feelingsCount'] = (agg['feelingsCount'] as int) + 1;
        }

        final sources = agg['sources'] as List<CoreEntityRef>;
        if (sources.length < 3) {
          final title = (m['routineName'] ?? 'Sesión') as String;
          final subtitle = [
            if (mins > 0) '$mins min',
            if (vol > 0) '${vol.toStringAsFixed(0)} kg',
          ].where((p) => p.isNotEmpty).join(' • ');
          sources.add(
            CoreEntityRef.forGymSession(
              id: d.id,
              dayId: dayId,
              title: title.isEmpty ? 'Entrenamiento' : title,
              subtitle: subtitle.isEmpty ? null : subtitle,
            ),
          );
        }
      }

      final out = <String, CoreDailyStats>{};
      map.forEach((dayId, agg) {
        final feelingsCount = (agg['feelingsCount'] as int);
        out[dayId] = CoreDailyStats(
          dayId: dayId,
          workoutsCount: agg['count'] as int,
          workoutMinutes: agg['minutes'] as int,
          workoutVolumeKg: agg['volume'] as double,
          avgEnergy:
              feelingsCount == 0 ? 0 : (agg['energy'] as double) / feelingsCount,
          avgFatigue:
              feelingsCount == 0 ? 0 : (agg['fatigue'] as double) / feelingsCount,
          avgMotivation:
              feelingsCount == 0
                  ? 0
                  : (agg['motivation'] as double) / feelingsCount,
          sources: agg['sources'] as List<CoreEntityRef>,
        );
      });
      return out;
    }).onErrorReturn({});
  }

  Stream<Map<String, CoreDailyStats>> _studyRange(String uid, DateTime from, DateTime to) {
    final startIso = DateTime(from.year, from.month, from.day).toIso8601String();
    final endIso = DateTime(to.year, to.month, to.day, 23, 59, 59).toIso8601String();
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('sessions')
        .orderBy('date')
        .where('date', isGreaterThanOrEqualTo: startIso)
        .where('date', isLessThanOrEqualTo: endIso)
        .snapshots();

    return col.map((snap) {
      final map = <String, Map<String, dynamic>>{};
      for (final d in snap.docs) {
        final m = d.data();
        final iso = (m['date'] ?? '') as String;
        final dayId = dayIdFromIso(iso);
        final agg = map.putIfAbsent(dayId, () => {
              'minutes': 0,
              'sessions': 0,
              'sources': <CoreEntityRef>[],
            });
        final mins = (m['minutes'] as num?)?.toInt() ?? 0;
        agg['minutes'] = (agg['minutes'] as int) + mins;
        agg['sessions'] = (agg['sessions'] as int) + 1;
        final sources = agg['sources'] as List<CoreEntityRef>;
        if (sources.length < 3) {
          final title = (m['courseName'] ?? 'Estudio') as String? ?? 'Estudio';
          sources.add(
            CoreEntityRef.forStudySession(
              id: d.id,
              dayId: dayId,
              title: title.isEmpty ? 'Sesión de estudio' : title,
              subtitle: mins > 0 ? '$mins min' : null,
            ),
          );
        }
      }
      final out = <String, CoreDailyStats>{};
      map.forEach((dayId, agg) {
        out[dayId] = CoreDailyStats(
          dayId: dayId,
          studyMinutes: agg['minutes'] as int,
          studySessionsCount: agg['sessions'] as int,
          sources: agg['sources'] as List<CoreEntityRef>,
        );
      });
      return out;
    }).onErrorReturn({});
  }

  Stream<Map<String, CoreDailyStats>> _tasksRange(String uid, DateTime from, DateTime to) {
    final start = Timestamp.fromDate(DateTime(from.year, from.month, from.day));
    final end = Timestamp.fromDate(DateTime(to.year, to.month, to.day, 23, 59, 59));
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('dueDate', isGreaterThanOrEqualTo: start)
        .where('dueDate', isLessThanOrEqualTo: end)
        .snapshots();

    return col.map((snap) {
      final map = <String, Map<String, dynamic>>{};
      for (final d in snap.docs) {
        final m = d.data() as Map<String, dynamic>;
        final due = m['dueDate'];
        String? dayId;
        if (due is Timestamp) {
          dayId = dayIdFromTimestamp(due);
        } else if (due is String) {
          dayId = dayIdFromIso(due);
        }
        if (dayId == null) continue;
        final agg = map.putIfAbsent(dayId, () => {
              'total': 0,
              'done': 0,
              'sources': <CoreEntityRef>[],
            });
        agg['total'] = (agg['total'] as int) + 1;
        final isDone = m['completed'] == true;
        if (isDone) agg['done'] = (agg['done'] as int) + 1;
        final sources = agg['sources'] as List<CoreEntityRef>;
        if (sources.length < 5) {
          final title = (m['title'] ?? 'Tarea') as String;
          sources.add(
            CoreEntityRef.forTask(
              id: d.id,
              dayId: dayId,
              title: title.isEmpty ? 'Tarea' : title,
              subtitle: isDone ? 'Completada' : 'Pendiente',
            ),
          );
        }
      }
      final out = <String, CoreDailyStats>{};
      map.forEach((dayId, agg) {
        out[dayId] = CoreDailyStats(
          dayId: dayId,
          tasksDone: agg['done'] as int,
          tasksTotal: agg['total'] as int,
          sources: agg['sources'] as List<CoreEntityRef>,
        );
      });
      return out;
    }).onErrorReturn({});
  }

  Stream<Map<String, CoreDailyStats>> _financeRange(String uid, DateTime from, DateTime to) {
    final start = Timestamp.fromDate(DateTime(from.year, from.month, from.day));
    final end = Timestamp.fromDate(DateTime(to.year, to.month, to.day, 23, 59, 59));
    final col = _db
        .collection('finance_transactions')
        .where('userId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .snapshots();

    return col.map((snap) {
      final map = <String, Map<String, dynamic>>{};
      for (final d in snap.docs) {
        final m = d.data();
        final ts = m['date'];
        String? dayId;
        if (ts is Timestamp) {
          dayId = dayIdFromTimestamp(ts);
        } else if (ts is String) {
          dayId = dayIdFromIso(ts);
        }
        if (dayId == null) continue;
        final agg = map.putIfAbsent(dayId, () => {
              'spent': 0.0,
              'income': 0.0,
              'food': 0.0,
              'gym': 0.0,
              'study': 0.0,
              'sources': <CoreEntityRef>[],
            });
        final type = (m['type'] ?? 'expense').toString();
        final cat = (m['category'] ?? '') as String;
        final amount = (m['amount'] as num?)?.toDouble() ?? 0;
        if (type == 'income') {
          agg['income'] = (agg['income'] as double) + amount;
        } else {
          agg['spent'] = (agg['spent'] as double) + amount;
          if (cat.toLowerCase() == 'food') agg['food'] = (agg['food'] as double) + amount;
          if (cat.toLowerCase() == 'gym') agg['gym'] = (agg['gym'] as double) + amount;
          if (cat.toLowerCase() == 'study') agg['study'] = (agg['study'] as double) + amount;
        }
        final sources = agg['sources'] as List<CoreEntityRef>;
        if (sources.length < 5) {
          final title = (m['title'] ?? 'Movimiento') as String;
          final subtitle = [
            type == 'income' ? 'Ingreso' : 'Gasto',
            if (cat.isNotEmpty) cat,
            if (amount != 0) amount.toStringAsFixed(2),
          ].where((e) => e.isNotEmpty).join(' • ');
          sources.add(
            CoreEntityRef.forFinanceTx(
              id: d.id,
              dayId: dayId,
              title: title.isEmpty ? 'Movimiento' : title,
              subtitle: subtitle,
            ),
          );
        }
      }
      final out = <String, CoreDailyStats>{};
      map.forEach((dayId, agg) {
        out[dayId] = CoreDailyStats(
          dayId: dayId,
          financeSpentTotal: agg['spent'] as double,
          financeSpentFood: agg['food'] as double,
          financeSpentGym: agg['gym'] as double,
          financeSpentStudy: agg['study'] as double,
          financeIncomeTotal: agg['income'] as double,
          sources: agg['sources'] as List<CoreEntityRef>,
        );
      });
      return out;
    }).onErrorReturn({});
  }
}