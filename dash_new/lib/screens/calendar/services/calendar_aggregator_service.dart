import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:mi_dashboard_personal/core/models/core_entity_ref.dart';
import 'package:mi_dashboard_personal/core/models/core_recommendation.dart';
import 'package:mi_dashboard_personal/screens/calendar/models/calendar_models.dart';
import 'package:mi_dashboard_personal/screens/calendar/services/calendar_service.dart';
import 'package:mi_dashboard_personal/screens/finance/models/transaction_model.dart';
import 'package:mi_dashboard_personal/screens/finance/services/transaction_service.dart';

class CalendarAggregatorService {
  CalendarAggregatorService._();
  static final CalendarAggregatorService I = CalendarAggregatorService._();

  final _db = FirebaseFirestore.instance;

  DateTime _day0(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _dayEnd(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  Stream<List<CalendarEvent>> combined(DateTime from, DateTime to) {
    return _withUser<List<CalendarEvent>>((uid) {
      final prefs$ = CalendarService.I.watchPrefs();

      return prefs$.asyncExpand((prefs) {
        final manual$ = CalendarService.I.watchRange(from, to).map((list) {
          final enabled = prefs.enabled;
          final filtered = list.where((e) => enabled.contains(e.type)).toList();
          return prefs.highOnly
              ? filtered
                  .where((e) => e.priority == CalendarPriority.high)
                  .toList()
              : filtered;
        });

        final enabled = prefs.enabled;
        final tasks$ =
            enabled.contains(CalendarType.task)
                ? _safeTasks(uid, from, to)
                : Stream<List<CalendarEvent>>.value(const []);
        final study$ =
            enabled.contains(CalendarType.study)
                ? _safeStudy(uid, from, to)
                : Stream<List<CalendarEvent>>.value(const []);
        final gym$ =
            enabled.contains(CalendarType.gym)
                ? _safeGym(uid, from, to)
                : Stream<List<CalendarEvent>>.value(const []);
        final food$ =
            enabled.contains(CalendarType.food)
                ? _safeFood(uid, from, to)
                : Stream<List<CalendarEvent>>.value(const []);
        final finance$ =
            enabled.contains(CalendarType.finance)
                ? _safeFinance(uid, from, to)
                : Stream<List<CalendarEvent>>.value(const []);

        final ctrl = StreamController<List<CalendarEvent>>.broadcast();
        final latest = <int, List<CalendarEvent>>{
          0: const [],
          1: const [],
          2: const [],
          3: const [],
          4: const [],
          5: const [],
        };
        late final List<StreamSubscription> subs;

        void emit() {
          final all = <CalendarEvent>[
            ...latest[0]!,
            ...latest[1]!,
            ...latest[2]!,
            ...latest[3]!,
            ...latest[4]!,
            ...latest[5]!,
          ];
          if (prefs.highOnly) {
            all.removeWhere((e) => e.priority != CalendarPriority.high);
          }
          all.sort((a, b) => a.start.compareTo(b.start));
          if (!ctrl.isClosed) ctrl.add(all);
        }

        subs = [
          manual$.listen((v) {
            latest[0] = v;
            emit();
          }),
          tasks$.listen((v) {
            latest[1] = v;
            emit();
          }),
          study$.listen((v) {
            latest[2] = v;
            emit();
          }),
          gym$.listen((v) {
            latest[3] = v;
            emit();
          }),
          food$.listen((v) {
            latest[4] = v;
            emit();
          }),
          finance$.listen((v) {
            latest[5] = v;
            emit();
          }),
        ];

        ctrl.onCancel = () async {
          for (final s in subs) {
            await s.cancel();
          }
        };

        emit();
        return ctrl.stream;
      });
    });
  }

  Future<String?> addEventFromCoreAction(
    CoreAction action, {
    required String actionId,
    CoreEntityRef? ref,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    final payload = Map<String, dynamic>.from(action.payload);
    final start =
      _dateFromPayload(payload['start'] ?? payload['date'] ?? payload['dayId']) ??
        DateTime.now();
    DateTime? end = _dateFromPayload(payload['end']);
    final allDay = payload['allDay'] == true;
    end ??= allDay ? null : start.add(const Duration(hours: 1));

    final calType = _mapType(payload['type'] ?? payload['module']);
    final existing = await _calendarCol(uid)
        .where('relatedActionId', isEqualTo: actionId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final event = CalendarEvent(
      id: '',
      title: (payload['title'] ?? ref?.title ?? 'Evento').toString(),
      type: calType,
      priority: CalendarPriority.normal,
      start: start,
      end: allDay ? null : end,
      allDay: allDay,
      notes: (payload['note'] ?? ref?.subtitle)?.toString(),
      relatedActionId: actionId,
    );
    final eventId = await CalendarService.I.addEvent(event);

    switch (calType) {
      case CalendarType.food:
        await _persistFoodPlan(uid, start, payload, actionId);
        break;
      case CalendarType.gym:
        await _persistGymPlan(uid, start, payload, actionId);
        break;
      case CalendarType.study:
        await _persistStudyPlan(uid, start, payload, actionId);
        break;
      case CalendarType.finance:
        await _persistFinancePlan(uid, start, payload, actionId);
        break;
      case CalendarType.task:
      case CalendarType.other:
        break;
    }

    return eventId;
  }

  CollectionReference<Map<String, dynamic>> _calendarCol(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('planner')
      .doc('data')
      .collection('calendar');

  CalendarPriority _mapPriority(Object? raw) {
    final v = (raw ?? '').toString().toLowerCase();
    switch (v) {
      case 'alta':
      case 'high':
        return CalendarPriority.high;
      case 'baja':
      case 'low':
        return CalendarPriority.low;
      case 'media':
      case 'normal':
      default:
        return CalendarPriority.normal;
    }
  }

  Stream<List<CalendarEvent>> _safeTasks(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final col = _db.collection('users').doc(uid).collection('tasks');
      final qs =
          col
              .where(
                'dueDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(_day0(from)),
              )
              .where(
                'dueDate',
                isLessThanOrEqualTo: Timestamp.fromDate(_dayEnd(to)),
              )
              .snapshots();
      yield* qs.map((s) {
        return s.docs.map((d) {
          final m = d.data();
          final due = (m['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();
          final prio = _mapPriority(m['priority']);
          final bool? completed = (m['completed'] as bool?);
          return CalendarEvent(
            id: 'task-${d.id}',
            title: (m['title'] ?? 'Task') as String,
            type: CalendarType.task,
            priority: prio,
            start: due,
            allDay: true,
            notes: (m['notes'] ?? m['description']) as String?,
            completed: completed,
          );
        }).toList();
      });
    } catch (_) {
      yield const <CalendarEvent>[];
    }
  }

  Stream<List<CalendarEvent>> _safeStudy(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('study')
          .doc('data')
          .collection('sessions');
      final qs =
          col
              .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
              .where('start', isLessThanOrEqualTo: Timestamp.fromDate(to))
              .snapshots();
      yield* qs.map((s) {
        return s.docs.map((d) {
          final m = d.data();
          final start = (m['start'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dur = (m['durationMin'] as num?)?.toInt() ?? 60;
          final name = (m['courseName'] ?? 'Estudio') as String;
          return CalendarEvent(
            id: 'study-${d.id}',
            title: 'Estudio: $name',
            type: CalendarType.study,
            priority: CalendarPriority.normal,
            start: start,
            end: start.add(Duration(minutes: dur)),
            notes: m['note'] as String?,
          );
        }).toList();
      });
    } catch (_) {
      yield const <CalendarEvent>[];
    }
  }

  Stream<List<CalendarEvent>> _safeGym(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('gym')
          .doc('data')
          .collection('sessions');
      final qs =
          col
              .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
              .where('start', isLessThanOrEqualTo: Timestamp.fromDate(to))
              .snapshots();
      yield* qs.map((s) {
        return s.docs.map((d) {
          final m = d.data();
          final start = (m['start'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dur = (m['durationMin'] as num?)?.toInt() ?? 75;
          final rn = (m['routineName'] ?? 'Gym') as String;
          final done = (m['done'] ?? false) as bool;
          return CalendarEvent(
            id: 'gym-${d.id}',
            title: done ? 'Gym (done): $rn' : 'Gym: $rn',
            type: CalendarType.gym,
            priority: done ? CalendarPriority.low : CalendarPriority.normal,
            start: start,
            end: start.add(Duration(minutes: dur)),
            notes: m['notes'] as String?,
          );
        }).toList();
      });
    } catch (_) {
      yield const <CalendarEvent>[];
    }
  }

  Stream<List<CalendarEvent>> _safeFood(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final weeksCol = _db
          .collection('users')
          .doc(uid)
          .collection('food')
          .doc('data')
          .collection('weeks');
      final ids = {_weekId(from), _weekId(to)}.toList();

      final ctrl = StreamController<List<CalendarEvent>>.broadcast();
      final latest = <String, Map<String, dynamic>>{};
      final subs = <StreamSubscription>[];

      List<CalendarEvent> build() {
        final list = <CalendarEvent>[];
        for (final entry in latest.entries) {
          final weekId = entry.key;
          final m = entry.value;
          final days = (m['days'] as Map?)?.cast<String, dynamic>() ?? {};
          days.forEach((k, v) {
            final date = _dateOfWeekKey(k, weekId);
            if (date == null) return;
            final entries = (v as List?) ?? const [];
            if (entries.isEmpty) return;
            list.add(
              CalendarEvent(
                id: 'food-$weekId-$k',
                title: 'Comidas planificadas ($k)',
                type: CalendarType.food,
                priority: CalendarPriority.low,
                start: date,
                allDay: true,
                notes: 'Items: ${entries.length}',
              ),
            );
          });
        }
        list.sort((a, b) => a.start.compareTo(b.start));
        return list;
      }

      for (final id in ids) {
        final sub = weeksCol.doc(id).snapshots().listen((snap) {
          if (snap.exists) {
            latest[id] = snap.data() ?? {};
          } else {
            latest.remove(id);
          }
          if (!ctrl.isClosed) ctrl.add(build());
        });
        subs.add(sub);
      }

      ctrl.onCancel = () async {
        for (final s in subs) {
          await s.cancel();
        }
      };

      ctrl.add(build());
      yield* ctrl.stream;
    } catch (_) {
      yield const <CalendarEvent>[];
    }
  }

  Stream<List<CalendarEvent>> _safeFinance(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('finance')
          .doc('data')
          .collection('transactions');
      final qs =
          col
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(_day0(from)),
              )
              .where(
                'date',
                isLessThanOrEqualTo: Timestamp.fromDate(_dayEnd(to)),
              )
              .snapshots();
      yield* qs.map((s) {
        return s.docs
            .map((d) {
              final m = d.data();
              final planned = (m['planned'] ?? false) as bool;
              final isBill = (m['isBill'] ?? false) as bool;
              final dueTs = (m['dueDate'] as Timestamp?);
              if (m['sourceRecurringId'] != null) return null;
              final date =
                  (dueTs ?? (m['date'] as Timestamp?))?.toDate() ??
                  DateTime.now();
              if (!(planned || isBill || dueTs != null)) return null;
              final type = (m['type'] ?? 'expense').toString();
              final cat = (m['category'] ?? '') as String;
              final amount = (m['amount'] as num?)?.toDouble() ?? 0.0;
              return CalendarEvent(
                id: 'fin-${d.id}',
                title:
                    (type == 'income')
                        ? 'Ingreso planificado'
                        : (isBill ? 'Pago (factura)' : 'Gasto planificado'),
                type: CalendarType.finance,
                priority: CalendarPriority.normal,
                start: date,
                allDay: true,
                notes: [
                  cat,
                  if (amount != 0) amount.toStringAsFixed(2),
                ].where((e) => e.isNotEmpty).join(' • '),
              );
            })
            .whereType<CalendarEvent>()
            .toList();
      });
    } catch (_) {
      yield const <CalendarEvent>[];
    }
  }

  String _weekId(DateTime d) {
    final first = DateTime(d.year, 1, 1);
    final days = d.difference(first).inDays + first.weekday;
    final wk = (days / 7).ceil();
    return 'week-${d.year}-W${wk.toString().padLeft(2, '0')}';
  }

  CalendarType _mapType(Object? raw) {
    if (raw is CalendarType) return raw;
    final v = (raw ?? '').toString();
    return CalendarType.values.firstWhere(
      (t) => t.name == v,
      orElse: () => CalendarType.other,
    );
  }

  DateTime? _dateFromPayload(Object? raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  String _dayKey(DateTime date) {
    const keys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return keys[(date.weekday - 1).clamp(0, 6)];
  }

  Future<void> _persistFoodPlan(
    String uid,
    DateTime date,
    Map<String, dynamic> payload,
    String actionId,
  ) async {
    final weekId = _weekId(date);
    final dayKey = _dayKey(date);
    final doc = _db.collection('weekPlanners').doc(weekId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final data = Map<String, dynamic>.from(snap.data() ?? {});
      final days = Map<String, dynamic>.from(data['days'] ?? {});
      final current = List<Map<String, dynamic>>.from(
        (days[dayKey] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? const [],
      );
      final refId = (payload['recipeId'] ?? payload['foodId'] ?? '').toString();
      final slot = (payload['slot'] ?? 'dinner').toString();
      final already = current.any((e) =>
          (e['relatedActionId']?.toString() == actionId) ||
          (e['refId']?.toString() == refId && e['slot']?.toString() == slot));
      if (already) return;
      current.add({
        'slot': slot,
        'type': (payload['type'] ?? 'recipe').toString(),
        'refId': refId,
        'servings': (payload['servings'] as num?)?.toDouble() ?? 1,
        'relatedActionId': actionId,
      });
      days[dayKey] = current;
      tx.set(
        doc,
        {
          'scope': data['scope'] ?? 'weekly',
          'days': days,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> _persistGymPlan(
    String uid,
    DateTime start,
    Map<String, dynamic> payload,
    String actionId,
  ) async {
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root')
        .collection('sessions');
    final dayName = _dayKey(start);
    final duration =
        (payload['duration'] as num?)?.toInt() ?? (payload['minutes'] as num?)?.toInt() ?? 60;
    final dup = await col.where('relatedActionId', isEqualTo: actionId).limit(1).get();
    if (dup.docs.isNotEmpty) return;
    await col.add({
      'routineId': payload['routineId'] ?? 'core-plan',
      'routineName': payload['title'] ?? 'Entrenamiento',
      'dayId': dayName,
      'dayName': dayName,
      'date': start.toIso8601String(),
      'durationMin': duration,
      'volumeKg': (payload['volume'] as num?)?.toDouble() ?? 0,
      'notes': payload['note'],
      'prList': const <String>[],
      'exercises': const <Map<String, dynamic>>[],
      'relatedActionId': actionId,
    });
  }

  Future<void> _persistStudyPlan(
    String uid,
    DateTime start,
    Map<String, dynamic> payload,
    String actionId,
  ) async {
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('sessions');
    final minutes =
        (payload['minutes'] as num?)?.toInt() ?? (payload['duration'] as num?)?.toInt() ?? 45;
    final dup = await col.where('relatedActionId', isEqualTo: actionId).limit(1).get();
    if (dup.docs.isNotEmpty) return;
    await col.add({
      'courseId': payload['courseId'] ?? '',
      if (payload['taskId'] != null) 'taskId': payload['taskId'],
      'method': (payload['method'] ?? 'pomodoro').toString(),
      'minutes': minutes,
      'configSnapshot': {'origin': 'coreAction'},
      if (payload['note'] != null) 'notes': payload['note'].toString(),
      'date': start.toIso8601String(),
      'relatedActionId': actionId,
    });
  }

  Future<void> _persistFinancePlan(
    String uid,
    DateTime date,
    Map<String, dynamic> payload,
    String actionId,
  ) async {
    final existing = await _db
        .collection('finance_transactions')
        .where('userId', isEqualTo: uid)
        .where('relatedTxId', isEqualTo: actionId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    final typeRaw = (payload['type'] ?? 'expense').toString();
    final tx = FinanceTransaction(
      id: '',
      userId: uid,
      date: date,
      type: typeRaw == 'income' ? TxType.income : TxType.expense,
      title: payload['title']?.toString() ?? 'Movimiento planificado',
      amount: (payload['amount'] as num?)?.toDouble() ?? 0,
      category: (payload['category'] ?? 'plan').toString(),
      subCategory: null,
      accountId: null,
      notes: payload['note']?.toString(),
      tags: const [],
      originalCurrency: null,
      fxRate: null,
      recurrence: null,
      envelopeId: null,
      relatedTxId: actionId,
    );
    await TransactionService.I.create(tx);
  }

  DateTime? _dateOfWeekKey(String key, String weekId) {
    try {
      final parts = weekId.split('-');
      final year = int.parse(parts[1]);
      final w = int.parse(parts[2].substring(1));
      final first = DateTime(year, 1, 1);
      final firstMonday = first.add(Duration(days: (8 - first.weekday) % 7));
      final monday = firstMonday.add(Duration(days: (w - 1) * 7));
      final idx =
          const {
            'Mon': 0,
            'Tue': 1,
            'Wed': 2,
            'Thu': 3,
            'Fri': 4,
            'Sat': 5,
            'Sun': 6,
          }[key] ??
          0;
      return monday.add(Duration(days: idx));
    } catch (_) {
      return null;
    }
  }

  Stream<R> _withUser<R>(Stream<R> Function(String uid) build) {
    return FirebaseAuth.instance
        .authStateChanges()
        .map((u) => u?.uid)
        .distinct()
        .asyncExpand((uid) {
          if (uid == null) return Stream<R>.empty();
          return build(uid);
        });
  }
}

