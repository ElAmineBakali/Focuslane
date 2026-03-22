import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../study/services/study_firestore_service.dart';
import '../../study/models/study_models.dart';
import '../../study/courses/courses_list_screen.dart';
import '../../study/schedule/schedule_screen.dart';
import '../../study/tasks/study_tasks_screen.dart';
import '../../study/timer/study_timer_screen.dart';
import '../../study/diary/study_diary_screen.dart';
import '../../study/planner/study_planner_screen.dart';
import '../../study/lists/study_lists_screen.dart';
import '../../../design/ui/components/focus_card.dart';
import '../../../design/ui/components/focus_metric_card.dart';
import '../../../design/ui/components/focus_section_title.dart';
import '../../../design/ui/components/focus_empty_state.dart';
import '../../../design/ui/components/focus_list_tile_compact.dart';
import '../../../design/ui/tokens/focuslane_tokens.dart';
import '../../../design/ui/components/focus_module_header.dart';
import '../../../design/ui/components/responsive_kpi_grid.dart';

class StudyDashboardScreen extends StatelessWidget {
  final StudyFirestoreService svc;

  const StudyDashboardScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final dateLabel = DateFormat('d MMM', 'es').format(now);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Study',
        subtitle: 'Sesiones, hábitos y productividad',
        leadingMode: FocusModuleLeadingMode.exitModule,
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          FocusSectionTitle(
            title: 'Resumen del día',
            subtitle: 'Actualizado $dateLabel',
            action: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudyTimerScreen(svc: svc),
                  ),
                );
              },
              child: const Text('Iniciar sesión'),
            ),
          ),
          const SizedBox(height: FocuslaneTokens.spacing8),
          StreamBuilder<List<StudySession>>(
            stream: svc.streamSessions(limit: 100),
            builder: (context, sessionsSnap) {
              final sessions = sessionsSnap.data ?? const [];
              final weekSessions = sessions.where((s) => s.date.isAfter(start));
              final totalMinutes =
                  weekSessions.fold<int>(0, (a, b) => a + b.minutes);
              final totalHours = totalMinutes / 60.0;
              final totalSessions = weekSessions.length;

              return StreamBuilder<List<StudyTask>>(
                stream: svc.streamTasks(),
                builder: (context, tasksSnap) {
                  final tasks = tasksSnap.data ?? const [];
                  final pending = tasks.where((t) => t.status != TaskStatus.done);
                  final nextTask = pending.isNotEmpty ? pending.first : null;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 1200
                          ? 4
                          : constraints.maxWidth >= 600
                              ? 2
                              : 1;

                      final cards = [
                        FocusMetricCard(
                          icon: Icons.timer,
                          label: 'Horas estudiadas (semana)',
                          value: totalHours > 0
                              ? totalHours.toStringAsFixed(1)
                              : '–',
                          subtitle: 'Últimos 7 días',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudyTimerScreen(svc: svc),
                            ),
                          ),
                        ),
                        FocusMetricCard(
                          icon: Icons.check_circle,
                          label: 'Sesiones completadas',
                          value: totalSessions > 0
                              ? totalSessions.toString()
                              : '–',
                          subtitle: 'Últimos 7 días',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudyDiaryScreen(svc: svc),
                            ),
                          ),
                        ),
                        FocusMetricCard(
                          icon: Icons.bolt,
                          label: 'Racha',
                          value: '–',
                          subtitle: 'Actual',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudyPlannerScreen(svc: svc),
                            ),
                          ),
                        ),
                        FocusMetricCard(
                          icon: Icons.flag,
                          label: 'Próximo objetivo',
                          value: nextTask?.title ?? '–',
                          subtitle: 'Tareas de estudio',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudyListsScreen(svc: svc),
                            ),
                          ),
                        ),
                      ];

                      return ResponsiveKpiGrid(
                        children: [
                          FocusMetricCard(
                            icon: Icons.timer,
                            label: 'Horas estudiadas (semana)',
                            value: totalHours > 0
                                ? totalHours.toStringAsFixed(1)
                                : '–',
                            subtitle: 'Últimos 7 días',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudyTimerScreen(svc: svc),
                              ),
                            ),
                          ),
                          FocusMetricCard(
                            icon: Icons.check_circle,
                            label: 'Sesiones completadas',
                            value: totalSessions > 0
                                ? totalSessions.toString()
                                : '–',
                            subtitle: 'Últimos 7 días',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudyDiaryScreen(svc: svc),
                              ),
                            ),
                          ),
                          FocusMetricCard(
                            icon: Icons.bolt,
                            label: 'Racha',
                            value: '–',
                            subtitle: 'Actual',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudyPlannerScreen(svc: svc),
                              ),
                            ),
                          ),
                          FocusMetricCard(
                            icon: Icons.flag,
                            label: 'Próximo objetivo',
                            value: nextTask?.title ?? '–',
                            subtitle: 'Tareas de estudio',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudyListsScreen(svc: svc),
                              ),
                            ),
                          ),
                        ],
                        childAspectRatio: 1.9,
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: FocuslaneTokens.spacing16),
          FocusSectionTitle(
            title: 'Plan semanal',
            subtitle: 'Clases y sesiones programadas',
            action: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleScreen(svc: svc),
                  ),
                );
              },
              child: const Text('Ver horario'),
            ),
          ),
          StreamBuilder<List<Course>>(
            stream: svc.streamCourses(),
            builder: (context, coursesSnap) {
              final courses = coursesSnap.data ?? const [];
              final courseMap = {
                for (final c in courses) c.id: c.name,
              };

              return StreamBuilder<List<StudyClassBlock>>(
                stream: svc.streamSchedule(),
                builder: (context, scheduleSnap) {
                  final blocks = scheduleSnap.data ?? const [];
                  if (blocks.isEmpty) {
                    return FocusCard(
                      maxHeight: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aún no tienes clases programadas',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: FocuslaneTokens.spacing8),
                          Text(
                            'Añade bloques en el planificador para organizar tu semana.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  return FocusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próximas clases',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: FocuslaneTokens.spacing8),
                        ...blocks.take(4).map((b) {
                          final name = courseMap[b.courseId] ?? 'Curso';
                          final days = b.daysOfWeek.join(', ');
                          final time =
                              '${b.start.format(context)} - ${b.end.format(context)}';
                          final subtitle = 'Días $days • $time';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FocusListTileCompact(
                              title: name,
                              subtitle: subtitle,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: FocuslaneTokens.spacing16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FocusSectionTitle(
                          title: 'Últimas sesiones',
                          subtitle: 'Actividad reciente',
                        ),
                        StreamBuilder<List<Course>>(
                          stream: svc.streamCourses(),
                          builder: (context, coursesSnap) {
                            final courseMap = {
                              for (final c in coursesSnap.data ?? const [])
                                c.id: c.name,
                            };

                            return StreamBuilder<List<StudySession>>(
                              stream: svc.streamSessions(limit: 5),
                              builder: (context, sessionsSnap) {
                                final sessions = sessionsSnap.data ?? const [];
                                if (sessions.isEmpty) {
                                  return const FocusEmptyState(
                                    icon: Icons.history,
                                    message: 'Sin sesiones recientes',
                                  );
                                }

                                return FocusCard(
                                  child: Column(
                                    children: sessions.map((s) {
                                      final course = courseMap[s.courseId] ?? 'Curso';
                                      final date = DateFormat('d MMM', 'es')
                                          .format(s.date);
                                        final subtitle = '$course - $date';
                                      final mins = s.minutes > 0
                                          ? '${s.minutes} min'
                                          : '–';

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: FocusListTileCompact(
                                          title: s.method.name,
                                          subtitle: subtitle,
                                          trailing: Text(
                                            mins,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: FocuslaneTokens.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FocusSectionTitle(
                          title: 'Pendientes',
                          subtitle: 'Tareas y recordatorios',
                        ),
                        StreamBuilder<List<StudyTask>>(
                          stream: svc.streamTasks(),
                          builder: (context, tasksSnap) {
                            final tasks = tasksSnap.data ?? const [];
                            final pending =
                                tasks.where((t) => t.status != TaskStatus.done).toList();

                            if (pending.isEmpty) {
                              return const FocusEmptyState(
                                icon: Icons.checklist,
                                message: 'Sin tareas pendientes',
                              );
                            }

                            return FocusCard(
                              child: Column(
                                children: pending.take(5).map((t) {
                                  final due = t.due != null
                                      ? DateFormat('d MMM', 'es').format(t.due!)
                                      : 'Sin fecha';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: FocusListTileCompact(
                                      title: t.title,
                                      subtitle: due,
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: FocuslaneTokens.spacing12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudyTasksScreen(svc: svc),
                                ),
                              );
                            },
                            child: const Text('Abrir tareas'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: FocuslaneTokens.spacing16),
          FocusSectionTitle(
            title: 'Cursos',
            subtitle: 'Acceso rápido a materias',
            action: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoursesListScreen(svc: svc),
                  ),
                );
              },
              child: const Text('Ver cursos'),
            ),
          ),
          FocusCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoursesListScreen(svc: svc),
                ),
              );
            },
            child: Row(
              children: [
                const Icon(Icons.school),
                const SizedBox(width: FocuslaneTokens.spacing12),
                Expanded(
                  child: Text(
                    'Gestiona tus cursos y objetivos',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

