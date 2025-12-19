import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gym_models.dart';

export '../models/gym_models.dart';

class GymFirestoreService {
  GymFirestoreService();

  String get _uid {
    final u = FirebaseAuth.instance.currentUser?.uid;
    if (u == null || u.isEmpty) {
      throw StateError('No hay usuario autenticado para GymFirestoreService');
    }
    return u;
  }

  DocumentReference<Map<String, dynamic>> get _root => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('gym')
      .doc('root');

  DocumentReference<Map<String, dynamic>> get root => _root;

     Stream<List<Routine>> streamRoutines() {
    return _root
        .collection('routines')
        .orderBy('name')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Routine.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<Routine?> streamDefaultRoutine() {
    return _root
        .collection('routines')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map(
          (s) =>
              s.docs.isEmpty
                  ? null
                  : Routine.fromMap(s.docs.first.id, s.docs.first.data()),
        );
  }

  Future<String> createRoutine({
    required String name,
    String? description,
    String splitType = 'Custom',
    int restSecDefault = 90,
    String? colorHex,
    bool isDefault = false,
  }) async {
    final doc = _root.collection('routines').doc();
    await doc.set({
      'name': name,
      'description': description,
      'splitType': splitType,
      'restSecDefault': restSecDefault,
      'colorHex': colorHex,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (isDefault) {
      await setDefaultRoutine(doc.id);
    }
    return doc.id;
  }

  Future<void> updateRoutine(String id, Map<String, dynamic> data) async {
    await _root.collection('routines').doc(id).update(data);
  }

  Future<void> setDefaultRoutine(String routineId) async {
    final col = _root.collection('routines');
    final batch = FirebaseFirestore.instance.batch();
    final all = await col.get();
    for (final d in all.docs) {
      batch.update(d.reference, {'isDefault': d.id == routineId});
    }
    await batch.commit();
  }

  Future<void> duplicateRoutine(String id) async {
    final src = await _root.collection('routines').doc(id).get();
    if (!src.exists) return;
    final data = src.data() as Map<String, dynamic>;
    final newDoc = _root.collection('routines').doc();
    await newDoc.set({
      ...data,
      'name': '${data['name']} (copia)',
      'isDefault': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final days =
        await _root.collection('routines').doc(id).collection('days').get();
    for (final d in days.docs) {
      final newDay = await newDoc.collection('days').add(d.data());
      final exs = await d.reference.collection('exercises').get();
      for (final e in exs.docs) {
        await newDay.collection('exercises').add(e.data());
      }
    }
  }

  Future<void> deleteRoutineCascade(String routineId) async {
    final rRef = _root.collection('routines').doc(routineId);
    final days = await rRef.collection('days').get();
    for (final d in days.docs) {
      final exs = await d.reference.collection('exercises').get();
      for (final e in exs.docs) {
        await e.reference.delete();
      }
      await d.reference.delete();
    }
    await rRef.delete();
  }

     Stream<List<RoutineDay>> streamDays(String routineId) {
    return _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .orderBy('order', descending: false)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => RoutineDay.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<String> addDay(
    String routineId,
    String name, {
    int? order,
    String? icon,
  }) async {
    final col = _root.collection('routines').doc(routineId).collection('days');
    final doc = await col.add({
      'name': name,
      'order': order ?? DateTime.now().millisecondsSinceEpoch,
      'icon': icon,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateDay(
    String routineId,
    String dayId,
    Map<String, dynamic> data,
  ) async {
    await _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId)
        .update(data);
  }

  Future<void> reorderDays(String routineId, List<String> orderedDayIds) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < orderedDayIds.length; i++) {
      final ref = _root
          .collection('routines')
          .doc(routineId)
          .collection('days')
          .doc(orderedDayIds[i]);
      batch.update(ref, {'order': i});
    }
    await batch.commit();
  }

  Future<void> duplicateDay(String routineId, String dayId) async {
    final src =
        await _root
            .collection('routines')
            .doc(routineId)
            .collection('days')
            .doc(dayId)
            .get();
    if (!src.exists) return;
    final data = src.data() as Map<String, dynamic>;
    final newDay = await _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .add({
          ...data,
          'name': '${data['name']} (copia)',
          'order': DateTime.now().millisecondsSinceEpoch,
          'createdAt': FieldValue.serverTimestamp(),
        });
    final exs = await src.reference.collection('exercises').get();
    for (final e in exs.docs) {
      await newDay.collection('exercises').add(e.data());
    }
  }

  Future<void> deleteDayCascade(String routineId, String dayId) async {
    final dRef = _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId);
    final exs = await dRef.collection('exercises').get();
    for (final e in exs.docs) {
      await e.reference.delete();
    }
    await dRef.delete();
  }

     Stream<List<RoutineExercise>> streamDayExercises(
    String routineId,
    String dayId,
  ) {
    return _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId)
        .collection('exercises')
        .orderBy('order', descending: false)
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => RoutineExercise.fromMap(d.id, d.data()))
                  .toList(),
        );
  }

  Future<void> addRoutineExercise(
    String routineId,
    String dayId,
    RoutineExercise e,
  ) async {
    final col = _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId)
        .collection('exercises');
    final data = e.toMap()..remove('id');
    await col.add(data);
  }

  Future<void> updateRoutineExercise(
    String routineId,
    String dayId,
    String exId,
    Map<String, dynamic> data,
  ) async {
    await _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId)
        .collection('exercises')
        .doc(exId)
        .update(data);
  }

  Future<void> reorderExercises(
    String routineId,
    String dayId,
    List<String> orderedExIds,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < orderedExIds.length; i++) {
      final ref = _root
          .collection('routines')
          .doc(routineId)
          .collection('days')
          .doc(dayId)
          .collection('exercises')
          .doc(orderedExIds[i]);
      batch.update(ref, {'order': i});
    }
    await batch.commit();
  }

  Future<void> duplicateExercise(
    String routineId,
    String dayId,
    String exId,
  ) async {
    final src =
        await _root
            .collection('routines')
            .doc(routineId)
            .collection('days')
            .doc(dayId)
            .collection('exercises')
            .doc(exId)
            .get();
    if (!src.exists) return;
    final data = src.data() as Map<String, dynamic>;
    await _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId)
        .collection('exercises')
        .add({...data, 'order': DateTime.now().millisecondsSinceEpoch});
  }

  Future<void> deleteRoutineExercise(
    String routineId,
    String dayId,
    String exId,
  ) async {
    await _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId)
        .collection('exercises')
        .doc(exId)
        .delete();
  }

     Future<void> saveSession(SessionDoc session) async {
    final doc = _root.collection('sessions').doc();
    await doc.set(session.toMap());

    try {
      await _root
          .collection('routines')
          .doc(session.routineId)
          .collection('days')
          .doc(session.dayId)
          .set({
            'lastDone': FieldValue.serverTimestamp(),
            'lastDoneLocal': session.date.toIso8601String(),
          }, SetOptions(merge: true));
    } catch (_) {}
  }

     Future<void> updateSessionFeelings(
    String sessionId,
    int energy,
    int fatigue,
    int motivation,
  ) async {
    await _root.collection('sessions').doc(sessionId).update({
      'feelingEnergy': energy,
      'feelingFatigue': fatigue,
      'feelingMotivation': motivation,
    });
  }

     Future<void> deleteSession(String sessionId) async {
         final sessionDoc = await _root.collection('sessions').doc(sessionId).get();
    if (!sessionDoc.exists) return;

    final sessionData = sessionDoc.data() as Map<String, dynamic>;
    final routineId = sessionData['routineId'] as String?;
    final dayId = sessionData['dayId'] as String?;

         await _root.collection('sessions').doc(sessionId).delete();

         if (routineId != null && dayId != null) {
      try {
        final remainingSessions = await _root
            .collection('sessions')
            .where('routineId', isEqualTo: routineId)
            .where('dayId', isEqualTo: dayId)
            .orderBy('date', descending: true)
            .limit(1)
            .get();

        if (remainingSessions.docs.isNotEmpty) {
          final lastSession = SessionDoc.fromMap(
            remainingSessions.docs.first.id,
            remainingSessions.docs.first.data(),
          );
          await _root
              .collection('routines')
              .doc(routineId)
              .collection('days')
              .doc(dayId)
              .update({
            'lastDone': FieldValue.serverTimestamp(),
            'lastDoneLocal': lastSession.date.toIso8601String(),
          });
        } else {
                     await _root
              .collection('routines')
              .doc(routineId)
              .collection('days')
              .doc(dayId)
              .update({
            'lastDone': FieldValue.delete(),
            'lastDoneLocal': FieldValue.delete(),
          });
        }
      } catch (_) {}
    }
  }

  Stream<List<SessionDoc>> streamSessions({
    String? routineId,
    String? dayId,
    int limit = 50,
  }) {
    Query q = _root
        .collection('sessions')
        .orderBy('date', descending: true)
        .limit(limit);
    if (routineId != null) q = q.where('routineId', isEqualTo: routineId);
    if (dayId != null) q = q.where('dayId', isEqualTo: dayId);
    return q.snapshots().map(
      (s) =>
          s.docs
              .map(
                (d) =>
                    SessionDoc.fromMap(d.id, d.data() as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Future<double?> bestE1rmForExercise(
    String exerciseName, {
    int lookback = 60,
  }) async {
    final snap =
        await _root
            .collection('sessions')
            .orderBy('date', descending: true)
            .limit(lookback)
            .get();
    double? best;
    for (final d in snap.docs) {
      final data = d.data();
      final list =
          (data['exercises'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
      for (final ex in list) {
        if ((ex['name'] ?? '') == exerciseName) {
          final sets =
              (ex['sets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          for (final s in sets) {
            final w = (s['weight'] ?? 0).toDouble();
            final r = (s['reps'] ?? 0).toInt();
            final e1 = w * (1 + r / 30.0);
            if (best == null || e1 > best) best = e1;
          }
        }
      }
    }
    return best;
  }

  Future<void> markDayCompleted(String routineId, String dayId) async {
    final ref = _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId);
    await ref.set({
      'lastDoneAt': FieldValue.serverTimestamp(),
      'completedCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

     Future<DateTime?> lastSessionDate() async {
    final snap =
        await _root
            .collection('sessions')
            .orderBy('date', descending: true)
            .limit(1)
            .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    return DateTime.tryParse(data['date']?.toString() ?? '');
  }

     Future<void> addBodyWeight(
    double kg,
    DateTime date, {
    double? trend7,
    bool computeTrend = true,
  }) async {
    final key = date.toIso8601String().substring(0, 10);
    double? t7 = trend7;
    if (computeTrend) {
      final prev =
          await _root
              .collection('bodyweight')
              .orderBy('date', descending: true)
              .limit(6)
              .get();
      final vals =
          prev.docs
              .map((d) => (d.data()['weight'] as num?)?.toDouble())
              .whereType<double>()
              .toList();
      vals.insert(0, kg);
      if (vals.isNotEmpty) {
        t7 = vals.take(7).reduce((a, b) => a + b) / vals.take(7).length;
      }
    }
    await _root.collection('bodyweight').doc(key).set({
      'date': date.toIso8601String(),
      'weight': kg,
      if (t7 != null) 'trend7': t7,
    });
  }

  Stream<List<BodyWeightEntry>> streamBodyWeight({int limit = 180}) {
    return _root
        .collection('bodyweight')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => BodyWeightEntry.fromMap(d.id, d.data()))
                  .toList()
                  .reversed
                  .toList(),
        );
  }

  Future<void> setBodyWeightTarget(double? kg) async {
    await _root.set({'bodyWeightTarget': kg}, SetOptions(merge: true));
  }

  Stream<GymGoals> streamGoals() {
    return _root.snapshots().map(
      (d) =>
          d.exists
              ? GymGoals.fromMap(d.data() as Map<String, dynamic>)
              : const GymGoals(),
    );
  }

     Future<void> addMeasurement(
    String muscle,
    double cm,
    DateTime date, {
    String site = 'avg',
  }) async {
    await _root.collection('measurements').add({
      'muscle': muscle,
      'valueCm': cm,
      'site': site,
      'date': date.toIso8601String(),
    });
  }

  Stream<List<MeasurementEntry>> streamMeasurements({
    String? muscle,
    int limit = 180,
  }) {
    Query q = _root
        .collection('measurements')
        .orderBy('date', descending: true)
        .limit(limit);
    if (muscle != null) q = q.where('muscle', isEqualTo: muscle);
    return q.snapshots().map(
      (s) =>
          s.docs
              .map(
                (d) => MeasurementEntry.fromMap(
                  d.id,
                  d.data() as Map<String, dynamic>,
                ),
              )
              .toList()
              .reversed
              .toList(),
    );
  }

     
     Future<List<({DateTime date, double e1rm})>> getExerciseE1rmHistory(
    String exerciseName, {
    int lookback = 90,
  }) async {
    final results = <({DateTime date, double e1rm})>[];
    final snap =
        await _root
            .collection('sessions')
            .orderBy('date', descending: true)
            .limit(lookback)
            .get();
    
    for (final d in snap.docs) {
      final data = d.data();
      final date = DateTime.tryParse(data['date'] ?? '');
      if (date == null) continue;
      
      final list =
          (data['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final ex in list) {
        if ((ex['name'] ?? '') == exerciseName) {
          final sets =
              (ex['sets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          double? bestInSession;
          for (final s in sets) {
            final w = (s['weight'] ?? 0).toDouble();
            final r = (s['reps'] ?? 0).toInt();
            final e1 = w * (1 + r / 30.0);
            if (bestInSession == null || e1 > bestInSession) {
              bestInSession = e1;
            }
          }
          if (bestInSession != null) {
            results.add((date: date, e1rm: bestInSession));
          }
        }
      }
    }
    
    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

     Future<List<({DateTime date, double volume})>> getExerciseVolumeHistory(
    String exerciseName, {
    int lookback = 90,
  }) async {
    final results = <({DateTime date, double volume})>[];
    final snap =
        await _root
            .collection('sessions')
            .orderBy('date', descending: true)
            .limit(lookback)
            .get();
    
    for (final d in snap.docs) {
      final data = d.data();
      final date = DateTime.tryParse(data['date'] ?? '');
      if (date == null) continue;
      
      final list =
          (data['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final ex in list) {
        if ((ex['name'] ?? '') == exerciseName) {
          final sets =
              (ex['sets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          double volume = 0;
          for (final s in sets) {
            final w = (s['weight'] ?? 0).toDouble();
            final r = (s['reps'] ?? 0).toInt();
            volume += w * r;
          }
          if (volume > 0) {
            results.add((date: date, volume: volume));
          }
        }
      }
    }
    
    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

     Future<List<({DateTime date, double weight, int reps, double e1rm})>> getExercisePRs(
    String exerciseName, {
    int limit = 10,
  }) async {
    final allRecords = <({DateTime date, double weight, int reps, double e1rm})>[];
    final snap =
        await _root
            .collection('sessions')
            .orderBy('date', descending: true)
            .get();
    
    for (final d in snap.docs) {
      final data = d.data();
      final date = DateTime.tryParse(data['date'] ?? '');
      if (date == null) continue;
      
      final list =
          (data['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final ex in list) {
        if ((ex['name'] ?? '') == exerciseName) {
          final sets =
              (ex['sets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          for (final s in sets) {
            final w = (s['weight'] ?? 0).toDouble();
            final r = (s['reps'] ?? 0).toInt();
            if (w > 0 && r > 0) {
              final e1 = w * (1 + r / 30.0);
              allRecords.add((date: date, weight: w, reps: r, e1rm: e1));
            }
          }
        }
      }
    }
    
         allRecords.sort((a, b) => b.e1rm.compareTo(a.e1rm));
    return allRecords.take(limit).toList();
  }

     Future<Map<String, dynamic>> exportAllData() async {
         final sessions = await _root.collection('sessions').get();
    final sessionsData = sessions.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    
         final bodyweight = await _root.collection('bodyweight').get();
    final bodyweightData = bodyweight.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    
         final measurements = await _root.collection('measurements').get();
    final measurementsData = measurements.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    
         final routines = await _root.collection('routines').get();
    final routinesData = <Map<String, dynamic>>[];
    for (final r in routines.docs) {
      final routineData = {'id': r.id, ...r.data()};
      final days = await r.reference.collection('days').get();
      final daysData = <Map<String, dynamic>>[];
      for (final d in days.docs) {
        final dayData = {'id': d.id, ...d.data()};
        final exs = await d.reference.collection('exercises').get();
        dayData['exercises'] = exs.docs.map((e) => {'id': e.id, ...e.data()}).toList();
        daysData.add(dayData);
      }
      routineData['days'] = daysData;
      routinesData.add(routineData);
    }
    
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'userId': _uid,
      'sessions': sessionsData,
      'bodyWeight': bodyweightData,
      'measurements': measurementsData,
      'routines': routinesData,
    };
  }

     Future<Map<String, dynamic>> getStatsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final sessions =
        await _root
            .collection('sessions')
            .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
            .where('date', isLessThanOrEqualTo: end.toIso8601String())
            .get();
    
    if (sessions.docs.isEmpty) {
      return {
        'totalSessions': 0,
        'totalVolume': 0.0,
        'avgDuration': 0,
        'avgEnergy': 0.0,
        'avgFatigue': 0.0,
        'avgMotivation': 0.0,
      };
    }
    
    double totalVolume = 0;
    int totalDuration = 0;
    int durationCount = 0;
    double totalEnergy = 0;
    double totalFatigue = 0;
    double totalMotivation = 0;
    int feelingsCount = 0;
    
    for (final d in sessions.docs) {
      final data = d.data();
      totalVolume += (data['volumeKg'] as num?)?.toDouble() ?? 0;
      final dur = (data['durationMin'] as num?)?.toInt();
      if (dur != null) {
        totalDuration += dur;
        durationCount++;
      }
      
      final energy = (data['feelingEnergy'] as num?)?.toDouble();
      final fatigue = (data['feelingFatigue'] as num?)?.toDouble();
      final motivation = (data['feelingMotivation'] as num?)?.toDouble();
      if (energy != null && fatigue != null && motivation != null) {
        totalEnergy += energy;
        totalFatigue += fatigue;
        totalMotivation += motivation;
        feelingsCount++;
      }
    }
    
    return {
      'totalSessions': sessions.docs.length,
      'totalVolume': totalVolume,
      'avgDuration': durationCount > 0 ? totalDuration / durationCount : 0,
      'avgEnergy': feelingsCount > 0 ? totalEnergy / feelingsCount : 0,
      'avgFatigue': feelingsCount > 0 ? totalFatigue / feelingsCount : 0,
      'avgMotivation': feelingsCount > 0 ? totalMotivation / feelingsCount : 0,
    };
  }

     Future<String> createRoutineFromPreset(
    String name,
    String description,
    String splitType,
    List<PresetDay> presetDays,
  ) async {
         final routineId = await createRoutine(
      name: name,
      description: description,
      splitType: splitType,
      restSecDefault: 90,
    );
    
         for (int dayIndex = 0; dayIndex < presetDays.length; dayIndex++) {
      final pd = presetDays[dayIndex];
      final dayId = await addDay(
        routineId,
        pd.name,
        order: dayIndex,
        icon: pd.icon,
      );
      
             for (int exIndex = 0; exIndex < pd.exercises.length; exIndex++) {
        final pe = pd.exercises[exIndex];
        final routineEx = RoutineExercise(
          id: '',
          exerciseId: pe.exerciseId,
          name: pe.name,
          muscleGroup: pe.muscleGroup,
          category: pe.category,
          targetSets: pe.targetSets,
          targetReps: pe.targetReps,
          order: exIndex,
          restSec: pe.restSec,
          tempo: pe.tempo,
          targetRPE: pe.targetRPE,
          notes: pe.notes,
        );
        await addRoutineExercise(routineId, dayId, routineEx);
      }
    }
    
    return routineId;
  }
}
