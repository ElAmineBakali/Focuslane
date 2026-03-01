import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../design/ui/components/focus_module_header.dart';

class IntegratedCalendarScreen extends StatefulWidget {
  final StudyFirestoreService svc;
  const IntegratedCalendarScreen({super.key, required this.svc});

  @override
  State<IntegratedCalendarScreen> createState() =>
      _IntegratedCalendarScreenState();
}

class _IntegratedCalendarScreenState extends State<IntegratedCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario acadÃ©mico'),
        leading: FocusModuleHeader.buildLeading(
          context,
          mode: FocusModuleLeadingMode.backToModuleDashboard,
          backRouteName: AppRoutes.studyDashboard,
        ),
        leadingWidth: 96,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: TableCalendar(
              firstDay: DateTime(_focusedDay.year - 1, 1, 1),
              lastDay: DateTime(_focusedDay.year + 1, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              onDaySelected:
                  (selected, focused) => setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  }),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
          Expanded(child: _DayEventsList(svc: svc, day: _selectedDay)),
        ],
      ),
    );
  }
}

class _DayEventsList extends StatelessWidget {
  final StudyFirestoreService svc;
  final DateTime day;
  const _DayEventsList({required this.svc, required this.day});

  @override
  Widget build(BuildContext context) {
    final key = DateTime(day.year, day.month, day.day);
    return StreamBuilder<List<StudyTask>>(
      stream: svc.streamTasks(),
      builder: (context, taskSnap) {
        final tasks =
            (taskSnap.data ?? const [])
                .where(
                  (t) =>
                      t.due != null &&
                      DateTime(t.due!.year, t.due!.month, t.due!.day) == key,
                )
                .toList();
        return StreamBuilder<List<StudySession>>(
          stream: svc.streamSessions(limit: 500),
          builder: (context, sessSnap) {
            final sessions =
                (sessSnap.data ?? const [])
                    .where(
                      (s) =>
                          DateTime(s.date.year, s.date.month, s.date.day) ==
                          key,
                    )
                    .toList();
            return StreamBuilder<List<StudyClassBlock>>(
              stream: svc.streamSchedule(),
              builder: (context, schedSnap) {
                final classes =
                    (schedSnap.data ?? const [])
                        .where((c) => c.daysOfWeek.contains(_weekday(key)))
                        .toList();
                final items = <Widget>[];
                if (tasks.isNotEmpty) {
                  items.add(_SectionHeader(title: 'Tareas/ExÃ¡menes'));
                  items.addAll(
                    tasks.map(
                      (t) => ListTile(
                        leading: Icon(
                          t.type == StudyItemType.exam
                              ? Icons.event_available
                              : Icons.task_alt,
                        ),
                        title: Text(t.title),
                        subtitle: Text(
                          'vence: ${t.due} â€¢ prio: ${t.priority.name} â€¢ estado: ${t.status.name}',
                        ),
                      ),
                    ),
                  );
                }
                if (classes.isNotEmpty) {
                  items.add(_SectionHeader(title: 'Clases'));
                  items.addAll(
                    classes.map(
                      (c) => ListTile(
                        leading: const Icon(Icons.class_),
                        title: Text('Curso: ${c.courseId}'),
                        subtitle: Text(
                          '${c.start.format(context)} - ${c.end.format(context)}${c.room != null ? ' â€¢ ${c.room}' : ''}',
                        ),
                      ),
                    ),
                  );
                }
                if (sessions.isNotEmpty) {
                  items.add(_SectionHeader(title: 'Sesiones de estudio'));
                  items.addAll(
                    sessions.map(
                      (s) => ListTile(
                        leading: const Icon(Icons.timer),
                        title: Text('Curso: ${s.courseId}'),
                        subtitle: Text('${s.method.name} â€¢ ${s.minutes} min'),
                      ),
                    ),
                  );
                }
                if (items.isEmpty) {
                  return const Center(child: Text('Sin eventos en este dÃ­a'));
                }
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: items,
                );
              },
            );
          },
        );
      },
    );
  }

  int _weekday(DateTime d) => d.weekday;
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider()),
        ],
      ),
    );
  }
}

