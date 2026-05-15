import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/finance/models/transaction_model.dart';
import 'package:focuslane/screens/finance/services/finance_category_labels.dart';
import 'package:focuslane/screens/finance/services/transaction_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, required this.onBackToDashboard});

  final VoidCallback onBackToDashboard;

  static const route = '/finance/analytics';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FinanceTransaction>>(
      stream: TransactionService.I.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PageContainer(
            child: FocusEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudo cargar el análisis',
              subtitle: '${snapshot.error}',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return _AnalyticsContent(
          transactions: snapshot.data ?? const <FinanceTransaction>[],
        );
      },
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.transactions});

  final List<FinanceTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    double income = 0;
    double expense = 0;
    final categoryTotals = <String, double>{};
    var aiCount = 0;

    for (final tx in transactions) {
      if (tx.type == TxType.income) income += tx.amount;
      if (tx.type == TxType.expense) {
        expense += tx.amount;
        final key = tx.category ?? 'otros';
        categoryTotals[key] = (categoryTotals[key] ?? 0) + tx.amount;
      }
      if (tx.aiMeta != null) aiCount++;
    }

    final balance = income - expense;
    final topCategories =
        categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FocusCard(
              child: FocusSectionHeader(
                title: 'Análisis financiero',
                subtitle: 'Ingresos, gastos y clasificación por categoría',
                icon: Icons.analytics_rounded,
                trailing: FocusBadge(
                  label: '$aiCount con IA',
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 220,
              spacing: 16,
              children: [
                FocusStatCard(
                  title: 'Ingresos',
                  value: _currency(income),
                  subtitle: 'registrados',
                  icon: Icons.trending_up_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                FocusStatCard(
                  title: 'Gastos',
                  value: _currency(expense),
                  subtitle: 'registrados',
                  icon: Icons.trending_down_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                FocusStatCard(
                  title: 'Balance',
                  value: _currency(balance),
                  subtitle: 'neto',
                  icon: Icons.account_balance_wallet_outlined,
                  color:
                      balance >= 0
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FocusCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FocusSectionHeader(
                    title: 'Gastos por categoría',
                    subtitle: 'Ordenado de mayor a menor importe',
                    icon: Icons.pie_chart_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  if (topCategories.isEmpty)
                    const FocusEmptyState(
                      icon: Icons.insights_outlined,
                      message: 'Sin gastos para analizar',
                    )
                  else
                    Column(
                      children: [
                        for (final entry in topCategories.take(8))
                          _CategoryBar(
                            label: labelForCategory(entry.key),
                            value: entry.value,
                            max: topCategories.first.value,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.value,
    required this.max,
  });

  final String label;
  final double value;
  final double max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = max <= 0 ? 0.0 : value / max;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _currency(value),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FocusProgressBar(
            value: progress.clamp(0.0, 1.0),
            color: scheme.primary,
          ),
        ],
      ),
    );
  }
}

String _currency(double value) => '${value.toStringAsFixed(2)} EUR';
