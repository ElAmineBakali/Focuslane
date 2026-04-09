import 'package:flutter/material.dart';
import 'package:focuslane/screens/finance/services/finance_category_labels.dart';
import 'package:focuslane/screens/finance/services/budget_service.dart';

import '../../../../design/ui/components/focus_card.dart';
import '../../../../design/ui/components/focus_module_header.dart';
import '../../../../design/ui/tokens/focuslane_tokens.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({
    super.key,
    required this.onBackToDashboard,
  });

  final VoidCallback onBackToDashboard;

  static const route = '/finance/budgets';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Finanzas',
        subtitle: 'Presupuestos',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        onBack: onBackToDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear presupuesto',
            onPressed: () => Navigator.pushNamed(context, '/finance/budgets/form'),
          ),
        ],
      ),
      body: Padding(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          children: [
            Expanded(
              child: FocusCard(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<List<BudgetWithProgress>>(
                  stream: BudgetService.I.watchAllWithProgress(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final budgets = snap.data ?? const [];
                    if (budgets.isEmpty) {
                      return const Center(child: Text('Sin presupuestos'));
                    }
                    return ListView.separated(
                      itemCount: budgets.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final b = budgets[i];
                        final pct =
                            (b.progress * 100).clamp(0, 999).toStringAsFixed(0);
                        return ListTile(
                          title: Text(b.budget.name),
                          subtitle: Text(labelForCategory(b.budget.category)),
                          trailing: Text(
                            '$pct%',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/finance/budgets/form',
                            arguments: b.budget,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





