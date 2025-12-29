import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import 'course_edit_sheet.dart';
import 'course_detail_editable_screen.dart';
import 'external_links_sheet.dart';
import '../settings/study_settings_sheet.dart';

class CoursesListScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  const CoursesListScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cursos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            tooltip: 'Ajustes de Study',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => StudySettingsSheet(svc: svc),
              );
            },
          ),
          IconButton(
            tooltip: 'Enlaces externos',
            icon: const Icon(Icons.link_rounded),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => const ExternalLinksSheet(),
              );
            },
          ),
          IconButton(
            tooltip: 'Archivados',
            icon: const Icon(Icons.archive_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _ArchivedCoursesScreen(svc: svc),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showModalBottomSheet<Course?>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => CourseEditSheet(svc: svc),
          );
          if (created != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        CourseDetailEditableScreen(svc: svc, course: created),
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: StreamBuilder<List<Course>>(
        stream: svc.streamCourses(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snap.data!;
          if (courses.isEmpty) {
            return Center(
              child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withOpacity(0.2),
                              colorScheme.secondary.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 70,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '¡Empieza tu jornada!',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Crea tu primer curso para comenzar a organizar tu estudio',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () async {
                          final created = await showModalBottomSheet<Course?>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => CourseEditSheet(svc: svc),
                          );
                          if (created != null && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CourseDetailEditableScreen(
                                      svc: svc,
                                      course: created,
                                    ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Crear primer curso'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom:
                  16 +
                  (MediaQuery.of(context).viewPadding.bottom > 0
                      ? MediaQuery.of(context).viewPadding.bottom
                      : 80),
            ),
            itemCount: courses.length,
            itemBuilder: (context, i) {
              final course = courses[i];
              return _CourseCard(
                    svc: svc,
                    course: course,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => CourseDetailEditableScreen(
                                svc: svc,
                                course: course,
                              ),
                        ),
                      );
                    },
                  )
                  .animate(delay: (i * 50).ms)
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: -0.1, end: 0);
            },
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final StudyFirestoreService svc;
  final Course course;
  final VoidCallback onTap;

  const _CourseCard({
    required this.svc,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = course.color ?? colorScheme.primary;

    return StreamBuilder<List<StudySession>>(
      stream: svc.streamSessions(courseId: course.id, limit: 100),
      builder: (context, sessionSnap) {
        final sessions = sessionSnap.data ?? [];
        final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.minutes);
        final goalMinutes = ((course.goalHours ?? 0) * 60).toInt();
        final progress = goalMinutes == 0 ? 0.0 : totalMinutes / goalMinutes;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.08), colorScheme.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icono decorativo
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((course.teacher ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        course.teacher!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),

                    // Información adicional
                    if (course.credits != null || course.goalHours != null) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (course.credits != null)
                            _InfoChip(
                              icon: Icons.menu_book_rounded,
                              label: '${course.credits?.toInt()} créditos',
                              color: color,
                            ),
                          if (course.goalHours != null)
                            _InfoChip(
                              icon: Icons.timer_rounded,
                              label:
                                  '${(totalMinutes / 60).toStringAsFixed(1)}/${course.goalHours} h',
                              color: color,
                            ),
                        ],
                      ),
                    ],

                    // Barra de progreso
                    if (course.goalHours != null && goalMinutes > 0) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0.0,
                            end: progress.clamp(0.0, 1.0),
                          ),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 10,
                              backgroundColor: color.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedCoursesScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  const _ArchivedCoursesScreen({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cursos archivados')),
      body: StreamBuilder<List<Course>>(
        stream: svc.streamCourses(includeArchived: true),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          final archived = all.where((c) => c.isArchived).toList();
          if (archived.isEmpty)
            return const Center(child: Text('No hay cursos archivados'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: archived.length,
            itemBuilder: (_, i) {
              final c = archived[i];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.archive_rounded, color: c.color),
                  title: Text(c.name),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restaurar'),
                    onPressed:
                        () => svc.updateCourse(c.id, {'isArchived': false}),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
