import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goals_models.dart';

class GoalsFirestoreService {
  GoalsFirestoreService._();
  static final I = GoalsFirestoreService._();

  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _coll() =>
      _db.collection('users').doc(_uid).collection('goals');

  Stream<List<Goal>> watchGoals() => _coll()
      .orderBy('order', descending: false)
      .snapshots()
      .map((s) => s.docs.map(Goal.fromSnap).toList());

  Future<String> addGoal(Goal g) async {
    final m = g.toMap(_uid);
    m['order'] = m['order'] ?? DateTime.now().millisecondsSinceEpoch;
    final doc = await _coll().add(m);
    return doc.id;
  }

  Future<void> updateGoal(Goal g) async {
    await _coll().doc(g.id).update(g.toMap(_uid));
  }

  Future<void> deleteGoal(String id) async {
    await _coll().doc(id).delete();
  }

  Future<void> updateGoalsOrder(List<Goal> goals) async {
    final batch = _db.batch();
    for (var i = 0; i < goals.length; i++) {
      final g = goals[i];
      batch.update(_coll().doc(g.id), {'order': i});
    }
    await batch.commit();
  }

  /// Backfill: asigna 'order' secuencial sólo a metas sin el campo.
  Future<void> backfillGoalsOrder() async {
    final snap = await _coll().get();
    final batch = _db.batch();
    int idx = 0;
    for (final d in snap.docs) {
      final data = d.data();
      if (!data.containsKey('order')) {
        batch.update(d.reference, {'order': idx});
      }
      idx++; // conserva el orden actual de consulta
    }
    await batch.commit();
  }

  // ===== Subgoals =====
  CollectionReference<Map<String, dynamic>> _subCol(String goalId) =>
      _coll().doc(goalId).collection('subgoals');

  /// Ordenamos sólo por `order` (para evitar índices compuestos);
  /// si necesitas por fecha también, ordénalo en memoria en la UI.
  Stream<List<SubGoal>> watchSubGoals(String goalId) => _subCol(goalId)
      .orderBy('order', descending: false)
      .snapshots()
      .map((s) => s.docs.map(SubGoal.fromSnap).toList());

  Future<String> addSubGoal(String goalId, SubGoal sg) async {
    final doc = _subCol(goalId).doc();
    await doc.set(sg.toMap());
    return doc.id;
  }

  Future<void> updateSubGoal(String goalId, SubGoal sg) async {
    await _subCol(goalId).doc(sg.id).update(sg.toMap());
  }

  Future<void> deleteSubGoal(String goalId, String subId) async {
    await _subCol(goalId).doc(subId).delete();
  }

  Future<void> setSubGoalStatus(
    String goalId,
    String subId,
    GoalStatus status,
  ) async {
    await _subCol(goalId).doc(subId).update({'status': status.name});
  }

  Future<void> bumpSubGoalProgress(
    String goalId,
    String subId,
    double delta,
  ) async {
    await _db.runTransaction((tx) async {
      final ref = _subCol(goalId).doc(subId);
      final snap = await tx.get(ref);
      final d = (snap.data() ?? {});
      final cur = (d['progress'] as num?)?.toDouble() ?? 0.0;
      tx.update(ref, {'progress': (cur + delta)});
    });
  }
}
