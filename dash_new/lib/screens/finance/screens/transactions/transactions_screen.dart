import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/finance/models/transaction_model.dart';
import 'package:focuslane/screens/finance/services/finance_category_labels.dart';
import 'package:focuslane/screens/finance/services/transaction_service.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key, required this.onBackToDashboard});

  final VoidCallback onBackToDashboard;

  static const route = '/finance/transactions';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FinanceTransaction>>(
      stream: TransactionService.I.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PageContainer(
            child: FocusEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudieron cargar las transacciones',
              subtitle:
                  'Error controlado. Si Firestore pide un indice, crea el indice indicado y vuelve a cargar: ${snapshot.error}',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return _TransactionsContent(
          transactions: snapshot.data ?? const <FinanceTransaction>[],
        );
      },
    );
  }
}

class _TransactionsContent extends StatelessWidget {
  const _TransactionsContent({required this.transactions});

  final List<FinanceTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final income = transactions
        .where((tx) => tx.type == TxType.income)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final expense = transactions
        .where((tx) => tx.type == TxType.expense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FocusCard(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transacciones',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Lista real de ingresos, gastos y clasificaciones guardadas.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FocusBadge(
                            label: '${transactions.length} movimientos',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          FocusBadge(
                            label: 'Ingresos ${_currency(income)}',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          FocusBadge(
                            label: 'Gastos ${_currency(expense)}',
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ],
                      ),
                    ],
                  );
                  final action = FocusPrimaryButton(
                    label: 'Nueva transacción',
                    icon: Icons.add_rounded,
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          '/finance/transactions/form',
                        ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [copy, const SizedBox(height: 16), action],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 16),
                      action,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FocusCard(
              padding: const EdgeInsets.all(12),
              child:
                  transactions.isEmpty
                      ? const FocusEmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'Sin transacciones',
                        subtitle: 'Crea un movimiento para verlo en la lista.',
                      )
                      : Column(
                        children: [
                          for (final tx in transactions) ...[
                            _TransactionTile(tx: tx),
                            if (tx != transactions.last)
                              Divider(
                                height: 14,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                              ),
                          ],
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final FinanceTransaction tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIncome = tx.type == TxType.income;
    final tone = isIncome ? scheme.primary : scheme.error;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap:
          () => Navigator.pushNamed(
            context,
            '/finance/transactions/form',
            arguments: tx,
          ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconForCategory(tx.category), color: tone, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tx.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (tx.aiMeta != null) ...[
                        const SizedBox(width: 8),
                        FocusBadge(label: 'IA', color: scheme.tertiary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      FocusChip(
                        label: labelForCategory(tx.category),
                        icon: Icons.category_outlined,
                        color: scheme.primary,
                      ),
                      if ((tx.subCategory ?? '').trim().isNotEmpty)
                        FocusChip(
                          label: labelForSubCategory(tx.subCategory),
                          icon: Icons.sell_outlined,
                          color: scheme.secondary,
                        ),
                      FocusChip(
                        label: DateFormat(
                          'd MMM yyyy, HH:mm',
                          'es_ES',
                        ).format(tx.date),
                        icon: Icons.event_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${isIncome ? '+' : '-'}${_currency(tx.amount)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tone,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _currency(double value) => '${value.toStringAsFixed(2)} EUR';
