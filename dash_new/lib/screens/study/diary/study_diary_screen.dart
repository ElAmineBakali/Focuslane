import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focuslane/navigation/app_routes.dart';
import '../../study/services/study_firestore_service.dart';
import '../../study/models/study_models.dart';
import '../../study/timer/study_timer_screen.dart';
import '../../../design/ui/components/focus_card.dart';
import '../../../design/ui/components/focus_section_title.dart';
import '../../../design/ui/components/focus_empty_state.dart';
import '../../../design/ui/components/focus_list_tile_compact.dart';
import '../../../design/ui/components/focus_module_header.dart';
import '../../../design/ui/tokens/focuslane_tokens.dart';

class StudyDiaryScreen extends StatelessWidget {
  final StudyFirestoreService svc;

  const StudyDiaryScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FocusModuleHeader(
        title: 'Diario',
        subtitle: 'Sesiones recientes',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        backRouteName: AppRoutes.studyDashboard,
      ),
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FocusSectionTitle(
              title: 'Diario de estudio',
              subtitle: 'Sesiones recientes',
              action: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudyTimerScreen(svc: svc),
                    ),
                  );
                },
                child: const Text('Iniciar sesión'),
              ),
            ),
            StreamBuilder<List<StudySession>>(
              stream: svc.streamSessions(limit: 20),
              builder: (context, snap) {
                final sessions = snap.data ?? const [];
                if (sessions.isEmpty) {
                  return const FocusEmptyState(
                    icon: Icons.menu_book,
                    message: 'Sin sesiones registradas',
                  );
                }

                return FocusCard(
                  child: Column(
                    children: sessions.map((s) {
                      final date = DateFormat('d MMM', 'es').format(s.date);
                      final subtitle = '$date - ${s.minutes} min';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FocusListTileCompact(
                          title: s.method.name,
                          subtitle: subtitle,
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


