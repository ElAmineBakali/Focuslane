import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../study/services/study_firestore_service.dart';
import '../../study/models/study_models.dart';

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

  String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return Scaffold(
      appBar: AppBar(title: Text('Asistencia: ${c.name}')),
      body: StreamBuilder<Map<String, String>>(
        stream: widget.svc.streamAttendanceMap(c.id),
        builder: (context, snap) {
          final map = snap.data ?? const <String, String>{};

          // Stats
          final attended = map.values.where((v) => v == 'A').length;
          final absent = map.values.where((v) => v == 'X').length;
          final noClass = map.values.where((v) => v == '-').length;
          final totalCount = attended + absent; // '-' no cuenta

          // 🔧 Aseguramos double en ambos branches
          final double pct =
              totalCount == 0 ? 0.0 : (attended * 100.0 / totalCount);

          // 🔧 También aseguramos double aquí
          final double target = c.attendanceRequired ?? 0.0;
          final bool meets = pct >= target;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _StatsHeader(
                attended: attended,
                absent: absent,
                noClass: noClass,
                percent: pct, // ahora es double
                target: target, // double
                meets: meets,
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar(
                    firstDay: DateTime(_focusedDay.year - 1, 1, 1),
                    lastDay: DateTime(_focusedDay.year + 1, 12, 31),
                    focusedDay: _focusedDay,
                    onPageChanged: (d) => setState(() => _focusedDay = d),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      titleTextStyle: Theme.of(
                        context,
                      ).textTheme.titleMedium!.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        shape: BoxShape.circle,
                      ),
                      outsideDaysVisible: false,
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, _) {
                        final k = _key(day);
                        final st = map[k]; // 'A', 'X', '-'  o null
                        Color bg;
                        Widget child;

                        if (st == 'A') {
                          bg = Colors.green.withValues(alpha: .8);
                          child = const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          );
                        } else if (st == 'X') {
                          bg = Colors.redAccent.withValues(alpha: .85);
                          child = const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white,
                          );
                        } else if (st == '-') {
                          bg = Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: .50);
                          child = Text(
                            '${day.day}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          );
                        } else {
                          bg = Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: .25);
                          child = Text(
                            '${day.day}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          );
                        }

                        return GestureDetector(
                          onTap: () => _editDay(day, st),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: child,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Hoy Asistió'),
                      onPressed:
                          () => widget.svc.setAttendance(
                            courseId: c.id,
                            day: DateTime.now(),
                            status: 'A',
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Hoy No asistió'),
                      onPressed:
                          () => widget.svc.setAttendance(
                            courseId: c.id,
                            day: DateTime.now(),
                            status: 'X',
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                icon: const Icon(Icons.remove),
                label: const Text('Hoy Sin clase'),
                onPressed:
                    () => widget.svc.setAttendance(
                      courseId: c.id,
                      day: DateTime.now(),
                      status: '-',
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editDay(DateTime day, String? current) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.check, color: Colors.green),
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
                  leading: const Icon(Icons.close, color: Colors.redAccent),
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
                  leading: const Icon(Icons.remove),
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
                if (current != null) const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final int attended;
  final int absent;
  final int noClass;
  final double percent; // 0..100
  final double target; // 0..100
  final bool meets;
  const _StatsHeader({
    required this.attended,
    required this.absent,
    required this.noClass,
    required this.percent,
    required this.target,
    required this.meets,
  });

  @override
  Widget build(BuildContext context) {
    final double p = percent.isNaN ? 0.0 : percent;
    // 🔧 clamp devuelve num; lo llevamos a double para el LinearProgressIndicator
    final double progress = (p.clamp(0.0, 100.0)) / 100.0;
    final color = meets ? Colors.green : Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _chip(context, Icons.check, ' ', attended, Colors.green),
                const SizedBox(width: 8),
                _chip(context, Icons.close, ' ', absent, Colors.redAccent),
                const SizedBox(width: 8),
                _chip(context, Icons.remove, ' ', noClass, Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistencia actual',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        color: color,
                        backgroundColor:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.toStringAsFixed(1)}% (objetivo ${target.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            Text(
              '$value',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
