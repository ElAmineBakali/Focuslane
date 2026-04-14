import 'package:flutter/material.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import 'package:focuslane/design/ui/components/focus_module_header.dart';

class SessionSummaryScreen extends StatelessWidget {
  final StudySession session;
  final StudyFirestoreService? svc;
  const SessionSummaryScreen({super.key, required this.session, this.svc});

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

  Widget _buildSummary(BuildContext context, String courseName) {
    final method = _methodLabel(session.method);
    final minutes = session.minutes;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text('$courseName - $method - $minutes min'),
            subtitle: const Text('Sesion guardada correctamente'),
          ),
        ),
        if (session.cycles != null || session.laps != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.timer),
              title: Text('Duracion total: $minutes min'),
              subtitle: Text(
                [
                  if (session.cycles != null) 'Ciclos: ${session.cycles}',
                  if (session.laps != null) 'Laps: ${session.laps}',
                ].join(' - '),
              ),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Listo'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de estudio'),
        leading: FocusModuleHeader.buildLeading(
          context,
          mode: FocusModuleLeadingMode.backToModuleDashboard,
          backRouteName: AppRoutes.studyDashboard,
        ),
        leadingWidth: 96,
      ),
      body: svc == null
          ? _buildSummary(context, session.courseId)
          : StreamBuilder<List<Course>>(
              stream: svc!.streamCourses(includeArchived: true),
              builder: (context, snapshot) {
                final courses = snapshot.data ?? const <Course>[];
                final match = courses.where((c) => c.id == session.courseId);
                final courseName =
                    match.isNotEmpty ? match.first.name : session.courseId;
                return _buildSummary(context, courseName);
              },
            ),
    );
  }
}




