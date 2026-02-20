// ─────────────────────────────────────────────────────────────────────
// TEMPORARY diagnostic runner — DELETE after testing
// Executes 4 interconexión scenarios and dumps full evidence to console
// AND writes results to Firestore doc: users/{uid}/diag/results
// ─────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

final _db = FirebaseFirestore.instance;
final _log = StringBuffer();

const JsonEncoder _j = JsonEncoder.withIndent('  ');
String _pretty(Map<String, dynamic> m) => _j.convert(_sanitize(m));

dynamic _sanitize(dynamic v) {
  if (v is Timestamp) return v.toDate().toIso8601String();
  if (v is FieldValue) return v.toString();
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), _sanitize(val)));
  if (v is List) return v.map(_sanitize).toList();
  return v;
}

void _p(String msg) {
  debugPrint(msg);
  _log.writeln(msg);
}

void _h(String title) {
  _p('');
  _p('╔${'═' * 70}');
  _p('║  $title');
  _p('╚${'═' * 70}');
}

void _s(String sub) {
  _p('  ┌── $sub');
}

Future<Map<String, dynamic>> _readDoc(String path) async {
  final snap = await _db.doc(path).get();
  if (!snap.exists) {
    _p('  ⛔ $path → DOES NOT EXIST');
    return const {};
  }
  final data = snap.data() ?? {};
  _p('  📄 $path');
  _p(_pretty(data));
  return data;
}

Future<void> _flushLog(String uid, String phase) async {
  try {
    await _db.collection('users').doc(uid).collection('diag').doc('results').set({
      'phase': phase,
      'log': _log.toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {}
}

Future<void> runFullDiagnostic(String uid) async {
  _log.clear();
  _p('');
  _p('██████████████████████████████████████████████████████████████████████');
  _p('██  RUNTIME DIAGNOSTIC — uid=$uid');
  _p('██  ${DateTime.now().toIso8601String()}');
  _p('██████████████████████████████████████████████████████████████████████');

  try {
    await _scenario1_GymToFood(uid);
    await _flushLog(uid, 'after_scenario_1');
    
    await _scenario2_StudyTasks(uid);
    await _flushLog(uid, 'after_scenario_2');
    
    await _scenario3_FinanceFood(uid);
    await _flushLog(uid, 'after_scenario_3');
    
    await _scenario4_Recurring(uid);
    await _flushLog(uid, 'after_scenario_4');
  } catch (e, st) {
    _p('');
    _p('❌ DIAGNOSTIC ERROR: $e');
    _p('$st');
  }

  _p('');
  _p('██████████████████████████████████████████████████████████████████████');
  _p('██  DIAGNOSTIC COMPLETE');
  _p('██████████████████████████████████████████████████████████████████████');
  
  await _flushLog(uid, 'COMPLETE');
}

// ═══════════════════════════════════════════════════════════════════════
// SCENARIO 1 — Gym → Food
// ═══════════════════════════════════════════════════════════════════════
Future<void> _scenario1_GymToFood(String uid) async {
  _h('SCENARIO 1 — Gym → Food (targets recalc)');

  // A) BEFORE STATE
  _s('A) BEFORE — reading Firestore docs');
  _p('  ── food/root/config/targets ──');
  final targetsBefore = await _readDoc('users/$uid/food/root/config/targets');
  _p('  ── food/root/config/alerts ──');
  final alertsBefore = await _readDoc('users/$uid/food/root/config/alerts');
  _p('  ── gym/root/config/alerts ──');
  await _readDoc('users/$uid/gym/root/config/alerts');

  // B) CREATE gym session
  _s('B) CREATING GYM SESSION — durationMin=75 volumeKg=8500');
  final sessRef = _db
      .collection('users')
      .doc(uid)
      .collection('gym')
      .doc('root')
      .collection('sessions')
      .doc('diag-session-${DateTime.now().millisecondsSinceEpoch}');

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final sessionData = {
    'date': todayStart.toIso8601String(),
    'durationMin': 75,
    'volumeKg': 8500,
    'routineName': 'DIAG-TEST',
    'dayName': 'Diagnostic Day',
    'exercises': [],
    'createdAt': FieldValue.serverTimestamp(),
  };
  _p('  ✏️ Writing to: ${sessRef.path}');
  _p(_pretty(sessionData));
  await sessRef.set(sessionData);
  _p('  ✅ Session written. Waiting 5s for listeners…');

  await Future.delayed(const Duration(seconds: 5));

  // C) AFTER STATE
  _s('C) AFTER — reading Firestore docs');
  _p('  ── food/root/config/targets ──');
  final targetsAfter = await _readDoc('users/$uid/food/root/config/targets');
  _p('  ── food/root/config/alerts ──');
  final alertsAfter = await _readDoc('users/$uid/food/root/config/alerts');
  _p('  ── gym/root/config/alerts ──');
  await _readDoc('users/$uid/gym/root/config/alerts');

  // DIFF
  _s('D) DIFF targets');
  final kcalBefore = targetsBefore['kcal'];
  final kcalAfter = targetsAfter['kcal'];
  final protBefore = targetsBefore['protein'];
  final protAfter = targetsAfter['protein'];
  _p('  kcal: $kcalBefore → $kcalAfter');
  _p('  protein: $protBefore → $protAfter');
  _p('  workoutsToday in alerts: ${alertsBefore['workoutsToday']} → ${alertsAfter['workoutsToday']}');

  // CLEANUP
  _s('CLEANUP — deleting test session');
  await sessRef.delete();
  _p('  🗑️ Deleted ${sessRef.path}');
}

// ═══════════════════════════════════════════════════════════════════════
// SCENARIO 2 — Study ↔ Tasks
// ═══════════════════════════════════════════════════════════════════════
Future<void> _scenario2_StudyTasks(String uid) async {
  _h('SCENARIO 2 — Study ↔ Tasks (bidirectional sync)');

  // A) CREATE StudyTask
  _s('A) CREATING STUDY TASK');
  final studyRef = _db
      .collection('users')
      .doc(uid)
      .collection('study')
      .doc('root')
      .collection('tasks')
      .doc('diag-study-${DateTime.now().millisecondsSinceEpoch}');

  final studyData = {
    'title': 'DIAG-StudyTask Test',
    'notes': 'Created by runtime diagnostic',
    'status': 'todo',
    'priority': 'high',
    'courseId': 'diag-course',
    'due': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
    'createdAt': FieldValue.serverTimestamp(),
  };
  _p('  ✏️ Writing to: ${studyRef.path}');
  _p(_pretty(studyData));
  await studyRef.set(studyData);
  _p('  ✅ StudyTask written. Waiting 5s for _mirrorStudyIntoTasks…');

  await Future.delayed(const Duration(seconds: 5));

  // READ StudyTask with syncedTaskId
  _s('B) AFTER MIRROR — StudyTask');
  final studySnap = await studyRef.get();
  final studyNow = studySnap.data() ?? {};
  _p(_pretty(studyNow));
  final mirroredTaskId = (studyNow['syncedTaskId'] ?? '').toString();
  _p('  syncedTaskId → $mirroredTaskId');

  if (mirroredTaskId.isNotEmpty) {
    _s('B) AFTER MIRROR — Task espejo');
    await _readDoc('users/$uid/tasks/$mirroredTaskId');
  } else {
    _p('  ⚠️ No syncedTaskId found — mirror may not have fired.');
  }

  // C) MARK DONE
  _s('C) MARKING STUDY TASK AS DONE');
  await studyRef.set({'status': 'done', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  _p('  ✅ status→done. Waiting 5s for sync listeners…');

  await Future.delayed(const Duration(seconds: 5));

  _s('D) AFTER DONE — StudyTask');
  final studyDone = (await studyRef.get()).data() ?? {};
  _p(_pretty(studyDone));

  if (mirroredTaskId.isNotEmpty) {
    _s('D) AFTER DONE — Task espejo');
    final taskDone = await _readDoc('users/$uid/tasks/$mirroredTaskId');
    _p('  task.completed = ${taskDone['completed']}');
  }

  // CLEANUP
  _s('CLEANUP');
  if (mirroredTaskId.isNotEmpty) {
    await _db.collection('users').doc(uid).collection('tasks').doc(mirroredTaskId).delete();
    _p('  🗑️ Deleted task/$mirroredTaskId');
  }
  await studyRef.delete();
  _p('  🗑️ Deleted ${studyRef.path}');
}

// ═══════════════════════════════════════════════════════════════════════
// SCENARIO 3 — Finance → Food (over budget)
// ═══════════════════════════════════════════════════════════════════════
Future<void> _scenario3_FinanceFood(String uid) async {
  _h('SCENARIO 3 — Finance → Food (overBudget detection)');

  // A) CREATE LOW BUDGET
  _s('A) CREATING LOW FOOD BUDGET (limit=50)');
  final budgetRef = _db.collection('finance_budgets').doc('diag-budget-${DateTime.now().millisecondsSinceEpoch}');
  final budgetData = {
    'userId': uid,
    'category': 'food',
    'amount': 50,
    'period': 'monthly',
    'startDate': DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String(),
    'createdAt': FieldValue.serverTimestamp(),
  };
  _p('  ✏️ Writing to: ${budgetRef.path}');
  _p(_pretty(budgetData));
  await budgetRef.set(budgetData);
  _p('  ✅ Budget written. Waiting 4s…');

  await Future.delayed(const Duration(seconds: 4));

  _s('A2) READING food alerts/flags BEFORE expense');
  final alertsBefore = await _readDoc('users/$uid/food/root/config/alerts');
  final flagsBefore = await _readDoc('users/$uid/food/root/config/flags');

  // B) CREATE EXPENSIVE FOOD TRANSACTION
  _s('B) CREATING FOOD EXPENSE (amount=120 > budget=50)');
  final txRef = _db.collection('finance_transactions').doc('diag-tx-${DateTime.now().millisecondsSinceEpoch}');
  final txData = {
    'userId': uid,
    'category': 'food',
    'type': 'expense',
    'amount': 120,
    'title': 'DIAG-FoodExpense',
    'date': Timestamp.fromDate(DateTime.now()),
    'createdAt': FieldValue.serverTimestamp(),
  };
  _p('  ✏️ Writing to: ${txRef.path}');
  _p(_pretty(txData));
  await txRef.set(txData);
  _p('  ✅ Transaction written. Waiting 5s for _recalcFoodOverBudget…');

  await Future.delayed(const Duration(seconds: 5));

  // C) READ AFTER
  _s('C) AFTER EXPENSE — alerts & flags');
  final alertsAfter = await _readDoc('users/$uid/food/root/config/alerts');
  final flagsAfter = await _readDoc('users/$uid/food/root/config/flags');

  _s('D) DIFF');
  _p('  alerts.foodOverBudget: ${alertsBefore['foodOverBudget']} → ${alertsAfter['foodOverBudget']}');
  _p('  flags.overBudgetFood: ${flagsBefore['overBudgetFood']} → ${flagsAfter['overBudgetFood']}');

  // CLEANUP
  _s('CLEANUP');
  await txRef.delete();
  _p('  🗑️ Deleted ${txRef.path}');
  await budgetRef.delete();
  _p('  🗑️ Deleted ${budgetRef.path}');

  // Wait for listeners to recalc with empty data
  await Future.delayed(const Duration(seconds: 3));
}

// ═══════════════════════════════════════════════════════════════════════
// SCENARIO 4 — Recurring Finance
// ═══════════════════════════════════════════════════════════════════════
Future<void> _scenario4_Recurring(String uid) async {
  _h('SCENARIO 4 — Recurring transactions (materialize)');

  // A) CREATE RECURRING TX
  final pastDate = DateTime.now().subtract(const Duration(days: 35));
  final txRef = _db.collection('finance_transactions').doc('diag-recurring-${DateTime.now().millisecondsSinceEpoch}');

  _s('A) CREATING RECURRING TRANSACTION (monthly, baseDate=${pastDate.toIso8601String()})');
  final txData = {
    'userId': uid,
    'title': 'DIAG-Recurring-Netflix',
    'amount': 15.99,
    'category': 'entertainment',
    'type': 'expense',
    'recurrence': 'monthly',
    'date': Timestamp.fromDate(pastDate),
    'createdAt': FieldValue.serverTimestamp(),
  };
  _p('  ✏️ Writing to: ${txRef.path}');
  _p(_pretty(txData));
  await txRef.set(txData);
  _p('  ✅ Recurring tx written. Waiting 6s for _materializeRecurring…');

  await Future.delayed(const Duration(seconds: 6));

  // B) CHECK MATERIALIZED
  _s('B) CHECKING materialized planned transactions');
  final finTxQuery = await _db
      .collection('users')
      .doc(uid)
      .collection('finance')
      .doc('data')
      .collection('transactions')
      .where('sourceRecurringId', isEqualTo: txRef.id)
      .get();

  _p('  Found ${finTxQuery.docs.length} materialized transaction(s)');
  for (final doc in finTxQuery.docs) {
    _p('  📄 ${doc.reference.path}');
    _p(_pretty(doc.data()));
  }

  _s('C) CHECKING calendar entries');
  final calQuery = await _db
      .collection('users')
      .doc(uid)
      .collection('planner')
      .doc('data')
      .collection('calendar')
      .where('sourceRecurringId', isEqualTo: txRef.id)
      .get();

  _p('  Found ${calQuery.docs.length} calendar entry(ies)');
  for (final doc in calQuery.docs) {
    _p('  📄 ${doc.reference.path}');
    _p(_pretty(doc.data()));
  }

  // CLEANUP
  _s('CLEANUP');
  for (final doc in finTxQuery.docs) {
    await doc.reference.delete();
    _p('  🗑️ Deleted ${doc.reference.path}');
  }
  for (final doc in calQuery.docs) {
    await doc.reference.delete();
    _p('  🗑️ Deleted ${doc.reference.path}');
  }
  await txRef.delete();
  _p('  🗑️ Deleted ${txRef.path}');
}
