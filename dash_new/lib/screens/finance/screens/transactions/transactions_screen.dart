import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/models/transaction_model.dart';
import 'package:mi_dashboard_personal/screens/finance/services/transaction_service.dart';

import '../../../../design/ui/components/focus_card.dart';
import '../../../../design/ui/components/focus_module_header.dart';
import '../../../../design/ui/tokens/focuslane_tokens.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({
    super.key,
    required this.onBackToDashboard,
  });

  final VoidCallback onBackToDashboard;

  static const route = '/finance/transactions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Finanzas',
        subtitle: 'Transacciones',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        onBack: onBackToDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva transacciÃ³n',
            onPressed: () =>
                Navigator.pushNamed(context, '/finance/transactions/form'),
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
                child: StreamBuilder<List<FinanceTransaction>>(
                  stream: TransactionService.I.watch(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final txs = snap.data ?? const [];
                    if (txs.isEmpty) {
                      return const Center(child: Text('Sin transacciones'));
                    }
                    return ListView.separated(
                      itemCount: txs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final t = txs[i];
                        final isIncome = t.type == TxType.income;
                        final color = isIncome ? Colors.green : Colors.red;
                        final sign = isIncome ? '+' : '-';
                        return ListTile(
                          title: Text(t.title),
                          subtitle: Text(t.category ?? 'General'),
                          trailing: Text(
                            '$sign${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/finance/transactions/form',
                            arguments: t,
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




