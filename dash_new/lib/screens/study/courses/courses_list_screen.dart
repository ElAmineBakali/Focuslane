import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import 'course_edit_sheet.dart';
import 'course_detail_screen.dart';
import 'package:mi_dashboard_personal/utils/app_links.dart';

class CoursesListScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  const CoursesListScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.link_rounded),
            onSelected: (v) {
              if (v == 'Canvas') AppLinks.openCanvas();
              if (v == 'ChatGPT') AppLinks.openChatGPT();
              if (v == 'Translate') AppLinks.openTranslate();
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'Canvas', child: Text('Canvas')),
                  PopupMenuItem(value: 'ChatGPT', child: Text('ChatGPT')),
                  PopupMenuItem(value: 'Translate', child: Text('Traductor')),
                ],
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
            builder: (_) => CourseEditSheet(svc: svc),
          );
          if (created != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(svc: svc, course: created),
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
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
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
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 70,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '¡Empieza tu jornada!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Crea tu primer curso para comenzar a organizar tu estudio',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            builder: (_) => CourseDetailScreen(svc: svc, course: created),
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
              ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12 + (MediaQuery.of(context).viewPadding.bottom > 0
                  ? MediaQuery.of(context).viewPadding.bottom
                  : 16),
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
                      builder: (_) =>
                          CourseDetailScreen(svc: svc, course: course),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Tarjeta mejorada de curso con indicador de progreso
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
    // Stream de sesiones de estudio para este curso
    final color = course.color ?? Theme.of(context).colorScheme.primary;

    return StreamBuilder<List<StudySession>>(
      stream: svc.streamSessions(courseId: course.id, limit: 100),
      builder: (context, sessionSnap) {
        final sessions = sessionSnap.data ?? [];
        final totalMinutes = sessions.fold<int>(
          0,
          (sum, s) => sum + s.minutes,
        );
        final goalMinutes = ((course.goalHours ?? 0) * 60).toInt();
        final progress = goalMinutes == 0 ? 0.0 : totalMinutes / goalMinutes;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con nombre y botón de acciones
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indicador de color
                      Container(
                        width: 6,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((course.teacher ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Prof: ${course.teacher}',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) =>
                                  CourseEditSheet(svc: svc, initial: course),
                            );
                          }
                          if (v == 'archive') {
                            await svc.updateCourse(
                              course.id,
                              {'isArchived': true},
                            );
                          }
                          if (v == 'delete') {
                            final ok = await _confirmDelete(context, course.name);
                            if (ok) await svc.deleteCourse(course.id);
                          }
                        },
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(Icons.archive_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Archivar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Eliminar'),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),

                  // Información de créditos y progreso
                  if (course.credits != null || course.goalHours != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      children: [
                        if (course.credits != null)
                          _InfoChip(
                            icon: Icons.menu_book_rounded,
                            label: '${course.credits?.toInt()} créditos',
                          ),
                        if (course.goalHours != null)
                          _InfoChip(
                            icon: Icons.timer_rounded,
                            label:
                                '${(totalMinutes / 60).toStringAsFixed(1)}/${course.goalHours} h',
                          ),
                      ],
                    ),
                  ],

                  // Barra de progreso si hay objetivo de horas
                  if (course.goalHours != null && goalMinutes > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: color.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String courseName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar curso'),
            content: Text(
              'Confirma que deseas eliminar "$courseName".\n\nLas sesiones y tareas asociadas NO se eliminarán automáticamente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    return ok == true;
  }
}

/// Chip pequeño de información
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
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
            return const Center(
              child: Text('No hay cursos archivados'),
            );
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: archived.length,
            itemBuilder: (_, i) {
              final c = archived[i];
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.archive_rounded,
                    color: c.color,
                  ),
                  title: Text(c.name),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restaurar'),
                    onPressed: () =>
                        svc.updateCourse(c.id, {'isArchived': false}),
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
