# Entrega: C�digo completo de archivos tocados`n
## lib/core/services/core_sync_service.dart

```dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../screens/finance/models/subscription_model.dart';
import '../../screens/finance/services/subscription_service.dart';
import '../../screens/food/services/food_firestore_service.dart';
import '../utils/date_utils.dart';

const bool kCoreSyncDebug = true;

class CoreSyncService {
  CoreSyncService._();
  static final CoreSyncService I = CoreSyncService._();

  final _db = FirebaseFirestore.instance;
  String? _activeUid;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _gymTodaySub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _studyTasksSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tasksSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _financeBudgetsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _financeTxSub;
  StreamSubscription<List<Subscription>>? _subsDueSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _financeRecurringSub;

  static const _actorStudy = 'core-sync:study';
  static const _actorTasks = 'core-sync:tasks';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedBudgetDocs = const [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedFinanceDocs = const [];
  bool _recalcBudgetBusy = false;

  void start(String uid) {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return;
    if (_activeUid == trimmed) return;

    stop();
    _activeUid = trimmed;
    _watchGymToday(trimmed);
    _watchStudyTasks(trimmed);
    _watchTasks(trimmed);
    _watchFoodBudgetRealtime(trimmed);
    _watchSubscriptions(trimmed);
    _watchRecurringFinance(trimmed);
  }

  void stop() {
    _disposeUserSubs();
    _activeUid = null;
    _cachedBudgetDocs = const [];
    _cachedFinanceDocs = const [];
    _recalcBudgetBusy = false;
  }

  void dispose() => stop();

  void _disposeUserSubs() {
    _gymTodaySub?.cancel();
    _studyTasksSub?.cancel();
    _tasksSub?.cancel();
    _financeBudgetsSub?.cancel();
    _financeTxSub?.cancel();
    _subsDueSub?.cancel();
    _financeRecurringSub?.cancel();
  }

  void _logListener(String listener, String uid, String docId) {
    if (!kCoreSyncDebug) return;
    debugPrint('CoreSync: $listener fired uid=$uid docId=$docId');
  }

  void _logWrite(String path, Map<String, dynamic> values) {
    if (!kCoreSyncDebug) return;
    debugPrint('CoreSync: write path=$path values=$values');
  }

  void _watchGymToday(String uid) {
    final todayRange = _todayIsoRange();
    _gymTodaySub = _db
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root')
        .collection('sessions')
        .where('date', isGreaterThanOrEqualTo: todayRange.start)
        .where('date', isLessThanOrEqualTo: todayRange.end)
        .snapshots()
        .listen((snap) {
          if (snap.docChanges.isEmpty) {
            _logListener('gymToday', uid, '-');
          } else {
            for (final ch in snap.docChanges) {
              _logListener('gymToday', uid, ch.doc.id);
            }
          }
          _syncFoodTargets(uid, snap.docs);
        });
  }

  void _watchStudyTasks(String uid) {
    _studyTasksSub = _db
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('tasks')
        .snapshots()
        .listen((snap) {
          if (snap.docChanges.isEmpty) {
            _logListener('studyTasks', uid, '-');
          } else {
            for (final ch in snap.docChanges) {
              _logListener('studyTasks', uid, ch.doc.id);
            }
          }
          _mirrorStudyIntoTasks(uid, snap);
        });
  }

  void _watchTasks(String uid) {
    _tasksSub = _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .snapshots()
        .listen((snap) {
          if (snap.docChanges.isEmpty) {
            _logListener('tasks', uid, '-');
          } else {
            for (final ch in snap.docChanges) {
              _logListener('tasks', uid, ch.doc.id);
            }
          }
          _mirrorTasksIntoStudy(uid, snap);
        });
  }

  void _watchFoodBudgetRealtime(String uid) {
    _financeBudgetsSub = _db
        .collection('finance_budgets')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
          _cachedBudgetDocs = snap.docs;
          if (snap.docChanges.isEmpty) {
            _logListener('financeBudgets', uid, '-');
          } else {
            for (final ch in snap.docChanges) {
              _logListener('financeBudgets', uid, ch.doc.id);
            }
          }
          _recalcFoodOverBudget(uid);
        });

    _financeTxSub = _db
        .collection('finance_transactions')
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: 'expense')
        .snapshots()
        .listen((snap) {
          _cachedFinanceDocs = snap.docs;
          if (snap.docChanges.isEmpty) {
            _logListener('financeTransactions', uid, '-');
          } else {
            for (final ch in snap.docChanges) {
              _logListener('financeTransactions', uid, ch.doc.id);
            }
          }
          _recalcFoodOverBudget(uid);
        });
  }

  Future<void> _recalcFoodOverBudget(String uid) async {
    if (_recalcBudgetBusy) return;
    _recalcBudgetBusy = true;
    try {
      final now = DateTime.now();
      var overBudget = false;
      String? overBudgetId;

      for (final d in _cachedBudgetDocs) {
        final m = d.data();
        final cat = (m['category'] ?? '').toString().toLowerCase();
        if (cat != 'food') continue;
        final amount = _n(m['amount']) ?? _n(m['limit']) ?? 0;
        if (amount <= 0) continue;

        final period = (m['period'] ?? 'monthly').toString();
        final startDate = _toDate(m['startDate']) ?? now;
        final endDate = _toDate(m['endDate']);
        final (rangeStart, rangeEnd) = _budgetRange(period, startDate, endDate, now);

        double spent = 0;
        for (final tx in _cachedFinanceDocs) {
          final t = tx.data();
          final txCat = (t['category'] ?? '').toString().toLowerCase();
          if (txCat != 'food') continue;
          final txDate = _toDate(t['date']);
          if (txDate == null) continue;
          if (txDate.isBefore(rangeStart) || txDate.isAfter(rangeEnd)) continue;
          spent += _n(t['amount']) ?? 0;
        }

        if (spent > amount) {
          overBudget = true;
          overBudgetId = d.id;
          break;
        }
      }

      final alertsRef = _db
          .collection('users')
          .doc(uid)
          .collection('food')
          .doc('root')
          .collection('config')
          .doc('alerts');
      final flagsRef = _db
          .collection('users')
          .doc(uid)
          .collection('food')
          .doc('root')
          .collection('config')
          .doc('flags');

      final alertsPatch = {
        'foodOverBudget': overBudget,
        'foodOverBudgetBudgetId': overBudgetId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      _logWrite('users/$uid/food/root/config/alerts', alertsPatch);
      await alertsRef.set(alertsPatch, SetOptions(merge: true));

      final flagsPatch = {
        'overBudgetFood': overBudget,
        'overBudgetBudgetId': overBudgetId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      _logWrite('users/$uid/food/root/config/flags', flagsPatch);
      await flagsRef.set(flagsPatch, SetOptions(merge: true));
    } finally {
      _recalcBudgetBusy = false;
    }
  }

  (DateTime, DateTime) _budgetRange(
    String period,
    DateTime startDate,
    DateTime? endDate,
    DateTime now,
  ) {
    if (period == 'weekly') {
      final from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return (from, to);
    }
    if (period == 'custom') {
      final from = DateTime(startDate.year, startDate.month, startDate.day);
      final toBase = endDate ?? now;
      final to = DateTime(toBase.year, toBase.month, toBase.day, 23, 59, 59);
      return (from, to);
    }
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return (from, to);
  }

  void _watchSubscriptions(String uid) {
    _subsDueSub = SubscriptionService.I.upcomingPayments(daysAhead: 7).listen((subs) async {
      final docId = subs.isEmpty ? '-' : (subs.first.id.isEmpty ? '-' : subs.first.id);
      _logListener('subscriptionsDue', uid, docId);

      final gymSubs = subs.where((s) => s.category.toLowerCase().contains('gym')).toList();
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('gym')
          .doc('root')
          .collection('config')
          .doc('alerts');

      if (gymSubs.isEmpty) {
        final patch = {
          'subscriptionDueSoon': false,
          'subscriptionDueAt': null,
          'subscriptionDueInDays': null,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        _logWrite('users/$uid/gym/root/config/alerts', patch);
        await ref.set(patch, SetOptions(merge: true));
        return;
      }

      final next = gymSubs.first;
      final now = DateTime.now();
      final dueInDays = next.nextDue.difference(DateTime(now.year, now.month, now.day)).inDays;
      final patch = {
        'subscriptionDueSoon': true,
        'subscriptionDueAt': Timestamp.fromDate(next.nextDue),
        'subscriptionTitle': next.title,
        'subscriptionDueInDays': dueInDays,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      _logWrite('users/$uid/gym/root/config/alerts', patch);
      await ref.set(patch, SetOptions(merge: true));
    });
  }

  void _watchRecurringFinance(String uid) {
    _financeRecurringSub = _db
        .collection('finance_transactions')
        .where('userId', isEqualTo: uid)
        .where('recurrence', isNotEqualTo: null)
        .snapshots()
        .listen((snap) {
          if (snap.docChanges.isEmpty) {
            _logListener('financeRecurring', uid, '-');
          } else {
            for (final ch in snap.docChanges) {
              _logListener('financeRecurring', uid, ch.doc.id);
            }
          }
          for (final doc in snap.docs) {
            _materializeRecurring(uid, doc.id, doc.data());
          }
        });
  }

  Future<void> _syncFoodTargets(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions,
  ) async {
    final todayId = dayIdFromDateTime(DateTime.now());
    var totalMinutes = 0;
    double totalVolume = 0;

    for (final d in sessions) {
      final m = d.data();
      totalMinutes += (m['durationMin'] as num?)?.toInt() ?? 0;
      totalVolume += (m['volumeKg'] as num?)?.toDouble() ?? 0;
    }

    final hashRaw = '$totalMinutes|$totalVolume|${sessions.length}';
    final hash = _hash(hashRaw);

    final foodRoot = _db
        .collection('users')
        .doc(uid)
        .collection('food')
        .doc('root');
    final targetRef = foodRoot.collection('config').doc('targets');
    final foodAlertsRef = foodRoot.collection('config').doc('alerts');
    final gymAlertsRef = _db
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root')
        .collection('config')
        .doc('alerts');

    final targetSnap = await targetRef.get();
    final targetData = targetSnap.data() ?? const <String, dynamic>{};
    final syncMeta = Map<String, dynamic>.from(targetData['syncMeta'] ?? const {});
    if (syncMeta['gymHash'] == hash) return;

    final foodSvc = FoodFirestoreService(uid);
    final global = await foodSvc.streamGlobalTargets().first;

    final baseKcal = _n(targetData['baseKcal']) ?? _n(targetData['kcal']) ?? (global['kcal'] ?? 2000);
    final baseProtein =
        _n(targetData['baseProtein']) ?? _n(targetData['protein']) ?? (global['protein'] ?? 120);

    final extraKcal = (totalMinutes * 8) + (totalVolume * 0.1);
    final extraProtein = (totalMinutes * 0.25).clamp(10, 60);

    final kcalTarget = baseKcal + extraKcal;
    final proteinTarget = baseProtein + extraProtein;

    final targetPatch = {
      'kcal': kcalTarget,
      'protein': proteinTarget,
      'baseKcal': baseKcal,
      'baseProtein': baseProtein,
      'syncMeta': {
        ...syncMeta,
        'gymHash': hash,
        'gymSyncedAt': FieldValue.serverTimestamp(),
        'gymWorkoutsCount': sessions.length,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };
    _logWrite('users/$uid/food/root/config/targets', targetPatch);
    await targetRef.set(targetPatch, SetOptions(merge: true));

    final todayIntakeRef = foodRoot.collection('intake').doc(todayId);
    final intakeSnap = await todayIntakeRef.get();
    final intakeData = intakeSnap.data() ?? const <String, dynamic>{};
    final totals = Map<String, dynamic>.from(intakeData['totals'] ?? const {});
    final proteinToday = _n(totals['protein']) ?? 0;
    final kcalToday = _n(totals['kcal']) ?? 0;
    final strongWorkout = totalMinutes >= 50 || totalVolume >= 5000;
    final kcalDelta = kcalToday - kcalTarget;
    final proteinLow = sessions.isNotEmpty && proteinToday < proteinTarget;
    final extremeDeficitWorkout = strongWorkout && kcalDelta < -400;

    final foodAlertPatch = {
      'workoutsToday': sessions.length,
      'workoutMinutesToday': totalMinutes,
      'workoutVolumeKgToday': totalVolume,
      'targetProteinToday': proteinTarget,
      'proteinToday': proteinToday,
      'foodProteinLowAfterWorkout': proteinLow,
      'foodExtremeDeficitWorkout': extremeDeficitWorkout,
      'kcalTargetToday': kcalTarget,
      'kcalToday': kcalToday,
      'kcalDeltaToday': kcalDelta,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    _logWrite('users/$uid/food/root/config/alerts', foodAlertPatch);
    await foodAlertsRef.set(foodAlertPatch, SetOptions(merge: true));

    final gymAlertPatch = {
      'extremeDeficitWorkout': extremeDeficitWorkout,
      'deficitKcal': kcalDelta,
      'workoutMinutesToday': totalMinutes,
      'workoutVolumeKgToday': totalVolume,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    _logWrite('users/$uid/gym/root/config/alerts', gymAlertPatch);
    await gymAlertsRef.set(gymAlertPatch, SetOptions(merge: true));
  }

  Future<void> _mirrorStudyIntoTasks(
    String uid,
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    for (final change in snap.docChanges) {
      if (change.type == DocumentChangeType.removed) continue;
      final raw = change.doc.data();
      if (raw == null) continue;
      final data = Map<String, dynamic>.from(raw);
      final hash = _studyHash(data);
      final meta = _metaFrom(data);
      if (_shouldSkip(meta, _actorStudy, hash)) continue;

      var linkedTaskId = (data['syncedTaskId'] ?? '').toString();

      if (linkedTaskId.isEmpty) {
        final due = _parseDueDate(data['due']);
        final priority = _mapStudyPriority(data['priority']);
        final newTaskRef = _db.collection('users').doc(uid).collection('tasks').doc();
        final createPatch = {
          'title': (data['title'] ?? '').toString(),
          'description': (data['notes'] ?? '').toString(),
          'completed': (data['status'] ?? 'todo') == 'done',
          'priority': priority,
          if (due != null) 'dueDate': Timestamp.fromDate(due),
          'linkedStudyCourseId': (data['courseId'] ?? '').toString(),
          'syncedStudyTaskId': change.doc.id,
          ..._metaPatch(_actorStudy, hash),
        };
        _logWrite('users/$uid/tasks/${newTaskRef.id}', createPatch);
        await newTaskRef.set(createPatch, SetOptions(merge: true));
        linkedTaskId = newTaskRef.id;

        final backPatch = {
          'syncedTaskId': linkedTaskId,
          ..._metaPatch(_actorStudy, hash),
        };
        _logWrite('users/$uid/study/root/tasks/${change.doc.id}', backPatch);
        await change.doc.reference.set(backPatch, SetOptions(merge: true));
        continue;
      }

      final ref = _db.collection('users').doc(uid).collection('tasks').doc(linkedTaskId);
      final dest = await ref.get();
      if (!dest.exists) continue;

      final due = _parseDueDate(data['due']);
      final priority = _mapStudyPriority(data['priority']);
      final patch = {
        'title': (data['title'] ?? '').toString(),
        'description': (data['notes'] ?? '').toString(),
        'completed': (data['status'] ?? 'todo') == 'done',
        'priority': priority,
        if (due != null) 'dueDate': Timestamp.fromDate(due),
        'syncedStudyTaskId': change.doc.id,
        ..._metaPatch(_actorStudy, hash),
      };

      _logWrite('users/$uid/tasks/$linkedTaskId', patch);
      await ref.set(patch, SetOptions(merge: true));

      final studyBackPatch = {
        'syncedTaskId': linkedTaskId,
        ..._metaPatch(_actorStudy, hash),
      };
      _logWrite('users/$uid/study/root/tasks/${change.doc.id}', studyBackPatch);
      await change.doc.reference.set(studyBackPatch, SetOptions(merge: true));
    }
  }

  Future<void> _mirrorTasksIntoStudy(
    String uid,
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    for (final change in snap.docChanges) {
      if (change.type == DocumentChangeType.removed) continue;
      final raw = change.doc.data();
      if (raw == null) continue;
      final data = Map<String, dynamic>.from(raw);
      final hash = _taskHash(data);
      final meta = _metaFrom(data);
      if (_shouldSkip(meta, _actorTasks, hash)) continue;

      var linkedStudyId = (data['syncedStudyTaskId'] ?? '').toString();
      if (linkedStudyId.isEmpty) {
        final linkedCourseId = (data['linkedStudyCourseId'] ?? '').toString();
        if (linkedCourseId.isNotEmpty) {
          final due = _parseDueDate(data['dueDate']);
          final status = (data['completed'] == true) ? 'done' : 'todo';
          final priority = _mapTaskPriority(data['priority']);
          final newStudyRef = _db
              .collection('users')
              .doc(uid)
              .collection('study')
              .doc('root')
              .collection('tasks')
              .doc();
          final createPatch = {
            'courseId': linkedCourseId,
            'title': (data['title'] ?? '').toString(),
            'type': 'task',
            'notes': (data['description'] ?? '').toString(),
            'status': status,
            'priority': priority,
            if (due != null) 'due': due.toIso8601String(),
            'syncedTaskId': change.doc.id,
            ..._metaPatch(_actorTasks, hash),
          };
          _logWrite('users/$uid/study/root/tasks/${newStudyRef.id}', createPatch);
          await newStudyRef.set(createPatch, SetOptions(merge: true));
          linkedStudyId = newStudyRef.id;

          final taskBackPatch = {
            'syncedStudyTaskId': linkedStudyId,
            ..._metaPatch(_actorTasks, hash),
          };
          _logWrite('users/$uid/tasks/${change.doc.id}', taskBackPatch);
          await change.doc.reference.set(taskBackPatch, SetOptions(merge: true));
          continue;
        }
        continue;
      }

      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('study')
          .doc('root')
          .collection('tasks')
          .doc(linkedStudyId);
      final dest = await ref.get();
      if (!dest.exists) continue;

      final due = _parseDueDate(data['dueDate']);
      final status = (data['completed'] == true) ? 'done' : 'todo';
      final priority = _mapTaskPriority(data['priority']);
      final patch = {
        'title': (data['title'] ?? '').toString(),
        'notes': (data['description'] ?? '').toString(),
        'status': status,
        'priority': priority,
        if (due != null) 'due': due.toIso8601String(),
        'syncedTaskId': change.doc.id,
        ..._metaPatch(_actorTasks, hash),
      };

      _logWrite('users/$uid/study/root/tasks/$linkedStudyId', patch);
      await ref.set(patch, SetOptions(merge: true));

      final taskBackPatch = {
        'syncedStudyTaskId': linkedStudyId,
        ..._metaPatch(_actorTasks, hash),
      };
      _logWrite('users/$uid/tasks/${change.doc.id}', taskBackPatch);
      await change.doc.reference.set(taskBackPatch, SetOptions(merge: true));
    }
  }

  Future<void> _materializeRecurring(String uid, String txId, Map<String, dynamic> data) async {
    final recurrence = (data['recurrence'] ?? '').toString();
    if (recurrence.isEmpty || recurrence == 'none') return;

    final baseDate = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final now = DateTime.now();
    DateTime next = baseDate;
    while (!next.isAfter(now)) {
      next = _nextDate(next, recurrence);
    }

    final dayId = dayIdFromDateTime(next);
    final plannedDoc = _db
        .collection('users')
        .doc(uid)
        .collection('finance')
        .doc('data')
        .collection('transactions')
        .doc('$txId-$dayId');

    final already = await plannedDoc.get();
    if (!already.exists) {
      final plannedPatch = {
        'title': data['title'] ?? 'Recurrente',
        'amount': data['amount'] ?? 0,
        'category': data['category'],
        'type': data['type'] ?? 'expense',
        'planned': true,
        'isBill': false,
        'date': Timestamp.fromDate(next),
        'dueDate': Timestamp.fromDate(next),
        'recurrence': recurrence,
        'sourceRecurringId': txId,
      };
      _logWrite('users/$uid/finance/data/transactions/$txId-$dayId', plannedPatch);
      await plannedDoc.set(plannedPatch);
    }

    final calRef = _db
        .collection('users')
        .doc(uid)
        .collection('planner')
        .doc('data')
        .collection('calendar')
        .doc('fin-$txId-$dayId');
    final calSnap = await calRef.get();
    if (!calSnap.exists) {
      final calPatch = {
        'title': data['title'] ?? 'Pago recurrente',
        'type': 'finance',
        'priority': 'normal',
        'start': Timestamp.fromDate(next),
        'allDay': true,
        'notes': data['category'],
        'sourceRecurringId': txId,
      };
      _logWrite('users/$uid/planner/data/calendar/fin-$txId-$dayId', calPatch);
      await calRef.set(calPatch);
    }
  }

  ({String start, String end}) _todayIsoRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    return (start: start.toIso8601String(), end: end.toIso8601String());
  }

  DateTime _nextDate(DateTime base, String recurrence) {
    switch (recurrence) {
      case 'weekly':
        return base.add(const Duration(days: 7));
      case 'yearly':
        return DateTime(base.year + 1, base.month, base.day);
      case 'monthly':
      default:
        return DateTime(base.year, base.month + 1, base.day);
    }
  }

  double? _n(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  String _studyHash(Map<String, dynamic> m) {
    final due = m['due']?.toString() ?? '';
    final raw = '${m['title']}|${m['notes']}|${m['status']}|${m['priority']}|$due';
    return _hash(raw);
  }

  String _taskHash(Map<String, dynamic> m) {
    final due = m['dueDate'];
    String dueStr = '';
    if (due is Timestamp) dueStr = due.toDate().toIso8601String();
    if (due is String) dueStr = due;
    final raw = '${m['title']}|${m['description']}|${m['completed']}|${m['priority']}|$dueStr';
    return _hash(raw);
  }

  String _hash(String input) => input.hashCode.toUnsigned(32).toRadixString(16);

  String _mapStudyPriority(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'high':
        return 'alta';
      case 'low':
        return 'baja';
      default:
        return 'media';
    }
  }

  String _mapTaskPriority(dynamic raw) {
    final v = (raw ?? '').toString().toLowerCase();
    if (v.contains('alta') || v.contains('high')) return 'high';
    if (v.contains('baja') || v.contains('low')) return 'low';
    return 'normal';
  }

  Map<String, dynamic> _metaFrom(Map<String, dynamic> data) {
    final raw = data['syncMeta'];
    final meta = raw is Map<String, dynamic>
        ? Map<String, dynamic>.from(raw)
        : raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
    if (data.containsKey('updatedAt') && !meta.containsKey('updatedAt')) {
      meta['updatedAt'] = data['updatedAt'];
    }
    return meta;
  }

  bool _shouldSkip(Map<String, dynamic> meta, String actor, String hash) {
    final lastBy = (meta['lastSyncedBy'] ?? '').toString();
    final lastHash = (meta['lastSyncedHash'] ?? '').toString();
    if (lastBy == actor && lastHash == hash) return true;
    final lastAt = _ts(meta['lastSyncedAt']);
    final updatedAt = _ts(meta['updatedAt']);
    if (lastBy == actor && lastAt != null && updatedAt != null && !lastAt.isBefore(updatedAt)) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> _metaPatch(String actor, String hash) {
    return {
      'syncMeta': {
        'lastSyncedBy': actor,
        'lastSyncedHash': hash,
        'lastSyncedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  DateTime? _parseDueDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }
}
```


## lib/screens/food/services/food_firestore_service.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_models.dart';

class FoodFirestoreService {
  final String userId;
  FoodFirestoreService(this.userId);

  DocumentReference<Map<String, dynamic>> get _root => FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId.trim().isEmpty ? 'local' : userId.trim())
      .collection('food')
      .doc('root');

  DocumentReference<Map<String, dynamic>> get _targetsRef =>
      _root.collection('config').doc('targets');

  DocumentReference<Map<String, dynamic>> get _flagsRef =>
      _root.collection('config').doc('flags');

  DocumentReference<Map<String, dynamic>> get _alertsRef =>
      _root.collection('config').doc('alerts');

  Stream<Map<String, dynamic>> streamFlags() {
    return _flagsRef.snapshots().map((d) => Map<String, dynamic>.from(d.data() ?? const {}));
  }

  Stream<Map<String, dynamic>> streamAlerts() {
    return _alertsRef.snapshots().map((d) => Map<String, dynamic>.from(d.data() ?? const {}));
  }

  Stream<Map<String, double?>> streamGlobalTargets() {
    return _targetsRef.snapshots().map((d) {
      final m = Map<String, dynamic>.from(d.data() ?? const {});
      double? n(String k) => (m[k] is num) ? (m[k] as num).toDouble() : null;
      return {
        'kcal': n('kcal'),
        'protein': n('protein'),
        'carbs': n('carbs'),
        'fat': n('fat'),
        'fiber': n('fiber'),
        'water': n('water'),
      };
    });
  }

  Future<void> setGlobalTargets({
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? waterMl,
  }) async {
    final patch = <String, dynamic>{};
    if (kcal != null) patch['kcal'] = kcal;
    if (protein != null) patch['protein'] = protein;
    if (carbs != null) patch['carbs'] = carbs;
    if (fat != null) patch['fat'] = fat;
    if (fiber != null) patch['fiber'] = fiber;
    if (waterMl != null) patch['water'] = waterMl.toDouble();
    if (patch.isEmpty) return;
    await _targetsRef.set(patch, SetOptions(merge: true));
  }

  Stream<List<Food>> streamFoods({
    String? query,
    bool supplementsOnly = false,
  }) {
    Query<Map<String, dynamic>> q = _root.collection('foods').orderBy('name');

    return q.snapshots().map((s) {
      var list = s.docs.map((d) => Food.fromMap(d.id, d.data())).toList();

      if (supplementsOnly) {
        list = list.where((f) => f.isSupplement).toList();
      }

      if (query != null && query.trim().isNotEmpty) {
        final ql = query.trim().toLowerCase();
        list =
            list
                .where(
                  (f) =>
                      f.name.toLowerCase().contains(ql) ||
                      (f.brand ?? '').toLowerCase().contains(ql),
                )
                .toList();
      }

      return list;
    });
  }

  Future<String> createFood(Food f) async {
    final doc = _root.collection('foods').doc();
    await doc.set(f.toMap());
    return doc.id;
  }

  Future<void> updateFood(String id, Map<String, dynamic> data) async {
    await _root.collection('foods').doc(id).update(data);
  }

  Future<void> deleteFood(String id) async {
    await _root.collection('foods').doc(id).delete();
  }

  Stream<List<Recipe>> streamRecipes() {
    return _root
        .collection('recipes')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => Recipe.fromMap(d.id, d.data())).toList());
  }

  Future<String> createRecipe(Recipe r) async {
    final doc = _root.collection('recipes').doc();
    await doc.set(r.toMap());
    return doc.id;
  }

  Future<void> updateRecipe(String id, Map<String, dynamic> data) async {
    await _root.collection('recipes').doc(id).update(data);
  }

  Future<void> deleteRecipe(String id) async {
    await _root.collection('recipes').doc(id).delete();
  }

  Stream<List<Favorite>> streamFavorites() {
    return _root
        .collection('favorites')
        .orderBy('alias', descending: false)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Favorite.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<String> saveFavorite(Favorite f) async {
    final doc = _root.collection('favorites').doc();
    await doc.set(f.toMap());
    return doc.id;
  }

  Future<void> deleteFavorite(String id) async {
    await _root.collection('favorites').doc(id).delete();
  }

  Future<String> addFavorite(Favorite f) => saveFavorite(f);
  Future<void> removeFavorite(String id) => deleteFavorite(id);

  DocumentReference<Map<String, dynamic>> _dayRef(String dayId) =>
      _root.collection('intake').doc(dayId);

  Future<DailyIntakeDoc> getDay(String dayId) async {
    final snap = await _dayRef(dayId).get();
    if (!snap.exists) {
      final empty = DailyIntakeDoc(
        id: dayId,
        entries: const [],
        waterMl: 0,
        totals: const {
          'kcal': 0.0,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
          'fiber': 0.0,
          'sodium': 0.0,
        },
        targets: const {
          'kcal': null,
          'protein': null,
          'carbs': null,
          'fat': null,
          'fiber': null,
        },
      );
      await _dayRef(dayId).set(empty.toMap());
      return empty;
    }
    return DailyIntakeDoc.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  Stream<DailyIntakeDoc> streamDay(String dayId) {
    return _dayRef(dayId).snapshots().map((d) {
      if (!d.exists) {
        return DailyIntakeDoc(
          id: dayId,
          entries: const [],
          waterMl: 0,
          totals: const {
            'kcal': 0.0,
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
            'fiber': 0.0,
            'sodium': 0.0,
          },
          targets: const {
            'kcal': null,
            'protein': null,
            'carbs': null,
            'fat': null,
            'fiber': null,
          },
        );
      }
      return DailyIntakeDoc.fromMap(d.id, d.data() as Map<String, dynamic>);
    });
  }

  Future<void> _recalcTotals(
    String dayId,
    List<Map<String, dynamic>> entries,
  ) async {
    double kcal = 0, p = 0, c = 0, f = 0, fib = 0, s = 0;
    for (final e in entries) {
      final m = Map<String, dynamic>.from(e['macrosSnapshot'] as Map);
      kcal += (m['kcal'] as num?)?.toDouble() ?? 0;
      p += (m['protein'] as num?)?.toDouble() ?? 0;
      c += (m['carbs'] as num?)?.toDouble() ?? 0;
      f += (m['fat'] as num?)?.toDouble() ?? 0;
      fib += (m['fiber'] as num?)?.toDouble() ?? 0;
      s += (m['sodium'] as num?)?.toDouble() ?? 0;
    }
    await _dayRef(dayId).set({
      'entries': entries,
      'totals': {
        'kcal': kcal,
        'protein': p,
        'carbs': c,
        'fat': f,
        'fiber': fib,
        'sodium': s,
      },
    }, SetOptions(merge: true));
  }

  Future<void> addEntry(String dayId, IntakeEntry entry) async {
    final snap = await _dayRef(dayId).get();
    final data = snap.data() ?? {};
    final entries =
        ((data['entries'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    entries.add(entry.toMap());
    await _recalcTotals(dayId, entries);
  }

  Future<void> updateEntry(
    String dayId,
    int index,
    Map<String, dynamic> patch,
  ) async {
    final snap = await _dayRef(dayId).get();
    if (!snap.exists) return;
    final entries =
        ((snap.data()!['entries'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    if (index < 0 || index >= entries.length) return;
    entries[index].addAll(patch);
    await _recalcTotals(dayId, entries);
  }

  Future<void> deleteEntry(String dayId, int index) async {
    final snap = await _dayRef(dayId).get();
    if (!snap.exists) return;
    final entries =
        ((snap.data()!['entries'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    if (index < 0 || index >= entries.length) return;
    entries.removeAt(index);
    await _recalcTotals(dayId, entries);
  }

  Future<void> setTargets(
    String dayId, {
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? waterMl,
  }) async {
    final snap = await _dayRef(dayId).get();
    final data = snap.data() ?? {};
    final targets = Map<String, dynamic>.from(data['targets'] ?? {});
    if (kcal != null) targets['kcal'] = kcal;
    if (protein != null) targets['protein'] = protein;
    if (carbs != null) targets['carbs'] = carbs;
    if (fat != null) targets['fat'] = fat;
    if (fiber != null) targets['fiber'] = fiber;
    if (waterMl != null) targets['water'] = waterMl.toDouble();
    await _dayRef(dayId).set({'targets': targets}, SetOptions(merge: true));
  }

  Future<void> incrementWater(String dayId, int addMl) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final ref = _dayRef(dayId);
      final snap = await tx.get(ref);
      final current = (snap.data()?['waterMl'] as num?)?.toInt() ?? 0;
      tx.set(ref, {'waterMl': current + addMl}, SetOptions(merge: true));
    });
  }

  Stream<DailyIntakeDoc> streamDailyIntake(String dayId) => streamDay(dayId);
  Future<void> addIntakeEntry(String dayId, IntakeEntry entry) =>
      addEntry(dayId, entry);
  Future<void> removeIntakeEntry(String dayId, String entryId) async {
    final index = int.tryParse(entryId);
    if (index != null) await deleteEntry(dayId, index);
  }

  Future<void> addWater(String dayId, int ml) => incrementWater(dayId, ml);

  Stream<List<DailyIntakeDoc>> streamLastNDays(int n) {
    final today = DateTime.now();
    final dayIds = List.generate(n, (i) {
      final d = today.subtract(Duration(days: i));
      return d.toIso8601String().substring(0, 10);
    });

    return _root.collection('intake').snapshots().map((snap) {
      final docs = <DailyIntakeDoc>[];
      for (final dayId in dayIds) {
        final doc = snap.docs.where((d) => d.id == dayId).firstOrNull;
        if (doc != null) {
          docs.add(DailyIntakeDoc.fromMap(doc.id, doc.data()));
        } else {
          docs.add(
            DailyIntakeDoc(
              id: dayId,
              entries: const [],
              waterMl: 0,
              totals: const {
                'kcal': 0.0,
                'protein': 0.0,
                'carbs': 0.0,
                'fat': 0.0,
                'fiber': 0.0,
                'sodium': 0.0,
              },
              targets: const {},
            ),
          );
        }
      }
      return docs;
    });
  }

  CollectionReference<Map<String, dynamic>> get _weekPlannersRef =>
      FirebaseFirestore.instance.collection('weekPlanners');

  DocumentReference<Map<String, dynamic>> _plannerRef(String weekId) =>
      _weekPlannersRef.doc(weekId);

  Future<WeekPlanner> getWeek(String weekId) async {
    final snap = await _plannerRef(weekId).get();
    if (!snap.exists) {
      final empty = WeekPlanner(
        id: weekId,
        scope: ShoppingScope.weekly,
        days: {
          'Mon': const [],
          'Tue': const [],
          'Wed': const [],
          'Thu': const [],
          'Fri': const [],
          'Sat': const [],
          'Sun': const [],
        },
      );
      await _plannerRef(weekId).set(empty.toMap());
      return empty;
    }
    return WeekPlanner.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  Stream<WeekPlanner> streamWeek(String weekId) {
    return _plannerRef(weekId).snapshots().map((d) {
      if (!d.exists) {
        return WeekPlanner(
          id: weekId,
          scope: ShoppingScope.weekly,
          days: {
            'Mon': const [],
            'Tue': const [],
            'Wed': const [],
            'Thu': const [],
            'Fri': const [],
            'Sat': const [],
            'Sun': const [],
          },
        );
      }
      return WeekPlanner.fromMap(d.id, d.data() as Map<String, dynamic>);
    });
  }

  Future<void> saveWeek(WeekPlanner w) async {
    await _plannerRef(w.id).set({
      ...w.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<dynamic>> streamPlanners() {
    return Stream.value([]);
  }

  Stream<List<Map<String, dynamic>>> streamWeekPlannersRaw() {
    return _weekPlannersRef.snapshots().map((snap) {
      return snap.docs
          .map(
            (d) => {
              'id': d.id,
              ...d.data(),
            },
          )
          .toList();
    });
  }

  Future<void> setActiveWeekPlanner(String id) async {
    final all = await _weekPlannersRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in all.docs) {
      batch.update(d.reference, {'isActive': d.id == id});
    }
    await batch.commit();
  }

  Future<String> createPlanner(String name) async {
    final doc = _root.collection('mealPlanners').doc();
    await doc.set({
      'name': name,
      'days': {for (var i = 0; i < 7; i++) '$i': []},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> deletePlanner(String id) async {
    await _root.collection('mealPlanners').doc(id).delete();
  }

  Future<void> updatePlannerName(String id, String name) async {
    await _root.collection('mealPlanners').doc(id).update({'name': name});
  }

  Stream<List<PlannerDayEntry>> streamPlannerDay(
    String plannerId,
    int dayIndex,
  ) {
    return _root.collection('mealPlanners').doc(plannerId).snapshots().map((
      snap,
    ) {
      if (!snap.exists) return [];
      final data = snap.data() as Map<String, dynamic>;
      final days = data['days'] as Map<String, dynamic>?;
      if (days == null) return [];
      final dayData = days['$dayIndex'] as List?;
      if (dayData == null) return [];
      return dayData
          .map(
            (e) => PlannerDayEntry.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    });
  }

  Future<void> addPlannerEntry(
    String plannerId,
    int dayIndex,
    PlannerDayEntry entry,
  ) async {
    final ref = _root.collection('mealPlanners').doc(plannerId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final days = Map<String, dynamic>.from(data['days'] ?? {});
    final dayList = List.from(days['$dayIndex'] ?? []);
    dayList.add(entry.toMap());
    days['$dayIndex'] = dayList;
    await ref.update({'days': days});
  }

  Future<void> removePlannerEntry(
    String plannerId,
    int dayIndex,
    String entryId,
  ) async {
    final ref = _root.collection('mealPlanners').doc(plannerId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final days = Map<String, dynamic>.from(data['days'] ?? {});
    final dayList = List.from(days['$dayIndex'] ?? []);
    dayList.removeWhere((e) => e['id'] == entryId);
    days['$dayIndex'] = dayList;
    await ref.update({'days': days});
  }

  Stream<List<ShoppingList>> streamShoppingLists() {
    return _root
        .collection('shoppingLists')
        .orderBy('name')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ShoppingList.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<String> createShoppingList(
    String name, {
    ShoppingScope scope = ShoppingScope.custom,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      final all = await _root.collection('shoppingLists').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in all.docs) {
        batch.update(d.reference, {'isDefault': false});
      }
      await batch.commit();
    }
    final doc = _root.collection('shoppingLists').doc();
    await doc.set({
      'name': name,
      'scope': scope.name,
      'isDefault': isDefault,
      'items': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> setDefaultList(String id) async {
    final all = await _root.collection('shoppingLists').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in all.docs) {
      batch.update(d.reference, {'isDefault': d.id == id});
    }
    await batch.commit();
  }

  Future<void> updateShoppingList(String id, Map<String, dynamic> patch) async {
    await _root.collection('shoppingLists').doc(id).update(patch);
  }

  Future<void> deleteShoppingList(String id) async {
    await _root.collection('shoppingLists').doc(id).delete();
  }

  Future<void> upsertShoppingItem(
    String listId,
    String itemId,
    ShoppingListItem item,
  ) async {
    await upsertShoppingItemInternal(listId, itemId: itemId, item: item);
  }

  Future<void> upsertShoppingItemInternal(
    String listId, {
    String? itemId,
    required ShoppingListItem item,
  }) async {
    final ref = _root.collection('shoppingLists').doc(listId);
    final snap = await ref.get();
    final data = (snap.data() ?? {});
    final items =
        ((data['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    if (itemId == null) {
      items.add(item.toMap());
    } else {
      final idx = int.tryParse(itemId);
      if (idx != null && idx >= 0 && idx < items.length) {
        items[idx] = item.toMap();
      } else {
        items.add(item.toMap());
      }
    }
    await ref.set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeShoppingItem(String listId, String itemId) async {
    final index = int.tryParse(itemId) ?? -1;
    await removeShoppingItemByIndex(listId, index);
  }

  Future<void> removeShoppingItemByIndex(String listId, int index) async {
    final ref = _root.collection('shoppingLists').doc(listId);
    final snap = await ref.get();
    final items =
        ((snap.data()?['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    await ref.set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleChecked(String listId, String itemId, bool checked) async {
    final index = int.tryParse(itemId) ?? -1;
    await toggleCheckedByIndex(listId, index, checked);
  }

  Future<void> toggleCheckedByIndex(
    String listId,
    int index,
    bool checked,
  ) async {
    final ref = _root.collection('shoppingLists').doc(listId);
    final snap = await ref.get();
    final items =
        ((snap.data()?['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    if (index < 0 || index >= items.length) return;
    items[index]['checked'] = checked;
    await ref.set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setAllChecked(String listId, bool checked) async {
    final ref = _root.collection('shoppingLists').doc(listId);
    final snap = await ref.get();
    final items =
        ((snap.data()?['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    for (final item in items) {
      item['checked'] = checked;
    }
    await ref.set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearCompleted(String listId) async {
    final ref = _root.collection('shoppingLists').doc(listId);
    final snap = await ref.get();
    final items =
        ((snap.data()?['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    items.removeWhere((item) => item['checked'] == true);
    await ref.set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<PantryItem>> streamPantry() {
    return _root
        .collection('pantry')
        .orderBy('name')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => PantryItem.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> upsertPantry(PantryItem item) async {
    await upsertPantryWithId(item, id: item.id.isEmpty ? null : item.id);
  }

  Future<void> upsertPantryWithId(PantryItem item, {String? id}) async {
    final col = _root.collection('pantry');
    if (id == null) {
      await col.add(item.toMap());
    } else {
      await col.doc(id).set(item.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deletePantry(String id) async {
    await _root.collection('pantry').doc(id).delete();
  }

  Future<void> consumePantry(String id, double qty) async {
    final ref = _root.collection('pantry').doc(id);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['qty'] as num?)?.toDouble() ?? 0;
      tx.update(ref, {'qty': (current - qty).clamp(0, double.infinity)});
    });
  }

  Future<void> generateShoppingFromWeek(
    String weekId, {
    ShoppingScope? scopeOverride,
    String? targetListId,
  }) async {
    final week = await _plannerRef(weekId).get();
    if (!week.exists) return;
    final w = WeekPlanner.fromMap(week.id, week.data() as Map<String, dynamic>);

    final foodsMap = <String, Food>{};
    final foodsSnap = await _root.collection('foods').get();
    for (final d in foodsSnap.docs) {
      final f = Food.fromMap(d.id, d.data());
      foodsMap[f.id] = f;
    }

    final aggregate = <String, Map<String, dynamic>>{};
    double multiplier = 1.0;
    final scope = scopeOverride ?? w.scope;
    if (scope == ShoppingScope.biweekly) multiplier = 2.0;
    if (scope == ShoppingScope.monthly) multiplier = 4.0;

    Future<void> addFood(
      String? foodId,
      String name,
      double qty,
      UnitKind unit,
    ) async {
      final key = foodId ?? name.toLowerCase();
      final current = aggregate[key];
      if (current == null) {
        aggregate[key] = {
          'foodId': foodId,
          'name': name,
          'qty': qty * multiplier,
          'unit': unit.name,
        };
      } else {
        current['qty'] = (current['qty'] as double) + qty * multiplier;
      }
    }

    for (final day in w.days.values) {
      for (final entry in day) {
        if (entry.type == FavoriteType.food) {
          final f = foodsMap[entry.refId];
          if (f != null) {
            await addFood(f.id, f.name, entry.servings * f.unitSize, f.perUnit);
          }
        } else {
          final recSnap =
              await _root.collection('recipes').doc(entry.refId).get();
          if (!recSnap.exists) continue;
          final rec = Recipe.fromMap(
            recSnap.id,
            recSnap.data() as Map<String, dynamic>,
          );
          final ratio = entry.servings / (rec.servings == 0 ? 1 : rec.servings);
          for (final ing in rec.ingredients) {
            if (ing.foodId != null) {
              final f = foodsMap[ing.foodId!];
              if (f != null) {
                await addFood(f.id, f.name, ing.qty * ratio, ing.unit);
              }
            } else {
              await addFood(
                null,
                (ing.freeName ?? 'Ingrediente'),
                ing.qty * ratio,
                ing.unit,
              );
            }
          }
        }
      }
    }

    String listId = targetListId ?? '';
    if (listId.isEmpty) {
      listId = await createShoppingList(
        'Lista $weekId',
        scope: scope,
        isDefault: false,
      );
    }
    final items =
        aggregate.values
            .map(
              (e) =>
                  ShoppingListItem(
                    id: '',
                    foodId: e['foodId'] as String?,
                    name: e['name'] as String,
                    qty: (e['qty'] as double),
                    unit: UnitKind.values.firstWhere(
                      (u) => u.name == e['unit'],
                    ),
                  ).toMap(),
            )
            .toList();

    await _root.collection('shoppingLists').doc(listId).set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> get _remindersRef =>
      _root.collection('config').doc('reminders');

  Future<Map<String, dynamic>> getRemindersConfig() async {
    final snap = await _remindersRef.get();
    return Map<String, dynamic>.from(snap.data() ?? const {});
  }

  Future<void> saveRemindersConfig(Map<String, dynamic> data) async {
    await _remindersRef.set(data, SetOptions(merge: true));
  }

  Future<void> markAwake(DateTime when, {required String dayId}) async {
    await _remindersRef.set({
      'lastAwakeAt': Timestamp.fromDate(when),
      'lastAwakeDayId': dayId,
    }, SetOptions(merge: true));
  }
}
```


## lib/screens/food/screens/food_dashboard_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_dashboard_personal/navigation/app_route_observer.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';
import 'food_dashboard_widgets.dart';
import '../../../shared/ui/app_card.dart';
import 'food_diary_screen.dart';
import 'recipes_list_screen.dart';
import 'recipe_detail_screen.dart';
import 'food_planner_screen.dart';
import 'shopping_lists_screen.dart';
import '../widgets/food_compact_widgets.dart';
import '../../../theme/focuslane_ui.dart';
import '../../../ui/components/focus_module_header.dart';

class FoodDashboardScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  
  const FoodDashboardScreen({super.key, required this.svc});

  @override
  State<FoodDashboardScreen> createState() => _FoodDashboardScreenState();
}

class _FoodDashboardScreenState extends State<FoodDashboardScreen>
    with RouteAware {
  String _dayId(DateTime d) => d.toIso8601String().substring(0, 10);
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final todayId = _dayId(DateTime.now());
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: FoodCompactAppBar(
        title: 'Food',
        subtitle: 'Planificación, recetas y seguimiento',
        leadingMode: FocusModuleLeadingMode.exitModule,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 18),
            tooltip: 'Plan semanal',
            onPressed: () => _navigateToPlanner(context),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Nueva receta',
            onPressed: () => _navigateToRecipes(context),
          ),
        ],
      ),
      body: ListView(
        padding: isDesktop
            ? const EdgeInsets.all(40)
            : FocuslaneUI.pagePaddingCompact,
        children: [
          _buildMetricsSection(context, todayId, isDesktop),
          const SizedBox(height: 8.0),
          _buildWeeklyPlanSection(context),
          const SizedBox(height: 10.0),
          isDesktop || isTablet
              ? _buildBottomSectionDesktop(context)
              : _buildBottomSectionMobile(context),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(
    BuildContext context,
    String todayId,
    bool isDesktop,
  ) {
    return StreamBuilder<Map<String, double?>>(
      stream: widget.svc.streamGlobalTargets(),
      builder: (context, targetsSnap) {
        final targetKcal = targetsSnap.data?['kcal'] ?? 2000;
        final targetProtein = targetsSnap.data?['protein'] ?? 150;
        return StreamBuilder<DailyIntakeDoc>(
          stream: widget.svc.streamDay(todayId),
          builder: (context, daySnap) {
            final day = daySnap.data ??
                DailyIntakeDoc(
                  id: todayId,
                  entries: const [],
                  waterMl: 0,
                  totals: const {
                    'kcal': 0.0,
                    'protein': 0.0,
                    'carbs': 0.0,
                    'fat': 0.0,
                  },
                  targets: const {},
                );

            final kcal = day.totals['kcal'] ?? 0.0;
            final protein = day.totals['protein'] ?? 0.0;

            final alerts = _buildAlerts(context);

            return StreamBuilder<List<Recipe>>(
              stream: widget.svc.streamRecipes(),
              builder: (context, recipesSnap) {
                final recipesCount = recipesSnap.data?.length ?? 0;

                return StreamBuilder<List<ShoppingList>>(
                  stream: widget.svc.streamShoppingLists(),
                  builder: (context, shoppingSnap) {
                    final shoppingItems =
                        shoppingSnap.data?.expand((list) => list.items).length ?? 0;

                    return Column(
                      children: [
                        alerts,
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth >= 1200
                                ? 4
                                : constraints.maxWidth >= 600
                                    ? 2
                                    : 1;

                            final cards = [
                              FoodMetricCard(
                                icon: Icons.local_fire_department,
                                label: 'Calorías hoy',
                                value: '${kcal.toStringAsFixed(0)} kcal',
                                subtitle: 'de ${targetKcal.toStringAsFixed(0)} objetivo',
                                onTap: () => _navigateToDiary(context),
                              ),
                              FoodMetricCard(
                                icon: Icons.fitness_center,
                                label: 'Proteína hoy',
                                value: '${protein.toStringAsFixed(0)} g',
                                subtitle: 'de ${targetProtein.toStringAsFixed(0)}g objetivo',
                                onTap: () => _navigateToDiary(context),
                              ),
                              FoodMetricCard(
                                icon: Icons.restaurant_menu,
                                label: 'Recetas guardadas',
                                value: '$recipesCount',
                                subtitle: 'en tu biblioteca',
                                onTap: () => _navigateToRecipes(context),
                              ),
                              FoodMetricCard(
                                icon: Icons.shopping_cart,
                                label: 'Lista de compra',
                                value: '$shoppingItems productos',
                                subtitle: 'pendientes',
                                onTap: () => _navigateToShopping(context),
                              ),
                            ];

                            if (crossAxisCount == 1) {
                              return Column(
                                children: cards
                                    .map(
                                      (card) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10.0,
                                        ),
                                        child: card,
                                      ),
                                    )
                                    .toList(),
                              );
                            } else {
                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10.0,
                                mainAxisSpacing: 10.0,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 1.8,
                                children: cards,
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAlerts(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: widget.svc.streamAlerts(),
      builder: (context, alertSnap) {
        final alerts = alertSnap.data ?? const {};
        final overBudget = alerts['foodOverBudget'] == true;
        final proteinLow = alerts['foodProteinLowAfterWorkout'] == true;
        final extremeDeficit = alerts['foodExtremeDeficitWorkout'] == true;
        if (!overBudget && !proteinLow && !extremeDeficit) {
          return const SizedBox.shrink();
        }

        final cards = <Widget>[];
        if (proteinLow) {
          final targetProtein = (alerts['targetProteinToday'] as num?)?.toDouble() ?? 0;
          final proteinToday = (alerts['proteinToday'] as num?)?.toDouble() ?? 0;
          final gap = (targetProtein - proteinToday).clamp(0, 9999);
          cards.add(
            _AlertCard(
              icon: Icons.warning_amber,
              title: 'Proteína baja tras entreno',
              message: 'Faltan ${gap.toStringAsFixed(0)} g para el objetivo de hoy.',
            ),
          );
        }
        if (extremeDeficit) {
          final deficit = (alerts['kcalDeltaToday'] as num?)?.toDouble() ?? 0;
          cards.add(
            _AlertCard(
              icon: Icons.local_fire_department,
              title: 'Déficit extremo con entreno fuerte',
              message: 'Balance energético actual ${deficit.toStringAsFixed(0)} kcal.',
            ),
          );
        }
        if (overBudget) {
          cards.add(
            _AlertCard(
              icon: Icons.payments,
              title: 'Presupuesto de comida superado',
              message: 'Revisa el plan o ajusta compras de la semana.',
            ),
          );
        }

        return Column(
          children: cards
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: c,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildWeeklyPlanSection(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.svc.streamWeekPlannersRaw(),
      builder: (context, snapshot) {
        final plannersRaw = snapshot.data ?? [];
        final selected = _pickActivePlanner(plannersRaw);
        if (selected == null) {
          return FoodWeeklyPlanCard(
            weekPlan: const {},
            onGeneratePlan: () => _navigateToPlanner(context),
            onExportList: () => _navigateToShopping(context),
            onViewCalendar: () => _navigateToPlanner(context),
          );
        }

        final planner = WeekPlanner.fromMap(
          selected['id'] as String,
          Map<String, dynamic>.from(selected),
        );

        return StreamBuilder<List<Food>>(
          stream: widget.svc.streamFoods(),
          builder: (context, foodsSnap) {
            final foods = foodsSnap.data ?? [];
            final foodsMap = {for (final f in foods) f.id: f.name};

            return StreamBuilder<List<Recipe>>(
              stream: widget.svc.streamRecipes(),
              builder: (context, recipesSnap) {
                final recipes = recipesSnap.data ?? [];
                final recipesMap = {
                  for (final r in recipes) r.id: r.name,
                };

                final displayPlan = _buildDisplayPlan(
                  planner,
                  foodsMap: foodsMap,
                  recipesMap: recipesMap,
                );

                return FoodWeeklyPlanCard(
                  weekPlan: displayPlan,
                  onGeneratePlan: () => _navigateToPlanner(context),
                  onExportList: () => _navigateToShopping(context),
                  onViewCalendar: () => _navigateToPlanner(context),
                );
              },
            );
          },
        );
      },
    );
  }
  
  String _getMealSlotName(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return 'Desayuno';
      case MealSlot.snack:
        return 'Aperitivo';
      case MealSlot.lunch:
        return 'Comida';
      case MealSlot.merienda:
        return 'Merienda';
      case MealSlot.dinner:
        return 'Cena';
    }
  }

  Widget _buildBottomSectionDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildRecipesSection(context),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          flex: 1,
          child: _buildShoppingSection(context),
        ),
      ],
    );
  }

  Widget _buildBottomSectionMobile(BuildContext context) {
    return Column(
      children: [
        _buildRecipesSection(context),
        const SizedBox(height: 10.0),
        _buildShoppingSection(context),
      ],
    );
  }

  Widget _buildRecipesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return StreamBuilder<List<Recipe>>(
      stream: widget.svc.streamRecipes(),
      builder: (context, snapshot) {
        final recipes = snapshot.data ?? [];
        final recentRecipes = recipes.take(6).toList();

        return AppSurface(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FoodSectionHeader(
                title: 'Recetas recientes',
                subtitle: 'Favoritas y últimas',
                icon: Icons.restaurant,
                actionLabel: 'Ver todas',
                onActionPressed: () => _navigateToRecipes(context),
              ),
              const SizedBox(height: 6.0),
              if (recentRecipes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 28,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'No hay recetas guardadas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _navigateToRecipes(context),
                          child: const Text('Añadir primera receta'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentRecipes.map((recipe) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: FoodRecipeCard(
                      name: recipe.name,
                      tags: _getRecipeTags(recipe),
                      kcal: _calculateRecipeKcal(recipe) ?? 0,
                      protein: _calculateRecipeProtein(recipe) ?? 0,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                            recipe: recipe,
                            svc: widget.svc,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShoppingSection(BuildContext context) {
    return StreamBuilder<List<ShoppingList>>(
      stream: widget.svc.streamShoppingLists(),
      builder: (context, snapshot) {
        final lists = snapshot.data ?? [];
        final activeLists = lists.where((l) => l.completedAt == null).toList();
        ShoppingList? activeList;

        if (activeLists.isNotEmpty) {
          activeList =
              activeLists.firstWhere(
                (l) => l.isDefault,
                orElse: () => activeLists.first,
              );
        }

        return FoodShoppingListCard(
          listId: activeList?.id,
          items: activeList?.items ?? const [],
          onToggleItem: (index, checked) {
            if (activeList == null) return;
            widget.svc.toggleCheckedByIndex(activeList.id, index, checked);
          },
          onMarkAll: () {
            if (activeList == null) return;
            widget.svc.setAllChecked(activeList.id, true);
          },
          onClearCompleted: () {
            if (activeList == null) return;
            widget.svc.clearCompleted(activeList.id);
          },
          onNavigate: () => _navigateToShopping(context),
        );
      },
    );
  }

  List<String> _getRecipeTags(Recipe recipe) {
    final tags = <String>[];
    
    if (recipe.name.toLowerCase().contains('pollo') ||
        recipe.name.toLowerCase().contains('pavo')) {
      tags.add('Alto en proteína');
    }
    if (recipe.name.toLowerCase().contains('ensalada') ||
        recipe.name.toLowerCase().contains('vegetal')) {
      tags.add('Bajo en carbohidratos');
    }
    if (recipe.name.toLowerCase().contains('vegano') ||
        recipe.name.toLowerCase().contains('vegan')) {
      tags.add('Vegano');
    }
    
    if (tags.isEmpty) {
      tags.add('Casera');
    }
    
    return tags;
  }

  double? _calculateRecipeKcal(Recipe recipe) {
    return 450.0;
  }

  double? _calculateRecipeProtein(Recipe recipe) {
    return 32.0;
  }

  Map<String, Map<String, String>> _buildDisplayPlan(
    WeekPlanner planner, {
    required Map<String, String> foodsMap,
    required Map<String, String> recipesMap,
  }) {
    final displayPlan = <String, Map<String, String>>{};

    for (final entry in planner.days.entries) {
      final dayId = entry.key;
      final dayEntries = entry.value;

      final meals = <String, String>{};
      for (final mealEntry in dayEntries) {
        final slotName = _getMealSlotName(mealEntry.slot);
        final name = mealEntry.type == FavoriteType.food
            ? foodsMap[mealEntry.refId]
            : recipesMap[mealEntry.refId];
        meals[slotName] = name ?? mealEntry.refId;
      }

      if (meals.isNotEmpty) {
        displayPlan[dayId] = meals;
      }
    }

    return displayPlan;
  }

  Map<String, dynamic>? _pickActivePlanner(List<Map<String, dynamic>> raw) {
    if (raw.isEmpty) return null;

    final flagged = raw.where((p) {
      return p['isActive'] == true || p['isDefault'] == true;
    }).toList();

    if (flagged.isNotEmpty) {
      return flagged.first;
    }

    raw.sort((a, b) {
      final ad = _toDate(a['updatedAt']) ?? _toDate(a['createdAt']);
      final bd = _toDate(b['updatedAt']) ?? _toDate(b['createdAt']);
      return (bd ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(ad ?? DateTime.fromMillisecondsSinceEpoch(0));
    });

    return raw.first;
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  void _navigateToDiary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDiaryScreen(svc: widget.svc),
      ),
    );
  }

  void _navigateToRecipes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipesListScreen(svc: widget.svc),
      ),
    );
  }

  void _navigateToPlanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodPlannerScreen(svc: widget.svc),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToShopping(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListsScreen(svc: widget.svc),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer.withOpacity(.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```


## lib/screens/food/screens/food_planner_screen.dart

```dart
import 'package:flutter/material.dart';
import '../../../theme/focuslane_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import '../widgets/food_compact_widgets.dart';

class FoodPlannerScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  const FoodPlannerScreen({super.key, required this.svc});

  @override
  State<FoodPlannerScreen> createState() => _FoodPlannerScreenState();
}

class _FoodPlannerScreenState extends State<FoodPlannerScreen> {
  String _currentPlannerId = 'menu';
  ShoppingScope _scope = ShoppingScope.weekly;
  bool _showPlannersList = false;
  String _selectedMobileDay = 'lunes';

  List<Map<String, dynamic>> _enabledSlots = [];
  bool _slotsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSlotsConfig();
  }

  Future<void> _loadSlotsConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = prefs.getString('meal_slots_config');

    if (slotsJson != null) {
      final List<dynamic> decoded = jsonDecode(slotsJson);
      setState(() {
        _enabledSlots =
            decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _slotsLoaded = true;
      });
    } else {
      setState(() {
        _enabledSlots = [
          {
            'slot': 'breakfast',
            'name': 'Desayuno',
            'icon': Icons.wb_sunny.codePoint,
            'enabled': true,
          },
          {
            'slot': 'snack',
            'name': 'Media Mañana',
            'icon': Icons.cookie.codePoint,
            'enabled': true,
          },
          {
            'slot': 'lunch',
            'name': 'Almuerzo',
            'icon': Icons.restaurant.codePoint,
            'enabled': true,
          },
          {
            'slot': 'merienda',
            'name': 'Merienda',
            'icon': Icons.icecream.codePoint,
            'enabled': true,
          },
          {
            'slot': 'dinner',
            'name': 'Cena',
            'icon': Icons.dinner_dining.codePoint,
            'enabled': true,
          },
        ];
        _slotsLoaded = true;
      });
    }
  }

  List<MealSlot> _getActiveSlots() {
    final slotMap = {
      'breakfast': MealSlot.breakfast,
      'snack': MealSlot.snack,
      'lunch': MealSlot.lunch,
      'merienda': MealSlot.merienda,
      'dinner': MealSlot.dinner,
    };

    return _enabledSlots
        .where((s) => s['enabled'] == true)
        .map((s) => slotMap[s['slot']])
        .whereType<MealSlot>()
        .toList();
  }

  String _getConfiguredSlotName(MealSlot slot) {
    final slotKey = slot.toString().split('.').last;
    final config = _enabledSlots.firstWhere(
      (s) => s['slot'] == slotKey,
      orElse: () => {'name': _getSlotName(slot)},
    );
    return config['name'] ?? _getSlotName(slot);
  }

  IconData _getConfiguredSlotIcon(MealSlot slot) {
    final slotKey = slot.toString().split('.').last;
    final config = _enabledSlots.firstWhere(
      (s) => s['slot'] == slotKey,
      orElse: () => {'icon': _getSlotIcon(slot).codePoint},
    );
    return IconData(
      config['icon'] ?? _getSlotIcon(slot).codePoint,
      fontFamily: 'MaterialIcons',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FoodCompactAppBar(
        title: 'Planificador',
        subtitle: _getPlannerName(),
        actions: [
          IconButton(
            onPressed:
                () => setState(() => _showPlannersList = !_showPlannersList),
            icon: const Icon(Icons.restaurant_menu, size: 18),
            tooltip: 'Cambiar planner',
          ),
          PopupMenuButton<ShoppingScope>(
            icon: const Icon(Icons.calendar_today, size: 18),
            tooltip: 'Alcance del planner',
            onSelected: (scope) => setState(() => _scope = scope),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: ShoppingScope.weekly,
                    child: Row(
                      children: [
                        Icon(
                          _scope == ShoppingScope.weekly
                              ? Icons.check
                              : Icons.calendar_view_week,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Semanal'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ShoppingScope.biweekly,
                    child: Row(
                      children: [
                        Icon(
                          _scope == ShoppingScope.biweekly
                              ? Icons.check
                              : Icons.calendar_view_week,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Quincenal (x2)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ShoppingScope.monthly,
                    child: Row(
                      children: [
                        Icon(
                          _scope == ShoppingScope.monthly
                              ? Icons.check
                              : Icons.calendar_view_month,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Mensual (x4)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ShoppingScope.custom,
                    child: Row(
                      children: [
                        Icon(
                          _scope == ShoppingScope.custom
                              ? Icons.check
                              : Icons.settings,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Personalizado'),
                      ],
                    ),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar, size: 18),
            tooltip: 'Configurar comidas',
            onPressed: _configureMealSlots,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout, size: 18),
            tooltip: 'Generar lista',
            onPressed: _generateShoppingList,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          return Column(
            children: [
              _buildRealtimeStatusBar(),
              if (_showPlannersList) _buildPlannersList(),
              if (isMobile) _buildMobileDaySelector(),
              Expanded(
                child:
                    isMobile
                        ? _buildMobileDayView(_selectedMobileDay)
                        : _buildWeekPlannerTable(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewPlanner,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildRealtimeStatusBar() {
    return StreamBuilder<Map<String, double?>>(
      stream: widget.svc.streamGlobalTargets(),
      builder: (context, targetsSnap) {
        final targetKcal = targetsSnap.data?['kcal'] ?? 2000;
        final targetProtein = targetsSnap.data?['protein'] ?? 120;
        return StreamBuilder<Map<String, dynamic>>(
          stream: widget.svc.streamAlerts(),
          builder: (context, alertsSnap) {
            final alerts = alertsSnap.data ?? const {};
            final overBudget = alerts['foodOverBudget'] == true;
            final proteinLow = alerts['foodProteinLowAfterWorkout'] == true;
            final extremeDeficit = alerts['foodExtremeDeficitWorkout'] == true;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    label: Text('Objetivo kcal ${targetKcal.toStringAsFixed(0)}'),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text('Objetivo proteína ${targetProtein.toStringAsFixed(0)}g'),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (proteinLow)
                    Chip(
                      label: const Text('Proteína baja tras entreno'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (extremeDeficit)
                    Chip(
                      label: const Text('Déficit extremo con entreno fuerte'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (overBudget)
                    Chip(
                      label: const Text('Presupuesto food superado'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlannersList() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('weekPlanners')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final planners = snapshot.data!.docs;

          return SizedBox(
            height: 88,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              itemCount: planners.length,
              itemBuilder: (context, index) {
                final planner = planners[index];
                final isSelected = planner.id == _currentPlannerId;

                return GestureDetector(
                  onTap: () {
                    widget.svc.setActiveWeekPlanner(planner.id);
                    setState(() {
                      _currentPlannerId = planner.id;
                      _showPlannersList = false;
                    });
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? colorScheme.surface
                              : colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color:
                            isSelected
                                ? FocuslaneUI.accent(context)
                                : Colors.transparent,
                        width: FocuslaneUI.borderW,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).dividerColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color:
                                  isSelected
                                      ? FocuslaneUI.accent(context)
                                      : AppColors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                planner.id,
                                style: AppTypography.label(context).copyWith(
                                  color:
                                      isSelected
                                      ? FocuslaneUI.accent(context)
                                          : AppColors.textSecondary,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Última edición',
                          style: AppTypography.caption(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          _formatDate(planner.get('updatedAt')),
                          style: AppTypography.caption(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().scale(
                  delay: Duration(milliseconds: index * 50),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekPlannerTable() {
    return StreamBuilder<WeekPlanner>(
      stream: widget.svc.streamWeek(_currentPlannerId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final planner = snap.data!;
        final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
        final dayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final slots = _slotsLoaded ? _getActiveSlots() : MealSlot.values;

        return StreamBuilder<List<Food>>(
          stream: widget.svc.streamFoods(),
          builder: (context, foodsSnap) {
            if (!foodsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final foods = foodsSnap.data!;
            final foodsMap = {for (final f in foods) f.id: f};

            return LayoutBuilder(
              builder: (context, constraints) {
                final viewW = constraints.maxWidth;
                final contentW = viewW < 1400 ? 1400.0 : viewW;

                return InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.7,
                  maxScale: 2.0,
                  boundaryMargin: const EdgeInsets.all(32),
                  child: Center(
                    child: SizedBox(
                      width: contentW,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                        size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                      const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Toca para añadir • Mantén pulsado para eliminar',
                                      style: AppTypography.caption(
                                        context,
                                      ).copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                ModernBadge(
                                  label: _getScopeLabel(_scope),
                                  color: FocuslaneUI.accent(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Table(
                                columnWidths: const {0: FixedColumnWidth(90)},
                                defaultColumnWidth: const FixedColumnWidth(170),
                                border: TableBorder.all(
                                  color: FocuslaneUI.borderColor(context),
                                  width: FocuslaneUI.borderW,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                ),
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer,
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(
                                          AppSpacing.radiusLg,
                                        ),
                                        topRight: Radius.circular(
                                          AppSpacing.radiusLg,
                                        ),
                                      ),
                                    ),
                                    children: [
                                      _buildHeaderCell(''),
                                      ...days.map((d) => _buildHeaderCell(d)),
                                    ],
                                  ),
                                  ...slots.asMap().entries.map((entry) {
                                    final slotIndex = entry.key;
                                    final slot = entry.value;
                                    final cs = Theme.of(context).colorScheme;

                                    return TableRow(
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? cs.surface
                                                : (slotIndex.isEven
                                                    ? cs.surfaceContainerHighest
                                                    : cs.surface),
                                      ),
                                      children: [
                                        _buildSlotHeaderCell(
                                          _getConfiguredSlotName(slot),
                                          _getConfiguredSlotIcon(slot),
                                        ),
                                        ...dayKeys.asMap().entries.map((
                                          dayEntry,
                                        ) {
                                          final dayIndex = dayEntry.key;
                                          final dayKey = dayEntry.value;
                                          final entries =
                                              planner.days[dayKey] ?? const [];
                                          final slotEntries =
                                              entries
                                                  .where((e) => e.slot == slot)
                                                  .toList();

                                          return _buildMealCell(
                                            planner: planner,
                                            dayKey: dayKey,
                                            slot: slot,
                                            entries: slotEntries,
                                            foodsMap: foodsMap,
                                            delay:
                                                (slotIndex * 7 + dayIndex) * 30,
                                          );
                                        }),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTypography.caption(context).copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSlotHeaderCell(String text, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, size: 16, color: FocuslaneUI.accent(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption(context).copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCell({
    required WeekPlanner planner,
    required String dayKey,
    required MealSlot slot,
    required List<PlannerDayEntry> entries,
    required Map<String, Food> foodsMap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: () => _openFoodSelector(planner, dayKey, slot, foodsMap),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.all(6),
        child:
            entries.isEmpty
                ? Center(
                  child: Icon(
                    Icons.add_circle_outline,
                    color: AppColors.textSecondary.withOpacity(0.5),
                    size: 24,
                  ),
                )
                : Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      entries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final plannerEntry = entry.value;
                        final food = foodsMap[plannerEntry.refId];

                        return GestureDetector(
                          onLongPress:
                              () => _deleteEntry(planner, dayKey, slot, index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: FocuslaneUI.accentSurface(
                                context,
                                opacity: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: FocuslaneUI.borderColor(context),
                                width: FocuslaneUI.borderW,
                              ),
                            ),
                            child: Text(
                              food?.name ?? plannerEntry.refId,
                              style: AppTypography.caption(context).copyWith(
                                color: FocuslaneUI.accent(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }

  String _getPlannerName() {
    if (_currentPlannerId == 'menu') return 'Principal';
    return _currentPlannerId.length > 12
        ? '${_currentPlannerId.substring(0, 12)}...'
        : _currentPlannerId;
  }

  String _getScopeLabel(ShoppingScope scope) {
    switch (scope) {
      case ShoppingScope.weekly:
        return 'Semanal';
      case ShoppingScope.biweekly:
        return 'Quincenal';
      case ShoppingScope.monthly:
        return 'Mensual';
      case ShoppingScope.custom:
        return 'Personalizado';
    }
  }

  String _getSlotName(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return 'Desayuno';
      case MealSlot.snack:
        return 'Aperitivo';
      case MealSlot.lunch:
        return 'Comida';
      case MealSlot.merienda:
        return 'Merienda';
      case MealSlot.dinner:
        return 'Cena';
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Reciente';
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Hoy';
      if (diff.inDays == 1) return 'Ayer';
      if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Reciente';
    }
  }

  Future<void> _generateShoppingList() async {
    try {
      await widget.svc.generateShoppingFromWeek(
        _currentPlannerId,
        scopeOverride: _scope,
      );

      if (mounted) {
        FoodFeedback.showSuccess(
          context,
          'Lista generada (${_getScopeLabel(_scope)})',
        );
      }
    } catch (e) {
      if (mounted) {
        FoodFeedback.showError(context, 'Error al generar: $e');
      }
    }
  }

  Future<void> _configureMealSlots() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _MealSlotsConfigSheet(
            onConfigSaved: () {
              _loadSlotsConfig();
            },
          ),
    );
  }

  Future<void> _createNewPlanner() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nuevo planificador'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nombre del planificador',
                hintText: 'Ej: Definición, Volumen, Familiar',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Crear'),
              ),
            ],
          ),
    );

    if (name != null && name.isNotEmpty) {
      final newPlanner = WeekPlanner(id: name, scope: _scope, days: {});
      await widget.svc.saveWeek(newPlanner);
      await widget.svc.setActiveWeekPlanner(name);

      setState(() {
        _currentPlannerId = name;
        _showPlannersList = false;
      });

      if (mounted) {
        FoodFeedback.showSuccess(context, 'Planificador "$name" creado');
      }
    }
  }

  Future<void> _openFoodSelector(
    WeekPlanner planner,
    String dayKey,
    MealSlot slot,
    Map<String, Food> foodsMap,
  ) async {
    final foods = foodsMap.values.toList();

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: AppSpacing.sm),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? colorScheme.onSurface.withOpacity(0.3)
                                  : FocuslaneUI.borderColor(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Selecciona alimentos',
                                style: AppTypography.heading3(context),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: FocuslaneUI.dividerW,
                        thickness: FocuslaneUI.dividerW,
                        color: FocuslaneUI.dividerColor(context),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: foods.length,
                          itemBuilder: (context, index) {
                            final food = foods[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    FocuslaneUI.accentSurface(
                                      context,
                                      opacity: 0.18,
                                    ),
                                child: const Icon(Icons.restaurant, size: 20),
                              ),
                              title: Text(
                                food.name,
                                style: AppTypography.body(context),
                              ),
                              subtitle:
                                  food.brand != null
                                      ? Text(
                                        food.brand!,
                                        style: AppTypography.caption(context),
                                      )
                                      : null,
                              trailing: Text(
                                '${food.kcal.toStringAsFixed(0)} kcal',
                                style: AppTypography.label(
                                  context,
                                ).copyWith(color: FocuslaneUI.accent(context)),
                              ),
                              onTap: () async {
                                await _addFoodToSlot(
                                  planner,
                                  dayKey,
                                  slot,
                                  food.id,
                                );
                                if (context.mounted) Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Future<void> _addFoodToSlot(
    WeekPlanner planner,
    String dayKey,
    MealSlot slot,
    String foodId,
  ) async {
    final dayList = List<PlannerDayEntry>.from(
      planner.days[dayKey] ?? const [],
    );
    dayList.add(
      PlannerDayEntry(
        slot: slot,
        type: FavoriteType.food,
        refId: foodId,
        servings: 1.0,
      ),
    );

    final newDays = Map<String, List<PlannerDayEntry>>.from(planner.days);
    newDays[dayKey] = dayList;

    await widget.svc.saveWeek(
      WeekPlanner(id: _currentPlannerId, scope: _scope, days: newDays),
    );
  }

  Future<void> _deleteEntry(
    WeekPlanner planner,
    String dayKey,
    MealSlot slot,
    int index,
  ) async {
    final dayList = List<PlannerDayEntry>.from(
      planner.days[dayKey] ?? const [],
    );
    final filtered = dayList.where((e) => e.slot == slot).toList();

    if (index >= filtered.length) return;

    final target = filtered[index];
    dayList.remove(target);

    final newDays = Map<String, List<PlannerDayEntry>>.from(planner.days);
    newDays[dayKey] = dayList;

    await widget.svc.saveWeek(
      WeekPlanner(id: _currentPlannerId, scope: _scope, days: newDays),
    );

    if (mounted) {
      FoodFeedback.showSuccess(context, 'Elemento eliminado');
    }
  }

  Widget _buildMobileDaySelector() {
    final days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == _selectedMobileDay;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(
                day[0].toUpperCase() + day.substring(1, 3),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: FocuslaneUI.accent(context),
              backgroundColor: colorScheme.surface,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedMobileDay = day);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileDayView(String dayKey) {
    return StreamBuilder<WeekPlanner?>(
      stream: widget.svc.streamWeek(_currentPlannerId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final planner =
            snap.data ??
            WeekPlanner(id: _currentPlannerId, scope: _scope, days: const {});
        final slots = _slotsLoaded ? _getActiveSlots() : MealSlot.values;

        return StreamBuilder<List<Food>>(
          stream: widget.svc.streamFoods(),
          builder: (context, foodsSnap) {
            if (!foodsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final foods = foodsSnap.data!;
            final foodsMap = {for (final f in foods) f.id: f};
            final colorScheme = Theme.of(context).colorScheme;

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                final entries =
                    (planner.days[dayKey] ?? const [])
                        .where((e) => e.slot == slot)
                        .toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: BorderSide(
                      color: FocuslaneUI.borderColor(context),
                      width: FocuslaneUI.borderW,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: FocuslaneUI.accentSurface(
                            context,
                            opacity: 0.16,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppSpacing.radiusMd),
                            topRight: Radius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getConfiguredSlotIcon(slot),
                              color: FocuslaneUI.accent(context),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _getConfiguredSlotName(slot),
                              style: AppTypography.heading4(
                                context,
                              ).copyWith(color: FocuslaneUI.accent(context)),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: FocuslaneUI.accent(context),
                              ),
                              onPressed:
                                  () => _openFoodSelector(
                                    planner,
                                    dayKey,
                                    slot,
                                    foodsMap,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(
                              'Toca + para añadir alimento',
                              style: AppTypography.caption(context),
                            ),
                          ),
                        )
                      else
                        ...entries.asMap().entries.map((mapEntry) {
                          final entryIndex = mapEntry.key;
                          final entry = mapEntry.value;
                          final food = foodsMap[entry.refId];

                          if (food == null) {
                            return ListTile(
                              title: Text('Alimento no encontrado'),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed:
                                    () => _deleteEntry(
                                      planner,
                                      dayKey,
                                      slot,
                                      entryIndex,
                                    ),
                              ),
                            );
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                food.isSupplement
                                    ? Icons.medication
                                    : Icons.restaurant,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(food.name),
                            subtitle: Text(
                              '${(food.kcal * entry.servings).toStringAsFixed(0)} kcal • ${entry.servings}x porción',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed:
                                  () => _deleteEntry(
                                    planner,
                                    dayKey,
                                    slot,
                                    entryIndex,
                                  ),
                            ),
                          );
                        }),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 100).ms);
              },
            );
          },
        );
      },
    );
  }

  IconData _getSlotIcon(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return Icons.wb_sunny;
      case MealSlot.snack:
        return Icons.cookie;
      case MealSlot.lunch:
        return Icons.restaurant;
      case MealSlot.merienda:
        return Icons.icecream;
      case MealSlot.dinner:
        return Icons.dinner_dining;
    }
  }
}

class _MealSlotsConfigSheet extends StatefulWidget {
  final VoidCallback onConfigSaved;
  const _MealSlotsConfigSheet({required this.onConfigSaved});

  @override
  State<_MealSlotsConfigSheet> createState() => _MealSlotsConfigSheetState();
}

class _MealSlotsConfigSheetState extends State<_MealSlotsConfigSheet> {
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = prefs.getString('meal_slots_config');

    if (slotsJson != null) {
      final List<dynamic> decoded = jsonDecode(slotsJson);
      setState(() {
        _slots = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _slots = [
          {
            'slot': 'breakfast',
            'name': 'Desayuno',
            'icon': Icons.wb_sunny.codePoint,
            'enabled': true,
          },
          {
            'slot': 'snack',
            'name': 'Media Mañana',
            'icon': Icons.cookie.codePoint,
            'enabled': true,
          },
          {
            'slot': 'lunch',
            'name': 'Almuerzo',
            'icon': Icons.restaurant.codePoint,
            'enabled': true,
          },
          {
            'slot': 'merienda',
            'name': 'Merienda',
            'icon': Icons.icecream.codePoint,
            'enabled': true,
          },
          {
            'slot': 'dinner',
            'name': 'Cena',
            'icon': Icons.dinner_dining.codePoint,
            'enabled': true,
          },
        ];
        _isLoading = false;
      });
    }
  }

  final List<IconData> _availableIcons = [
    Icons.wb_sunny,
    Icons.cookie,
    Icons.restaurant,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.local_cafe,
    Icons.bakery_dining,
    Icons.fastfood,
    Icons.ramen_dining,
    Icons.icecream,
    Icons.apple,
    Icons.egg,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? colorScheme.onSurface.withOpacity(0.3)
                        : AppColors.grey300,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.edit_calendar,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configurar Comidas',
                        style: AppTypography.heading2(context),
                      ),
                      Text(
                        'Personaliza las comidas del día',
                        style: AppTypography.caption(context),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _slots.length,
                itemBuilder: (context, index) {
                  final slot = _slots[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FocuslaneUI.radius),
                      side: BorderSide(
                        color: FocuslaneUI.borderColor(context),
                        width: FocuslaneUI.borderW,
                      ),
                    ),
                    child: ListTile(
                      leading: Switch(
                        value: slot['enabled'],
                        onChanged: (v) => setState(() => slot['enabled'] = v),
                        activeThumbColor: colorScheme.primary,
                      ),
                      title: TextFormField(
                        initialValue: slot['name'],
                        decoration: InputDecoration(
                          hintText: 'Nombre de la comida',
                          enabled: slot['enabled'],
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: AppTypography.body(context),
                        onChanged: (v) => slot['name'] = v,
                      ),
                      trailing: PopupMenuButton<int>(
                        icon: Icon(
                          IconData(slot['icon'], fontFamily: 'MaterialIcons'),
                          color:
                              slot['enabled']
                                  ? colorScheme.primary
                                  : Colors.grey,
                        ),
                        enabled: slot['enabled'],
                        onSelected:
                            (iconCode) =>
                                setState(() => slot['icon'] = iconCode),
                        itemBuilder:
                            (context) =>
                                _availableIcons.map((icon) {
                                  return PopupMenuItem(
                                    value: icon.codePoint,
                                    child: Icon(icon),
                                  );
                                }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _slots.clear();
                        _slots.addAll([
                          {
                            'slot': 'breakfast',
                            'name': 'Desayuno',
                            'icon': Icons.wb_sunny.codePoint,
                            'enabled': true,
                          },
                          {
                            'slot': 'snack',
                            'name': 'Media Mañana',
                            'icon': Icons.cookie.codePoint,
                            'enabled': true,
                          },
                          {
                            'slot': 'lunch',
                            'name': 'Almuerzo',
                            'icon': Icons.restaurant.codePoint,
                            'enabled': true,
                          },
                          {
                            'slot': 'merienda',
                            'name': 'Merienda',
                            'icon': Icons.icecream.codePoint,
                            'enabled': true,
                          },
                          {
                            'slot': 'dinner',
                            'name': 'Cena',
                            'icon': Icons.dinner_dining.codePoint,
                            'enabled': true,
                          },
                        ]);
                      });
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Restablecer'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ModernPrimaryButton(
                    label: 'Guardar',
                    icon: Icons.check,
                    fullWidth: true,
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final slotsJson = jsonEncode(_slots);
                      await prefs.setString('meal_slots_config', slotsJson);

                      widget.onConfigSaved();

                      if (mounted) {
                        Navigator.pop(context);
                        FoodFeedback.showSuccess(
                          context,
                          'Configuración guardada',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```


## lib/screens/gym/dashboard/gym_dashboard_screen.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../gym/services/gym_firestore_service.dart';
import '../../gym/routines/routines_list_screen.dart';
import '../../gym/routines/routine_detail_screen.dart';
import '../../gym/session/session_history_screen.dart';
import '../../gym/goals/gym_goals_screen.dart';
import '../../../ui/components/focus_card.dart';
import '../../../ui/components/focus_metric_card.dart';
import '../../../ui/components/focus_section_title.dart';
import '../../../ui/components/focus_empty_state.dart';
import '../../../ui/components/focus_list_tile_compact.dart';
import '../../../ui/tokens/focuslane_tokens.dart';
import '../../../ui/components/focus_module_header.dart';

class GymDashboardScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymDashboardScreen({super.key, required this.svc});

  Widget _buildAlerts(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();
    final alerts$ = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root')
        .collection('config')
        .doc('alerts')
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: alerts$,
      builder: (context, alertSnap) {
        final alert = alertSnap.data?.data() ?? const {};
        final showDeficit = alert['extremeDeficitWorkout'] == true;
        final subSoon = alert['subscriptionDueSoon'] == true;
        if (!showDeficit && !subSoon) return const SizedBox.shrink();
        final cards = <Widget>[];
        if (showDeficit) {
          final deficit = (alert['deficitKcal'] as num?)?.toDouble() ?? 0;
          cards.add(
            _GymAlertCard(
              icon: Icons.local_fire_department,
              title: 'Déficit extremo con entreno fuerte',
              message: 'Balance energético actual ${deficit.toStringAsFixed(0)} kcal.',
            ),
          );
        }
        if (subSoon) {
          final dueDays = (alert['subscriptionDueInDays'] as num?)?.toInt();
          String dueLabel = 'pronto';
          if (dueDays != null) {
            dueLabel = dueDays <= 0 ? 'hoy' : 'en $dueDays días';
          } else {
            final due = alert['subscriptionDueAt'];
            if (due is Timestamp) {
              dueLabel = DateFormat('d MMM').format(due.toDate());
            }
          }
          cards.add(
            _GymAlertCard(
              icon: Icons.event_available,
              title: 'Pago próximo',
              message: 'Suscripción de gym $dueLabel.',
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: FocuslaneTokens.spacing12),
                    child: c,
                  ))
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final dateLabel = DateFormat('d MMM', 'es').format(now);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Gym',
        subtitle: 'Rutinas, progreso y objetivos',
        leadingMode: FocusModuleLeadingMode.exitModule,
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          _buildAlerts(context),
          FocusSectionTitle(
            title: 'Resumen del día',
            subtitle: 'Actualizado $dateLabel',
            action: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionHistoryScreen(svc: svc),
                  ),
                );
              },
              child: const Text('Ver historial'),
            ),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: svc.getStatsForDateRange(start, now),
            builder: (context, snap) {
              final data = snap.data;
              final totalSessions = data?['totalSessions'] as int?;
              final totalVolume = data?['totalVolume'] as double?;
              final totalSessionsText =
                  totalSessions == null ? '—' : totalSessions.toString();
              final totalVolumeText = totalVolume == null
                  ? '—'
                  : '${(totalVolume / 1000).toStringAsFixed(1)} ton';

              return StreamBuilder<List<BodyWeightEntry>>(
                stream: svc.streamBodyWeight(limit: 1),
                builder: (context, weightSnap) {
                  final weight =
                      weightSnap.data?.isNotEmpty == true
                          ? weightSnap.data!.first.weight
                          : null;

                  return FutureBuilder(
                    future: svc.root.get(),
                    builder: (context, rootSnap) {
                      final rootData = rootSnap.data?.data();
                      final target = (rootData?['bodyWeightTarget'] as num?)?.toDouble();
                      final weightText = weight == null
                          ? '—'
                          : '${weight.toStringAsFixed(1)} kg';
                      final targetText = target == null
                          ? '—'
                          : '${target.toStringAsFixed(1)} kg';

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 1200
                              ? 4
                              : constraints.maxWidth >= 600
                                  ? 2
                                  : 1;

                          final cards = [
                            FocusMetricCard(
                              icon: Icons.fitness_center,
                              label: 'Entrenos esta semana',
                              value: totalSessionsText,
                              subtitle: 'Últimos 7 días',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SessionHistoryScreen(svc: svc),
                                  ),
                                );
                              },
                            ),
                            FocusMetricCard(
                              icon: Icons.auto_graph,
                              label: 'Volumen total',
                              value: totalVolumeText,
                              subtitle: 'Últimos 7 días',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SessionHistoryScreen(svc: svc),
                                  ),
                                );
                              },
                            ),
                            const FocusMetricCard(
                              icon: Icons.bolt,
                              label: 'Racha',
                              value: '—',
                              subtitle: 'Actual',
                            ),
                            FocusMetricCard(
                              icon: Icons.monitor_weight,
                              label: 'Peso actual / objetivo',
                              value: weightText,
                              subtitle: targetText,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GymGoalsScreen(svc: svc),
                                  ),
                                );
                              },
                            ),
                          ];

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: FocuslaneTokens.spacing12,
                            crossAxisSpacing: FocuslaneTokens.spacing12,
                            childAspectRatio: constraints.maxWidth >= 600 ? 3.2 : 2.8,
                            children: cards,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: FocuslaneTokens.spacing16),
          FocusSectionTitle(
            title: 'Rutina semanal',
            subtitle: 'Tu planificación principal',
            action: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoutinesListScreen(svc: svc),
                  ),
                );
              },
              child: const Text('Ver rutinas'),
            ),
          ),
          StreamBuilder<Routine?>(
            stream: svc.streamDefaultRoutine(),
            builder: (context, snap) {
              final routine = snap.data;
              if (routine == null) {
                return FocusCard(
                  maxHeight: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aún no tienes una rutina principal',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: FocuslaneTokens.spacing8),
                      Text(
                        'Crea una rutina para organizar tu semana.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: FocuslaneTokens.spacing12),
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoutinesListScreen(svc: svc),
                            ),
                          );
                        },
                        child: const Text('Crear rutina'),
                      ),
                    ],
                  ),
                );
              }

              return StreamBuilder<List<RoutineDay>>(
                stream: svc.streamDays(routine.id),
                builder: (context, daysSnap) {
                  final days = daysSnap.data ?? const [];
                  return FocusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: FocuslaneTokens.spacing8),
                        if (days.isEmpty)
                          Text(
                            'Añade días y ejercicios para estructurar tu semana.',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          Wrap(
                            spacing: FocuslaneTokens.spacing8,
                            runSpacing: FocuslaneTokens.spacing8,
                            children: days.take(6).map((d) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: FocuslaneTokens.spacing8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: FocuslaneTokens.accentSurface(
                                    context,
                                    opacity: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    FocuslaneTokens.radius12,
                                  ),
                                  border: Border.all(
                                    color: FocuslaneTokens.borderColor(context),
                                    width: FocuslaneTokens.borderW,
                                  ),
                                ),
                                child: Text(
                                  d.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: FocuslaneTokens.spacing12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoutineDetailScreen(
                                    svc: svc,
                                    routine: routine,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Abrir rutina'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: FocuslaneTokens.spacing16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FocusSectionTitle(
                          title: 'Últimos entrenos',
                          subtitle: 'Sesiones recientes',
                        ),
                        StreamBuilder<List<SessionDoc>>(
                          stream: svc.streamSessions(limit: 5),
                          builder: (context, snap) {
                            final sessions = snap.data ?? const [];
                            if (sessions.isEmpty) {
                              return const FocusEmptyState(
                                icon: Icons.history,
                                message: 'Sin entrenos recientes',
                              );
                            }

                            return FocusCard(
                              child: Column(
                                children: sessions.map((s) {
                                  final date = DateFormat('d MMM', 'es')
                                      .format(s.date);
                                  final subtitle =
                                      '${s.routineName} · $date';
                                  final volume = s.volumeKg > 0
                                      ? '${(s.volumeKg / 1000).toStringAsFixed(1)} ton'
                                      : '—';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: FocusListTileCompact(
                                      title: s.dayName,
                                      subtitle: subtitle,
                                      trailing: Text(
                                        volume,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: FocuslaneTokens.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FocusSectionTitle(
                          title: 'Objetivos',
                          subtitle: 'Metas y seguimiento',
                        ),
                        FocusCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Define tus objetivos de fuerza y peso.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: FocuslaneTokens.spacing12),
                              FilledButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GymGoalsScreen(svc: svc),
                                    ),
                                  );
                                },
                                child: const Text('Abrir objetivos'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          ],
        ),
      ),
    );
  }
}

class _GymAlertCard extends StatelessWidget {
  const _GymAlertCard({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer.withOpacity(.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```


## lib/main.dart

```dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_dashboard_personal/supabase_config.dart';
import 'package:mi_dashboard_personal/models/outfit_model.dart';
import 'package:mi_dashboard_personal/screens/culture/culture_routes.dart';
import 'package:mi_dashboard_personal/screens/goals/goals_home_screen.dart';
import 'package:mi_dashboard_personal/screens/modules_screen.dart';
import 'package:mi_dashboard_personal/screens/notes/note_model.dart';
import 'package:mi_dashboard_personal/screens/ropa/outfit_builder_screen.dart';
import 'package:mi_dashboard_personal/screens/ropa/outfit_detail_screen.dart';
import 'package:mi_dashboard_personal/screens/ropa/outfit_list_screen.dart';
import 'package:mi_dashboard_personal/screens/ropa/planificador_screen.dart';
import 'package:mi_dashboard_personal/screens/ropa/prenda_form_screen.dart';
import 'package:mi_dashboard_personal/screens/ropa/ropa_home_screen.dart';
import 'package:mi_dashboard_personal/screens/skills/skills_routes.dart';
import 'package:mi_dashboard_personal/screens/tasks/task_edit_screen.dart';
import 'package:mi_dashboard_personal/screens/tasks/task_model.dart';
import 'package:mi_dashboard_personal/screens/trading/live/trading_live_chart_screen.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';
import 'package:mi_dashboard_personal/widgets/avoid_fab.dart';
import 'package:mi_dashboard_personal/widgets/auth_gate.dart';
import 'package:mi_dashboard_personal/screens/auth/login_screen.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';
import 'theme/prefs.dart';
import 'widgets/app_background.dart';
import 'screens/home_screen.dart';
import 'screens/tasks/tasks_main_screen.dart';
import 'screens/tasks/task_create_screen.dart';
import 'screens/notes/notes_list_screen.dart';
import 'screens/notes/note_editor_screen.dart';
import 'screens/habits/habits_table_screen.dart';
import 'screens/habits/habit_create_screen.dart';
import 'screens/habits/habit_detail_screen.dart';
import 'screens/habits/habit_stats_screen.dart';
import 'screens/habits/habit_model.dart';
import 'screens/gym/main/gym_main_screen.dart';
import 'screens/gym/services/gym_firestore_service.dart';
import 'screens/gym/routines/routines_list_screen.dart';
import 'screens/gym/analytics/gym_analytics_screen_v2.dart';
import 'screens/gym/goals/gym_goals_screen.dart';
import 'screens/gym/body/bodyweight_screen.dart';
import 'screens/gym/body/measurements_screen.dart';
import 'screens/study/services/study_firestore_service.dart';
import 'screens/study/timer/study_timer_screen.dart';
import 'screens/study/analytics/study_analytics_screen.dart';
import 'screens/study/main/study_main_screen.dart';
import 'screens/food/services/food_firestore_service.dart';
import 'screens/food/main/food_main_screen.dart';
import 'screens/finance/main/finance_routes.dart';
import 'screens/meditation/meditation_routes.dart';
import 'screens/trading/trading_routes.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'navigation/app_route_observer.dart';
import 'navigation/app_routes.dart';
import 'core/services/core_sync_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await NotificationService.I.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
    final n = msg.notification;
    if (n != null) {
      await NotificationService.I.showNow(
        id: (n.title ?? 'msg').hashCode ^ (n.body ?? '').hashCode,
        title: n.title ?? 'Mensaje',
        body: n.body ?? '',
      );
    }
  });
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  // Configure Firebase Auth persistence
  try {
    if (kIsWeb) {
      await fb_auth.FirebaseAuth.instance.setPersistence(
        fb_auth.Persistence.LOCAL,
      );
    }
  } catch (_) {}

  // Configure Firestore persistence
  try {
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } else {
      await FirebaseFirestore.instance.enablePersistence();
      FirebaseFirestore.instance.settings = const Settings(
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (_) {}

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemePreset _preset = ThemePreset.ocean;
  ThemeMode _themeMode = ThemeMode.system;
  BackgroundStyle _bgStyle = BackgroundStyle.none;
  bool _loaded = false;

  FoodFirestoreService? _foodSvc;
  GymFirestoreService? _gymService;
  StudyFirestoreService? _studySvc;

  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _askNotifPermission();
    NotificationService.I.scheduleHabitDailyReminder(
      const TimeOfDay(hour: 0, minute: 0),
    );

    _notifSub = NotificationService.I.onPayload.listen((p) {
      if (p == 'OPEN_HABITS') {
        appNavigatorKey.currentState?.pushNamed('/habits');
      } else if (p == 'OPEN_CALENDAR') {
        appNavigatorKey.currentState?.pushNamed('/calendar');
      } else if (p == 'OPEN_TASKS') {
        appNavigatorKey.currentState?.pushNamed('/tasks');
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    CoreSyncService.I.dispose();
    super.dispose();
  }

  Future<void> _askNotifPermission() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.getToken();
  }

  Future<void> _loadPrefs() async {
    final (p, m, b) = await ThemePrefs.load();
    setState(() {
      _preset = p;
      _themeMode = m;
      _bgStyle = b;
      _loaded = true;
    });
  }

  void toggleTheme(bool isDarkMode) {
    final next = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    setState(() => _themeMode = next);
    ThemePrefs.save(preset: _preset, mode: next, bg: _bgStyle);
  }

  ThemeData _safe(ThemeData candidate) {
    final seed = candidate.colorScheme.primary;
    final bright = candidate.brightness;
    final fixed = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: bright),
      textTheme: candidate.textTheme,
    );
    return fixed.copyWith(
      appBarTheme: candidate.appBarTheme,
      cardTheme: candidate.cardTheme,
      chipTheme: candidate.chipTheme,
      elevatedButtonTheme: candidate.elevatedButtonTheme,
      inputDecorationTheme: candidate.inputDecorationTheme,
      iconTheme: candidate.iconTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _safe(AppTheme.getLight(_preset)),
        darkTheme: _safe(AppTheme.getDark(_preset)),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: false,
        ),
        navigatorObservers: [appRouteObserver],
      );
    }

    final light = _safe(AppTheme.getLight(_preset));
    final dark = _safe(AppTheme.getDark(_preset));

        return MaterialApp(
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Mi Dashboard Personal',
          theme: light,
          darkTheme: dark,
          themeMode: _themeMode,
          navigatorObservers: [appRouteObserver],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            scrollbars: false,
          ),

          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final padded = mq.copyWith(
              padding:
                  mq.padding + const EdgeInsets.only(bottom: kFabAvoidHeight),
            );
            return MediaQuery(
              data: padded,
              child: AppBackground(
                style: _bgStyle,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },

          home: AuthGate(
            authenticated: HomeScreen(
              toggleTheme: (isDark) {
                setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
                ThemePrefs.save(
                  preset: _preset,
                  mode: _themeMode,
                  bg: _bgStyle,
                );
              },
              themeMode: _themeMode,
            ),
            unauthenticated: const LoginScreen(),
          ),

          routes: {
            '/settings':
                (_) => SettingsScreen(
                  currentPreset: _preset,
                  currentMode: _themeMode,
                  currentBackground: _bgStyle,
                  onChangePreset: (p) {
                    setState(() => _preset = p);
                    ThemePrefs.save(
                      preset: _preset,
                      mode: _themeMode,
                      bg: _bgStyle,
                    );
                  },
                  onChangeMode: (m) {
                    setState(() => _themeMode = m);
                    ThemePrefs.save(
                      preset: _preset,
                      mode: _themeMode,
                      bg: _bgStyle,
                    );
                  },
                  onChangeBackground: (b) {
                    setState(() => _bgStyle = b);
                    ThemePrefs.save(
                      preset: _preset,
                      mode: _themeMode,
                      bg: _bgStyle,
                    );
                  },
                ),
            '/modules': (_) => const ModulesScreen(),
            '/tasks': (_) => const TasksMainScreen(),
            '/tasks/create': (_) => const TaskCreateScreen(),
            '/tasks/detail': (ctx) {
              final task = ModalRoute.of(ctx)!.settings.arguments as Task;
              return TaskEditScreen(task: task);
            },

            '/notes': (_) => const NotesListScreen(),
            '/notes/list': (_) => const NotesListScreen(),
            '/notes/editor': (ctx) {
              final args = ModalRoute.of(ctx)!.settings.arguments;
              if (args is Note) {
                return NoteEditorScreen(note: args);
              } else if (args is String) {
                return NoteEditorScreen(noteId: args);
              } else {
                return const NoteEditorScreen();
              }
            },

            '/habits': (_) => const HabitsTableScreen(),
            '/habits/create': (_) => const HabitCreateScreen(),
            '/habit-create': (_) => const HabitCreateScreen(),
            '/habits/detail': (ctx) {
              final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
              return HabitDetailScreen(habit: habit);
            },
            '/habit-detail': (ctx) {
              final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
              return HabitDetailScreen(habit: habit);
            },
            '/habits/stats': (ctx) {
              final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
              return HabitStatsScreen(habit: habit);
            },

            AppRoutes.gymDashboard: (_) {
              _gymService ??= GymFirestoreService();
              return GymMainScreen(svc: _gymService!);
            },
            '/gym/routines': (_) {
              _gymService ??= GymFirestoreService();
              return RoutinesListScreen(svc: _gymService!);
            },
            '/gym/analytics': (_) {
              _gymService ??= GymFirestoreService();
              return GymAnalyticsScreenV2(svc: _gymService!);
            },
            '/gym/goals': (_) {
              _gymService ??= GymFirestoreService();
              return GymGoalsScreen(svc: _gymService!);
            },
            '/gym/body/weight': (_) {
              _gymService ??= GymFirestoreService();
              return BodyweightScreen(svc: _gymService!);
            },
            '/gym/body/measurements': (_) {
              _gymService ??= GymFirestoreService();
              return MeasurementsScreen(svc: _gymService!);
            },

            AppRoutes.studyDashboard: (_) {
              _studySvc ??= StudyFirestoreService();
              return StudyMainScreen(svc: _studySvc!);
            },
            '/study/timer': (_) {
              _studySvc ??= StudyFirestoreService();
              return StudyTimerScreen(svc: _studySvc!);
            },
            '/study/analytics': (_) {
              _studySvc ??= StudyFirestoreService();
              return StudyAnalyticsScreen(svc: _studySvc!);
            },

            AppRoutes.foodDashboard: (_) {
              final userId = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';
              _foodSvc ??= FoodFirestoreService(userId);
              return FoodMainScreen(svc: _foodSvc!);
            },
            ...financeRoutes,
            ...meditationRoutes,
            ...tradingRoutes,
            ...cultureRoutes,
            ...skillsRoutes,

            '/calendar': (_) => const CalendarScreen(),
            '/ropa': (_) => const RopaHomeScreen(),
            '/prendaForm': (_) => const PrendaFormScreen(),
            '/outfitBuilder': (_) => const OutfitBuilderScreen(),
            '/outfits': (_) => const OutfitListScreen(),
            '/outfitDetalle': (ctx) {
              final outfit = ModalRoute.of(ctx)!.settings.arguments as Outfit;
              return OutfitDetailScreen(outfit: outfit);
            },
            '/planificadorRopa': (_) => const PlanificadorScreen(),
            '/trading/live': (_) => const TradingLiveChartScreen(),
            GoalsHomeScreen.route: (_) => const GoalsHomeScreen(),
          },
          onGenerateRoute: (settings) => null,
        );
  }
}
```


