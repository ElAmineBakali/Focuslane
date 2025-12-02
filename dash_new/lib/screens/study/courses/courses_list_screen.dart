import 'package:flutter/material.dart';
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
        title: const Text('Asignaturas'),
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
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Course>>(
        stream: svc.streamCourses(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final courses = snap.data!;
          if (courses.isEmpty) {
            return const Center(
              child: Text('Crea tu primer curso con el botón +'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final c = courses[i];
              return Card(
                key: ValueKey(c.id),
                child: ListTile(
                  leading: Icon(
                    Icons.circle,
                    color: c.color ?? Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(c.name),
                  subtitle: Text(
                    [
                      if ((c.teacher ?? '').isNotEmpty) 'Prof: ${c.teacher}',
                      if (c.goalHours != null) 'Objetivo: ${c.goalHours} h',
                    ].join(' • '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => CourseEditSheet(svc: svc, initial: c),
                        );
                      }
                      if (v == 'archive') {
                        await svc.updateCourse(c.id, {'isArchived': true});
                      }
                      if (v == 'delete') {
                        final ok = await _confirm(
                          context,
                          'Eliminar curso',
                          '¿Eliminar "${c.name}"? Esta acción no borrará sesiones/ tareas asociadas automáticamente.',
                        );
                        if (ok) await svc.deleteCourse(c.id);
                      }
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'archive',
                            child: Text('Archivar'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailScreen(svc: svc, course: c),
                      ),
                    );
                  },
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: courses.length,
          );
        },
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    return ok == true;
  }
}

class _ArchivedCoursesScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  const _ArchivedCoursesScreen({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archivados')),
      body: StreamBuilder<List<Course>>(
        stream: svc.streamCourses(includeArchived: true),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          final archived = all.where((c) => c.isArchived).toList();
          if (archived.isEmpty)
            return const Center(child: Text('Sin archivados'));
          return ListView.builder(
            itemCount: archived.length,
            itemBuilder: (_, i) {
              final c = archived[i];
              return ListTile(
                leading: const Icon(Icons.archive_rounded),
                title: Text(c.name),
                trailing: TextButton(
                  child: const Text('Desarchivar'),
                  onPressed:
                      () => svc.updateCourse(c.id, {'isArchived': false}),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
