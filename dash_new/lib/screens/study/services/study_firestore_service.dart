import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_models.dart';

class StudyFirestoreService {
  final String _fallbackUserId;
  StudyFirestoreService([this._fallbackUserId = '']);

  String get _uid {
    final u = FirebaseAuth.instance.currentUser?.uid;
    if (u != null && u.isNotEmpty) return u;
    return _fallbackUserId.isNotEmpty ? _fallbackUserId : 'local';
  }

  DocumentReference<Map<String, dynamic>> get _root => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('study')
      .doc('root');

  Stream<List<Course>> streamCourses({bool includeArchived = false}) {
    Query q = _root.collection('courses');
    if (!includeArchived) q = q.where('isArchived', isEqualTo: false);
    return q
        .orderBy('name')
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map(
                    (d) =>
                        Course.fromMap(d.id, d.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  Future<String> createCourse(Course c) async {
    final doc = _root.collection('courses').doc();
    await doc.set({...c.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    return doc.id;
  }

  Future<void> updateCourse(String id, Map<String, dynamic> data) async {
    await _root.collection('courses').doc(id).update(data);
  }

  Future<void> deleteCourse(String id) async {
    await _root.collection('courses').doc(id).delete();
  }

  Stream<List<StudyTask>> streamTasks({
    String? courseId,
    TaskStatus? status,
    bool highPriorityOnly = false,
    DateTime? from,
    DateTime? to,
  }) {
    Query q = _root.collection('tasks');

    if (courseId != null) {
      q = q.where('courseId', isEqualTo: courseId);
    }
    if (status != null) {
      q = q.where('status', isEqualTo: status.name);
    }
    if (highPriorityOnly) {
      q = q.where('priority', isEqualTo: Priority.high.name);
    }
    if (from != null) {
      q = q.where('due', isGreaterThanOrEqualTo: from.toIso8601String());
    }
    if (to != null) {
      q = q.where('due', isLessThanOrEqualTo: to.toIso8601String());
    }

    return q.snapshots().map((s) {
      var list =
          s.docs
              .map(
                (d) =>
                    StudyTask.fromMap(d.id, d.data() as Map<String, dynamic>),
              )
              .toList();

      list.sort((a, b) {
        final ad =
            a.due?.millisecondsSinceEpoch ??
            DateTime.now().add(Duration(days: 9999)).millisecondsSinceEpoch;
        final bd =
            b.due?.millisecondsSinceEpoch ??
            DateTime.now().add(Duration(days: 9999)).millisecondsSinceEpoch;
        return ad.compareTo(bd);
      });

      return list;
    });
  }

  Future<String> createTask(StudyTask t) async {
    final doc = _root.collection('tasks').doc();
    await doc.set({...t.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    return doc.id;
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _root.collection('tasks').doc(id).update(data);
  }

  Future<void> deleteTask(String id) async {
    await _root.collection('tasks').doc(id).delete();
  }

  Stream<List<TimerPreset>> streamPresets({String? courseId}) {
    Query q = _root.collection('presets');
    if (courseId != null) q = q.where('courseId', isEqualTo: courseId);
    return q
        .orderBy('name')
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map(
                    (d) => TimerPreset.fromMap(
                      d.id,
                      d.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  Future<String> savePreset(TimerPreset p) async {
    final doc = _root.collection('presets').doc();
    await doc.set(p.toMap());
    return doc.id;
  }

  Future<void> deletePreset(String id) async {
    await _root.collection('presets').doc(id).delete();
  }

  Stream<List<StudySession>> streamSessions({
    String? courseId,
    int limit = 100,
  }) {
    Query q = _root
        .collection('sessions')
        .orderBy('date', descending: true)
        .limit(limit);
    if (courseId != null) q = q.where('courseId', isEqualTo: courseId);
    return q.snapshots().map(
      (s) =>
          s.docs
              .map(
                (d) => StudySession.fromMap(
                  d.id,
                  d.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  Future<void> addSession(StudySession s) async {
    final doc = _root.collection('sessions').doc();
    await doc.set(s.toMap());
  }

  Stream<List<StudyClassBlock>> streamSchedule({String? courseId}) {
    Query q = _root.collection('schedule');
    if (courseId != null) q = q.where('courseId', isEqualTo: courseId);
    return q.snapshots().map(
      (s) =>
          s.docs
              .map(
                (d) => StudyClassBlock.fromMap(
                  d.id,
                  d.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  Future<String> addScheduleBlock(StudyClassBlock b) async {
    final doc = _root.collection('schedule').doc();
    await doc.set(b.toMap());
    return doc.id;
  }

  Future<void> updateScheduleBlock(String id, Map<String, dynamic> data) async {
    await _root.collection('schedule').doc(id).update(data);
  }

  Future<void> deleteScheduleBlock(String id) async {
    await _root.collection('schedule').doc(id).delete();
  }

  Stream<List<GradeEntry>> streamGrades({String? courseId}) {
    Query q = _root.collection('grades');
    if (courseId != null) q = q.where('courseId', isEqualTo: courseId);
    return q
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map(
                    (d) => GradeEntry.fromMap(
                      d.id,
                      d.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  Future<String> addGrade(GradeEntry g) async {
    final doc = _root.collection('grades').doc();
    await doc.set(g.toMap());
    return doc.id;
  }

  Future<void> updateGrade(String id, Map<String, dynamic> data) async {
    await _root.collection('grades').doc(id).update(data);
  }

  Future<void> deleteGrade(String id) async {
    await _root.collection('grades').doc(id).delete();
  }

  Stream<Map<String, String>> streamAttendanceMap(String courseId) {
    return _root
        .collection('attendance')
        .doc(courseId)
        .snapshots()
        .map((d) {
          final raw = d.data() ?? const <String, dynamic>{};
          final parsed = <String, String>{};
          for (final entry in raw.entries) {
            final key = entry.key;
            if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
              continue;
            }
            final status = entry.value is String
                ? (entry.value as String).trim().toUpperCase()
                : '';
            if (status == 'A' || status == 'X' || status == '-') {
              parsed[key] = status;
            }
          }
          return parsed;
        });
  }

  Future<void> setAttendance({
    required String courseId,
    required DateTime day,
    required String status,
  }) async {
    final key =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';

    await _root.collection('attendance').doc(courseId).set({
      key: status,
    }, SetOptions(merge: true));
  }

  Future<void> setAttendanceRequired(String courseId, double percent) async {
    await _root.collection('courses').doc(courseId).update({
      'attendanceRequired': percent,
    });
  }
}
