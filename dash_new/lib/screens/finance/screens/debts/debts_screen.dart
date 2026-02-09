import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/models/loan_model.dart';
import 'package:mi_dashboard_personal/screens/finance/services/debt_service_loans.dart';

import '../../../../ui/components/focus_card.dart';
import '../../../../ui/components/focus_module_header.dart';
import '../../../../ui/tokens/focuslane_tokens.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({
    super.key,
    required this.onBackToDashboard,
  });

  final VoidCallback onBackToDashboard;

  static const route = '/finance/debts';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Finanzas',
        subtitle: 'Deudas',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        onBack: onBackToDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva deuda',
            onPressed: () => Navigator.pushNamed(context, '/finance/debts/form'),
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
                child: StreamBuilder<List<Debt>>(
                  stream: DebtService.I.watchAll(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final debts = snap.data ?? const [];
                    if (debts.isEmpty) {
                      return const Center(child: Text('Sin deudas'));
                    }
                    return ListView.separated(
                      itemCount: debts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final d = debts[i];
                        final progress = 1 - (d.balance / d.originalAmount);
                        final pct =
                            (progress * 100).clamp(0, 100).toStringAsFixed(0);
                        return ListTile(
                          title: Text(d.name),
                          subtitle: Text(d.creditor),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${d.balance.toStringAsFixed(2)}€',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '$pct% pagado',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/finance/debts/form',
                            arguments: d,
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



