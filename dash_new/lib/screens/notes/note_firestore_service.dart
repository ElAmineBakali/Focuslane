import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'note_model.dart';

class NoteFirestoreService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('notes');

  static Stream<T> _withUserStream<T>(Stream<T> Function(String uid) build) {
    return FirebaseAuth.instance
        .authStateChanges()
        .map((u) => u?.uid)
        .distinct()
        .asyncExpand((uid) => uid == null ? const Stream.empty() : build(uid));
  }

  static Stream<List<Note>> getNotes() {
    return _withUserStream((uid) {
      return _col(uid)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Note.fromDoc(doc)).toList(),
          );
    });
  }

  static Future<String?> add(Note note) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final data = note.toMap();
    // Asegurar timestamps y consistencia
    if (!data.containsKey('createdAt'))
      data['createdAt'] = Timestamp.fromDate(DateTime.now());
    if (!data.containsKey('updatedAt'))
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    final ref = await _col(uid).add(data);
    // Añadir campo id explícito para futuras migraciones (opcional)
    try {
      await ref.update({'id': ref.id});
    } catch (e) {
      // ignore: avoid_print
      print('[NoteFirestoreService] Error updating id field: $e');
    }
    // Debug log
    // ignore: avoid_print
    print('[NoteFirestoreService] add -> id=${ref.id} title=${note.title}');
    return ref.id;
  }

  static Future<void> update(Note note) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = note.toMap();
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _col(uid).doc(note.id).update(data);
    // ignore: avoid_print
    print('[NoteFirestoreService] update -> id=${note.id} title=${note.title}');
  }

  static Future<void> delete(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _col(uid).doc(id).delete();
  }

  static Future<Note?> getById(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _col(uid).doc(id).get();
    if (!doc.exists) return null;
    return Note.fromDoc(doc);
  }
}
