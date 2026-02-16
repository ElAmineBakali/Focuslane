import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../../screens/finance/services/budget_service.dart';
import '../../screens/finance/models/subscription_model.dart';
import '../../screens/finance/services/subscription_service.dart';
import '../../screens/food/services/food_firestore_service.dart';
import '../utils/date_utils.dart';

class CoreSyncService {
  CoreSyncService._();
  static final CoreSyncService I = CoreSyncService._();

  final _db = FirebaseFirestore.instance;
  String? _activeUid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _gymTodaySub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _studyTasksSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tasksSub;
  StreamSubscription<List<BudgetWithProgress>>? _budgetsSub;
  StreamSubscription<List<Subscription>>? _subsDueSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _financeRecurringSub;

  static const _actorStudy = 'core-sync:study';
  static const _actorTasks = 'core-sync:tasks';

  void start(String uid) {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return;
    if (_activeUid == trimmed) return;

    stop();
    _activeUid = trimmed;
    _watchGymToday(trimmed);
    _watchStudyTasks(trimmed);
    _watchTasks(trimmed);
    _watchBudgets(trimmed);
    _watchSubscriptions(trimmed);
    _watchRecurringFinance(trimmed);
  }

  void stop() {
    _disposeUserSubs();
    _activeUid = null;
  }

  void dispose() => stop();

  void _disposeUserSubs() {
    _gymTodaySub?.cancel();
    _studyTasksSub?.cancel();
    _tasksSub?.cancel();
    _budgetsSub?.cancel();
    _subsDueSub?.cancel();
    _financeRecurringSub?.cancel();
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
        .listen((snap) => _syncFoodTargets(uid, snap.docs));
  }

  void _watchStudyTasks(String uid) {
    _studyTasksSub = _db
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('tasks')
        .snapshots()
      .listen((snap) => _mirrorStudyIntoTasks(uid, snap));
  }

  void _watchTasks(String uid) {
    _tasksSub = _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .snapshots()
      .listen((snap) => _mirrorTasksIntoStudy(uid, snap));
  }

  void _watchBudgets(String uid) {
    _budgetsSub = BudgetService.I.watchAllWithProgress().listen((list) async {
      final over = list.where((e) {
        return e.budget.category.toLowerCase() == 'food' && e.spent > e.budget.amount;
      }).toList();
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('food')
          .doc('root')
          .collection('config')
          .doc('flags');
      await ref.set(
        {
          'overBudgetFood': over.isNotEmpty,
          'overBudgetBudgetId': over.isNotEmpty ? over.first.budget.id : null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  void _watchSubscriptions(String uid) {
    _subsDueSub = SubscriptionService.I.upcomingPayments(daysAhead: 7).listen((subs) async {
      final gymSubs = subs.where((s) => s.category.toLowerCase().contains('gym')).toList();
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('gym')
          .doc('root')
          .collection('config')
          .doc('alerts');
      if (gymSubs.isEmpty) {
        await ref.set({'subscriptionDueSoon': false, 'subscriptionDueAt': null}, SetOptions(merge: true));
        return;
      }
      final next = gymSubs.first;
      await ref.set(
        {
          'subscriptionDueSoon': true,
          'subscriptionDueAt': Timestamp.fromDate(next.nextDue),
          'subscriptionTitle': next.title,
        },
        SetOptions(merge: true),
      );
    });
  }

  void _watchRecurringFinance(String uid) {
    _financeRecurringSub = _db
        .collection('finance_transactions')
        .where('userId', isEqualTo: uid)
        .where('recurrence', isNotEqualTo: null)
        .snapshots()
        .listen((snap) {
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
    final hash = sha1.convert(utf8.encode(hashRaw)).toString();

    final foodSvc = FoodFirestoreService(uid);
    final dayRef = _db
        .collection('users')
        .doc(uid)
        .collection('food')
        .doc('root')
        .collection('intake')
        .doc(todayId);

    final snap = await dayRef.get();
    final data = snap.data() ?? {};
    final syncMeta = Map<String, dynamic>.from(data['syncMeta'] ?? const {});
    if (syncMeta['gymHash'] == hash) return;

    final targets = Map<String, dynamic>.from(data['targets'] ?? const {});
    final global = await foodSvc.streamGlobalTargets().first;

    double baseKcal = _n(targets['baseKcal']) ?? _n(targets['kcal']) ?? (global['kcal'] ?? 2000);
    double baseProtein = _n(targets['baseProtein']) ?? _n(targets['protein']) ?? (global['protein'] ?? 120);

    final extraKcal = (totalMinutes * 8) + (totalVolume * 0.1);
    final extraProtein = (totalMinutes * 0.25).clamp(10, 60);

    final newTargets = {
      'kcal': baseKcal + extraKcal,
      'protein': baseProtein + extraProtein,
      'baseKcal': baseKcal,
      'baseProtein': baseProtein,
    };

    await dayRef.set(
      {
        'targets': {...targets, ...newTargets},
        'syncMeta': {
          ...syncMeta,
          'gymHash': hash,
          'gymSyncedAt': FieldValue.serverTimestamp(),
          'gymWorkoutsCount': sessions.length,
        },
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _mirrorStudyIntoTasks(
    String uid,
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    for (final change in snap.docChanges) {
      final raw = change.doc.data();
      if (raw == null) continue;
      final data = Map<String, dynamic>.from(raw);
      final linkedTaskId = (data['syncedTaskId'] ?? '').toString();
      if (linkedTaskId.isEmpty) continue;
      final hash = _studyHash(data);
      final meta = _metaFrom(data);
      if (_shouldSkip(meta, _actorStudy, hash)) continue;

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

      await ref.set(patch, SetOptions(merge: true));
      await change.doc.reference.set({
        'syncedTaskId': linkedTaskId,
        ..._metaPatch(_actorStudy, hash),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _mirrorTasksIntoStudy(
    String uid,
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    for (final change in snap.docChanges) {
      final raw = change.doc.data();
      if (raw == null) continue;
      final data = Map<String, dynamic>.from(raw);
      final linkedStudyId = (data['syncedStudyTaskId'] ?? '').toString();
      if (linkedStudyId.isEmpty) continue;
      final hash = _taskHash(data);
      final meta = _metaFrom(data);
      if (_shouldSkip(meta, _actorTasks, hash)) continue;

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

      await ref.set(patch, SetOptions(merge: true));
      await change.doc.reference.set({
        ..._metaPatch(_actorTasks, hash),
      }, SetOptions(merge: true));
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
      await plannedDoc.set({
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
      });
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
      await calRef.set({
        'title': data['title'] ?? 'Pago recurrente',
        'type': 'finance',
        'priority': 'normal',
        'start': Timestamp.fromDate(next),
        'allDay': true,
        'notes': data['category'],
      });
    }
  }

  ({String start, String end}) _todayIsoRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
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

  String _studyHash(Map<String, dynamic> m) {
    final due = m['due']?.toString() ?? '';
    final raw = '${m['title']}|${m['notes']}|${m['status']}|${m['priority']}|$due';
    return sha1.convert(utf8.encode(raw)).toString();
  }

  String _taskHash(Map<String, dynamic> m) {
    final due = m['dueDate'];
    String dueStr = '';
    if (due is Timestamp) dueStr = due.toDate().toIso8601String();
    final raw = '${m['title']}|${m['description']}|${m['completed']}|${m['priority']}|$dueStr';
    return sha1.convert(utf8.encode(raw)).toString();
  }

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