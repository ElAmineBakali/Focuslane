import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import '../../study/services/study_firestore_service.dart';
import '../../study/models/study_models.dart';
import '../../study/grades/grades_screen.dart';
import '../../study/attendance/attendance_screen.dart';
import '../../../design/ui/components/focus_card.dart';
import '../../../design/ui/components/focus_section_title.dart';
import '../../../design/ui/components/focus_empty_state.dart';
import '../../../design/ui/components/focus_list_tile_compact.dart';
import '../../../design/ui/components/focus_module_header.dart';
import '../../../design/ui/tokens/focuslane_tokens.dart';

class StudyPantryScreen extends StatelessWidget {
  final StudyFirestoreService svc;

  const StudyPantryScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FocusModuleHeader(
        title: 'Notas',
        subtitle: 'Notas y asistencia',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        backRouteName: AppRoutes.studyDashboard,
      ),
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FocusSectionTitle(
              title: 'Notas y asistencia',
              subtitle: 'Seguimiento académico',
            ),
            FocusCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GradesScreen(svc: svc),
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.insights),
                  const SizedBox(width: FocuslaneTokens.spacing12),
                  Expanded(
                    child: Text(
                      'Calificaciones',
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
            const SizedBox(height: FocuslaneTokens.spacing12),
            const FocusSectionTitle(
              title: 'Asistencia',
              subtitle: 'Elige un curso',
            ),
            StreamBuilder<List<Course>>(
              stream: svc.streamCourses(),
              builder: (context, snap) {
                final courses = snap.data ?? const [];
                if (courses.isEmpty) {
                  return const FocusEmptyState(
                    icon: Icons.school,
                    message: 'No hay cursos para registrar asistencia',
                  );
                }

                return FocusCard(
                  child: Column(
                    children: courses.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FocusListTileCompact(
                          title: c.name,
                          subtitle: c.teacher ?? 'Curso sin profesor',
                          trailing: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AttendanceScreen(
                                    svc: svc,
                                    course: c,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Abrir'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

