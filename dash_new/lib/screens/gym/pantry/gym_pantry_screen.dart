import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import '../../gym/services/gym_firestore_service.dart';
import '../../gym/body/bodyweight_screen.dart';
import '../../gym/body/measurements_screen.dart';
import '../../../ui/components/focus_card.dart';
import '../../../ui/components/focus_section_title.dart';
import '../../../ui/components/focus_module_header.dart';
import '../../../ui/tokens/focuslane_tokens.dart';

class GymPantryScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymPantryScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FocusModuleHeader(
        title: 'Cuerpo',
        subtitle: 'Peso y medidas corporales',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        backRouteName: AppRoutes.gymDashboard,
      ),
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FocusSectionTitle(
              title: 'Cuerpo',
              subtitle: 'Peso y medidas corporales',
            ),
            FocusCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BodyweightScreen(svc: svc),
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.monitor_weight),
                  const SizedBox(width: FocuslaneTokens.spacing12),
                  Expanded(
                    child: Text(
                      'Registro de peso',
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
            FocusCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeasurementsScreen(svc: svc),
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.straighten),
                  const SizedBox(width: FocuslaneTokens.spacing12),
                  Expanded(
                    child: Text(
                      'Medidas corporales',
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
