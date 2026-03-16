import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'note_model.dart';

enum NotesSortField { createdAt, lastEditedAt, title }

enum NotesSortDirection { ascending, descending }

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

  static Query<Map<String, dynamic>> _buildSortedQuery(
    String uid,
    NotesSortField sortField,
    NotesSortDirection direction,
  ) {
    final descending = direction == NotesSortDirection.descending;
    final query = _col(uid);

    switch (sortField) {
      case NotesSortField.createdAt:
        return query.orderBy('createdAt', descending: descending);
      case NotesSortField.title:
        return query.orderBy('title', descending: descending);
      case NotesSortField.lastEditedAt:
        // Keep compatibility with legacy docs that may not have lastEditedAt yet.
        return query.orderBy('updatedAt', descending: descending);
    }
  }

  static Stream<List<Note>> getNotes({
    NotesSortField sortField = NotesSortField.lastEditedAt,
    NotesSortDirection direction = NotesSortDirection.descending,
  }) {
    return _withUserStream((uid) {
      return _buildSortedQuery(uid, sortField, direction)
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
    final now = DateTime.now();
    final data = note.toMap();
    data['createdAt'] ??= Timestamp.fromDate(now);
    data['updatedAt'] ??= Timestamp.fromDate(now);
    data['lastEditedAt'] ??= Timestamp.fromDate(now);

    final ref = await _col(uid).add(data);
    try {
      await ref.update({'id': ref.id});
    } catch (e) {
      assert(() { debugPrint('[NoteFirestoreService] Error updating id: $e'); return true; }());
    }
    return ref.id;
  }

  static Future<void> update(Note note) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final data = note.toMap();
    data['updatedAt'] = Timestamp.fromDate(now);
    data['lastEditedAt'] = Timestamp.fromDate(now);
    await _col(uid).doc(note.id).update(data);
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
