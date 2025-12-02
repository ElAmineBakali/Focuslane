import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/skills_models.dart';

class SkillsFirestoreService {
  SkillsFirestoreService._();
  static final SkillsFirestoreService I = SkillsFirestoreService._();

  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Raíces
  CollectionReference<Map<String, dynamic>> get _root =>
      _db.collection('users').doc(_uid).collection('skills');
  CollectionReference<Map<String, dynamic>> get _skillsCol =>
      _root.doc('data').collection('skills');
  DocumentReference<Map<String, dynamic>> _skillDoc(String skillId) =>
      _skillsCol.doc(skillId);

  CollectionReference _subSkillsCol(String skillId) =>
      _skillDoc(skillId).collection('subskills');
  CollectionReference _sessionsCol(String skillId) =>
      _skillDoc(skillId).collection('sessions');
  CollectionReference _projectsCol(String skillId) =>
      _skillDoc(skillId).collection('projects');
  CollectionReference _resourcesCol(String skillId) =>
      _skillDoc(skillId).collection('resources');

  DocumentReference<Map<String, dynamic>> get _metaDoc => _root.doc('meta');

  // ===== Skills
  Stream<List<Skill>> watchSkills() => _skillsCol
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Skill.fromSnap).toList());

  Future<String> addSkill(Skill s) async {
    final r = await _skillsCol.add(s.toMap());
    await _touchMeta();
    return r.id;
  }

  Future<void> updateSkill(Skill s) async {
    await _skillsCol.doc(s.id).update(s.toMap());
    await _touchMeta();
  }

  Future<void> deleteSkill(String id) async {
    await _skillsCol.doc(id).delete();
    await _touchMeta();
  }

  // ===== SubSkills
  Stream<List<SubSkill>> watchSubSkills(String skillId) =>
      _subSkillsCol(skillId)
          .orderBy('order')
          .snapshots()
          .map((s) => s.docs.map(SubSkill.fromSnap).toList());

  Future<void> addSubSkill(String skillId, SubSkill x) async =>
      _subSkillsCol(skillId).add(x.toMap());

  Future<void> updateSubSkill(String skillId, SubSkill x) async =>
      _subSkillsCol(skillId).doc(x.id).update(x.toMap());

  Future<void> deleteSubSkill(String skillId, String id) async =>
      _subSkillsCol(skillId).doc(id).delete();

  // ===== Sessions
  Stream<List<PracticeSession>> watchSessions(String skillId) =>
      _sessionsCol(skillId)
          .orderBy('start', descending: true)
          .snapshots()
          .map((s) => s.docs.map(PracticeSession.fromSnap).toList());

  Future<void> addSession(PracticeSession ss) async {
    await _sessionsCol(ss.skillId).add(ss.toMap());
    await _recalcSkillAggregates(ss.skillId);
  }

  // ===== Projects
  Stream<List<Project>> watchProjects(String skillId) =>
      _projectsCol(skillId)
          .orderBy('state')
          .snapshots()
          .map((s) => s.docs.map(Project.fromSnap).toList());

  Future<void> addProject(Project p) async =>
      _projectsCol(p.skillId).add(p.toMap());

  Future<void> updateProject(Project p) async =>
      _projectsCol(p.skillId).doc(p.id).update(p.toMap());

  Future<void> deleteProject(String skillId, String id) async =>
      _projectsCol(skillId).doc(id).delete();

  // ===== Resources
  Stream<List<ResourceLink>> watchResources(String skillId) =>
      _resourcesCol(skillId)
          .orderBy('title')
          .snapshots()
          .map((s) => s.docs.map(ResourceLink.fromSnap).toList());

  Future<void> addResource(String skillId, ResourceLink r) async =>
      _resourcesCol(skillId).add(r.toMap());

  Future<void> deleteResource(String skillId, String id) async =>
      _resourcesCol(skillId).doc(id).delete();

  // ===== KPIs / Analytics básicos
  Future<Map<String, dynamic>> kpisForSkill(String skillId) async {
    final sessions = await _sessionsCol(skillId).get();
    int minutes = 0;
    int days = 0;
    final seenDays = <String>{};
    for (final d in sessions.docs) {
      final m = d.data() as Map<String, dynamic>;
      minutes += ((m['minutes'] ?? 0) as num).toInt();
      final dayKey =
          ((m['start'] as Timestamp?)?.toDate() ?? DateTime.now()).toIso8601String().substring(0, 10);
      seenDays.add(dayKey);
    }
    days = seenDays.length;

    return {
      'totalHours': minutes / 60.0,
      'activeDays': days,
      'sessions': sessions.docs.length,
    };
  }

  Future<Map<String, double>> sessionsBySubSkill(String skillId) async {
    final sessions = await _sessionsCol(skillId).get();
    final map = <String, double>{};
    for (final d in sessions.docs) {
      final m = d.data() as Map<String, dynamic>;
      final sub = (m['subSkillId'] ?? '—') as String;
      final mins = ((m['minutes'] ?? 0) as num).toDouble();
      map[sub] = (map[sub] ?? 0) + mins;
    }
    return map;
  }

  // ===== Meta / agregados
  Future<void> _touchMeta() async {
    await _metaDoc
        .set({'lastUpdated': Timestamp.now()}, SetOptions(merge: true));
  }

  Future<void> _recalcSkillAggregates(String skillId) async {
    final sess = await _sessionsCol(skillId).get();
    final sub = await _subSkillsCol(skillId).get();

    int minutes = 0;
    final dayKeys = <String>{};
    for (final d in sess.docs) {
      final m = d.data() as Map<String, dynamic>;
      minutes += ((m['minutes'] ?? 0) as num).toInt();
      final dt = (m['start'] as Timestamp?)?.toDate() ?? DateTime.now();
      dayKeys.add('${dt.year}-${dt.month}-${dt.day}');
    }

    // Streak calculado: días consecutivos con sesiones (hoy incluido si hay)
    final today = DateTime.now();
    int streak = 0;
    DateTime cursor = DateTime(today.year, today.month, today.day);
    while (dayKeys.contains('${cursor.year}-${cursor.month}-${cursor.day}')) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    await _skillsCol.doc(skillId).update({
      'totalHours': minutes / 60.0,
      'streakDays': streak,
      'updatedAt': Timestamp.now(),
      // guardamos recuento de subskills por si hace falta en tarjetas
      'subskillsCount': sub.docs.length,
    });
  }
}
