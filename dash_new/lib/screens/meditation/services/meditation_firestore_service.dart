import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meditation_models.dart';

class MeditationFirestoreService {
  MeditationFirestoreService._();
  static final MeditationFirestoreService I = MeditationFirestoreService._();

  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  /// Paths
  CollectionReference get _root =>
      _db.collection('users').doc(_uid).collection('meditation');
  CollectionReference get _sessionsCol =>
      _root.doc('data').collection('sessions');
  CollectionReference get _programsCol =>
      _root.doc('data').collection('programs');
  CollectionReference programDaysCol(String programId) =>
      _programsCol.doc(programId).collection('days');
  CollectionReference get _presetsCol =>
      _root.doc('data').collection('breath_presets');
  CollectionReference get _remindersCol =>
      _root.doc('data').collection('reminders');
  CollectionReference get _tagsCol => _root.doc('data').collection('tags');
  CollectionReference get _guidedCol =>
      _root.doc('data').collection('guided'); // NUEVO
  DocumentReference get _metaDoc => _root.doc('meta');

  // ---- helpers de clave de fecha/mes ----
  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  /// ===== Sessions
  Stream<List<MeditationSession>> watchSessions(
      {DateTime? from, DateTime? to, SessionType? type}) {
    Query q = _sessionsCol.orderBy('date', descending: true);
    if (type != null) q = q.where('type', isEqualTo: type.name);
    if (from != null) {
      q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    return q.snapshots().map((s) => s.docs.map(MeditationSession.fromSnap).toList());
  }

  Future<void> addSession(MeditationSession x) async {
    await _sessionsCol.add(x.toMap());
    await _updateMetaAfterSession(x);
  }

  Future<void> updateSession(MeditationSession x) async {
    await _sessionsCol.doc(x.id).update(x.toMap());
  }

  Future<void> deleteSession(String id) async {
    await _sessionsCol.doc(id).delete();
  }

  /// Actualiza minutos y racha (streak/bestStreak).
  Future<void> _updateMetaAfterSession(MeditationSession x) async {
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final monthKey = _monthKey(now);
    final addMinutes = (x.durationSec / 60).round();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(_metaDoc);
      int newStreak = 1;
      int bestStreak = 1;
      int minutesThisMonth = addMinutes;
      int minutesTotal = addMinutes;

      if (snap.exists) {
        final m = (snap.data() as Map<String, dynamic>);
        final lastDayKey = m['lastDayKey'] as String?;
        final lastMonthKey = m['lastMonthKey'] as String?;
        final prevStreak = (m['streak'] as num?)?.toInt() ?? 0;
        bestStreak = (m['bestStreak'] as num?)?.toInt() ?? 0;

        if (lastDayKey == todayKey) {
          // Más de una sesión en el mismo día: mantener racha
          newStreak = prevStreak > 0 ? prevStreak : 1;
        } else if (lastDayKey ==
            _dayKey(now.subtract(const Duration(days: 1)))) {
          newStreak = prevStreak + 1;
        } else {
          newStreak = 1;
        }
        if (newStreak > bestStreak) bestStreak = newStreak;

        minutesTotal =
            ((m['minutesTotal'] as num?)?.toInt() ?? 0) + addMinutes;

        if (lastMonthKey == monthKey) {
          minutesThisMonth =
              ((m['minutesThisMonth'] as num?)?.toInt() ?? 0) + addMinutes;
        } else {
          minutesThisMonth = addMinutes;
        }
      }

      tx.set(
        _metaDoc,
        {
          'lastSessionAt': Timestamp.fromDate(x.date),
          'lastDayKey': todayKey,
          'lastMonthKey': monthKey,
          'streak': newStreak,
          'bestStreak': bestStreak,
          'minutesThisMonth': minutesThisMonth,
          'minutesTotal': minutesTotal,
        },
        SetOptions(merge: true),
      );
    });
  }

  /// ===== Programs
  Stream<List<MeditationProgram>> watchPrograms({bool? onlyActive}) {
    Query q = _programsCol.orderBy('name');
    if (onlyActive == true) q = q.where('isActive', isEqualTo: true);
    return q.snapshots().map((s) => s.docs.map(MeditationProgram.fromSnap).toList());
  }

  Future<String> addProgram(MeditationProgram p) async {
    final ref = await _programsCol.add(p.toMap());
    return ref.id;
  }

  Future<void> updateProgram(MeditationProgram p) async {
    await _programsCol.doc(p.id).update(p.toMap());
  }

  Future<void> deleteProgram(String id) async {
    await _programsCol.doc(id).delete();
  }

  Stream<List<ProgramDay>> watchProgramDays(String programId) => programDaysCol(programId)
      .orderBy('dayNumber')
      .snapshots()
      .map((s) => s.docs.map(ProgramDay.fromSnap).toList());

  Future<void> addProgramDay(String programId, ProgramDay d) async =>
      await programDaysCol(programId).add(d.toMap());

  Future<void> updateProgramDay(String programId, ProgramDay d) async =>
      await programDaysCol(programId).doc(d.id).update(d.toMap());

  Future<void> deleteProgramDay(String programId, String dayId) async =>
      await programDaysCol(programId).doc(dayId).delete();

  /// ===== Presets
  Stream<List<BreathPreset>> watchPresets() => _presetsCol
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(BreathPreset.fromSnap).toList());

  Future<void> addPreset(BreathPreset p) async => _presetsCol.add(p.toMap());
  Future<void> updatePreset(BreathPreset p) async =>
      _presetsCol.doc(p.id).update(p.toMap());
  Future<void> deletePreset(String id) async => _presetsCol.doc(id).delete();

  /// ===== Reminders
  Stream<List<MeditationReminder>> watchReminders() => _remindersCol
      .orderBy('timeOfDay')
      .snapshots()
      .map((s) => s.docs.map(MeditationReminder.fromSnap).toList());

  // ⬇️ Devuelve el id para poder programar la notificación al guardar
  Future<String> addReminder(MeditationReminder r) async {
    final ref = await _remindersCol.add(r.toMap());
    return ref.id;
  }

  Future<void> updateReminder(MeditationReminder r) async =>
      _remindersCol.doc(r.id).update(r.toMap());
  Future<void> deleteReminder(String id) async =>
      _remindersCol.doc(id).delete();

  /// ===== Tags
  Stream<List<SimpleTag>> watchTags() => _tagsCol
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(SimpleTag.fromSnap).toList());

  Future<void> addTag(SimpleTag t) async => _tagsCol.add(t.toMap());
  Future<void> deleteTag(String id) async => _tagsCol.doc(id).delete();

  /// ===== Guided Library
  Stream<List<GuidedAudio>> watchGuided() => _guidedCol
      .orderBy('title')
      .snapshots()
      .map((s) => s.docs.map(GuidedAudio.fromSnap).toList());

  Future<void> addGuided(GuidedAudio g) async => _guidedCol.add(g.toMap());
  Future<void> updateGuided(GuidedAudio g) async =>
      _guidedCol.doc(g.id).update(g.toMap());
  Future<void> deleteGuided(String id) async => _guidedCol.doc(id).delete();

  /// ===== Analytics helpers
  Future<Map<String, dynamic>> monthStats(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final qs = await _sessionsCol
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    int minutes = 0;
    int count = qs.docs.length;
    final byType = <String, int>{};
    for (final d in qs.docs) {
      final m = d.data() as Map<String, dynamic>;
      final dur = (m['durationSec'] as num?)?.toInt() ?? 0;
      minutes += (dur / 60).round();

      final t = m['type']?.toString() ?? 'timer';
      byType[t] = (byType[t] ?? 0) + (dur / 60).round();
    }
    return {
      'minutes': minutes,
      'count': count,
      'byType': byType,
    };
  }

  Future<Map<DateTime, int>> heatmapMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final qs = await _sessionsCol
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final map = <DateTime, int>{};
    for (final d in qs.docs) {
      final m = d.data() as Map<String, dynamic>;
      final dt = (m['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final key = DateTime(dt.year, dt.month, dt.day);
      final durMin = ((m['durationSec'] as num?)?.toInt() ?? 0) ~/ 60;
      map[key] = (map[key] ?? 0) + durMin;
    }
    return map;
  }

  /// ===== Meta (streak, etc.)
  Stream<Map<String, dynamic>> watchMeta() {
    return _metaDoc.snapshots().map((d) {
      final raw = d.data();
      if (raw is Map<String, dynamic>) return raw;
      return const <String, dynamic>{};
    });
  }
}
