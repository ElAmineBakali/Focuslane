import 'package:flutter/material.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import '../tasks/study_tasks_screen.dart';
import '../timer/study_timer_screen.dart';
import '../analytics/study_analytics_screen.dart';
import 'course_edit_sheet.dart';
import '../attendance/attendance_screen.dart';
import 'package:focuslane/design/ui/components/focus_module_header.dart';

class CourseDetailScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  final Course course;
  const CourseDetailScreen({
    super.key,
    required this.svc,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final accent = course.color ?? Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        leading: FocusModuleHeader.buildLeading(
          context,
          mode: FocusModuleLeadingMode.backToModuleDashboard,
          backRouteName: AppRoutes.studyDashboard,
        ),
        leadingWidth: 96,
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit),
            onPressed:
                () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CourseEditSheet(svc: svc, initial: course),
                ),
          ),
          IconButton(
            tooltip: 'Estadísticas',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            StudyAnalyticsScreen(svc: svc, courseId: course.id),
                  ),
                ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.play_circle_fill, color: accent),
              title: const Text('Estudiar ahora'),
              subtitle: const Text('Inicia una sesión con el último preset'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => StudyTimerScreen(
                          svc: svc,
                          initialCourseId: course.id,
                        ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.checklist, color: accent),
              title: const Text('Tareas / Exámenes'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => StudyTasksScreen(
                          svc: svc,
                          initialCourseId: course.id,
                        ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.event_available, color: accent),
              title: const Text('Asistencia'),
              subtitle: Text(
                course.attendanceRequired != null
                    ? 'Requerida: ${course.attendanceRequired!.toStringAsFixed(0)}%'
                  : 'Define el % requerido en "Editar" (opcional)',
              ),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => AttendanceScreen(svc: svc, course: course),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}




