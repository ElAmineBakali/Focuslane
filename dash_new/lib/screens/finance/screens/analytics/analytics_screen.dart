import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/models/transaction_model.dart';
import 'package:mi_dashboard_personal/screens/finance/services/transaction_service.dart';

import '../../../../design/ui/components/focus_card.dart';
import '../../../../design/ui/components/focus_module_header.dart';
import '../../../../design/ui/tokens/focuslane_tokens.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({
    super.key,
    required this.onBackToDashboard,
  });

  final VoidCallback onBackToDashboard;

  static const route = '/finance/analytics';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Finanzas',
        subtitle: 'Ingresos vs gastos',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        onBack: onBackToDashboard,
      ),
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: FocusCard(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<List<FinanceTransaction>>(
            stream: TransactionService.I.watch(),
            builder: (context, snap) {
              final txs = snap.data ?? const [];
              double income = 0, expense = 0;
              for (final t in txs) {
                if (t.type == TxType.income) income += t.amount;
                if (t.type == TxType.expense) expense += t.amount;
              }
              final balance = income - expense;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumen', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _metric(context, 'Ingresos', income, Colors.green),
                  _metric(context, 'Gastos', expense, Colors.red),
                  _metric(
                    context,
                    'Balance',
                    balance,
                    balance >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text('${value.toStringAsFixed(2)}â‚¬', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}




