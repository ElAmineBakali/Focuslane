import 'package:flutter/material.dart';

import '../../../../ui/components/focus_card.dart';
import '../../../../ui/components/focus_module_header.dart';
import '../../../../ui/tokens/focuslane_tokens.dart';

class FinanceSettingsScreen extends StatelessWidget {
  const FinanceSettingsScreen({
    super.key,
    required this.onBackToDashboard,
  });

  final VoidCallback onBackToDashboard;

  static const route = '/finance/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Finanzas',
        subtitle: 'Ajustes',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        onBack: onBackToDashboard,
      ),
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: FocusCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Configuración básica',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text('Ajusta tus preferencias de finanzas. (Pendiente de detalle)'),
            ],
          ),
        ),
      ),
    );
  }
}


