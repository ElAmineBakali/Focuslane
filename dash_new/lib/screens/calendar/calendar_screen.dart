import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/core/services/notification_service.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:mi_dashboard_personal/screens/calendar/services/calendar_aggregator_service.dart';

import 'models/calendar_models.dart';
import '../../screens/calendar/services/calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  static const route = '/calendar';

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _svc = CalendarService.I;
  final _agg = CalendarAggregatorService.I;

  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  Map<DateTime, List<CalendarEvent>> _eventsByDay = {};
  PlannerPrefs? _prefs;

  String? _currentTimetableId;

  StreamSubscription<List<CalendarEvent>>? _monthSub;
  StreamSubscription<PlannerPrefs>? _prefsSub;

  static const double _monthRowHeight = 40;
  static const double _eventsHeaderH = 44;
  static const double _eventsBodyH = 150;
  static const double _eventsCardH = _eventsHeaderH + _eventsBodyH;

  @override
  void initState() {
    super.initState();
    _watchMonth(_focused);
    _prefsSub = _svc.watchPrefs().listen((p) {
      setState(() {
        _prefs = p;
        if (p.defaultTimetableId != null &&
            p.defaultTimetableId != _currentTimetableId) {
          _currentTimetableId = p.defaultTimetableId;
        }
      });
      _watchMonth(_focused);
    });
  }

  @override
  void dispose() {
    _monthSub?.cancel();
    _prefsSub?.cancel();
    super.dispose();
  }

  void _watchMonth(DateTime anchor) {
    final from = DateTime(anchor.year, anchor.month, 1);
    final to = DateTime(anchor.year, anchor.month + 1, 0, 23, 59, 59);
    _monthSub?.cancel();
    _monthSub = _agg.combined(from, to).listen((list) {
      final by = <DateTime, List<CalendarEvent>>{};
      for (final e in list) {
        final k = DateTime(e.start.year, e.start.month, e.start.day);
        (by[k] ??= <CalendarEvent>[]).add(e);
      }
      if (mounted) setState(() => _eventsByDay = by);
    });
  }

  List<CalendarEvent> _eventsFor(DateTime d) {
    final k = DateTime(d.year, d.month, d.day);
    return List<CalendarEvent>.of(_eventsByDay[k] ?? const <CalendarEvent>[]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // Only the Month view is currently enabled; set length to 1
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calendario'),
          actions: [
            IconButton(
              tooltip: 'Hoy',
              icon: const Icon(Icons.today),
              onPressed:
                  () => setState(() {
                    _focused = DateTime.now();
                    _selected = DateTime.now();
                    _watchMonth(_focused);
                  }),
            ),
          ],
        ),
        body: SafeArea(
          bottom: true,
          child: TabBarView(
            children: [
              _buildMonth(),
              /* _buildWeek(),
              _buildDay(), */
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _editEvent(context, null, defaultDay: _selected),
          icon: const Icon(Icons.add),
          label: const Text('Evento'),
        ),
        bottomNavigationBar: const SizedBox(height: 50),
      ),
    );
  }

  Widget _buildMonth() {
    final s = Theme.of(context).colorScheme;
    final eventsToday = _eventsFor(_selected)
      ..sort((a, b) => a.start.compareTo(b.start));

    final now = DateTime.now();
    final todayYMD = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: TableCalendar<CalendarEvent>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate:
                (d) =>
                    d.year == _selected.year &&
                    d.month == _selected.month &&
                    d.day == _selected.day,
            onDaySelected:
                (sel, foc) => setState(() {
                  _selected = sel;
                  _focused = foc;
                }),
            onPageChanged: (f) {
              _focused = f;
              _watchMonth(f);
            },
            rowHeight: _monthRowHeight,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            eventLoader: _eventsFor,
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              todayDecoration: const BoxDecoration(),
              selectedDecoration: BoxDecoration(
                color: s.primary,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              todayBuilder: (ctx, day, _) {
                final cs = Theme.of(ctx).colorScheme;
                return _DayNumberRing(
                  day: day.day,
                  border: cs.primary,
                  textColor: cs.onSurface,
                );
              },
              selectedBuilder: (ctx, day, _) {
                final cs = Theme.of(ctx).colorScheme;
                return _DayNumberCell(
                  day: day.day,
                  bg: cs.primary,
                  fg: cs.onPrimary,
                );
              },
              defaultBuilder: (ctx, day, _) {
                final ymd = DateTime(day.year, day.month, day.day);
                final isPast = ymd.isBefore(todayYMD);
                if (!isPast) {
                  return Center(child: Text('${day.day}'));
                }
                final cs = Theme.of(ctx).colorScheme;
                return _DayNumberCell(
                  day: day.day,
                  bg: cs.surfaceContainerHighest.withOpacity(.45),
                  fg: cs.onSurface.withOpacity(.75),
                );
              },

              outsideBuilder: (ctx, day, _) {
                final ymd = DateTime(day.year, day.month, day.day);
                final cs = Theme.of(ctx).colorScheme;
                final isPast = ymd.isBefore(todayYMD);
                if (isPast) {
                  return _DayNumberCell(
                    day: day.day,
                    bg: cs.surfaceContainerHighest.withOpacity(.45),
                    fg: cs.onSurface.withOpacity(.75),
                  );
                } else {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: cs.onSurface.withOpacity(.7)),
                    ),
                  );
                }
              },
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                final high = events.any(
                  (e) => e.priority == CalendarPriority.high,
                );
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        events.length.clamp(1, 3),
                        (i) => Container(
                          width: high ? 7 : 5,
                          height: high ? 7 : 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: high ? Colors.redAccent : s.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: _eventsCardH,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                SizedBox(
                  height: _eventsHeaderH,
                  child: Row(
                    children: const [
                      SizedBox(width: 12),
                      Text(
                        'Eventos de hoy',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: _eventsBodyH,
                  child: _DayEventList(
                    events: eventsToday,
                    onEdit: (e) => _editEvent(context, e),
                    onDelete: (id) => _svc.deleteEvent(id),
                    scrollable: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _buildFilterChips() {
    final p = _prefs;
    if (p == null) return const SizedBox.shrink();
    final enabled = p.enabled;

    FilterChip chip(CalendarType t, String label, IconData icon) => FilterChip(
      label: Text(label),
      selected: enabled.contains(t),
      avatar: Icon(icon, size: 18),
      onSelected: (v) {
        final set = {...enabled};
        if (v) {
          set.add(t);
        } else {
          set.remove(t);
        }
        _svc.savePrefs(
          PlannerPrefs(
            enabled: set,
            highOnly: p.highOnly,
            defaultTimetableId: p.defaultTimetableId,
          ),
        );
      },
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          chip(CalendarType.task, 'Tareas', Icons.checklist),
          const SizedBox(width: 6),
          chip(CalendarType.study, 'Estudio', Icons.school),
          const SizedBox(width: 6),
          chip(CalendarType.gym, 'Gym', Icons.fitness_center),
          const SizedBox(width: 6),
          chip(CalendarType.finance, 'Pagos', Icons.payments),
          const SizedBox(width: 6),
          chip(CalendarType.food, 'Comidas', Icons.restaurant),
          const SizedBox(width: 6),
          chip(CalendarType.other, 'Otros', Icons.event_note),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('Solo prioridad alta'),
            selected: p.highOnly,
            avatar: const Icon(Icons.priority_high),
            onSelected: (v) {
              _svc.savePrefs(
                PlannerPrefs(
                  enabled: enabled,
                  highOnly: v,
                  defaultTimetableId: p.defaultTimetableId,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editEvent(
    BuildContext context,
    CalendarEvent? e, {
    DateTime? defaultDay,
  }) async {
    final title = TextEditingController(text: e?.title ?? '');
    CalendarType type = e?.type ?? CalendarType.other;
    CalendarPriority prio = e?.priority ?? CalendarPriority.normal;
    bool allDay = e?.allDay ?? false;
    final notes = TextEditingController(text: e?.notes ?? '');
    DateTime when = e?.start ?? (defaultDay ?? DateTime.now());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setS) {
              final bottom = MediaQuery.of(ctx).viewInsets.bottom;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              e == null ? 'Nuevo evento' : 'Editar evento',
                              style: Theme.of(ctx).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Cerrar',
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: title,
                          decoration: const InputDecoration(
                            labelText: 'TÃ­tulo del evento',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<CalendarType>(
                                initialValue: type,
                                items:
                                    CalendarType.values
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t.name),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) => setS(() => type = v ?? type),
                                decoration: const InputDecoration(
                                  labelText: 'Tipo',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<CalendarPriority>(
                                initialValue: prio,
                                items:
                                    CalendarPriority.values
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t.name),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) => setS(() => prio = v ?? prio),
                                decoration: const InputDecoration(
                                  labelText: 'Prioridad',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          value: allDay,
                          onChanged: (v) => setS(() => allDay = v),
                          title: const Text('Todo el dÃ­a'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event),
                          title: Text(_humanDateTime(when, allDay)),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: when,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) {
                              if (!allDay) {
                                final t = await showTimePicker(
                                  context: ctx,
                                  initialTime: TimeOfDay.fromDateTime(when),
                                );
                                setS(
                                  () =>
                                      when = DateTime(
                                        d.year,
                                        d.month,
                                        d.day,
                                        t?.hour ?? 9,
                                        t?.minute ?? 0,
                                      ),
                                );
                              } else {
                                setS(
                                  () => when = DateTime(d.year, d.month, d.day),
                                );
                              }
                            }
                          },
                        ),
                        TextField(
                          controller: notes,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notas / detalles',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (e != null)
                              TextButton(
                                style: TextButton.styleFrom(
                                  textStyle: const TextStyle(fontSize: 13),
                                  minimumSize: const Size(0, 40),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () async {
                                  await CalendarService.I.deleteEvent(e.id);
                                  await NotificationService.I.cancel(
                                    e.id.hashCode,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: const Text('Eliminar'),
                              ),
                            const Spacer(),
                            TextButton(
                              style: TextButton.styleFrom(
                                textStyle: const TextStyle(fontSize: 13),
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                textStyle: const TextStyle(fontSize: 13),
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () async {
                                final data = CalendarEvent(
                                  id: e?.id ?? '',
                                  title:
                                      title.text.trim().isEmpty
                                          ? 'Evento'
                                          : title.text.trim(),
                                  type: type,
                                  priority: prio,
                                  start: when,
                                  allDay: allDay,
                                  end: e?.end,
                                  notes:
                                      notes.text.trim().isNotEmpty
                                          ? notes.text.trim()
                                          : null,
                                );

                                if (e == null) {
                                  final newId = await CalendarService.I
                                      .addEvent(data);
                                  final notifId = (newId ?? data.id).hashCode;
                                  if (!allDay &&
                                      when.isAfter(
                                        DateTime.now().add(
                                          const Duration(seconds: 1),
                                        ),
                                      )) {
                                    await NotificationService.I.scheduleOnce(
                                      id: notifId,
                                      title: data.title,
                                      body: data.notes ?? 'Recordatorio',
                                      whenLocal: when,
                                      useExact: true,
                                      payload: 'OPEN_CALENDAR',
                                    );
                                    await NotificationService.I.debugStatus();
                                  }
                                } else {
                                  await CalendarService.I.updateEvent(data);
                                  final notifId = data.id.hashCode;
                                  await NotificationService.I.cancel(notifId);
                                  if (!allDay &&
                                      when.isAfter(
                                        DateTime.now().add(
                                          const Duration(seconds: 1),
                                        ),
                                      )) {
                                    await NotificationService.I.scheduleOnce(
                                      id: notifId,
                                      title: data.title,
                                      body: data.notes ?? 'Recordatorio',
                                      whenLocal: when,
                                      useExact: true,
                                      payload: 'OPEN_CALENDAR',
                                    );
                                    await NotificationService.I.debugStatus();
                                  }
                                }
                                _focused = DateTime(when.year, when.month, 15);
                                _selected = DateTime(
                                  when.year,
                                  when.month,
                                  when.day,
                                );
                                _watchMonth(_focused);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  String _humanDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _humanDateTime(DateTime d, bool allDay) {
    if (allDay) return '${_humanDate(d)} (todo el dÃ­a)';
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${_humanDate(d)} â€¢ $hh:$mm';
  }
}

class _DayNumberCell extends StatelessWidget {
  final int day;
  final Color? bg;
  final Color? fg;
  const _DayNumberCell({required this.day, this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    final child = Center(child: Text('$day', style: TextStyle(color: fg)));
    if (bg == null) return child;
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}

class _DayNumberRing extends StatelessWidget {
  final int day;
  final Color border;
  final Color? textColor;
  const _DayNumberRing({
    required this.day,
    required this.border,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 2),
        ),
        alignment: Alignment.center,
        child: Text('$day', style: TextStyle(color: textColor)),
      ),
    );
  }
}

class _DayEventList extends StatelessWidget {
  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent> onEdit;
  final ValueChanged<String> onDelete;
  final bool scrollable;

  const _DayEventList({
    required this.events,
    required this.onEdit,
    required this.onDelete,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No hay eventos para este dÃ­a'),
      );
    }
    final s = Theme.of(context).colorScheme;

    final list = ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: !scrollable,
      physics:
          scrollable
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = events[i];
        final icon = switch (e.type) {
          CalendarType.task => Icons.checklist,
          CalendarType.study => Icons.school,
          CalendarType.gym => Icons.fitness_center,
          CalendarType.finance => Icons.payments,
          CalendarType.food => Icons.restaurant,
          CalendarType.other => Icons.event_note,
        };
        final color =
            e.priority == CalendarPriority.high ? Colors.redAccent : s.primary;
        final timeLabel =
            e.allDay
                ? 'Todo el dÃ­a'
                : '${e.start.hour.toString().padLeft(2, '0')}:${e.start.minute.toString().padLeft(2, '0')}';

        final isCompleted =
            (e.type == CalendarType.task) && (e.completed == true);

        final baseTitle = TextStyle(
          decoration:
              isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          color: isCompleted ? s.onSurface.withOpacity(.65) : null,
        );
        final baseSub = TextStyle(
          color: isCompleted ? s.onSurfaceVariant.withOpacity(.7) : null,
        );
        final avatarBg = isCompleted ? s.surfaceContainerHighest : color;
        final avatarFg = isCompleted ? s.onSurfaceVariant : s.onPrimary;

        return ListTile(
          dense: false,
          leading: CircleAvatar(
            backgroundColor: avatarBg,
            child: Icon(icon, color: avatarFg),
          ),
          title: Text(e.title, style: baseTitle),
          subtitle: Text(
            [timeLabel, if ((e.notes ?? '').isNotEmpty) e.notes!].join(' â€¢ '),
            style: baseSub,
          ),
          onTap: () => onEdit(e),
          onLongPress: () => onDelete(e.id),
        );
      },
    );

    return list;
  }
}


