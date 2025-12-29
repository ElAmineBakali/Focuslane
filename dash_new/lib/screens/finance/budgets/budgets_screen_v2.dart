import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/budget_model.dart';
import 'package:mi_dashboard_personal/services/finance/budget_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BudgetsScreenV2 extends StatelessWidget {
  const BudgetsScreenV2({super.key});
  static const route = '/finance/budgets';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FinanceScreenBody(
        slivers: [
          const FinanceHeaderLarge(
            title: 'Presupuestos',
            icon: Icons.savings_outlined,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: StreamBuilder<List<Budget>>(
                stream: BudgetService.I.watchAll(),
                builder: (context, s) {
                  final budgets = s.data ?? [];
                  if (budgets.isEmpty) {
                    return const Center(child: Text('Sin presupuestos'));
                  }
                  return Column(
                    children: budgets
                        .map((b) => _BudgetCard(budget: b))
                        .toList()
                        .animate(interval: 100.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.15, end: 0),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FinanceFab(
        onPressed: () => Navigator.pushNamed(context, '/finance/budgets/edit'),
        label: 'Crear',
        icon: Icons.add,
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: BudgetService.I.getSpentForBudget(budget),
      builder: (context, s) {
        final spent = s.data ?? 0;
        final progress = spent / budget.limit;
        final color =
            progress > budget.thresholdPercent
                ? Colors.red
                : progress > 0.6
                ? Colors.orange
                : Colors.green;

        return FinanceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.category, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${budget.period.name} · ${budget.limit.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${spent.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(fontSize: 12, color: color),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.15),
                color: color,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        );
      },
    );
  }
}
