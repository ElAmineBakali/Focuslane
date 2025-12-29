import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/services/finance/transaction_service.dart';
import 'package:mi_dashboard_personal/models/finance/transaction_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class FinanceAnalyticsScreenV2 extends StatelessWidget {
  const FinanceAnalyticsScreenV2({super.key});
  static const route = '/finance/analytics';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FinanceScreenBody(
        slivers: [
          const FinanceHeaderLarge(
            title: 'Analíticas',
            icon: Icons.analytics_outlined,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                children: [
                  Text(
                    'Resumen mensual',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<FinanceTransaction>>(
                    stream: TransactionService.I.watch(),
                    builder: (context, s) {
                      final txs = s.data ?? [];
                      double income = 0, expense = 0;
                      for (final t in txs) {
                        if (t.type == TxType.income) income += t.amount;
                        if (t.type == TxType.expense) expense += t.amount;
                      }
                      final balance = income - expense;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FinanceKpiCard(
                                  title: 'Ingresos',
                                  value: income.toStringAsFixed(2),
                                  icon: Icons.trending_up,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FinanceKpiCard(
                                  title: 'Gastos',
                                  value: expense.toStringAsFixed(2),
                                  icon: Icons.trending_down,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FinanceKpiCard(
                            title: 'Balance',
                            value: balance.toStringAsFixed(2),
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          const SizedBox(height: 24),
                          _buildPieChart(income, expense),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(double income, double expense) {
    final total = income + expense;
    if (total == 0) return const Text('Sin datos');

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: income,
              title: 'Ingresos\n${(income / total * 100).toStringAsFixed(0)}%',
              color: Colors.green,
              radius: 80,
              titleStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: expense,
              title: 'Gastos\n${(expense / total * 100).toStringAsFixed(0)}%',
              color: Colors.red,
              radius: 80,
              titleStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
