import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/services/finance/transaction_service.dart';
import 'package:mi_dashboard_personal/services/finance/budget_service.dart';
import 'package:mi_dashboard_personal/services/finance/subscription_service.dart';
import 'package:mi_dashboard_personal/models/finance/transaction_model.dart';
import 'package:intl/intl.dart';

class FinanceHomeScreenV2 extends StatefulWidget {
  const FinanceHomeScreenV2({super.key});
  static const route = '/finance';

  @override
  State<FinanceHomeScreenV2> createState() => _FinanceHomeScreenV2State();
}

class _FinanceHomeScreenV2State extends State<FinanceHomeScreenV2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          FinanceUI.sliverAppBar(
            context,
            title: 'Finanzas',
            backgroundIcon: Icons.account_balance_wallet,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.pushNamed(context, '/finance/settings'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthlyKpis().animate().fadeIn(duration: 600.ms),
                  const SizedBox(height: 24),
                  _buildAlerts(),
                  const SizedBox(height: 24),
                  FinanceUI.sectionTitle(context, 'Acciones Rápidas'),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  FinanceUI.sectionTitle(context, 'Últimas transacciones'),
                  const SizedBox(height: 12),
                  _buildRecentTransactions(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/finance/transactions/form'),
        icon: const Icon(Icons.add),
        label: Text('Nueva', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMonthlyKpis() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final previousMonth = DateTime(now.year, now.month - 1, 1);

    return StreamBuilder<Map<String, double>>(
      stream: TransactionService.I.monthlyStats(currentMonth),
      builder: (context, currentSnap) {
        return StreamBuilder<Map<String, double>>(
          stream: TransactionService.I.monthlyStats(previousMonth),
          builder: (context, prevSnap) {
            final current = currentSnap.data ?? {'income': 0, 'expense': 0, 'balance': 0};
            final prev = prevSnap.data ?? {'income': 0, 'expense': 0, 'balance': 0};

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinanceUI.gradientCard(
                  context: context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMMM yyyy', 'es').format(now),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Balance del Mes',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${current['balance']!.toStringAsFixed(2)}€',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (prev['balance']! > 0)
                            _buildTrendIndicator(
                              current['balance']! - prev['balance']!,
                              prev['balance']!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FinanceUI.statCard(
                        context: context,
                        label: 'Ingresos',
                        value: '${current['income']!.toStringAsFixed(2)}€',
                        subtitle: _getTrend(current['income']!, prev['income']!),
                        icon: Icons.trending_up,
                        iconColor: FinanceUI.income,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FinanceUI.statCard(
                        context: context,
                        label: 'Gastos',
                        value: '${current['expense']!.toStringAsFixed(2)}€',
                        subtitle: _getTrend(current['expense']!, prev['expense']!),
                        icon: Icons.trending_down,
                        iconColor: FinanceUI.expense,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTrendIndicator(double diff, double base) {
    final percent = base > 0 ? (diff / base * 100) : 0;
    final isPositive = diff >= 0;
    final color = isPositive ? FinanceUI.income : FinanceUI.expense;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${percent.abs().toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getTrend(double current, double previous) {
    if (previous == 0) return 'vs mes anterior';
    final diff = current - previous;
    final percent = (diff / previous * 100).abs();
    final sign = diff >= 0 ? '+' : '-';
    return '$sign${percent.toStringAsFixed(0)}% vs anterior';
  }

  Widget _buildAlerts() {
    return StreamBuilder<List<BudgetWithProgress>>(
      stream: BudgetService.I.watchAllWithProgress(),
      builder: (context, budgetSnap) {
        return StreamBuilder(
          stream: SubscriptionService.I.upcomingPayments(daysAhead: 3),
          builder: (context, subSnap) {
            final budgets = budgetSnap.data ?? [];
            final subs = subSnap.data ?? [];

            final overBudget = budgets.where((b) => b.isOverBudget).toList();
            final upcoming = subs;

            if (overBudget.isEmpty && upcoming.isEmpty) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinanceUI.sectionTitle(context, 'Alertas', trailing: Icon(Icons.warning_amber, color: FinanceUI.warning)),
                ...overBudget.map(
                  (b) => Card(
                    color: FinanceUI.critical.withOpacity(0.1),
                    child: ListTile(
                      leading: Icon(Icons.warning, color: FinanceUI.critical),
                      title: Text('Presupuesto excedido: ${b.budget.name}'),
                      subtitle: Text('${b.spent.toStringAsFixed(2)}€ / ${b.budget.amount.toStringAsFixed(2)}€'),
                      trailing: Text(
                        '${(b.progress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: FinanceUI.critical),
                      ),
                      onTap: () => Navigator.pushNamed(context, '/finance/budgets'),
                    ),
                  ),
                ),
                ...upcoming.map(
                  (s) {
                    final daysLeft = s.nextDue.difference(DateTime.now()).inDays;
                    return Card(
                      color: FinanceUI.warning.withOpacity(0.1),
                      child: ListTile(
                        leading: Icon(Icons.notifications_active, color: FinanceUI.warning),
                        title: Text('Próximo pago: ${s.title}'),
                        subtitle: Text('Vence en $daysLeft días - ${s.amount.toStringAsFixed(2)}€'),
                        trailing: Text(
                          DateFormat('d MMM', 'es').format(s.nextDue),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        onTap: () => Navigator.pushNamed(context, '/finance/subscriptions'),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        FinanceUI.actionCard(
          context: context,
          title: 'Transacciones',
          subtitle: 'Ver todas',
          icon: Icons.receipt_long,
          onTap: () => Navigator.pushNamed(context, '/finance/transactions'),
        ),
        FinanceUI.actionCard(
          context: context,
          title: 'Presupuestos',
          subtitle: 'Gestionar',
          icon: Icons.savings_outlined,
          iconColor: Colors.green,
          onTap: () => Navigator.pushNamed(context, '/finance/budgets'),
        ),
        FinanceUI.actionCard(
          context: context,
          title: 'Suscripciones',
          subtitle: 'Administrar',
          icon: Icons.subscriptions_outlined,
          iconColor: Colors.purple,
          onTap: () => Navigator.pushNamed(context, '/finance/subscriptions'),
        ),
        FinanceUI.actionCard(
          context: context,
          title: 'Analíticas',
          subtitle: 'Ver gráficos',
          icon: Icons.bar_chart,
          iconColor: Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/finance/analytics'),
        ),
        FinanceUI.actionCard(
          context: context,
          title: 'Depósitos',
          subtitle: 'Cuentas y mov.',
          icon: Icons.savings,
          iconColor: Colors.teal,
          onTap: () => Navigator.pushNamed(context, '/finance/deposits'),
        ),
        FinanceUI.actionCard(
          context: context,
          title: 'Gastos variables',
          subtitle: 'Mes en curso',
          icon: Icons.receipt_long_outlined,
          iconColor: Colors.orange,
          onTap: () => Navigator.pushNamed(context, '/finance/variable-expenses'),
        ),
        FinanceUI.actionCard(
          context: context,
          title: 'Deudas',
          subtitle: 'Ver y pagar',
          icon: Icons.account_balance,
          iconColor: Colors.redAccent,
          onTap: () => Navigator.pushNamed(context, '/finance/debts'),
        ),
        FinanceUI.actionCard(
          context: context,
          title: 'Activos',
          subtitle: 'Patrimonio',
          icon: Icons.business_center,
          iconColor: Colors.indigo,
          onTap: () => Navigator.pushNamed(context, '/finance/assets'),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).scale();
  }

  Widget _buildRecentTransactions() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    return StreamBuilder<List<FinanceTransaction>>(
      stream: TransactionService.I.watch(from: currentMonth),
      builder: (context, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final data = s.data!;
        if (data.isEmpty) {
          return FinanceUI.emptyState(
            context,
            message: 'No hay transacciones este mes',
            icon: Icons.receipt_long_outlined,
            actionText: 'Nueva transacción',
            onAction: () => Navigator.pushNamed(context, '/finance/transactions/form'),
          );
        }

        return Column(
          children: data.take(10).map((t) {
            final sign = t.type == TxType.expense ? '-' : '+';
            final color = t.type == TxType.income ? FinanceUI.income : FinanceUI.expense;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    t.type == TxType.income ? Icons.trending_up : Icons.trending_down,
                    color: color,
                  ),
                ),
                title: Text(
                  t.title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${t.category ?? '—'} • ${DateFormat('d MMM, HH:mm', 'es').format(t.date)}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: Text(
                  '$sign${t.amount.toStringAsFixed(2)}€',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/finance/transactions/form',
                  arguments: t,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
