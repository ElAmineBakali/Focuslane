import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_model.dart';
import '../utils/habit_utils.dart';

class HabitFirestoreService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('habits');

  static Stream<T> _withUserStream<T>(Stream<T> Function(String uid) build) {
    return FirebaseAuth.instance
        .authStateChanges()
        .map((u) => u?.uid)
        .distinct()
        .asyncExpand((uid) => uid == null ? const Stream.empty() : build(uid));
  }

  static Stream<List<Habit>> getHabits({bool activeOnly = true}) {
    return _withUserStream((uid) {
      Query q = _col(uid).orderBy('order');
      if (activeOnly) q = q.where('isActive', isEqualTo: true);
      q = q.limit(200);
      return q.snapshots().map(
        (s) => s.docs.map((d) => Habit.fromDoc(d)).toList(),
      );
    });
  }

  static Stream<List<Habit>> getArchivedHabits() {
    return _withUserStream((uid) {
      return _col(uid)
          .where('isActive', isEqualTo: false)
          .orderBy('order')
          .limit(200)
          .snapshots()
          .map((s) => s.docs.map((d) => Habit.fromDoc(d)).toList());
    });
  }

  Future<void> addHabit(Habit habit) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await _col(uid).get();
    final docRef = _col(uid).doc();
    final toSave =
        habit.copyWith(id: docRef.id, order: snap.docs.length).toMap();
    await docRef.set(toSave);
  }

  static Future<void> updateHabit(Habit habit) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _col(uid).doc(habit.id).update(habit.toMap());
  }

  static Future<void> updateHabitFields(
    String id,
    Map<String, dynamic> fields,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _col(uid).doc(id).update(fields);
  }

  static Future<void> deleteHabit(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _col(uid).doc(id).delete();
  }

  Future<void> updateHabitOrder(List<Habit> habits) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final batch = _db.batch();
    for (int i = 0; i < habits.length; i++) {
      batch.update(_col(uid).doc(habits[i].id), {'order': i});
    }
    await batch.commit();
  }

  Future<void> archiveHabit(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _col(uid).doc(id).update({'isActive': false});
  }

  Future<void> unarchiveHabit(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _col(uid).doc(id).update({'isActive': true});
  }

  Future<void> updateHabitHistory(
    String id,
    DateTime date,
    dynamic value,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final key = habitDateKey(date);
    await _col(uid).doc(id).set({
      'history': {key: value},
      'lastUpdated': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}
