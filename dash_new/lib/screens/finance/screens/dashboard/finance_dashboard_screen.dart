import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/finance/models/subscription_model.dart';
import 'package:focuslane/screens/finance/models/transaction_model.dart';
import 'package:focuslane/screens/finance/services/finance_category_labels.dart';
import 'package:focuslane/screens/finance/services/subscription_service.dart';
import 'package:focuslane/screens/finance/services/transaction_service.dart';

class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({super.key, required this.onSelectSection});

  final ValueChanged<int> onSelectSection;

  static const route = '/finance';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    return StreamBuilder<List<FinanceTransaction>>(
      stream: TransactionService.I.watch(from: monthStart),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PageContainer(
            child: FocusEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudo cargar el panel de finanzas',
              subtitle:
                  'Si Firestore solicita un indice, la pantalla seguira protegida y este error quedara controlado: ${snapshot.error}',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data ?? const <FinanceTransaction>[];
        double income = 0;
        double expense = 0;
        for (final tx in transactions) {
          if (tx.type == TxType.income) income += tx.amount;
          if (tx.type == TxType.expense) expense += tx.amount;
        }
        final balance = income - expense;
        final savingsRate = income == 0 ? 0.0 : balance / income;

        return _FinanceDashboardContent(
          transactions: transactions,
          income: income,
          expense: expense,
          balance: balance,
          savingsRate: savingsRate,
          onSelectSection: onSelectSection,
        );
      },
    );
  }
}

class _FinanceDashboardContent extends StatelessWidget {
  const _FinanceDashboardContent({
    required this.transactions,
    required this.income,
    required this.expense,
    required this.balance,
    required this.savingsRate,
    required this.onSelectSection,
  });

  final List<FinanceTransaction> transactions;
  final double income;
  final double expense;
  final double balance;
  final double savingsRate;
  final ValueChanged<int> onSelectSection;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FinanceHero(
              balance: balance,
              transactionCount: transactions.length,
              onNewTransaction:
                  () => Navigator.pushNamed(
                    context,
                    '/finance/transactions/form',
                  ),
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 220,
              spacing: 16,
              children: [
                FocusStatCard(
                  title: 'Balance mensual',
                  value: _currency(balance),
                  subtitle: 'Ingresos menos gastos',
                  icon: Icons.account_balance_wallet_outlined,
                  color:
                      balance >= 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                  onTap: () => onSelectSection(1),
                ),
                FocusStatCard(
                  title: 'Ingresos',
                  value: _currency(income),
                  subtitle: 'Mes actual',
                  icon: Icons.trending_up_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => onSelectSection(1),
                ),
                FocusStatCard(
                  title: 'Gastos',
                  value: _currency(expense),
                  subtitle: 'Mes actual',
                  icon: Icons.trending_down_rounded,
                  color: Theme.of(context).colorScheme.error,
                  onTap: () => onSelectSection(1),
                ),
                FocusStatCard(
                  title: 'Tasa de ahorro',
                  value:
                      income == 0
                          ? '0%'
                          : '${(savingsRate * 100).toStringAsFixed(1)}%',
                  subtitle: 'Sobre ingresos',
                  icon: Icons.savings_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => onSelectSection(5),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 940;
                final recent = _RecentTransactionsCard(
                  transactions: transactions,
                  onOpenAll: () => onSelectSection(1),
                );
                final subs = _SubscriptionsPreview(
                  onOpenAll: () => onSelectSection(2),
                );
                if (!wide) {
                  return Column(
                    children: [recent, const SizedBox(height: 16), subs],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: recent),
                      const SizedBox(width: 16),
                      Expanded(child: subs),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceHero extends StatelessWidget {
  const _FinanceHero({
    required this.balance,
    required this.transactionCount,
    required this.onNewTransaction,
  });

  final double balance;
  final int transactionCount;
  final VoidCallback onNewTransaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel financiero',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Resumen protegido de movimientos, suscripciones y clasificación.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(
                    label: '$transactionCount transacciones',
                    color: scheme.primary,
                  ),
                  FocusBadge(
                    label:
                        balance >= 0 ? 'Balance positivo' : 'Balance negativo',
                    color: balance >= 0 ? scheme.secondary : scheme.error,
                  ),
                ],
              ),
            ],
          );
          final action = FocusPrimaryButton(
            label: 'Nueva transacción',
            icon: Icons.add_rounded,
            onPressed: onNewTransaction,
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
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({
    required this.transactions,
    required this.onOpenAll,
  });

  final List<FinanceTransaction> transactions;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final recent = transactions.take(6).toList(growable: false);

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Últimas transacciones',
            subtitle: 'Movimiento mensual reciente',
            icon: Icons.receipt_long_rounded,
            trailing: TextButton(
              onPressed: onOpenAll,
              child: const Text('Ver todas'),
            ),
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            const FocusEmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No hay transacciones este mes',
              subtitle: 'Crea una transacción para empezar el resumen.',
            )
          else
            Column(
              children: [
                for (final tx in recent) _TransactionPreviewTile(tx: tx),
              ],
            ),
        ],
      ),
    );
  }
}

class _TransactionPreviewTile extends StatelessWidget {
  const _TransactionPreviewTile({required this.tx});

  final FinanceTransaction tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIncome = tx.type == TxType.income;
    final tone = isIncome ? scheme.primary : scheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap:
            () => Navigator.pushNamed(
              context,
              '/finance/transactions/form',
              arguments: tx,
            ),
        child: Row(
          children: [
            Icon(iconForCategory(tx.category), color: tone, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${labelForCategory(tx.category)} · ${DateFormat('d MMM', 'es_ES').format(tx.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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

class _SubscriptionsPreview extends StatelessWidget {
  const _SubscriptionsPreview({required this.onOpenAll});

  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Suscripciones',
            subtitle: 'Próximos pagos guardados',
            icon: Icons.subscriptions_rounded,
            trailing: TextButton(
              onPressed: onOpenAll,
              child: const Text('Abrir'),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Subscription>>(
            stream: SubscriptionService.I.watchAll(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return FocusEmptyState(
                  icon: Icons.error_outline_rounded,
                  message: 'No se pudieron cargar las suscripciones',
                  subtitle: '${snapshot.error}',
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final subs = snapshot.data ?? const <Subscription>[];
              if (subs.isEmpty) {
                return const FocusEmptyState(
                  icon: Icons.subscriptions_outlined,
                  message: 'Sin suscripciones',
                  subtitle: 'Los pagos recurrentes aparecerán aquí.',
                );
              }
              return Column(
                children: [
                  for (final sub in subs.take(4))
                    _SubscriptionPreviewTile(sub: sub),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SubscriptionPreviewTile extends StatelessWidget {
  const _SubscriptionPreviewTile({required this.sub});

  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysLeft = sub.nextDue.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap:
            () => Navigator.pushNamed(
              context,
              '/finance/subscriptions/form',
              arguments: sub,
            ),
        child: Row(
          children: [
            Icon(
              iconForCategory(sub.category),
              color: scheme.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    labelForCategory(sub.category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FocusBadge(label: 'En $daysLeft d', color: scheme.secondary),
          ],
        ),
      ),
    );
  }
}

String _currency(double value) => '${value.toStringAsFixed(2)} EUR';
