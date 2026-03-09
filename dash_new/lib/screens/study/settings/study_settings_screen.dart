import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import '../../study/services/study_firestore_service.dart';
import '../../study/settings/study_settings_sheet.dart';
import '../../../design/ui/components/focus_card.dart';
import '../../../design/ui/components/focus_section_title.dart';
import '../../../design/ui/components/focus_dialog.dart';
import '../../../design/ui/components/focus_module_header.dart';
import '../../../design/ui/tokens/focuslane_tokens.dart';

class StudySettingsScreen extends StatelessWidget {
  final StudyFirestoreService svc;

  const StudySettingsScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FocusModuleHeader(
        title: 'Ajustes',
        subtitle: 'Preferencias del módulo',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        backRouteName: AppRoutes.studyDashboard,
      ),
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FocusSectionTitle(
              title: 'Ajustes',
              subtitle: 'Preferencias del módulo',
            ),
            FocusCard(
              onTap: () {
                showFocusBottomSheet(
                  context: context,
                  child: StudySettingsSheet(svc: svc),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.tune),
                  const SizedBox(width: FocuslaneTokens.spacing12),
                  Expanded(
                    child: Text(
                      'Configuración avanzada',
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
          ],
        ),
      ),
    );
  }
}

