import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/transaction_model.dart';
import 'package:mi_dashboard_personal/services/finance/transaction_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreenV2 extends StatefulWidget {
  const AnalyticsScreenV2({super.key});
  static const route = '/finance/analytics';

  @override
  State<AnalyticsScreenV2> createState() => _AnalyticsScreenV2State();
}

class _AnalyticsScreenV2State extends State<AnalyticsScreenV2> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          FinanceUI.sliverAppBar(
            context,
            title: 'Análisis',
            backgroundIcon: Icons.analytics,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 24),
                  _buildIncomeExpenseChart(),
                  const SizedBox(height: 24),
                  _buildCategoryPieChart(),
                  const SizedBox(height: 24),
                  _buildCashflowLineChart(),
                  const SizedBox(height: 24),
                  _buildTopCategories(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                });
              },
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat('MMMM yyyy', 'es').format(_selectedMonth),
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: () => setState(() => _selectedMonth = DateTime.now()),
              tooltip: 'Hoy',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseChart() {
    return StreamBuilder<List<FinanceTransaction>>(
      stream: TransactionService.I.watch(
        from: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
        to: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59),
      ),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final txs = snap.data!;
        final income = txs.where((t) => t.type == TxType.income).fold<double>(0, (sum, t) => sum + t.amount);
        final expense = txs.where((t) => t.type == TxType.expense).fold<double>(0, (sum, t) => sum + t.amount);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinanceUI.sectionTitle(context, 'Ingresos vs Gastos', subtitle: 'Mes actual'),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: [income, expense].reduce((a, b) => a > b ? a : b) * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text('Ingresos');
                              if (value == 1) return const Text('Gastos');
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}€',
                                style: GoogleFonts.poppins(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: income,
                              color: FinanceUI.income,
                              width: 40,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: expense,
                              color: FinanceUI.expense,
                              width: 40,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Ingresos', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        Text(
                          '${income.toStringAsFixed(2)}€',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: FinanceUI.income,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Gastos', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        Text(
                          '${expense.toStringAsFixed(2)}€',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: FinanceUI.expense,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Balance', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        Text(
                          '${(income - expense).toStringAsFixed(2)}€',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: income - expense >= 0 ? FinanceUI.income : FinanceUI.expense,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCategoryPieChart() {
    return StreamBuilder<List<FinanceTransaction>>(
      stream: TransactionService.I.watch(
        from: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
        to: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59),
        type: TxType.expense,
      ),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final txs = snap.data!;
        final categoryTotals = <String, double>{};
        for (final tx in txs) {
          final cat = tx.category ?? 'Sin categoría';
          categoryTotals[cat] = (categoryTotals[cat] ?? 0) + tx.amount;
        }

        if (categoryTotals.isEmpty) return const SizedBox();

        final colors = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.teal,
          Colors.pink,
          Colors.amber,
        ];

        final sections = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final total = sections.fold<double>(0, (sum, e) => sum + e.value);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinanceUI.sectionTitle(context, 'Gastos por Categoría', subtitle: 'Distribución'),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: sections
                          .take(8)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final idx = entry.key;
                        final e = entry.value;
                        final pct = (e.value / total * 100);
                        return PieChartSectionData(
                          value: e.value,
                          title: '${pct.toStringAsFixed(0)}%',
                          color: colors[idx % colors.length],
                          radius: 100,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: sections.take(8).toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final e = entry.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colors[idx % colors.length],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${e.key}: ${e.value.toStringAsFixed(0)}€',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildCashflowLineChart() {
    return StreamBuilder<List<FinanceTransaction>>(
      stream: TransactionService.I.watch(
        from: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
        to: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59),
      ),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final txs = snap.data!;
        
        // Daily cashflow
        final dailyFlow = <int, double>{};
        for (var i = 1; i <= 31; i++) {
          dailyFlow[i] = 0;
        }
        
        double cumulative = 0;
        for (final tx in txs..sort((a, b) => a.date.compareTo(b.date))) {
          final day = tx.date.day;
          if (tx.type == TxType.income) {
            cumulative += tx.amount;
          } else {
            cumulative -= tx.amount;
          }
          dailyFlow[day] = cumulative;
        }

        final spots = dailyFlow.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinanceUI.sectionTitle(context, 'Flujo de Caja', subtitle: 'Acumulado diario'),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: GoogleFonts.poppins(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}€',
                                style: GoogleFonts.poppins(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildTopCategories() {
    return StreamBuilder<List<FinanceTransaction>>(
      stream: TransactionService.I.watch(
        from: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
        to: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59),
        type: TxType.expense,
      ),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final txs = snap.data!;
        final categoryTotals = <String, double>{};
        for (final tx in txs) {
          final cat = tx.category ?? 'Sin categoría';
          categoryTotals[cat] = (categoryTotals[cat] ?? 0) + tx.amount;
        }

        final top5 = (categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).toList();
        if (top5.isEmpty) return const SizedBox();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinanceUI.sectionTitle(context, 'Top 5 Categorías', subtitle: 'Mayor gasto'),
                const SizedBox(height: 12),
                ...top5.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cat = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: FinanceUI.expense.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.key, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              LinearProgressIndicator(
                                value: cat.value / top5.first.value,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation(FinanceUI.expense),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${cat.value.toStringAsFixed(2)}€',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: FinanceUI.expense,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }
}
