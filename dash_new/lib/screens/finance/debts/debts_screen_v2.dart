import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/loan_model.dart';
import 'package:mi_dashboard_personal/services/finance/debt_service_loans.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DebtsScreenV2 extends StatelessWidget {
  const DebtsScreenV2({super.key});
  static const route = '/finance/debts';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FinanceScreenBody(
        slivers: [
          const FinanceHeaderLarge(
            title: 'Deudas',
            icon: Icons.account_balance_outlined,
          ),
          StreamBuilder<List<Debt>>(
            stream: DebtService.I.watchAll(),
            builder: (context, s) {
              final debts = s.data ?? [];
              final totalDebt = debts.fold<double>(0, (sum, d) => sum + d.balance);
              
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deuda Total',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${totalDebt.toStringAsFixed(2)}€',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: FinanceUI.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            sliver: StreamBuilder<List<Debt>>(
              stream: DebtService.I.watchAll(),
              builder: (context, s) {
                final debts = s.data ?? [];
                if (debts.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('Sin deudas', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final debt = debts[i];
                      final progress = 1 - (debt.balance / debt.originalAmount);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/finance/debts/form',
                            arguments: debt,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            debt.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            debt.creditor,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${debt.balance.toStringAsFixed(2)}€',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: FinanceUI.expense,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    color: progress > 0.7 ? FinanceUI.income : FinanceUI.expense,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}% pagado',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      'Original: ${debt.originalAmount.toStringAsFixed(2)}€',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
                    },
                    childCount: debts.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FinanceFab(
        onPressed: () => Navigator.pushNamed(context, '/finance/debts/form'),
        label: 'Nueva Deuda',
        icon: Icons.add,
      ),
    );
  }
}
