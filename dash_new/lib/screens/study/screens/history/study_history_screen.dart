import 'package:flutter/material.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';

class StudyHistoryScreen extends StatelessWidget {
  final StudyFirestoreService svc;

  const StudyHistoryScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de estudio')),
      body: StreamBuilder<List<Course>>(
        stream: svc.streamCourses(includeArchived: true),
        builder: (context, coursesSnap) {
          final courses = coursesSnap.data ?? const <Course>[];
          final courseNames = {
            for (final course in courses) course.id: course.name,
          };

          return StreamBuilder<List<StudySession>>(
            stream: svc.streamSessions(limit: 100),
            builder: (context, sessionsSnap) {
              return StreamBuilder<List<StudyTask>>(
                stream: svc.streamTasks(),
                builder: (context, tasksSnap) {
                  if (!coursesSnap.hasData ||
                      !sessionsSnap.hasData ||
                      !tasksSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sessions = sessionsSnap.data ?? const <StudySession>[];
                  final doneTasks = (tasksSnap.data ?? const <StudyTask>[])
                      .where((task) => task.status == TaskStatus.done)
                      .toList();

                  final events = <_HistoryEvent>[
                    ...sessions.map(
                      (session) => _HistoryEvent(
                        date: session.date,
                        title:
                            'Sesión ${_methodLabel(session.method)} · ${session.minutes} min',
                        subtitle:
                            'Curso: ${courseNames[session.courseId] ?? 'Curso eliminado'}',
                        icon: Icons.timer_outlined,
                      ),
                    ),
                    ...doneTasks
                        .where((task) => task.due != null)
                        .map(
                          (task) => _HistoryEvent(
                            date: task.due!,
                            title: 'Tarea completada: ${task.title}',
                            subtitle:
                                'Curso: ${courseNames[task.courseId] ?? 'Curso eliminado'}',
                            icon: Icons.task_alt,
                          ),
                        ),
                  ];

                  events.sort((a, b) => b.date.compareTo(a.date));

                  if (events.isEmpty) {
                    return const Center(
                      child: Text('Aún no hay actividad de estudio registrada'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(event.icon),
                          title: Text(event.title),
                          subtitle: Text(
                            '${event.subtitle}\n${_formatDate(event.date)}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _methodLabel(StudyMethod method) {
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

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
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


