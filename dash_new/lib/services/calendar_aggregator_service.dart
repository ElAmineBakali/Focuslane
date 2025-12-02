import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../models/calendar_models.dart';
import 'calendar_service.dart';

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
