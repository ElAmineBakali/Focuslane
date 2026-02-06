import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import '../../gym/services/gym_firestore_service.dart';
import '../../gym/session/session_history_screen.dart';
import '../../../ui/components/focus_empty_state.dart';
import '../../../ui/components/focus_module_header.dart';
import '../../../ui/tokens/focuslane_tokens.dart';

class GymDiaryScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymDiaryScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FocusModuleHeader(
        title: 'Diario',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        backRouteName: AppRoutes.gymDashboard,
      ),
      body: Padding(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: FocusEmptyState(
          icon: Icons.receipt_long,
          message: 'Registra tus sesiones para ver el diario completo.',
          actionLabel: 'Ver historial',
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SessionHistoryScreen(svc: svc),
              ),
            );
          },
        ),
      ),
    );
  }
}
