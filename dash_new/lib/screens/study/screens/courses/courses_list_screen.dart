import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';

import 'course_detail_editable_screen.dart';
import 'course_edit_sheet.dart';
import 'external_links_sheet.dart';

class CoursesListScreen extends StatelessWidget {
  const CoursesListScreen({
    super.key,
    required this.svc,
    this.embedded = false,
  });

  final StudyFirestoreService svc;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<Course>>(
      stream: svc.streamCourses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PageContainer(
            child: FocusEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudieron cargar los cursos',
              subtitle: '${snapshot.error}',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return _CoursesContent(svc: svc, courses: snapshot.data ?? const []);
      },
    );

    if (embedded) return content;

    return AppShell(
      title: 'Estudio',
      subtitle: 'Cursos y materias.',
      activeRoute: AppRoutes.studyDashboard,
      child: content,
    );
  }
}

class _CoursesContent extends StatelessWidget {
  const _CoursesContent({required this.svc, required this.courses});

  final StudyFirestoreService svc;
  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    final activeCourses =
        courses.where((course) => !course.isArchived).toList();
    final archivedCount = courses.length - activeCourses.length;

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoursesHeader(
              activeCount: activeCourses.length,
              archivedCount: archivedCount,
              onCreate: () => _createCourse(context),
              onLinks: () => _openExternalLinks(context),
              onArchived: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ArchivedCoursesScreen(svc: svc),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            if (activeCourses.isEmpty)
              FocusCard(
                child: FocusEmptyState(
                  icon: Icons.school_outlined,
                  message: 'Aun no tienes cursos activos',
                  subtitle:
                      'Crea un curso para enlazar tareas, sesiones y calificaciones.',
                  actionLabel: 'Nuevo curso',
                  onAction: () => _createCourse(context),
                ),
              )
            else
              ResponsiveGrid(
                minItemWidth: 300,
                spacing: 16,
                children: [
                  for (final course in activeCourses)
                    _CourseCard(
                      key: ValueKey(course.id),
                      svc: svc,
                      course: course,
                      onTap: () => _openCourse(context, course),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCourse(BuildContext context) async {
    final created = await showModalBottomSheet<Course?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CourseEditSheet(svc: svc),
    );
    if (created != null && context.mounted) {
      _openCourse(context, created);
    }
  }

  Future<void> _openExternalLinks(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ExternalLinksSheet(),
    );
  }

  void _openCourse(BuildContext context, Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailEditableScreen(svc: svc, course: course),
      ),
    );
  }
}

class _CoursesHeader extends StatelessWidget {
  const _CoursesHeader({
    required this.activeCount,
    required this.archivedCount,
    required this.onCreate,
    required this.onLinks,
    required this.onArchived,
  });

  final int activeCount;
  final int archivedCount;
  final VoidCallback onCreate;
  final VoidCallback onLinks;
  final VoidCallback onArchived;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cursos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gestiona materias, metas de horas, asistencia y calificaciones.',
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
                    label: '$activeCount activos',
                    color: scheme.primary,
                  ),
                  FocusBadge(
                    label: '$archivedCount archivados',
                    color: scheme.secondary,
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
                label: 'Nuevo curso',
                icon: Icons.add_rounded,
                onPressed: onCreate,
              ),
              FocusSecondaryButton(
                label: 'Enlaces',
                icon: Icons.link_rounded,
                onPressed: onLinks,
              ),
              FocusSecondaryButton(
                label: 'Archivados',
                icon: Icons.archive_rounded,
                onPressed: onArchived,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 16), actions],
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

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    super.key,
    required this.svc,
    required this.course,
    required this.onTap,
  });

  final StudyFirestoreService svc;
  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = course.color ?? scheme.primary;

    return StreamBuilder<List<StudySession>>(
      stream: svc.streamSessions(courseId: course.id, limit: 100),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <StudySession>[];
        final totalMinutes = sessions.fold<int>(
          0,
          (sum, session) => sum + session.minutes,
        );
        final goalMinutes = ((course.goalHours ?? 0) * 60).round();
        final progress = goalMinutes <= 0 ? 0.0 : totalMinutes / goalMinutes;

        return FocusCard(
          onTap: onTap,
          backgroundColor: scheme.surfaceContainerLowest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tone.withValues(alpha: 0.28)),
                    ),
                    child: Icon(Icons.school_rounded, color: tone, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if ((course.teacher ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            course.teacher!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (course.credits != null)
                    FocusChip(
                      label: '${course.credits!.toStringAsFixed(0)} créditos',
                      icon: Icons.star_rounded,
                      color: tone,
                    ),
                  FocusChip(
                    label: '${(totalMinutes / 60).toStringAsFixed(1)} h',
                    icon: Icons.timer_outlined,
                    color: scheme.secondary,
                  ),
                  if (course.attendanceRequired != null)
                    FocusChip(
                      label:
                          '${course.attendanceRequired!.toStringAsFixed(0)}% asistencia',
                      icon: Icons.how_to_reg_rounded,
                      color: scheme.tertiary,
                    ),
                ],
              ),
              if (goalMinutes > 0) ...[
                const SizedBox(height: 16),
                FocusProgressBar(value: progress.clamp(0.0, 1.0), color: tone),
                const SizedBox(height: 8),
                Text(
                  '${(totalMinutes / 60).toStringAsFixed(1)} / ${course.goalHours!.toStringAsFixed(1)} h objetivo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ArchivedCoursesScreen extends StatelessWidget {
  const _ArchivedCoursesScreen({required this.svc});

  final StudyFirestoreService svc;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Estudio',
      subtitle: 'Cursos archivados.',
      activeRoute: AppRoutes.studyDashboard,
      child: StreamBuilder<List<Course>>(
        stream: svc.streamCourses(includeArchived: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return PageContainer(
              child: FocusEmptyState(
                icon: Icons.error_outline_rounded,
                message: 'No se pudieron cargar los cursos archivados',
                subtitle: '${snapshot.error}',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final archived =
              snapshot.data!.where((course) => course.isArchived).toList();

          return SingleChildScrollView(
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FocusSectionHeader(
                    title: 'Cursos archivados',
                    subtitle: 'Restauralos cuando vuelvan a estar activos',
                    icon: Icons.archive_rounded,
                  ),
                  const SizedBox(height: 16),
                  if (archived.isEmpty)
                    const FocusCard(
                      child: FocusEmptyState(
                        icon: Icons.archive_outlined,
                        message: 'No hay cursos archivados',
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final course in archived) ...[
                          FocusCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.archive_rounded,
                                  color:
                                      course.color ??
                                      Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    course.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.restore_rounded),
                                  label: const Text('Restaurar'),
                                  onPressed:
                                      () => svc.updateCourse(course.id, {
                                        'isArchived': false,
                                      }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
