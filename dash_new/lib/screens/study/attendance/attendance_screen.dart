import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_dashboard_personal/theme/global_ui_theme.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../study/models/study_models.dart';
import '../../study/services/study_firestore_service.dart';

class AttendanceScreen extends StatefulWidget {
  final StudyFirestoreService svc;
  final Course course;
  const AttendanceScreen({super.key, required this.svc, required this.course});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late DateTime _focusedDay;
  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final cs = Theme.of(context).colorScheme;
    final gradient = LinearGradient(
      colors: [cs.primary.withOpacity(0.16), cs.surface],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar.large(
                backgroundColor: Colors.transparent,
                foregroundColor: cs.onSurface,
                flexibleSpace: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.secondary, cs.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                title: Text('Asistencia: ${c.name}'),
              ),
              SliverToBoxAdapter(
                child: StreamBuilder<Map<String, String>>(
                  stream: widget.svc.streamAttendanceMap(c.id),
                  builder: (context, snap) {
                    final map = snap.data ?? const <String, String>{};

                    final attended = map.values.where((v) => v == 'A').length;
                    final absent = map.values.where((v) => v == 'X').length;
                    final noClass = map.values.where((v) => v == '-').length;
                    final totalCount = attended + absent;
                    final double pct =
                        totalCount == 0 ? 0.0 : (attended * 100.0 / totalCount);

                    final double target = c.attendanceRequired ?? 0.0;
                    final bool meets = pct >= target;

                    final attendColor = cs.primary;
                    final absentColor = cs.error;
                    final freeColor = cs.tertiary;

                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatsHeader(
                            attended: attended,
                            absent: absent,
                            noClass: noClass,
                            percent: pct,
                            target: target,
                            meets: meets,
                            attendColor: attendColor,
                            absentColor: absentColor,
                            freeColor: freeColor,
                          ),

                          const SizedBox(height: AppSpacing.md),
                          _LegendRow(
                            attendColor: attendColor,
                            absentColor: absentColor,
                            freeColor: freeColor,
                          ),

                          const SizedBox(height: AppSpacing.lg),
                          _CalendarCard(
                            focusedDay: _focusedDay,
                            onFocusedChanged:
                                (d) => setState(() => _focusedDay = d),
                            map: map,
                            onEdit: _editDay,
                            attendColor: attendColor,
                            absentColor: absentColor,
                            freeColor: freeColor,
                          ),

                          const SizedBox(height: AppSpacing.lg),
                          _ActionButtons(
                            onAttend:
                                () => widget.svc.setAttendance(
                                  courseId: c.id,
                                  day: DateTime.now(),
                                  status: 'A',
                                ),
                            onAbsent:
                                () => widget.svc.setAttendance(
                                  courseId: c.id,
                                  day: DateTime.now(),
                                  status: 'X',
                                ),
                            onNoClass:
                                () => widget.svc.setAttendance(
                                  courseId: c.id,
                                  day: DateTime.now(),
                                  status: '-',
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editDay(DateTime day, String? current) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.check, color: cs.primary),
                    title: const Text('Asistió'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.svc.setAttendance(
                        courseId: widget.course.id,
                        day: day,
                        status: 'A',
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.close, color: cs.error),
                    title: const Text('No asistió'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.svc.setAttendance(
                        courseId: widget.course.id,
                        day: day,
                        status: 'X',
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.remove, color: cs.tertiary),
                    title: const Text('Sin clase'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.svc.setAttendance(
                        courseId: widget.course.id,
                        day: day,
                        status: '-',
                      );
                    },
                  ),
                  if (current != null) const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final int attended;
  final int absent;
  final int noClass;
  final double percent;
  final double target;
  final bool meets;
  final Color attendColor;
  final Color absentColor;
  final Color freeColor;
  const _StatsHeader({
    required this.attended,
    required this.absent,
    required this.noClass,
    required this.percent,
    required this.target,
    required this.meets,
    required this.attendColor,
    required this.absentColor,
    required this.freeColor,
  });

  @override
  Widget build(BuildContext context) {
    final double p = percent.isNaN ? 0.0 : percent;
    final double progress = (p.clamp(0.0, 100.0)) / 100.0;
    final color = meets ? attendColor : Theme.of(context).colorScheme.error;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _chip(context, Icons.check, 'Asistió', attended, attendColor),
              const SizedBox(width: AppSpacing.sm),
              _chip(context, Icons.close, 'Faltó', absent, absentColor),
              const SizedBox(width: AppSpacing.sm),
              _chip(context, Icons.remove, 'Sin clase', noClass, freeColor),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistencia actual',
                      style: AppTypography.label(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        color: color,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${p.toStringAsFixed(1)}% (objetivo ${target.toStringAsFixed(0)}%)',
                      style: AppTypography.caption(context, color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext ctx,
    IconData icon,
    String label,
    int value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            Text('$value', style: AppTypography.label(ctx, color: color)),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color attendColor;
  final Color absentColor;
  final Color freeColor;
  const _LegendRow({
    required this.attendColor,
    required this.absentColor,
    required this.freeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _legendChip(attendColor, 'Asistió'),
        _legendChip(absentColor, 'Faltó'),
        _legendChip(freeColor, 'Sin clase'),
      ],
    );
  }

  Widget _legendChip(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label),
      ],
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime focusedDay;
  final ValueChanged<DateTime> onFocusedChanged;
  final Map<String, String> map;
  final void Function(DateTime, String?) onEdit;
  final Color attendColor;
  final Color absentColor;
  final Color freeColor;

  const _CalendarCard({
    required this.focusedDay,
    required this.onFocusedChanged,
    required this.map,
    required this.onEdit,
    required this.attendColor,
    required this.absentColor,
    required this.freeColor,
  });

  String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: TableCalendar(
          firstDay: DateTime(focusedDay.year - 1, 1, 1),
          lastDay: DateTime(focusedDay.year + 1, 12, 31),
          focusedDay: focusedDay,
          onPageChanged: onFocusedChanged,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            titleTextStyle: AppTypography.label(context),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              border: Border.all(color: cs.primary),
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) {
              final k = _key(day);
              final st = map[k];
              Color bg;
              Color textColor = cs.onSurface;
              Widget child;

              if (st == 'A') {
                bg = attendColor.withOpacity(.85);
                textColor = cs.onPrimary;
                child = const Icon(
                  Icons.check,
                  size: 18,
                  color: Color(0xFFFFFFFF),
                );
              } else if (st == 'X') {
                bg = absentColor.withOpacity(.9);
                textColor = cs.onPrimary;
                child = const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFFFFFFFF),
                );
              } else if (st == '-') {
                bg = cs.surfaceContainerHighest.withOpacity(.5);
                child = Text(
                  '${day.day}',
                  style: AppTypography.label(context, color: textColor),
                );
              } else {
                bg = cs.surfaceContainerHighest.withOpacity(.25);
                child = Text(
                  '${day.day}',
                  style: AppTypography.label(context, color: textColor),
                );
              }

              return GestureDetector(
                onTap: () => onEdit(day, st),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onAttend;
  final VoidCallback onAbsent;
  final VoidCallback onNoClass;

  const _ActionButtons({
    required this.onAttend,
    required this.onAbsent,
    required this.onNoClass,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Hoy asistió'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                onPressed: onAttend,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.close),
                label: const Text('Hoy no asistió'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                onPressed: onAbsent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            icon: const Icon(Icons.remove),
            label: const Text('Hoy sin clase'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              foregroundColor: cs.onSurface,
            ),
            onPressed: onNoClass,
          ),
        ),
      ],
    );
  }
}
