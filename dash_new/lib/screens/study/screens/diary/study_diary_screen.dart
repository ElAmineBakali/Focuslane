import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/study/screens/timer/study_timer_screen.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';

class StudyDiaryScreen extends StatelessWidget {
  const StudyDiaryScreen({super.key, required this.svc, this.embedded = false});

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
            if (coursesSnap.hasError || sessionsSnap.hasError) {
              return PageContainer(
                child: FocusEmptyState(
                  icon: Icons.error_outline_rounded,
                  message: 'No se pudo cargar el diario',
                  subtitle: '${coursesSnap.error ?? sessionsSnap.error}',
                ),
              );
            }
            if (!coursesSnap.hasData || !sessionsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return _StudyDiaryContent(
              svc: svc,
              courses: coursesSnap.data ?? const <Course>[],
              sessions: sessionsSnap.data ?? const <StudySession>[],
            );
          },
        );
      },
    );

    if (embedded) return content;

    return AppShell(
      title: 'Estudio',
      subtitle: 'Diario de sesiones recientes.',
      activeRoute: AppRoutes.studyDashboard,
      child: content,
    );
  }
}

class _StudyDiaryContent extends StatelessWidget {
  const _StudyDiaryContent({
    required this.svc,
    required this.courses,
    required this.sessions,
  });

  final StudyFirestoreService svc;
  final List<Course> courses;
  final List<StudySession> sessions;

  @override
  Widget build(BuildContext context) {
    final courseById = {for (final course in courses) course.id: course};
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, session) => sum + session.minutes,
    );
    final today = DateTime.now();
    final todayMinutes = sessions
        .where(
          (session) =>
              session.date.year == today.year &&
              session.date.month == today.month &&
              session.date.day == today.day,
        )
        .fold<int>(0, (sum, session) => sum + session.minutes);

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FocusCard(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diario de estudio',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Consulta sesiones reales, duración y curso asociado.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                  final action = FocusPrimaryButton(
                    label: 'Iniciar sesión',
                    icon: Icons.play_arrow_rounded,
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudyTimerScreen(svc: svc),
                          ),
                        ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [copy, const SizedBox(height: 16), action],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 16),
                      action,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 220,
              spacing: 16,
              children: [
                FocusStatCard(
                  title: 'Tiempo total',
                  value: '${(totalMinutes / 60).toStringAsFixed(1)} h',
                  subtitle: '${sessions.length} sesiones',
                  icon: Icons.timer_outlined,
                ),
                FocusStatCard(
                  title: 'Hoy',
                  value: '$todayMinutes min',
                  subtitle: 'registrados',
                  icon: Icons.today_rounded,
                ),
                FocusStatCard(
                  title: 'Cursos',
                  value: '${courses.length}',
                  subtitle: 'con historial disponible',
                  icon: Icons.school_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FocusCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FocusSectionHeader(
                    title: 'Historial de sesiones',
                    subtitle: 'Ordenado de más reciente a antiguo',
                    icon: Icons.history_rounded,
                  ),
                  const SizedBox(height: 16),
                  if (sessions.isEmpty)
                    const FocusEmptyState(
                      icon: Icons.menu_book_outlined,
                      message: 'Sin sesiones registradas',
                      subtitle: 'Cuando guardes una sesión aparecerá aquí.',
                    )
                  else
                    Column(
                      children: [
                        for (final session in sessions)
                          _SessionTile(
                            session: session,
                            course: courseById[session.courseId],
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.course});

  final StudySession session;
  final Course? course;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = course?.color ?? scheme.primary;

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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.timer_outlined, color: tone, size: 21),
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
                  '${_methodLabel(session.method)} · ${DateFormat('d MMM yyyy, HH:mm', 'es_ES').format(session.date)}',
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
          FocusBadge(label: '${session.minutes} min', color: tone),
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
