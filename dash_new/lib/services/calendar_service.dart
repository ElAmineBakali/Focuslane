import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/calendar_models.dart';

class CalendarService {
  CalendarService._();
  static final CalendarService I = CalendarService._();

  final _db = FirebaseFirestore.instance;

  int _minOf(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
    return h * 60 + m;
  }

  String _norm(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<String?> _ensureUid() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Stream<T> _withUserStream<T>(Stream<T> Function(String uid) build) {
    return FirebaseAuth.instance
        .authStateChanges()
        .map((u) => u?.uid)
        .distinct()
        .asyncExpand((uid) {
          if (uid == null) return Stream<T>.empty();
          return build(uid);
        });
  }

  DocumentReference<Map<String, dynamic>> _plannerDoc(String uid) =>
      _db.collection('users').doc(uid).collection('planner').doc('data');

  CollectionReference<Map<String, dynamic>> _eventsCol(String uid) =>
      _plannerDoc(uid).collection('calendar');

  CollectionReference<Map<String, dynamic>> _timetableCol(String uid) =>
      _plannerDoc(uid).collection('timetables');

  Stream<PlannerPrefs> watchPrefs() {
    return _withUserStream((uid) {
      final doc = _plannerDoc(uid).collection('meta').doc('prefs');
      return doc.snapshots().map(PlannerPrefs.fromSnap);
    });
  }

  Future<void> savePrefs(PlannerPrefs p) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    await _plannerDoc(uid).collection('meta').doc('prefs')
        .set(p.toMap(), SetOptions(merge: true));
  }

  Stream<List<CalendarEvent>> watchRange(DateTime from, DateTime to) {
    return _withUserStream((uid) {
      return _eventsCol(uid)
          .where('start', isGreaterThanOrEqualTo:
              Timestamp.fromDate(DateTime(from.year, from.month, from.day)))
          .where('start', isLessThanOrEqualTo:
              Timestamp.fromDate(DateTime(to.year, to.month, to.day, 23, 59, 59)))
          .snapshots()
          .map((s) => s.docs.map(CalendarEvent.fromSnap).toList());
    });
  }

  Future<String?> addEvent(CalendarEvent e) async {
    final uid = await _ensureUid();
    if (uid == null) return null;
    final fixed = _withDefaultEnd(e);
    final d = await _eventsCol(uid).add(fixed.toMap());
    return d.id;
  }

  Future<void> updateEvent(CalendarEvent e) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    final fixed = _withDefaultEnd(e);
    await _eventsCol(uid).doc(e.id).update(fixed.toMap());
  }

  Future<void> deleteEvent(String id) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    await _eventsCol(uid).doc(id).delete();
  }

  CalendarEvent _withDefaultEnd(CalendarEvent e) {
    if (e.end != null) return e;
    if (e.allDay) {
      return CalendarEvent(
        id: e.id, title: e.title, type: e.type, priority: e.priority,
        start: e.start,
        end: DateTime(e.start.year, e.start.month, e.start.day, 23, 59),
        allDay: true, notes: e.notes,
      );
    } else {
      return CalendarEvent(
        id: e.id, title: e.title, type: e.type, priority: e.priority,
        start: e.start,
        end: e.start.add(const Duration(hours: 1)),
        allDay: false, notes: e.notes,
      );
    }
  }

  Stream<List<Timetable>> watchTimetables() {
    return _withUserStream((uid) {
      return _timetableCol(uid)
          .orderBy('name')
          .snapshots()
          .map((s) => s.docs.map(Timetable.fromSnap).toList());
    });
  }

  Future<String?> addTimetable(Timetable t) async {
    final uid = await _ensureUid();
    if (uid == null) return null;
    final d = await _timetableCol(uid).add(t.toMap());
    return d.id;
  }

  Future<void> updateTimetable(Timetable t) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    await _timetableCol(uid).doc(t.id).update(t.toMap());
  }

  Future<void> deleteTimetable(String id) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    await _timetableCol(uid).doc(id).delete();
  }

  Stream<List<TimetableSlot>> watchSlots(String timetableId) {
    return _withUserStream((uid) {
      return _timetableCol(uid).doc(timetableId).collection('slots')
          .orderBy('day')
          .orderBy('startMin')
          .snapshots()
          .map((s) => s.docs.map(TimetableSlot.fromSnap).toList());
    });
  }

  Future<String?> addSlot(String timetableId, TimetableSlot s) async {
    final uid = await _ensureUid();
    if (uid == null) return null;
    final data = s.toMap()
      ..['start']    = _norm(s.start)
      ..['end']      = _norm(s.end)
      ..['startMin'] = _minOf(s.start)
      ..['endMin']   = _minOf(s.end);
    final d = await _timetableCol(uid).doc(timetableId)
        .collection('slots').add(data);
    return d.id;
  }

  Future<void> updateSlot(String timetableId, TimetableSlot s) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    final data = s.toMap()
      ..['start']    = _norm(s.start)
      ..['end']      = _norm(s.end)
      ..['startMin'] = _minOf(s.start)
      ..['endMin']   = _minOf(s.end);
    await _timetableCol(uid).doc(timetableId)
        .collection('slots').doc(s.id).update(data);
  }

  Future<void> deleteSlot(String timetableId, String slotId) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    await _timetableCol(uid).doc(timetableId)
        .collection('slots').doc(slotId).delete();
  }
}
