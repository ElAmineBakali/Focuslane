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
    if (trimmed.isEmpty) {
      debugPrint('[CoreSync] start() SKIPPED — uid is empty');
      return;
    }
    if (_activeUid == trimmed) {
      debugPrint('[CoreSync] start() SKIPPED — already active uid=$trimmed');
      return;
    }

    debugPrint('[CoreSync] ══════════════════════════════════════');
    debugPrint('[CoreSync] start() uid=$trimmed — launching all listeners');
    stop();
    _activeUid = trimmed;
    _watchGymToday(trimmed);
    _watchStudyTasks(trimmed);
    _watchTasks(trimmed);
    _watchFoodBudgetRealtime(trimmed);
    _watchSubscriptions(trimmed);
    _watchRecurringFinance(trimmed);
    debugPrint('[CoreSync] start() — all 6 listeners launched');
    debugPrint('[CoreSync] ══════════════════════════════════════');
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
    debugPrint('[CoreSync][gymToday] LISTENER STARTED uid=$uid');
    final todayRange = _todayIsoRange();
    debugPrint('[CoreSync][gymToday] query range=${todayRange.start} → ${todayRange.end}');
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
          debugPrint('[CoreSync][gymToday] ▶ EVENT received uid=$uid docs=${snap.docs.length} changes=${snap.docChanges.length}');
          for (final ch in snap.docChanges) {
            final d = ch.doc.data() ?? {};
            debugPrint('[CoreSync][gymToday]   change type=${ch.type.name} docId=${ch.doc.id} durationMin=${d['durationMin']} volumeKg=${d['volumeKg']} date=${d['date']}');
          }
          debugPrint('[CoreSync][gymToday] → side-effect: _syncFoodTargets(${snap.docs.length} sessions)');
          _syncFoodTargets(uid, snap.docs);
        });
  }

  void _watchStudyTasks(String uid) {
    debugPrint('[CoreSync][studyTasks] LISTENER STARTED uid=$uid');
    _studyTasksSub = _db
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('tasks')
        .snapshots()
        .listen((snap) {
          debugPrint('[CoreSync][studyTasks] ▶ EVENT received uid=$uid docs=${snap.docs.length} changes=${snap.docChanges.length}');
          for (final ch in snap.docChanges) {
            final d = ch.doc.data() ?? {};
            debugPrint('[CoreSync][studyTasks]   change type=${ch.type.name} docId=${ch.doc.id} title=${d['title']} status=${d['status']} syncedTaskId=${d['syncedTaskId']}');
          }
          debugPrint('[CoreSync][studyTasks] → side-effect: _mirrorStudyIntoTasks');
          _mirrorStudyIntoTasks(uid, snap);
        });
  }

  void _watchTasks(String uid) {
    debugPrint('[CoreSync][tasks] LISTENER STARTED uid=$uid');
    _tasksSub = _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .snapshots()
        .listen((snap) {
          debugPrint('[CoreSync][tasks] ▶ EVENT received uid=$uid docs=${snap.docs.length} changes=${snap.docChanges.length}');
          for (final ch in snap.docChanges) {
            final d = ch.doc.data() ?? {};
            debugPrint('[CoreSync][tasks]   change type=${ch.type.name} docId=${ch.doc.id} title=${d['title']} completed=${d['completed']} syncedStudyTaskId=${d['syncedStudyTaskId']}');
          }
          debugPrint('[CoreSync][tasks] → side-effect: _mirrorTasksIntoStudy');
          _mirrorTasksIntoStudy(uid, snap);
        });
  }

  void _watchFoodBudgetRealtime(String uid) {
    debugPrint('[CoreSync][financeBudgets] LISTENER STARTED uid=$uid');
    _financeBudgetsSub = _db
        .collection('finance_budgets')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
          _cachedBudgetDocs = snap.docs;
          debugPrint('[CoreSync][financeBudgets] ▶ EVENT received uid=$uid docs=${snap.docs.length} changes=${snap.docChanges.length}');
          for (final ch in snap.docChanges) {
            final d = ch.doc.data() ?? {};
            debugPrint('[CoreSync][financeBudgets]   change type=${ch.type.name} docId=${ch.doc.id} category=${d['category']} amount=${d['amount']} period=${d['period']}');
          }
          debugPrint('[CoreSync][financeBudgets] → side-effect: _recalcFoodOverBudget');
          _recalcFoodOverBudget(uid);
        });

    debugPrint('[CoreSync][financeTransactions] LISTENER STARTED uid=$uid');
    _financeTxSub = _db
        .collection('finance_transactions')
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: 'expense')
        .snapshots()
        .listen((snap) {
          _cachedFinanceDocs = snap.docs;
          debugPrint('[CoreSync][financeTransactions] ▶ EVENT received uid=$uid docs=${snap.docs.length} changes=${snap.docChanges.length}');
          for (final ch in snap.docChanges) {
            final d = ch.doc.data() ?? {};
            debugPrint('[CoreSync][financeTransactions]   change type=${ch.type.name} docId=${ch.doc.id} category=${d['category']} amount=${d['amount']} date=${d['date']}');
          }
          debugPrint('[CoreSync][financeTransactions] → side-effect: _recalcFoodOverBudget');
          _recalcFoodOverBudget(uid);
        });
  }

  Future<void> _recalcFoodOverBudget(String uid) async {
    if (_recalcBudgetBusy) {
      debugPrint('[CoreSync][_recalcFoodOverBudget] SKIPPED — already busy uid=$uid');
      return;
    }
    _recalcBudgetBusy = true;
    debugPrint('[CoreSync][_recalcFoodOverBudget] ENTER uid=$uid budgetDocs=${_cachedBudgetDocs.length} txDocs=${_cachedFinanceDocs.length}');
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

        debugPrint('[CoreSync][_recalcFoodOverBudget]   budget=${d.id} cat=$cat amount=$amount spent=$spent over=${spent > amount}');
        if (spent > amount) {
          overBudget = true;
          overBudgetId = d.id;
          debugPrint('[CoreSync][_recalcFoodOverBudget] ⚠ OVER BUDGET detected id=$overBudgetId spent=$spent > limit=$amount');
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
      debugPrint('[CoreSync][_recalcFoodOverBudget] RESULT overBudget=$overBudget overBudgetId=$overBudgetId');
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
    debugPrint('[CoreSync][subscriptionsDue] LISTENER STARTED uid=$uid');
    _subsDueSub = SubscriptionService.I.upcomingPayments(daysAhead: 7).listen((subs) async {
      debugPrint('[CoreSync][subscriptionsDue] ▶ EVENT received uid=$uid subs=${subs.length}');
      final docId = subs.isEmpty ? '-' : (subs.first.id.isEmpty ? '-' : subs.first.id);
      _logListener('subscriptionsDue', uid, docId);

      final gymSubs = subs.where((s) => s.category.toLowerCase().contains('gym')).toList();
      debugPrint('[CoreSync][subscriptionsDue]   gymSubs=${gymSubs.length}');
      for (final s in gymSubs) {
        debugPrint('[CoreSync][subscriptionsDue]   gym sub: id=${s.id} title=${s.title} nextDue=${s.nextDue}');
      }
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
    debugPrint('[CoreSync][financeRecurring] LISTENER STARTED uid=$uid');
    _financeRecurringSub = _db
        .collection('finance_transactions')
        .where('userId', isEqualTo: uid)
        .where('recurrence', isNotEqualTo: null)
        .snapshots()
        .listen((snap) {
          debugPrint('[CoreSync][financeRecurring] ▶ EVENT received uid=$uid docs=${snap.docs.length} changes=${snap.docChanges.length}');
          for (final ch in snap.docChanges) {
            final d = ch.doc.data() ?? {};
            debugPrint('[CoreSync][financeRecurring]   change type=${ch.type.name} docId=${ch.doc.id} title=${d['title']} recurrence=${d['recurrence']} amount=${d['amount']}');
          }
          debugPrint('[CoreSync][financeRecurring] → side-effect: _materializeRecurring for ${snap.docs.length} docs');
          for (final doc in snap.docs) {
            _materializeRecurring(uid, doc.id, doc.data());
          }
        });
  }

  Future<void> _syncFoodTargets(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions,
  ) async {
    debugPrint('[CoreSync][_syncFoodTargets] ENTER uid=$uid sessions=${sessions.length}');
    final todayId = dayIdFromDateTime(DateTime.now());
    debugPrint('[CoreSync][_syncFoodTargets] dayId=$todayId');
    var totalMinutes = 0;
    double totalVolume = 0;

    for (final d in sessions) {
      final m = d.data();
      final durMin = (m['durationMin'] as num?)?.toInt() ?? 0;
      final volKg = (m['volumeKg'] as num?)?.toDouble() ?? 0;
      debugPrint('[CoreSync][_syncFoodTargets]   session=${d.id} durationMin=$durMin volumeKg=$volKg date=${m['date']}');
      totalMinutes += durMin;
      totalVolume += volKg;
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
    if (syncMeta['gymHash'] == hash) {
      debugPrint('[CoreSync][_syncFoodTargets] SKIPPED — gymHash unchanged ($hash)');
      return;
    }
    debugPrint('[CoreSync][_syncFoodTargets] gymHash changed old=${syncMeta['gymHash']} new=$hash — recalculating targets');

    final foodSvc = FoodFirestoreService(uid);
    final global = await foodSvc.streamGlobalTargets().first;

    final baseKcal = _n(targetData['baseKcal']) ?? _n(targetData['kcal']) ?? (global['kcal'] ?? 2000);
    final baseProtein =
        _n(targetData['baseProtein']) ?? _n(targetData['protein']) ?? (global['protein'] ?? 120);

    final extraKcal = (totalMinutes * 8) + (totalVolume * 0.1);
    final extraProtein = (totalMinutes * 0.25).clamp(10, 60);

    final kcalTarget = baseKcal + extraKcal;
    final proteinTarget = baseProtein + extraProtein;
    debugPrint('[CoreSync][_syncFoodTargets] baseKcal=$baseKcal extraKcal=$extraKcal → kcalTarget=$kcalTarget');
    debugPrint('[CoreSync][_syncFoodTargets] baseProtein=$baseProtein extraProtein=$extraProtein → proteinTarget=$proteinTarget');
    debugPrint('[CoreSync][_syncFoodTargets] totalMinutes=$totalMinutes totalVolume=$totalVolume');

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
    debugPrint('[CoreSync][_syncFoodTargets] intake: kcalToday=$kcalToday proteinToday=$proteinToday');
    debugPrint('[CoreSync][_syncFoodTargets] alerts: strongWorkout=$strongWorkout kcalDelta=$kcalDelta proteinLow=$proteinLow extremeDeficit=$extremeDeficitWorkout');

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
    debugPrint('[CoreSync][_mirrorStudyIntoTasks] ENTER uid=$uid changes=${snap.docChanges.length}');
    for (final change in snap.docChanges) {
      if (change.type == DocumentChangeType.removed) {
        debugPrint('[CoreSync][_mirrorStudyIntoTasks]   SKIP removed doc=${change.doc.id}');
        continue;
      }
      final raw = change.doc.data();
      if (raw == null) continue;
      final data = Map<String, dynamic>.from(raw);
      final hash = _studyHash(data);
      final meta = _metaFrom(data);
      if (_shouldSkip(meta, _actorStudy, hash)) {
        debugPrint('[CoreSync][_mirrorStudyIntoTasks]   SKIP same-actor doc=${change.doc.id} hash=$hash');
        continue;
      }
      debugPrint('[CoreSync][_mirrorStudyIntoTasks]   PROCESSING doc=${change.doc.id} title=${data['title']} status=${data['status']} syncedTaskId=${data['syncedTaskId']}');

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
      // NOTE: No backpatch to study doc for existing links —
      // the link (syncedTaskId) is already set and updating
      // syncMeta here would trigger the study listener again.
    }
  }

  Future<void> _mirrorTasksIntoStudy(
    String uid,
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    debugPrint('[CoreSync][_mirrorTasksIntoStudy] ENTER uid=$uid changes=${snap.docChanges.length}');
    for (final change in snap.docChanges) {
      if (change.type == DocumentChangeType.removed) {
        debugPrint('[CoreSync][_mirrorTasksIntoStudy]   SKIP removed doc=${change.doc.id}');
        continue;
      }
      final raw = change.doc.data();
      if (raw == null) continue;
      final data = Map<String, dynamic>.from(raw);
      final hash = _taskHash(data);
      final meta = _metaFrom(data);
      if (_shouldSkip(meta, _actorTasks, hash)) {
        debugPrint('[CoreSync][_mirrorTasksIntoStudy]   SKIP same-actor doc=${change.doc.id} hash=$hash');
        continue;
      }
      debugPrint('[CoreSync][_mirrorTasksIntoStudy]   PROCESSING doc=${change.doc.id} title=${data['title']} completed=${data['completed']} syncedStudyTaskId=${data['syncedStudyTaskId']}');

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
      // NOTE: No backpatch to task doc for existing links —
      // the link (syncedStudyTaskId) is already set and updating
      // syncMeta here would trigger the tasks listener again.
    }
  }

  Future<void> _materializeRecurring(String uid, String txId, Map<String, dynamic> data) async {
    final recurrence = (data['recurrence'] ?? '').toString();
    if (recurrence.isEmpty || recurrence == 'none') {
      debugPrint('[CoreSync][_materializeRecurring] SKIP txId=$txId — no recurrence');
      return;
    }
    debugPrint('[CoreSync][_materializeRecurring] ENTER uid=$uid txId=$txId recurrence=$recurrence title=${data['title']} amount=${data['amount']}');

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

    debugPrint('[CoreSync][_materializeRecurring] nextDate=$next dayId=$dayId');
    final already = await plannedDoc.get();
    if (!already.exists) {
      debugPrint('[CoreSync][_materializeRecurring] CREATING planned transaction $txId-$dayId');
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
      debugPrint('[CoreSync][_materializeRecurring] CREATING calendar entry fin-$txId-$dayId');
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
    // ALWAYS use top-level updatedAt: user edits change it but NOT
    // syncMeta.updatedAt, so this lets us detect real user changes.
    if (data.containsKey('updatedAt')) {
      meta['updatedAt'] = data['updatedAt'];
    }
    return meta;
  }

  bool _shouldSkip(Map<String, dynamic> meta, String actor, String hash) {
    final lastBy = (meta['lastSyncedBy'] ?? '').toString();
    final lastHash = (meta['lastSyncedHash'] ?? '').toString();
    // 1) Same actor, same hash → definitely skip
    if (lastBy == actor && lastHash == hash) return true;

    final lastAt = _ts(meta['lastSyncedAt']);
    final updatedAt = _ts(meta['updatedAt']);

    // 2) ANY core-sync actor last touched this doc AND no user edit
    //    happened since → it's a sync echo, not a real change.
    //    (updatedAt comes from top-level field, updated by both user
    //    code and sync; lastSyncedAt is only set by sync writes.)
    if (lastBy.startsWith('core-sync:') &&
        lastAt != null &&
        updatedAt != null &&
        !lastAt.isBefore(updatedAt)) {
      return true;
    }

    return false;
  }

  Map<String, dynamic> _metaPatch(String actor, String hash) {
    // Use client-side Timestamp instead of FieldValue.serverTimestamp()
    // because serverTimestamp appears as null in local snapshots (before
    // server confirms the write), breaking the _shouldSkip timestamp check.
    final now = Timestamp.fromDate(DateTime.now());
    return {
      'syncMeta': {
        'lastSyncedBy': actor,
        'lastSyncedHash': hash,
        'lastSyncedAt': now,
        'updatedAt': now,
      },
      'updatedAt': now,
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