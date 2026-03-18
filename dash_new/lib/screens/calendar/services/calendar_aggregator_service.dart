import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_dashboard_personal/core/constants/core_routes.dart';
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

  String _dayId(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Stream<List<CalendarEvent>> combined(DateTime from, DateTime to) {
    return combinedItems(from, to).map(
      (items) => items.map((item) => item.toEvent()).toList(growable: false),
    );
  }

  Stream<List<CalendarItem>> combinedItems(DateTime from, DateTime to) {
    return _withUser<List<CalendarItem>>((uid) {
      final prefs$ = CalendarService.I.watchPrefs();

      return prefs$.asyncExpand((prefs) {
        final enabled = prefs.enabled;

        final manual$ = CalendarService.I.watchRange(from, to).map((events) {
          final filtered = events
              .where((e) => enabled.contains(e.type))
              .map(_plannerEventToItem)
              .toList(growable: false);
          return filtered;
        });

        final tasks$ =
            enabled.contains(CalendarType.task)
                ? _safeTasks(uid, from, to)
                : Stream<List<CalendarItem>>.value(const []);

        final studyTasks$ =
            enabled.contains(CalendarType.study)
                ? _safeStudyTasks(uid, from, to)
                : Stream<List<CalendarItem>>.value(const []);

        final studySessions$ =
            enabled.contains(CalendarType.study)
                ? _safeStudySessions(uid, from, to)
                : Stream<List<CalendarItem>>.value(const []);

        final gym$ =
            enabled.contains(CalendarType.gym)
                ? _safeGym(uid, from, to)
                : Stream<List<CalendarItem>>.value(const []);

        final food$ =
            enabled.contains(CalendarType.food)
                ? _safeFood(uid, from, to)
                : Stream<List<CalendarItem>>.value(const []);

        final financeTx$ =
            enabled.contains(CalendarType.finance)
                ? _safeFinanceTransactions(uid, from, to)
                : Stream<List<CalendarItem>>.value(const []);

        final financeSubs$ =
            enabled.contains(CalendarType.finance)
                ? _safeFinanceSubscriptions(uid, from, to)
                : Stream<List<CalendarItem>>.value(const []);

        final habits$ =
            enabled.contains(CalendarType.other)
                ? _safeHabits(uid, from, to)
                : Stream<List<CalendarItem>>.value(const []);

        final ctrl = StreamController<List<CalendarItem>>.broadcast();
        final latest = <int, List<CalendarItem>>{
          0: const [],
          1: const [],
          2: const [],
          3: const [],
          4: const [],
          5: const [],
          6: const [],
          7: const [],
          8: const [],
        };
        late final List<StreamSubscription> subs;

        void emit() {
          final all = <CalendarItem>[
            ...latest[0]!,
            ...latest[1]!,
            ...latest[2]!,
            ...latest[3]!,
            ...latest[4]!,
            ...latest[5]!,
            ...latest[6]!,
            ...latest[7]!,
            ...latest[8]!,
          ];

          final filtered =
              prefs.highOnly
                  ? all
                      .where((e) => e.priority == CalendarPriority.high)
                      .toList()
                  : all;

          final deduped = _dedupeItems(filtered);
          deduped.sort((a, b) {
            final byStart = a.startAt.compareTo(b.startAt);
            if (byStart != 0) return byStart;
            final byAllDay =
                (a.isAllDay == b.isAllDay) ? 0 : (a.isAllDay ? -1 : 1);
            if (byAllDay != 0) return byAllDay;
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          });

          if (!ctrl.isClosed) ctrl.add(deduped);
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
          studyTasks$.listen((v) {
            latest[2] = v;
            emit();
          }),
          studySessions$.listen((v) {
            latest[3] = v;
            emit();
          }),
          gym$.listen((v) {
            latest[4] = v;
            emit();
          }),
          food$.listen((v) {
            latest[5] = v;
            emit();
          }),
          financeTx$.listen((v) {
            latest[6] = v;
            emit();
          }),
          financeSubs$.listen((v) {
            latest[7] = v;
            emit();
          }),
          habits$.listen((v) {
            latest[8] = v;
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

  CalendarItem _plannerEventToItem(CalendarEvent event) {
    return CalendarItem.fromEvent(
      event,
      sourceModule: CalendarSourceModule.planner,
      deepLink: CalendarDeepLink(
        routeName: '/calendar',
        arguments: {'eventId': event.id},
      ),
      editPolicy: CalendarItemEditPolicy.planner,
      displayColorKey: _displayColorKey(event.type, event.priority),
    );
  }

  String _displayColorKey(CalendarType type, CalendarPriority priority) {
    if (priority == CalendarPriority.high) return 'warning';
    switch (type) {
      case CalendarType.task:
        return 'primary';
      case CalendarType.study:
        return 'secondary';
      case CalendarType.gym:
        return 'success';
      case CalendarType.finance:
        return 'warning';
      case CalendarType.food:
        return 'tertiary';
      case CalendarType.other:
        return 'surfaceVariant';
    }
  }

  CalendarItem _buildItem({
    required String id,
    required CalendarSourceModule sourceModule,
    required String title,
    required DateTime startAt,
    required CalendarType type,
    required CalendarDeepLink deepLink,
    String? description,
    DateTime? endAt,
    bool isAllDay = false,
    CalendarPriority priority = CalendarPriority.normal,
    bool? completed,
    String? relatedActionId,
    String? relatedTxId,
    String? dedupeKey,
    String? displayColorKey,
  }) {
    return CalendarItem(
      id: id,
      sourceModule: sourceModule,
      title: title,
      description: description,
      startAt: startAt,
      endAt: endAt,
      isAllDay: isAllDay,
      deepLink: deepLink,
      editPolicy: CalendarItemEditPolicy.readOnly,
      type: type,
      priority: priority,
      completed: completed,
      relatedActionId: relatedActionId,
      relatedTxId: relatedTxId,
      dedupeKey: dedupeKey,
      displayColorKey: displayColorKey ?? _displayColorKey(type, priority),
    );
  }

  Stream<List<CalendarItem>> _safeTasks(
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
        return s.docs
            .map((d) {
              final m = d.data();
              if (m['isCalendarVisible'] == false) return null;
              final due = _dateFromPayload(m['dueDate']);
              if (due == null) return null;
              return _buildItem(
                id: d.id,
                sourceModule: CalendarSourceModule.task,
                title: (m['title'] ?? 'Tarea') as String,
                description: (m['description'] ?? m['notes']) as String?,
                startAt: due,
                isAllDay: true,
                type: CalendarType.task,
                priority: _mapPriority(m['priority']),
                completed: m['completed'] as bool?,
                deepLink: CalendarDeepLink(
                  routeName: CoreRoutes.tasks,
                  arguments: {'highlightId': d.id},
                ),
              );
            })
            .whereType<CalendarItem>()
            .toList(growable: false);
      });
    } catch (_) {
      yield const <CalendarItem>[];
    }
  }

  Stream<List<CalendarItem>> _safeStudyTasks(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('study')
          .doc('root')
          .collection('tasks');
      final qs =
          col
              .where(
                'due',
                isGreaterThanOrEqualTo: _day0(from).toIso8601String(),
              )
              .where('due', isLessThanOrEqualTo: _dayEnd(to).toIso8601String())
              .snapshots();
      yield* qs.map((s) {
        return s.docs
            .map((d) {
              final m = d.data();
              final due = _dateFromPayload(m['due']);
              if (due == null) return null;
              final status = (m['status'] ?? 'todo').toString().toLowerCase();
              return _buildItem(
                id: d.id,
                sourceModule: CalendarSourceModule.study,
                title: (m['title'] ?? 'Estudio') as String,
                description: m['notes'] as String?,
                startAt: due,
                isAllDay: true,
                type: CalendarType.study,
                priority: _mapPriority(m['priority']),
                completed: status == 'done',
                deepLink: CalendarDeepLink(
                  routeName: CoreRoutes.studyDashboard,
                  arguments: {'taskId': d.id},
                ),
              );
            })
            .whereType<CalendarItem>()
            .toList(growable: false);
      });
    } catch (_) {
      yield const <CalendarItem>[];
    }
  }

  Stream<List<CalendarItem>> _safeStudySessions(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('study')
          .doc('root')
          .collection('sessions');
      final qs =
          col
              .where(
                'date',
                isGreaterThanOrEqualTo: _day0(from).toIso8601String(),
              )
              .where('date', isLessThanOrEqualTo: _dayEnd(to).toIso8601String())
              .snapshots();
      yield* qs.map((s) {
        return s.docs
            .map((d) {
              final m = d.data();
              final start = _dateFromPayload(m['date']);
              if (start == null) return null;
              final minutes = (m['minutes'] as num?)?.toInt() ?? 45;
              final courseName =
                  (m['courseName'] ?? 'Sesión de estudio').toString();
              return _buildItem(
                id: 'study-session-${d.id}',
                sourceModule: CalendarSourceModule.study,
                title: courseName,
                description: m['notes'] as String?,
                startAt: start,
                endAt: start.add(Duration(minutes: minutes)),
                isAllDay: false,
                type: CalendarType.study,
                priority: CalendarPriority.normal,
                deepLink: CalendarDeepLink(
                  routeName: CoreRoutes.studyDashboard,
                  arguments: {'sessionId': d.id},
                ),
              );
            })
            .whereType<CalendarItem>()
            .toList(growable: false);
      });
    } catch (_) {
      yield const <CalendarItem>[];
    }
  }

  Stream<List<CalendarItem>> _safeGym(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('gym')
          .doc('root')
          .collection('sessions');
      final qs =
          col
              .where(
                'date',
                isGreaterThanOrEqualTo: _day0(from).toIso8601String(),
              )
              .where('date', isLessThanOrEqualTo: _dayEnd(to).toIso8601String())
              .snapshots();
      yield* qs.map((s) {
        return s.docs
            .map((d) {
              final m = d.data();
              final start = _dateFromPayload(m['date']);
              if (start == null) return null;
              final minutes = (m['durationMin'] as num?)?.toInt() ?? 60;
              final title = (m['routineName'] ?? 'Entrenamiento').toString();
              final done = m['done'] == true;
              return _buildItem(
                id: d.id,
                sourceModule: CalendarSourceModule.gym,
                title: title,
                description: m['notes'] as String?,
                startAt: start,
                endAt: start.add(Duration(minutes: minutes)),
                isAllDay: false,
                type: CalendarType.gym,
                priority: done ? CalendarPriority.low : CalendarPriority.normal,
                deepLink: CalendarDeepLink(
                  routeName: CoreRoutes.gymDashboard,
                  arguments: {'sessionId': d.id},
                ),
              );
            })
            .whereType<CalendarItem>()
            .toList(growable: false);
      });
    } catch (_) {
      yield const <CalendarItem>[];
    }
  }

  Stream<List<CalendarItem>> _safeFood(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final fromId = _dayId(_day0(from));
      final toId = _dayId(_day0(to));
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('food')
          .doc('root')
          .collection('intake')
          .orderBy(FieldPath.documentId)
          .startAt([fromId])
          .endAt([toId]);

      yield* col.snapshots().map((s) {
        return s.docs
            .map((d) {
              final date = _dateFromPayload(d.id);
              if (date == null) return null;
              final m = d.data();
              final entries = (m['entries'] as List?) ?? const [];
              if (entries.isEmpty) return null;
              final totals = Map<String, dynamic>.from(m['totals'] ?? const {});
              final kcal = (totals['kcal'] as num?)?.toDouble() ?? 0;
              final note = <String>[
                '${entries.length} items',
                if (kcal > 0) '${kcal.toStringAsFixed(0)} kcal',
              ].join(' • ');
              return _buildItem(
                id: d.id,
                sourceModule: CalendarSourceModule.food,
                title: 'Registro de comida',
                description: note,
                startAt: DateTime(date.year, date.month, date.day),
                isAllDay: true,
                type: CalendarType.food,
                priority: CalendarPriority.low,
                deepLink: CalendarDeepLink(
                  routeName: CoreRoutes.foodDashboard,
                  arguments: {'dayId': d.id},
                ),
              );
            })
            .whereType<CalendarItem>()
            .toList(growable: false);
      });
    } catch (_) {
      yield const <CalendarItem>[];
    }
  }

  Stream<List<CalendarItem>> _safeFinanceTransactions(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final col = _db
          .collection('finance_transactions')
          .where('userId', isEqualTo: uid)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_day0(from)),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_dayEnd(to)));
      yield* col.snapshots().map((s) {
        return s.docs
            .map((d) {
              final m = d.data();
              if (m['sourceRecurringId'] != null) return null;
              final planned =
                  (m['planned'] == true) ||
                  (m['isBill'] == true) ||
                  (m['dueDate'] != null);
              if (!planned) return null;

              final date =
                  _dateFromPayload(m['dueDate']) ?? _dateFromPayload(m['date']);
              if (date == null) return null;

              final type = (m['type'] ?? 'expense').toString();
              final category = (m['category'] ?? '').toString();
              final amount = (m['amount'] as num?)?.toDouble() ?? 0;
              final title = (m['title'] ?? '').toString().trim();
              final label =
                  title.isEmpty
                      ? (type == 'income'
                          ? 'Ingreso planificado'
                          : 'Gasto planificado')
                      : title;

              final note = <String>[
                if (category.isNotEmpty) category,
                if (amount != 0) amount.toStringAsFixed(2),
              ].join(' • ');

              return _buildItem(
                id: d.id,
                sourceModule: CalendarSourceModule.finance,
                title: label,
                description: note.isEmpty ? null : note,
                startAt: DateTime(date.year, date.month, date.day),
                isAllDay: true,
                type: CalendarType.finance,
                priority: CalendarPriority.normal,
                relatedTxId: (m['relatedTxId'] ?? d.id).toString(),
                dedupeKey: m['dedupeKey']?.toString(),
                deepLink: CalendarDeepLink(
                  routeName: CoreRoutes.financeTransactions,
                  arguments: {'txId': d.id},
                ),
              );
            })
            .whereType<CalendarItem>()
            .toList(growable: false);
      });
    } catch (_) {
      yield const <CalendarItem>[];
    }
  }

  Stream<List<CalendarItem>> _safeFinanceSubscriptions(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final col = _db
          .collection('finance_subscriptions')
          .where('userId', isEqualTo: uid)
          .where('active', isEqualTo: true)
          .where(
            'nextDue',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_day0(from)),
          )
          .where(
            'nextDue',
            isLessThanOrEqualTo: Timestamp.fromDate(_dayEnd(to)),
          )
          .orderBy('nextDue');

      yield* col.snapshots().map((s) {
        return s.docs
            .map((d) {
              final m = d.data();
              final nextDue =
                  _dateFromPayload(m['nextDue']) ??
                  _dateFromPayload(m['nextPaymentDate']);
              if (nextDue == null) return null;
              final title =
                  (m['title'] ?? m['name'] ?? 'Suscripción').toString();
              final amount = (m['amount'] as num?)?.toDouble() ?? 0;
              final daysLeft =
                  _day0(nextDue).difference(_day0(DateTime.now())).inDays;
              final prio =
                  daysLeft <= 2
                      ? CalendarPriority.high
                      : CalendarPriority.normal;
              return _buildItem(
                id: 'sub-${d.id}',
                sourceModule: CalendarSourceModule.finance,
                title: title,
                description: amount == 0 ? null : amount.toStringAsFixed(2),
                startAt: DateTime(nextDue.year, nextDue.month, nextDue.day),
                isAllDay: true,
                type: CalendarType.finance,
                priority: prio,
                dedupeKey: 'sub-${d.id}-${_dayId(nextDue)}',
                deepLink: CalendarDeepLink(
                  routeName: '/finance/subscriptions',
                  arguments: {'subId': d.id},
                ),
              );
            })
            .whereType<CalendarItem>()
            .toList(growable: false);
      });
    } catch (_) {
      yield const <CalendarItem>[];
    }
  }

  Stream<List<CalendarItem>> _safeHabits(
    String uid,
    DateTime from,
    DateTime to,
  ) async* {
    try {
      final fromId = _dayId(_day0(from));
      final toId = _dayId(_day0(to));
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('habits')
          .where('isActive', isEqualTo: true)
          .limit(200);
      yield* col.snapshots().map((s) {
        final items = <CalendarItem>[];
        for (final d in s.docs) {
          final m = d.data();
          final name = (m['name'] ?? 'Hábito').toString();
          final completedDates =
              (m['completedDates'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
          for (final dayId in completedDates) {
            if (dayId.compareTo(fromId) < 0 || dayId.compareTo(toId) > 0) {
              continue;
            }
            final day = _dateFromPayload(dayId);
            if (day == null) continue;
            items.add(
              _buildItem(
                id: '${d.id}-$dayId',
                sourceModule: CalendarSourceModule.habit,
                title: name,
                description: 'Completado',
                startAt: DateTime(day.year, day.month, day.day),
                isAllDay: true,
                type: CalendarType.other,
                priority: CalendarPriority.low,
                deepLink: const CalendarDeepLink(routeName: '/habits'),
              ),
            );
          }
        }
        return items;
      });
    } catch (_) {
      yield const <CalendarItem>[];
    }
  }

  List<CalendarItem> _dedupeItems(List<CalendarItem> items) {
    final byIdentity = <String, CalendarItem>{};
    for (final item in items) {
      final identity = '${item.sourceModule.name}:${item.id}';
      final existing = byIdentity[identity];
      byIdentity[identity] =
          existing == null ? item : _preferItem(existing, item);
    }

    final byCross = <String, CalendarItem>{};
    final passthrough = <CalendarItem>[];

    for (final item in byIdentity.values) {
      final cross = _crossDedupeKey(item);
      if (cross == null) {
        passthrough.add(item);
        continue;
      }
      final existing = byCross[cross];
      byCross[cross] = existing == null ? item : _preferItem(existing, item);
    }

    return <CalendarItem>[...byCross.values, ...passthrough];
  }

  String? _crossDedupeKey(CalendarItem item) {
    if ((item.dedupeKey ?? '').trim().isNotEmpty) {
      return 'dedupe:${item.dedupeKey}';
    }
    if ((item.relatedTxId ?? '').trim().isNotEmpty) {
      return 'tx:${item.relatedTxId}';
    }
    if (item.type == CalendarType.finance) {
      final t = item.title.trim().toLowerCase();
      final n = (item.description ?? '').trim().toLowerCase();
      return 'fin:${_dayId(item.startAt)}:$t:$n';
    }
    return null;
  }

  CalendarItem _preferItem(CalendarItem a, CalendarItem b) {
    int weight(CalendarItem item) {
      var w = 0;
      if (item.sourceModule == CalendarSourceModule.planner) w -= 100;
      if (item.editPolicy.editable) w -= 20;
      switch (item.priority) {
        case CalendarPriority.high:
          w -= 3;
          break;
        case CalendarPriority.normal:
          w -= 2;
          break;
        case CalendarPriority.low:
          w -= 1;
          break;
      }
      return w;
    }

    return weight(b) < weight(a) ? b : a;
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
        _dateFromPayload(
          payload['start'] ?? payload['date'] ?? payload['dayId'],
        ) ??
        DateTime.now();
    DateTime? end = _dateFromPayload(payload['end']);
    final allDay = payload['allDay'] == true;
    end ??= allDay ? null : start.add(const Duration(hours: 1));

    final calType = _mapType(payload['type'] ?? payload['module']);
    final existing =
        await _calendarCol(
          uid,
        ).where('relatedActionId', isEqualTo: actionId).limit(1).get();
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
      case 'medium':
      case 'normal':
      default:
        return CalendarPriority.normal;
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
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
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
        (days[dayKey] as List?)?.map(
              (e) => Map<String, dynamic>.from(e as Map),
            ) ??
            const [],
      );
      final refId = (payload['recipeId'] ?? payload['foodId'] ?? '').toString();
      final slot = (payload['slot'] ?? 'dinner').toString();
      final already = current.any(
        (e) =>
            (e['relatedActionId']?.toString() == actionId) ||
            (e['refId']?.toString() == refId && e['slot']?.toString() == slot),
      );
      if (already) return;
      current.add({
        'slot': slot,
        'type': (payload['type'] ?? 'recipe').toString(),
        'refId': refId,
        'servings': (payload['servings'] as num?)?.toDouble() ?? 1,
        'relatedActionId': actionId,
      });
      days[dayKey] = current;
      tx.set(doc, {
        'scope': data['scope'] ?? 'weekly',
        'days': days,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
        (payload['duration'] as num?)?.toInt() ??
        (payload['minutes'] as num?)?.toInt() ??
        60;
    final dup =
        await col.where('relatedActionId', isEqualTo: actionId).limit(1).get();
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
        (payload['minutes'] as num?)?.toInt() ??
        (payload['duration'] as num?)?.toInt() ??
        45;
    final dup =
        await col.where('relatedActionId', isEqualTo: actionId).limit(1).get();
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
    final existing =
        await _db
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
