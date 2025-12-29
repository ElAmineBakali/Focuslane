import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_model.dart';

class TaskFirestoreService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  static Stream<T> _withUserStream<T>(Stream<T> Function(String uid) build) {
    return FirebaseAuth.instance
        .authStateChanges()
        .map((u) => u?.uid)
        .distinct()
        .asyncExpand((uid) => uid == null ? const Stream.empty() : build(uid));
  }

  static Stream<List<Task>> getTasks() {
    return _withUserStream((uid) {
      return _col(uid).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return Task.fromMap(data);
        }).toList();
      });
    });
  }

  static Future<String?> addTask(Task task) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final map = task.toMap()..remove('id');
    final ref = await _col(uid).add(map);
    return ref.id;
  }

  static Future<void> updateTask(Task task) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final map = task.toMap()..remove('id');
    await _col(uid).doc(task.id).update(map);
  }

  static Future<void> deleteTask(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _col(uid).doc(id).delete();
  }
}
