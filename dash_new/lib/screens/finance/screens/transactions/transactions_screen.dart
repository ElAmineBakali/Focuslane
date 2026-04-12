import 'package:flutter/material.dart';
import 'package:focuslane/screens/finance/models/transaction_model.dart';
import 'package:focuslane/screens/finance/services/finance_category_labels.dart';
import 'package:focuslane/screens/finance/services/transaction_service.dart';

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
            tooltip: 'Nueva transacción',
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
                      return const Center(child: Text('Error al cargar transacciones'));
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
                          title: Row(
                            children: [
                              Expanded(child: Text(t.title)),
                              if (t.aiMeta != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'IA',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Icon(
                                iconForCategory(t.category),
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(labelForCategory(t.category)),
                            ],
                          ),
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





