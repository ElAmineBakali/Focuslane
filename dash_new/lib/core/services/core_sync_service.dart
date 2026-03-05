import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../screens/calendar/models/calendar_models.dart';
import '../../screens/food/services/food_firestore_service.dart';
import '../utils/date_utils.dart';

/// Sync-debug logging.
/// Active by default in debug builds; pass `--dart-define=DEBUG_SYNC_LOGS=false`
/// to mute, or `--dart-define=DEBUG_SYNC_LOGS=true` to enable in release/profile.
const bool kCoreSyncDebug =
    bool.fromEnvironment('DEBUG_SYNC_LOGS', defaultValue: kDebugMode);

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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _financeSubsSub;
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
    _financeSubsSub?.cancel();
    _financeRecurringSub?.cancel();
  }

  void _log(String message) {
    if (!kCoreSyncDebug) return;
    debugPrint(message);
  }

  void _logError(String scope, Object error, [StackTrace? stackTrace]) {
    _log('[CoreSync][$scope] ERROR $error');
    if (stackTrace != null) {
      _log('[CoreSync][$scope] STACK $stackTrace');
    }
  }

  void _logWrite(String path, Map<String, dynamic> values) {
    _log('[CoreSync] → side-effect write path=$path values=$values');
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
          unawaited(
            _syncFoodTargets(uid, snap.docs).catchError((Object e, StackTrace st) {
              _logError('gymToday→syncFoodTargets', e, st);
            }),
          );
        }, onError: (Object e, StackTrace st) {
          _logError('gymToday', e, st);
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
          unawaited(
            _mirrorStudyIntoTasks(uid, snap).catchError((Object e, StackTrace st) {
              _logError('studyTasks→mirrorStudyIntoTasks', e, st);
            }),
          );
        }, onError: (Object e, StackTrace st) {
          _logError('studyTasks', e, st);
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
          unawaited(
            _mirrorTasksIntoStudy(uid, snap).catchError((Object e, StackTrace st) {
              _logError('tasks→mirrorTasksIntoStudy', e, st);
            }),
          );
        }, onError: (Object e, StackTrace st) {
          _logError('tasks', e, st);
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
          unawaited(
            _recalcFoodOverBudget(uid).catchError((Object e, StackTrace st) {
              _logError('financeBudgets→recalcFoodOverBudget', e, st);
            }),
          );
        }, onError: (Object e, StackTrace st) {
          _logError('financeBudgets', e, st);
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
          unawaited(
            _recalcFoodOverBudget(uid).catchError((Object e, StackTrace st) {
              _logError('financeTransactions→recalcFoodOverBudget', e, st);
            }),
          );
        }, onError: (Object e, StackTrace st) {
          _logError('financeTransactions', e, st);
        });
  }

  Future<void> _recalcFoodOverBudget(String uid) async {
    if (_recalcBudgetBusy) {
      _log('[CoreSync][_recalcFoodOverBudget] SKIP already busy uid=$uid');
      return;
    }
    _recalcBudgetBusy = true;
    _log('[CoreSync][_recalcFoodOverBudget] ENTER uid=$uid budgetDocs=${_cachedBudgetDocs.length} txDocs=${_cachedFinanceDocs.length}');
    try {
      final now = DateTime.now();
      var overBudget = false;
      String? overBudgetId;
      var selectedSpent = 0.0;
      var selectedLimit = 0.0;

      for (final d in _cachedBudgetDocs) {
        final m = d.data();
        final cat = _normalizeCategoryKey((m['category'] ?? '').toString());
        if (!_isFoodCategory(cat)) continue;
        final amount = _n(m['limit']) ?? _n(m['amount']) ?? 0;
        if (amount <= 0) {
          _log('[CoreSync][_recalcFoodOverBudget] SKIP budget=${d.id} invalid limit=$amount');
          continue;
        }

        final period = (m['period'] ?? 'monthly').toString();
        final startDate = _toDate(m['startDate']) ?? now;
        final endDate = _toDate(m['endDate']);
        final (rangeStart, rangeEnd) = _budgetRange(period, startDate, endDate, now);

        double spent = 0;
        for (final tx in _cachedFinanceDocs) {
          final t = tx.data();
          final txCat = _normalizeCategoryKey((t['category'] ?? '').toString());
          if (!_isFoodCategory(txCat)) continue;
          final txDate = _toDate(t['date']);
          if (txDate == null) continue;
          if (txDate.isBefore(rangeStart) || txDate.isAfter(rangeEnd)) continue;
          spent += _n(t['amount']) ?? 0;
        }

        selectedSpent = spent;
        selectedLimit = amount;
        _log('[CoreSync][_recalcFoodOverBudget] budget=${d.id} cat=$cat spent=$spent limit=$amount over=${spent > amount}');
        if (spent > amount) {
          overBudget = true;
          overBudgetId = d.id;
          _log('[CoreSync][_recalcFoodOverBudget] OVER-BUDGET budgetId=$overBudgetId spent=$spent limit=$amount');
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

      final alertsPatch = {
        'overBudget': overBudget,
        'categoryKey': 'alimentacion',
        'spent': selectedSpent,
        'limit': selectedLimit,
        'foodOverBudget': overBudget,
        'foodOverBudgetBudgetId': overBudgetId,
        'foodOverBudgetSpent': selectedSpent,
        'foodOverBudgetLimit': selectedLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      _logWrite('users/$uid/food/root/config/alerts', alertsPatch);
      await alertsRef.set(alertsPatch, SetOptions(merge: true));
      _log('[CoreSync][_recalcFoodOverBudget] RESULT overBudget=$overBudget spent=$selectedSpent limit=$selectedLimit budgetId=$overBudgetId');
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
    _log('[CoreSync][financeSubscriptions] LISTENER STARTED uid=$uid');
    _financeSubsSub = _db
        .collection('finance_subscriptions')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snap) async {
          try {
            _log('[CoreSync][financeSubscriptions] ▶ EVENT received uid=$uid docs=${snap.docs.length} changes=${snap.docChanges.length}');
            for (final ch in snap.docChanges) {
              final d = ch.doc.data() ?? const <String, dynamic>{};
              _log('[CoreSync][financeSubscriptions] change type=${ch.type.name} docId=${ch.doc.id} title=${d['title'] ?? d['name']} nextPaymentDate=${d['nextPaymentDate'] ?? d['nextDue']} amount=${d['amount']}');
            }

            final today = DateTime.now();
            final startOfToday = DateTime(today.year, today.month, today.day);
            final lastDueDate = DateTime(
              startOfToday.year,
              startOfToday.month,
              startOfToday.day + 7,
              23,
              59,
              59,
            );

            QueryDocumentSnapshot<Map<String, dynamic>>? nextDoc;
            DateTime? nextPaymentDate;
            double? amount;

            for (final doc in snap.docs) {
              final data = doc.data();
              final active = (data['active'] ?? data['isActive'] ?? true) == true;
              if (!active) continue;

              final dueDate = _toDate(data['nextPaymentDate']) ?? _toDate(data['nextDue']);
              if (dueDate == null) continue;
              if (dueDate.isBefore(startOfToday) || dueDate.isAfter(lastDueDate)) continue;

              if (nextPaymentDate == null || dueDate.isBefore(nextPaymentDate)) {
                nextDoc = doc;
                nextPaymentDate = dueDate;
                amount = _n(data['amount']) ?? 0;
              }
            }

            final dueSoon = nextDoc != null;
            final ref = _db
                .collection('users')
                .doc(uid)
                .collection('gym')
                .doc('root')
                .collection('alerts')
                .doc('subscription');

            final patch = {
              'dueSoon': dueSoon,
              'nextPaymentDate': dueSoon && nextPaymentDate != null
                  ? Timestamp.fromDate(nextPaymentDate)
                  : null,
              'amount': dueSoon ? amount : null,
              'subscriptionId': dueSoon ? nextDoc.id : null,
              'updatedAt': FieldValue.serverTimestamp(),
            };
            _logWrite('users/$uid/gym/root/alerts/subscription', patch);
            await ref.set(patch, SetOptions(merge: true));
          } catch (e, st) {
            _logError('financeSubscriptions→computeAndWrite', e, st);
          }
        }, onError: (Object e, StackTrace st) {
          _logError('financeSubscriptions', e, st);
        });
  }

  void _watchRecurringFinance(String uid) {
    debugPrint('[CoreSync][financeRecurring] LISTENER STARTED uid=$uid');
    _financeRecurringSub = _db
        .collection('finance_transactions')
        .where('userId', isEqualTo: uid)
        .where('recurrence', isNotEqualTo: null)
        .snapshots()
        .listen((snap) async {
          debugPrint('[CoreSync][financeRecurring] ▶ EVENT received uid=$uid docs=${snap.docs.length} changes=${snap.docChanges.length}');
          for (final ch in snap.docChanges) {
            try {
              final d = ch.doc.data() ?? {};
              debugPrint('[CoreSync][financeRecurring]   change type=${ch.type.name} docId=${ch.doc.id} title=${d['title']} recurrence=${d['recurrence']} amount=${d['amount']}');
              if (ch.type == DocumentChangeType.removed) {
                _log('[CoreSync][financeRecurring] SKIP removed tx=${ch.doc.id}');
                continue;
              }
              _log('[CoreSync][financeRecurring] → side-effect _materializeRecurring tx=${ch.doc.id}');
              await _materializeRecurring(uid, ch.doc.id, d);
            } catch (e, st) {
              _logError('financeRecurring→materialize tx=${ch.doc.id}', e, st);
            }
          }
        }, onError: (Object e, StackTrace st) {
          _logError('financeRecurring', e, st);
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
      _log('[CoreSync][_materializeRecurring] SKIP txId=$txId no recurrence');
      return;
    }
    _log('[CoreSync][_materializeRecurring] ENTER uid=$uid txId=$txId recurrence=$recurrence title=${data['title']} amount=${data['amount']}');

    final baseDate = _toDate(data['date']) ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime next = baseDate;
    while (DateTime(next.year, next.month, next.day).isBefore(today)) {
      next = _nextDate(next, recurrence);
    }
    final nextDay = DateTime(next.year, next.month, next.day);

    final dayId = dayIdFromDateTime(nextDay);
    final plannedDoc = _db
        .collection('users')
        .doc(uid)
        .collection('finance')
        .doc('data')
        .collection('transactions')
        .doc('$txId-$dayId');

    _log('[CoreSync][_materializeRecurring] nextDate=$nextDay dayId=$dayId');
    final already = await plannedDoc.get();
    if (!already.exists) {
      _log('[CoreSync][_materializeRecurring] → side-effect create planned tx $txId-$dayId');
      final plannedPatch = {
        'title': data['title'] ?? 'Recurrente',
        'amount': data['amount'] ?? 0,
        'category': data['category'],
        'type': data['type'] ?? 'expense',
        'planned': true,
        'isBill': false,
        'date': Timestamp.fromDate(nextDay),
        'dueDate': Timestamp.fromDate(nextDay),
        'recurrence': recurrence,
        'sourceRecurringId': txId,
      };
      _logWrite('users/$uid/finance/data/transactions/$txId-$dayId', plannedPatch);
      await plannedDoc.set(plannedPatch);
    } else {
      _log('[CoreSync][_materializeRecurring] SKIP planned tx already exists doc=$txId-$dayId');
    }

    final calendarCol = _db
        .collection('users')
        .doc(uid)
        .collection('planner')
        .doc('data')
        .collection('calendar');
    final dedupeKey = '$txId|$dayId';
    final calendarDocId = 'fin-rec-$txId-$dayId';
    final calRef = calendarCol.doc(calendarDocId);

    final calSnap = await calRef.get();
    if (calSnap.exists) {
      _log('[CoreSync][_materializeRecurring] SKIP calendar idempotent doc=$calendarDocId');
      return;
    }

    final dup = await calendarCol
        .where('relatedTxId', isEqualTo: txId)
        .where('dedupeKey', isEqualTo: dedupeKey)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) {
      _log('[CoreSync][_materializeRecurring] SKIP calendar idempotent dedupeKey=$dedupeKey doc=${dup.docs.first.id}');
      return;
    }

    final event = CalendarEvent(
      id: calendarDocId,
      title: (data['title'] ?? 'Pago recurrente').toString(),
      type: CalendarType.finance,
      priority: CalendarPriority.normal,
      start: nextDay,
      end: DateTime(nextDay.year, nextDay.month, nextDay.day, 23, 59),
      allDay: true,
      notes: (data['category'] ?? '').toString(),
      relatedActionId: 'finance-recurring:$txId:$dayId',
      relatedTxId: txId,
      dedupeKey: dedupeKey,
    );
    final calPatch = {
      ...event.toMap(),
      'relatedTxId': txId,
      'dedupeKey': dedupeKey,
      'amount': _n(data['amount']) ?? 0,
      'sourceRecurringId': txId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    _logWrite('users/$uid/planner/data/calendar/$calendarDocId', calPatch);
    await calRef.set(calPatch, SetOptions(merge: true));
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
      case 'daily':
        return base.add(const Duration(days: 1));
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

  bool _isFoodCategory(String normalizedCategoryKey) {
    return normalizedCategoryKey == 'alimentacion' ||
        normalizedCategoryKey == 'food' ||
        normalizedCategoryKey == 'comida' ||
        normalizedCategoryKey == 'supermercado';
  }

  String _normalizeCategoryKey(String raw) {
    var value = raw.trim().toLowerCase();
    if (value.isEmpty) return '';

    const replacements = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };

    replacements.forEach((from, to) {
      value = value.replaceAll(from, to);
    });

    value = value
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return value;
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