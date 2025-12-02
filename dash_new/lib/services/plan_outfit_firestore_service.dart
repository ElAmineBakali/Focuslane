import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan_outfit_model.dart';

class PlanOutfitFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('wardrobe_plans');

  Stream<List<PlanOutfit>> planesPorRango(
    String uid,
    DateTime inicio,
    DateTime fin,
  ) {
    return _col(uid)
        .where('fecha', isGreaterThanOrEqualTo: inicio)
        .where('fecha', isLessThanOrEqualTo: fin)
        .snapshots()
        .map((s) => s.docs.map((d) => PlanOutfit.fromFirestore(d)).toList());
  }

  Future<void> addPlan(String uid, PlanOutfit plan) async {
    final doc = _col(uid).doc();
    await doc.set(plan.toFirestore());
  }

  Future<void> updatePlan(String uid, PlanOutfit plan) async {
    await _col(uid).doc(plan.id).update(plan.toFirestore());
  }

  Future<void> deletePlan(String uid, String planId) async {
    await _col(uid).doc(planId).delete();
  }
}
