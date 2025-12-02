import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gym_models.dart';

class GymFirestoreService {
  GymFirestoreService();

  String get _uid {
    final u = FirebaseAuth.instance.currentUser?.uid;
    if (u == null || u.isEmpty) {
      throw StateError('No hay usuario autenticado para GymFirestoreService');
    }
    return u;
  }

  DocumentReference<Map<String, dynamic>> get _root => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('gym')
      .doc('root');

  DocumentReference<Map<String, dynamic>> get root => _root;

  // ===== Routines =====
  Stream<List<Routine>> streamRoutines() {
    return _root.collection('routines').orderBy('name').snapshots().map(
          (s) => s.docs.map((d) => Routine.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<Routine?> streamDefaultRoutine() {
    return _root
        .collection('routines')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((s) =>
            s.docs.isEmpty ? null : Routine.fromMap(s.docs.first.id, s.docs.first.data()));
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
    final days = await _root.collection('routines').doc(id).collection('days').get();
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

  // ===== Days =====
  Stream<List<RoutineDay>> streamDays(String routineId) {
    return _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .orderBy('order', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => RoutineDay.fromMap(d.id, d.data())).toList());
  }

  Future<String> addDay(String routineId, String name, {int? order, String? icon}) async {
    final col = _root.collection('routines').doc(routineId).collection('days');
    final doc = await col.add({
      'name': name,
      'order': order ?? DateTime.now().millisecondsSinceEpoch,
      'icon': icon,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateDay(String routineId, String dayId, Map<String, dynamic> data) async {
    await _root.collection('routines').doc(routineId).collection('days').doc(dayId).update(data);
  }

  Future<void> reorderDays(String routineId, List<String> orderedDayIds) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < orderedDayIds.length; i++) {
      final ref =
          _root.collection('routines').doc(routineId).collection('days').doc(orderedDayIds[i]);
      batch.update(ref, {'order': i});
    }
    await batch.commit();
  }

  Future<void> duplicateDay(String routineId, String dayId) async {
    final src =
        await _root.collection('routines').doc(routineId).collection('days').doc(dayId).get();
    if (!src.exists) return;
    final data = src.data() as Map<String, dynamic>;
    final newDay =
        await _root.collection('routines').doc(routineId).collection('days').add({
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
    final dRef = _root.collection('routines').doc(routineId).collection('days').doc(dayId);
    final exs = await dRef.collection('exercises').get();
    for (final e in exs.docs) {
      await e.reference.delete();
    }
    await dRef.delete();
  }

  // ===== Exercises in day =====
  Stream<List<RoutineExercise>> streamDayExercises(String routineId, String dayId) {
    return _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId)
        .collection('exercises')
        .orderBy('order', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => RoutineExercise.fromMap(d.id, d.data())).toList());
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

  Future<void> duplicateExercise(String routineId, String dayId, String exId) async {
    final src = await _root
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
        .add({
      ...data,
      'order': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteRoutineExercise(String routineId, String dayId, String exId) async {
    await _root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId)
        .collection('exercises')
        .doc(exId)
        .delete();
  }

  // ===== Sessions =====
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

  Stream<List<SessionDoc>> streamSessions({
    String? routineId,
    String? dayId,
    int limit = 50,
  }) {
    Query q = _root.collection('sessions').orderBy('date', descending: true).limit(limit);
    if (routineId != null) q = q.where('routineId', isEqualTo: routineId);
    if (dayId != null) q = q.where('dayId', isEqualTo: dayId);
    return q.snapshots().map(
          (s) =>
              s.docs.map((d) => SessionDoc.fromMap(d.id, d.data() as Map<String, dynamic>)).toList(),
        );
  }

  Future<double?> bestE1rmForExercise(String exerciseName, {int lookback = 60}) async {
    final snap =
        await _root.collection('sessions').orderBy('date', descending: true).limit(lookback).get();
    double? best;
    for (final d in snap.docs) {
      final data = d.data();
      final list = (data['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final ex in list) {
        if ((ex['name'] ?? '') == exerciseName) {
          final sets = (ex['sets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
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
    final ref = _root.collection('routines').doc(routineId).collection('days').doc(dayId);
    await ref.set({
      'lastDoneAt': FieldValue.serverTimestamp(),
      'completedCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// 🔎 Última sesión registrada (para recordar inactividad)
  Future<DateTime?> lastSessionDate() async {
    final snap = await _root
        .collection('sessions')
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    return DateTime.tryParse(data['date']?.toString() ?? '');
  }

  // ===== Body weight =====
  Future<void> addBodyWeight(double kg, DateTime date,
      {double? trend7, bool computeTrend = true}) async {
    final key = date.toIso8601String().substring(0, 10);
    double? t7 = trend7;
    if (computeTrend) {
      final prev =
          await _root.collection('bodyweight').orderBy('date', descending: true).limit(6).get();
      final vals = prev.docs
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
        .map((s) => s.docs
            .map((d) => BodyWeightEntry.fromMap(d.id, d.data()))
            .toList()
            .reversed
            .toList());
  }

  Future<void> setBodyWeightTarget(double? kg) async {
    await _root.set({'bodyWeightTarget': kg}, SetOptions(merge: true));
  }

  Stream<GymGoals> streamGoals() {
    return _root.snapshots().map((d) =>
        d.exists ? GymGoals.fromMap(d.data() as Map<String, dynamic>) : const GymGoals());
  }

  // ===== Measurements (cm) =====
  Future<void> addMeasurement(String muscle, double cm, DateTime date,
      {String site = 'avg'}) async {
    await _root.collection('measurements').add({
      'muscle': muscle,
      'valueCm': cm,
      'site': site,
      'date': date.toIso8601String(),
    });
  }

  Stream<List<MeasurementEntry>> streamMeasurements({String? muscle, int limit = 180}) {
    Query q =
        _root.collection('measurements').orderBy('date', descending: true).limit(limit);
    if (muscle != null) q = q.where('muscle', isEqualTo: muscle);
    return q.snapshots().map((s) => s.docs
        .map((d) => MeasurementEntry.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList()
        .reversed
        .toList());
  }
}
