import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';

class StudyHistoryScreen extends StatelessWidget {
  const StudyHistoryScreen({
    super.key,
    required this.svc,
    this.embedded = false,
  });

  final StudyFirestoreService svc;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<Course>>(
      stream: svc.streamCourses(includeArchived: true),
      builder: (context, coursesSnap) {
        return StreamBuilder<List<StudySession>>(
          stream: svc.streamSessions(limit: 100),
          builder: (context, sessionsSnap) {
            return StreamBuilder<List<StudyTask>>(
              stream: svc.streamTasks(),
              builder: (context, tasksSnap) {
                if (coursesSnap.hasError ||
                    sessionsSnap.hasError ||
                    tasksSnap.hasError) {
                  return PageContainer(
                    child: FocusEmptyState(
                      icon: Icons.error_outline_rounded,
                      message: 'No se pudo cargar el historial',
                      subtitle:
                          '${coursesSnap.error ?? sessionsSnap.error ?? tasksSnap.error}',
                    ),
                  );
                }

                if (!coursesSnap.hasData ||
                    !sessionsSnap.hasData ||
                    !tasksSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final courseNames = {
                  for (final course in coursesSnap.data ?? const <Course>[])
                    course.id: course.name,
                };
                final events = _buildEvents(
                  sessionsSnap.data ?? const <StudySession>[],
                  tasksSnap.data ?? const <StudyTask>[],
                  courseNames,
                );

                return _HistoryContent(events: events);
              },
            );
          },
        );
      },
    );

    if (embedded) return content;

    return AppShell(
      title: 'Estudio',
      subtitle: 'Historial académico.',
      activeRoute: AppRoutes.studyDashboard,
      child: content,
    );
  }

  static List<_HistoryEvent> _buildEvents(
    List<StudySession> sessions,
    List<StudyTask> tasks,
    Map<String, String> courseNames,
  ) {
    final doneTasks =
        tasks.where((task) => task.status == TaskStatus.done).toList();
    final events = <_HistoryEvent>[
      ...sessions.map(
        (session) => _HistoryEvent(
          date: session.date,
          title: 'Sesion ${_methodLabel(session.method)}',
          subtitle:
              '${courseNames[session.courseId] ?? 'Curso eliminado'} · ${session.minutes} min',
          icon: Icons.timer_outlined,
        ),
      ),
      ...doneTasks
          .where((task) => task.due != null)
          .map(
            (task) => _HistoryEvent(
              date: task.due!,
              title: 'Tarea completada',
              subtitle:
                  '${task.title} · ${courseNames[task.courseId] ?? 'Curso eliminado'}',
              icon: Icons.task_alt_rounded,
            ),
          ),
    ];

    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.events});

  final List<_HistoryEvent> events;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FocusCard(
              child: FocusSectionHeader(
                title: 'Historial',
                subtitle: 'Sesiones guardadas y tareas completadas',
                icon: Icons.history_rounded,
                trailing: FocusBadge(
                  label: '${events.length} eventos',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              const FocusCard(
                child: FocusEmptyState(
                  icon: Icons.history_rounded,
                  message: 'Aun no hay actividad registrada',
                  subtitle:
                      'Las sesiones guardadas y tareas completadas aparecerán aquí.',
                ),
              )
            else
              FocusCard(
                child: Column(
                  children: [
                    for (final event in events) ...[
                      _HistoryTile(event: event),
                      if (event != events.last)
                        Divider(
                          height: 16,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.event});

  final _HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(event.icon, color: scheme.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                event.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FocusBadge(label: _formatDate(event.date), color: scheme.secondary),
      ],
    );
  }
}

class _HistoryEvent {
  const _HistoryEvent({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final IconData icon;
}

String _methodLabel(StudyMethod method) {
  switch (method) {
    case StudyMethod.pomodoro:
      return 'Pomodoro';
    case StudyMethod.flowtime:
      return 'Flowtime';
    case StudyMethod.timeboxing:
      return 'Timeboxing';
    case StudyMethod.simple:
      return 'Simple';
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $hh:$mm';
}
