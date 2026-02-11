import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/models/budget_model.dart';
import 'package:mi_dashboard_personal/screens/finance/models/subscription_model.dart';
import 'package:mi_dashboard_personal/screens/finance/models/transaction_model.dart';
import 'package:mi_dashboard_personal/screens/finance/services/budget_service.dart';
import 'package:mi_dashboard_personal/screens/finance/services/subscription_service.dart';
import 'package:mi_dashboard_personal/screens/finance/services/transaction_service.dart';
import 'package:mi_dashboard_personal/core/constants/core_routes.dart';

import '../../../../ui/components/focus_card.dart';
import '../../../../ui/components/focus_metric_card.dart';
import '../../../../ui/components/focus_module_header.dart';
import '../../../../ui/tokens/focuslane_tokens.dart';

class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({super.key, required this.onSelectSection});

  final ValueChanged<int> onSelectSection;

  static const route = '/finance';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Finanzas',
        subtitle: 'Patrimonio, gastos y análisis',
        leadingMode: FocusModuleLeadingMode.exitModule,
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            tooltip: 'Abrir Hub',
            onPressed: () => Navigator.pushNamed(context, CoreRoutes.coreHub),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva transacción',
            onPressed: () =>
                Navigator.pushNamed(context, '/finance/transactions/form'),
          ),
        ],
      ),
      body: StreamBuilder<List<FinanceTransaction>>(
        stream: TransactionService.I.watch(from: monthStart),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final txs = snap.data ?? const [];
          double income = 0;
          double expense = 0;
          for (final t in txs) {
            if (t.type == TxType.income) income += t.amount;
            if (t.type == TxType.expense) expense += t.amount;
          }
          final balance = income - expense;
          final savings = income == 0 ? 0.0 : (income - expense) / income;

          return SingleChildScrollView(
            padding: FocuslaneTokens.pagePaddingCompact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetricsRow(
                  income: income,
                  expense: expense,
                  balance: balance,
                  savings: savings,
                  onSelectSection: onSelectSection,
                ),
                const SizedBox(height: FocuslaneTokens.spacing16),
                _SummaryCard(
                  income: income,
                  expense: expense,
                  balance: balance,
                ),
                const SizedBox(height: FocuslaneTokens.spacing16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 960;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _RecentTransactions(
                              transactions: txs,
                              onSelectSection: onSelectSection,
                            ),
                          ),
                          const SizedBox(width: FocuslaneTokens.spacing12),
                          Expanded(
                            child: _BudgetAndSubs(
                              onSelectSection: onSelectSection,
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _RecentTransactions(
                          transactions: txs,
                          onSelectSection: onSelectSection,
                        ),
                        const SizedBox(height: FocuslaneTokens.spacing12),
                        _BudgetAndSubs(onSelectSection: onSelectSection),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.income,
    required this.expense,
    required this.balance,
    required this.savings,
    required this.onSelectSection,
  });

  final double income;
  final double expense;
  final double balance;
  final double savings;
  final ValueChanged<int> onSelectSection;

  @override
  Widget build(BuildContext context) {
    final cards = [
      FocusMetricCard(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Balance total',
        value: _currency(balance),
        subtitle: 'Mes actual',
        onTap: () => onSelectSection(1),
      ),
      FocusMetricCard(
        icon: Icons.trending_down,
        label: 'Gastos del mes',
        value: _currency(expense),
        subtitle: 'Actualizado',
        onTap: () => onSelectSection(1),
      ),
      FocusMetricCard(
        icon: Icons.trending_up,
        label: 'Ingresos del mes',
        value: _currency(income),
        subtitle: 'Actualizado',
        onTap: () => onSelectSection(1),
      ),
      FocusMetricCard(
        icon: Icons.savings_outlined,
        label: 'Ahorro / tasa',
        value: income == 0
            ? '—'
            : '${(income - expense).toStringAsFixed(2)} · ${(savings * 100).toStringAsFixed(1)}%',
        subtitle: 'Ingreso - gasto',
        onTap: () => onSelectSection(2),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = constraints.maxWidth >= 1200
            ? 4
            : constraints.maxWidth >= 720
                ? 2
                : 1;
        if (cross == 1) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: c,
                    ))
                .toList(),
          );
        }
        return GridView.count(
          crossAxisCount: cross,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.9,
          children: cards,
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.balance,
  });

  final double income;
  final double expense;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart, size: 18),
              SizedBox(width: 8),
              Text('Resumen mensual', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance: ${_currency(balance)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text('Ingresos: ${_currency(income)}'),
              Text('Gastos: ${_currency(expense)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({
    required this.transactions,
    required this.onSelectSection,
  });
  final List<FinanceTransaction> transactions;
  final ValueChanged<int> onSelectSection;

  @override
  Widget build(BuildContext context) {
    final recent = transactions.take(6).toList();
    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Últimas transacciones', style: TextStyle(fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () => onSelectSection(1),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Text('No hay transacciones')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = recent[i];
                final isIncome = t.type == TxType.income;
                final sign = isIncome ? '+' : '-';
                final color = isIncome ? Colors.green : Colors.red;
                return ListTile(
                  dense: true,
                  title: Text(t.title),
                  subtitle: Text(t.category ?? 'Sin categoría'),
                  trailing: Text(
                    '$sign${t.amount.toStringAsFixed(2)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/finance/transactions/form',
                    arguments: t,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BudgetAndSubs extends StatelessWidget {
  const _BudgetAndSubs({required this.onSelectSection});

  final ValueChanged<int> onSelectSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BudgetsCard(onSelectSection: onSelectSection),
        const SizedBox(height: FocuslaneTokens.spacing12),
        _SubsCard(onSelectSection: onSelectSection),
      ],
    );
  }
}

class _BudgetsCard extends StatelessWidget {
  const _BudgetsCard({required this.onSelectSection});

  final ValueChanged<int> onSelectSection;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Presupuestos', style: TextStyle(fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () => onSelectSection(2),
                child: const Text('Abrir'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Budget>>(
            stream: BudgetService.I.watchAll(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text('Error: ${snap.error}');
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final budgets = snap.data ?? const [];
              if (budgets.isEmpty) return const Text('Sin presupuestos');
              return Column(
                children: budgets.take(3).map((b) {
                  return ListTile(
                    dense: true,
                    title: Text(b.name),
                    subtitle: Text(b.category.isEmpty ? 'General' : b.category),
                    trailing: Text(
                      '${b.limit.toStringAsFixed(2)} EUR',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/finance/budgets/form',
                      arguments: b,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SubsCard extends StatelessWidget {
  const _SubsCard({required this.onSelectSection});

  final ValueChanged<int> onSelectSection;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Suscripciones', style: TextStyle(fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () => onSelectSection(3),
                child: const Text('Abrir'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Subscription>>(
            stream: SubscriptionService.I.watchAll(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text('Error: ${snap.error}');
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final subs = snap.data ?? const [];
              if (subs.isEmpty) return const Text('Sin suscripciones');
              return Column(
                children: subs.take(3).map((s) {
                  final daysLeft = s.nextDue.difference(DateTime.now()).inDays;
                  return ListTile(
                    dense: true,
                    title: Text(s.title),
                    subtitle: Text(s.category ?? 'General'),
                    trailing: Text('En $daysLeft d'),
                    onTap: () => Navigator.pushNamed(context, '/finance/subscriptions/form', arguments: s),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _currency(double v) => '${v.toStringAsFixed(2)}€';



