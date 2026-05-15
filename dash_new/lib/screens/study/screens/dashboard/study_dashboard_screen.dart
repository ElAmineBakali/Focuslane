import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/study/screens/courses/courses_list_screen.dart';
import 'package:focuslane/screens/study/screens/diary/study_diary_screen.dart';
import 'package:focuslane/screens/study/screens/schedule/schedule_screen.dart';
import 'package:focuslane/screens/study/screens/tasks/study_tasks_screen.dart';
import 'package:focuslane/screens/study/screens/timer/study_timer_screen.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';

class StudyDashboardScreen extends StatelessWidget {
  const StudyDashboardScreen({
    super.key,
    required this.svc,
    this.embedded = false,
    this.onOpenSection,
  });

  final StudyFirestoreService svc;
  final bool embedded;
  final ValueChanged<int>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<StudySession>>(
      stream: svc.streamSessions(limit: 100),
      builder: (context, sessionsSnap) {
        return StreamBuilder<List<StudyTask>>(
          stream: svc.streamTasks(),
          builder: (context, tasksSnap) {
            return StreamBuilder<List<Course>>(
              stream: svc.streamCourses(),
              builder: (context, coursesSnap) {
                return StreamBuilder<List<StudyClassBlock>>(
                  stream: svc.streamSchedule(),
                  builder: (context, scheduleSnap) {
                    if (sessionsSnap.hasError ||
                        tasksSnap.hasError ||
                        coursesSnap.hasError ||
                        scheduleSnap.hasError) {
                      return PageContainer(
                        child: FocusEmptyState(
                          icon: Icons.error_outline_rounded,
                          message: 'No se pudo cargar Estudio',
                          subtitle:
                              'Revisa la conexion o vuelve a intentarlo en unos segundos.',
                          actionLabel: 'Reintentar',
                          onAction: () {},
                        ),
                      );
                    }

                    if (!sessionsSnap.hasData ||
                        !tasksSnap.hasData ||
                        !coursesSnap.hasData ||
                        !scheduleSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return _StudyDashboardContent(
                      svc: svc,
                      sessions: sessionsSnap.data ?? const <StudySession>[],
                      tasks: tasksSnap.data ?? const <StudyTask>[],
                      courses: coursesSnap.data ?? const <Course>[],
                      schedule: scheduleSnap.data ?? const <StudyClassBlock>[],
                      onOpenSection: onOpenSection,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );

    if (embedded) return content;

    return AppShell(
      title: 'Estudio',
      subtitle: 'Panel académico y actividad reciente.',
      activeRoute: AppRoutes.studyDashboard,
      child: content,
    );
  }
}

class _StudyDashboardContent extends StatelessWidget {
  const _StudyDashboardContent({
    required this.svc,
    required this.sessions,
    required this.tasks,
    required this.courses,
    required this.schedule,
    required this.onOpenSection,
  });

  final StudyFirestoreService svc;
  final List<StudySession> sessions;
  final List<StudyTask> tasks;
  final List<Course> courses;
  final List<StudyClassBlock> schedule;
  final ValueChanged<int>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final weekSessions = sessions
        .where((session) => session.date.isAfter(weekStart))
        .toList(growable: false);
    final totalMinutes = weekSessions.fold<int>(
      0,
      (sum, session) => sum + session.minutes,
    );
    final pendingTasks =
        tasks.where((task) => task.status != TaskStatus.done).toList();
    final doneTasks = tasks.where((task) => task.status == TaskStatus.done);
    final upcomingTasks =
        pendingTasks.where((task) => task.due != null).toList()
          ..sort((a, b) => a.due!.compareTo(b.due!));
    final courseById = {for (final course in courses) course.id: course};

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StudyHero(
              visibleCourses: courses.length,
              pendingTasks: pendingTasks.length,
              onStartTimer: () => _openTimer(context),
              onOpenCourses:
                  () => _openSectionOrPush(
                    context,
                    sectionIndex: 2,
                    builder: (_) => CoursesListScreen(svc: svc),
                  ),
            ),
            const SizedBox(height: 20),
            ResponsiveGrid(
              minItemWidth: 210,
              spacing: 16,
              children: [
                FocusStatCard(
                  title: 'Horas esta semana',
                  value: (totalMinutes / 60).toStringAsFixed(1),
                  subtitle: '${weekSessions.length} sesiones',
                  icon: Icons.timer_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  onTap:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 1,
                        builder: (_) => StudyDiaryScreen(svc: svc),
                      ),
                ),
                FocusStatCard(
                  title: 'Tareas pendientes',
                  value: '${pendingTasks.length}',
                  subtitle: '${doneTasks.length} completadas',
                  icon: Icons.checklist_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 4,
                        builder: (_) => StudyTasksScreen(svc: svc),
                      ),
                ),
                FocusStatCard(
                  title: 'Cursos activos',
                  value: '${courses.length}',
                  subtitle: 'materias visibles',
                  icon: Icons.school_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 2,
                        builder: (_) => CoursesListScreen(svc: svc),
                      ),
                ),
                FocusStatCard(
                  title: 'Clases programadas',
                  value: '${schedule.length}',
                  subtitle: 'bloques semanales',
                  icon: Icons.calendar_month_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  onTap:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 3,
                        builder: (_) => ScheduleScreen(svc: svc),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 920;
                final left = _RecentStudySessions(
                  sessions: sessions,
                  courseById: courseById,
                  onOpenDiary:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 1,
                        builder: (_) => StudyDiaryScreen(svc: svc),
                      ),
                );
                final right = _UpcomingStudyWork(
                  tasks: upcomingTasks,
                  courseById: courseById,
                  onOpenTasks:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 4,
                        builder: (_) => StudyTasksScreen(svc: svc),
                      ),
                );

                if (!wide) {
                  return Column(
                    children: [left, const SizedBox(height: 16), right],
                  );
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: 16),
                      Expanded(child: right),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _WeeklySchedulePreview(
              schedule: schedule,
              courseById: courseById,
              onOpenSchedule:
                  () => _openSectionOrPush(
                    context,
                    sectionIndex: 3,
                    builder: (_) => ScheduleScreen(svc: svc),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTimer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudyTimerScreen(svc: svc)),
    );
  }

  void _openSectionOrPush(
    BuildContext context, {
    required int sectionIndex,
    required WidgetBuilder builder,
  }) {
    final handler = onOpenSection;
    if (handler != null) {
      handler(sectionIndex);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }
}

class _StudyHero extends StatelessWidget {
  const _StudyHero({
    required this.visibleCourses,
    required this.pendingTasks,
    required this.onStartTimer,
    required this.onOpenCourses,
  });

  final int visibleCourses;
  final int pendingTasks;
  final VoidCallback onStartTimer;
  final VoidCallback onOpenCourses;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      backgroundColor: scheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estudio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Coordina cursos, sesiones, tareas y calificaciones sin perder el hilo de tu semana.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(
                    label: '$visibleCourses cursos',
                    color: scheme.primary,
                  ),
                  FocusBadge(
                    label: '$pendingTasks pendientes',
                    color: scheme.secondary,
                  ),
                  FocusBadge(
                    label: DateFormat('d MMM', 'es_ES').format(DateTime.now()),
                    color: scheme.tertiary,
                  ),
                ],
              ),
            ],
          );
          final actions = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FocusPrimaryButton(
                label: 'Iniciar sesión',
                icon: Icons.play_arrow_rounded,
                onPressed: onStartTimer,
              ),
              FocusSecondaryButton(
                label: 'Ver cursos',
                icon: Icons.school_rounded,
                onPressed: onOpenCourses,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 18), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _RecentStudySessions extends StatelessWidget {
  const _RecentStudySessions({
    required this.sessions,
    required this.courseById,
    required this.onOpenDiary,
  });

  final List<StudySession> sessions;
  final Map<String, Course> courseById;
  final VoidCallback onOpenDiary;

  @override
  Widget build(BuildContext context) {
    final recent = sessions.take(5).toList(growable: false);

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Últimas sesiones',
            subtitle: 'Actividad reciente con nombres de curso',
            icon: Icons.history_rounded,
            trailing: TextButton(
              onPressed: onOpenDiary,
              child: const Text('Abrir'),
            ),
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            const _InlineEmpty(
              icon: Icons.timer_outlined,
              title: 'Sin sesiones registradas',
              subtitle: 'Inicia un temporizador para crear historial real.',
            )
          else
            Column(
              children: [
                for (final session in recent)
                  _StudyPreviewRow(
                    icon: Icons.timer_outlined,
                    title: _methodLabel(session.method),
                    subtitle:
                        '${courseById[session.courseId]?.name ?? 'Curso eliminado'} · ${DateFormat('d MMM, HH:mm', 'es_ES').format(session.date)}',
                    trailing: '${session.minutes} min',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UpcomingStudyWork extends StatelessWidget {
  const _UpcomingStudyWork({
    required this.tasks,
    required this.courseById,
    required this.onOpenTasks,
  });

  final List<StudyTask> tasks;
  final Map<String, Course> courseById;
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final pending = tasks.take(5).toList(growable: false);

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Próximas tareas',
            subtitle: 'Entregas y exámenes pendientes',
            icon: Icons.checklist_rounded,
            trailing: TextButton(
              onPressed: onOpenTasks,
              child: const Text('Abrir'),
            ),
          ),
          const SizedBox(height: 16),
          if (pending.isEmpty)
            const _InlineEmpty(
              icon: Icons.task_alt_rounded,
              title: 'Sin tareas con fecha',
              subtitle:
                  'Las nuevas tareas aparecerán aquí al asignarles fecha.',
            )
          else
            Column(
              children: [
                for (final task in pending)
                  _StudyPreviewRow(
                    icon:
                        task.type == StudyItemType.exam
                            ? Icons.school_rounded
                            : Icons.assignment_rounded,
                    title: task.title,
                    subtitle:
                        '${courseById[task.courseId]?.name ?? 'Curso eliminado'} · ${DateFormat('d MMM', 'es_ES').format(task.due!)}',
                    trailing: _priorityLabel(task.priority),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WeeklySchedulePreview extends StatelessWidget {
  const _WeeklySchedulePreview({
    required this.schedule,
    required this.courseById,
    required this.onOpenSchedule,
  });

  final List<StudyClassBlock> schedule;
  final Map<String, Course> courseById;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Plan semanal',
            subtitle: 'Clases y bloques académicos',
            icon: Icons.calendar_month_rounded,
            trailing: TextButton(
              onPressed: onOpenSchedule,
              child: const Text('Ver horario'),
            ),
          ),
          const SizedBox(height: 16),
          if (schedule.isEmpty)
            const _InlineEmpty(
              icon: Icons.event_available_rounded,
              title: 'Aun no tienes clases programadas',
              subtitle:
                  'Anade bloques en el planificador para organizar la semana.',
            )
          else
            ResponsiveGrid(
              minItemWidth: 260,
              spacing: 12,
              children: [
                for (final block in schedule.take(4))
                  _ScheduleBlockPreview(
                    block: block,
                    course: courseById[block.courseId],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScheduleBlockPreview extends StatelessWidget {
  const _ScheduleBlockPreview({required this.block, required this.course});

  final StudyClassBlock block;
  final Course? course;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = course?.color ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.school_rounded, color: tone, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course?.name ?? 'Curso eliminado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_dayLabels(block.daysOfWeek)} · ${block.start.format(context)}-${block.end.format(context)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyPreviewRow extends StatelessWidget {
  const _StudyPreviewRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FocusBadge(label: trailing, color: scheme.secondary),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

String _priorityLabel(Priority priority) {
  switch (priority) {
    case Priority.high:
      return 'Alta';
    case Priority.normal:
      return 'Media';
    case Priority.low:
      return 'Baja';
  }
}

String _dayLabels(List<int> days) {
  const labels = {
    1: 'Lun',
    2: 'Mar',
    3: 'Mie',
    4: 'Jue',
    5: 'Vie',
    6: 'Sab',
    7: 'Dom',
  };
  return days.map((day) => labels[day] ?? '$day').join(', ');
}
