import 'package:flutter/material.dart';
import 'courses/courses_list_screen.dart';
import 'tasks/study_tasks_screen.dart';
import 'timer/study_timer_screen.dart';
import 'analytics/study_analytics_screen.dart';
import 'schedule/schedule_screen.dart';
import 'services/study_firestore_service.dart';
import 'services/study_notifications.dart';
import 'models/study_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla raíz centralizada del módulo Study.
/// Proporciona acceso estructurado a todas las funcionalidades:
/// - Cursos
/// - Tareas
/// - Temporizador
/// - Estadísticas
/// - Asistencia
/// - Horario académico
class StudyHomeScreen extends StatefulWidget {
  final StudyFirestoreService svc;
  const StudyHomeScreen({super.key, required this.svc});

  @override
  State<StudyHomeScreen> createState() => _StudyHomeScreenState();
}

class _StudyHomeScreenState extends State<StudyHomeScreen> {
  int _selectedIndex = 0;

  static const _kNotifyClasses = 'study_notify_classes';
  static const _kNotifyTasks = 'study_notify_tasks';

  @override
  void initState() {
    super.initState();
    _maybeScheduleOnStart();
  }

  Future<void> _maybeScheduleOnStart() async {
    final prefs = await SharedPreferences.getInstance();
    final notifyClasses = prefs.getBool(_kNotifyClasses) ?? true;
    final notifyTasks = prefs.getBool(_kNotifyTasks) ?? true;
    if (!mounted) return;
    if (notifyClasses || notifyTasks) {
      final n = StudyNotifications(widget.svc);
      await n.scheduleAll(classes: notifyClasses, tasks: notifyTasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CoursesListScreen(svc: widget.svc),
      StudyTasksScreen(svc: widget.svc),
      StudyTimerScreen(svc: widget.svc),
      StudyAnalyticsScreen(svc: widget.svc),
      _AttendanceOverviewScreen(svc: widget.svc),
      ScheduleScreen(svc: widget.svc),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.school_rounded),
          label: 'Cursos',
          tooltip: 'Mis cursos',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_rounded),
          label: 'Tareas',
          tooltip: 'Tareas y exámenes',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_rounded),
          label: 'Estudio',
          tooltip: 'Temporizador',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Analíticas',
          tooltip: 'Estadísticas',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          label: 'Asistencia',
          tooltip: 'Asistencia',
        ),
        NavigationDestination(
          icon: Icon(Icons.schedule_rounded),
          label: 'Horario',
          tooltip: 'Horario semanal',
        ),
      ],
    );
  }
}

/// Widget para mostrar resumen de asistencia de todos los cursos
class _AttendanceOverviewScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  const _AttendanceOverviewScreen({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia')),
      body: StreamBuilder<List<Course>>(
        stream: svc.streamCourses(),
        builder: (context, courseSnap) {
          if (!courseSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = courseSnap.data!;
          if (courses.isEmpty) {
            return const Center(child: Text('No hay cursos registrados'));
          }

          final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
          return ListView.builder(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12 + bottomPadding,
            ),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _AttendanceCard(svc: svc, course: course);
            },
          );
        },
      ),
    );
  }
}

/// Tarjeta de asistencia para un curso
class _AttendanceCard extends StatelessWidget {
  final StudyFirestoreService svc;
  final Course course;
  const _AttendanceCard({required this.svc, required this.course});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, String>>(
      stream: svc.streamAttendanceMap(course.id),
      builder: (context, snap) {
        final map = snap.data ?? const <String, String>{};
        final attended = map.values.where((v) => v == 'A').length;
        final absent = map.values.where((v) => v == 'X').length;
        final total = attended + absent;
        final percent = total == 0 ? 0.0 : (attended * 100.0 / total);
        final target = course.attendanceRequired ?? 0.0;
        final meets = percent >= target;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: meets
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: meets ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(
                      meets ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(label: 'Asistencias', value: '$attended'),
                    _StatItem(label: 'Faltas', value: '$absent'),
                    if (target > 0)
                      _StatItem(
                        label: 'Requerido',
                        value: '${target.toInt()}%',
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
