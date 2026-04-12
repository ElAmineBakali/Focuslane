import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:focuslane/navigation/app_routes.dart';

import '../../../design/ui/components/focus_badge.dart';
import '../../../design/ui/components/focus_empty_state.dart';
import '../../../design/ui/components/focus_module_header.dart';
import '../../../design/ui/tokens/focuslane_tokens.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

class FoodHistoryScreen extends StatefulWidget {
  const FoodHistoryScreen({super.key, required this.svc});

  final FoodFirestoreService svc;

  @override
  State<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends State<FoodHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _daysRange = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _FoodHistoryAppBar(controller: _tabController),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTrendsTab(), _buildShoppingHistoryTab()],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FocusSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRangeChip(7, '7 dias'),
              _buildRangeChip(30, '30 dias'),
              _buildRangeChip(90, '90 dias'),
            ],
          ),
          const SizedBox(height: FocusSpacing.md),
          StreamBuilder<List<DailyIntakeDoc>>(
            stream: widget.svc.streamLastNDays(_daysRange),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final days = snap.data ?? const <DailyIntakeDoc>[];
              if (days.isEmpty) {
                return const FocusEmptyState(
                  icon: Icons.show_chart,
                  message: 'Sin datos en este rango',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCaloriesChart(days),
                  const SizedBox(height: FocusSpacing.md),
                  _buildProteinChart(days),
                  const SizedBox(height: FocusSpacing.md),
                  _buildWaterChart(days),
                  const SizedBox(height: FocusSpacing.md),
                  _buildSummaryStats(days),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(int days, String label) {
    final isSelected = _daysRange == days;
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _daysRange = days),
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : FocusColors.grey700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCaloriesChart(List<DailyIntakeDoc> days) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        side: BorderSide(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FocusSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: FocusColors.food,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: FocusSpacing.md),
                Text('Calorias', style: FocusTypography.heading3(context)),
              ],
            ),
            const SizedBox(height: FocusSpacing.md),
            SizedBox(
              height: 140,
              child: LineChart(
                _buildLineChartData(
                  days,
                  (d) => d.totals['kcal'] ?? 0,
                  FocusColors.food,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildProteinChart(List<DailyIntakeDoc> days) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        side: BorderSide(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FocusSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: FocusSpacing.md),
                Text('Proteinas', style: FocusTypography.heading3(context)),
              ],
            ),
            const SizedBox(height: FocusSpacing.md),
            SizedBox(
              height: 140,
              child: LineChart(
                _buildLineChartData(
                  days,
                  (d) => d.totals['protein'] ?? 0,
                  Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildWaterChart(List<DailyIntakeDoc> days) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        side: BorderSide(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FocusSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: FocusSpacing.md),
                Text('Hidratacion', style: FocusTypography.heading3(context)),
              ],
            ),
            const SizedBox(height: FocusSpacing.md),
            SizedBox(
              height: 140,
              child: BarChart(
                _buildBarChartData(days, (d) => d.waterMl.toDouble(), Colors.blue),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildSummaryStats(List<DailyIntakeDoc> days) {
    final avgKcal =
        days.map((d) => d.totals['kcal'] ?? 0).reduce((a, b) => a + b) /
        days.length;
    final avgProtein =
        days.map((d) => d.totals['protein'] ?? 0).reduce((a, b) => a + b) /
        days.length;
    final avgWater =
        days.map((d) => d.waterMl).reduce((a, b) => a + b) / days.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Promedios', style: FocusTypography.heading3(context)),
        const SizedBox(height: FocusSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Calorias',
                value: avgKcal.toStringAsFixed(0),
                subtitle: 'kcal promedio',
                icon: Icons.local_fire_department,
                color: FocusColors.food,
              ),
            ),
            const SizedBox(width: FocusSpacing.md),
            Expanded(
              child: _StatCard(
                label: 'Proteinas',
                value: avgProtein.toStringAsFixed(1),
                subtitle: 'g promedio',
                icon: Icons.fitness_center,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: FocusSpacing.md),
        _StatCard(
          label: 'Agua',
          value: avgWater.toStringAsFixed(0),
          subtitle: 'ml promedio',
          icon: Icons.water_drop,
          color: Colors.blue,
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(
    List<DailyIntakeDoc> days,
    double Function(DailyIntakeDoc) valueGetter,
    Color color,
  ) {
    final spots = days
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), valueGetter(e.value)))
        .toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 500,
        getDrawingHorizontalLine: (_) {
          return FlLine(color: FocusColors.grey300, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, _) {
              return Text(
                value.toInt().toString(),
                style: FocusTypography.caption(context),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, _) {
              final index = value.toInt();
              if (index < 0 || index >= days.length) return const SizedBox();

              if (_daysRange == 7 || index % 5 == 0) {
                final day = DateTime.parse(days[index].id);
                return Text(
                  '${day.day}/${day.month}',
                  style: FocusTypography.caption(context),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.black87,
          getTooltipItems: (lineSpots) {
            return lineSpots
                .map(
                  (spot) => LineTooltipItem(
                    spot.y.toStringAsFixed(1),
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                  ),
                )
                .toList();
          },
        ),
      ),
    );
  }

  BarChartData _buildBarChartData(
    List<DailyIntakeDoc> days,
    double Function(DailyIntakeDoc) valueGetter,
    Color color,
  ) {
    final barGroups = days
        .asMap()
        .entries
        .map(
          (e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: valueGetter(e.value),
                color: color,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          ),
        )
        .toList();

    return BarChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, _) {
              return Text(
                value.toInt().toString(),
                style: FocusTypography.caption(context),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, _) {
              final index = value.toInt();
              if (index < 0 || index >= days.length) return const SizedBox();
              if (_daysRange == 7 || index % 5 == 0) {
                final day = DateTime.parse(days[index].id);
                return Text(
                  '${day.day}/${day.month}',
                  style: FocusTypography.caption(context),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.black87,
          getTooltipItem: (_, __, rod, ___) {
            return BarTooltipItem(
              '${rod.toY.toInt()} ml',
              TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShoppingHistoryTab() {
    return StreamBuilder<List<CompletedShoppingList>>(
      stream: Stream.value(const []),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final completed = snap.data ?? const <CompletedShoppingList>[];
        if (completed.isEmpty) {
          return const FocusEmptyState(
            icon: Icons.shopping_bag,
            message:
                'Sin compras completadas\nCompleta una lista de compras para ver el historial',
          );
        }

        final grouped = <String, List<CompletedShoppingList>>{};
        for (final c in completed) {
          final month = c.completedAt.toIso8601String().substring(0, 7);
          grouped.putIfAbsent(month, () => <CompletedShoppingList>[]).add(c);
        }

        final months = grouped.keys.toList();
        return ListView.builder(
          padding: const EdgeInsets.all(FocusSpacing.lg),
          itemCount: months.length,
          itemBuilder: (_, i) {
            final month = months[i];
            return _buildMonthGroup(context, month, grouped[month]!);
          },
        );
      },
    );
  }

  Widget _buildMonthGroup(
    BuildContext context,
    String month,
    List<CompletedShoppingList> items,
  ) {
    final totalSpent =
        items.map((c) => c.totalSpent ?? 0).reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: FocusSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatMonth(month), style: FocusTypography.heading3(context)),
              if (totalSpent > 0)
                FocusBadge(
                  text: '\$${totalSpent.toStringAsFixed(2)}',
                  color: FocusColors.success,
                ),
            ],
          ),
        ),
        ...items.map((c) => _buildCompletedCard(context, c)),
        const SizedBox(height: FocusSpacing.lg),
      ],
    );
  }

  Widget _buildCompletedCard(
    BuildContext context,
    CompletedShoppingList completed,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: FocusSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
        side: BorderSide(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary),
        ),
        title: Text(
          completed.plannerId ?? 'Compra',
          style: FocusTypography.heading4(context),
        ),
        subtitle: Text(_formatDate(completed.completedAt), style: FocusTypography.caption(context)),
        trailing: completed.totalSpent != null
            ? Text(
                '\$${completed.totalSpent!.toStringAsFixed(2)}',
                style: FocusTypography.label(context).copyWith(
                  color: FocusColors.success,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        children: completed.items
            .map(
              (item) => ListTile(
                dense: true,
                leading: Icon(
                  item.checked ? Icons.check_box : Icons.check_box_outline_blank,
                  color: item.checked ? Colors.green : FocusColors.grey600,
                  size: 20,
                ),
                title: Text(
                  item.name,
                  style: TextStyle(
                    decoration: item.checked ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: Text(
                  '${item.qty} ${item.unit.name}',
                  style: FocusTypography.caption(context),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _formatMonth(String month) {
    final date = DateTime.parse('$month-01');
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FoodHistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FoodHistoryAppBar({required this.controller});

  final TabController controller;

  @override
  Size get preferredSize => const Size.fromHeight(48 + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FocusModuleHeader(
          title: 'Historial',
          leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
          backRouteName: AppRoutes.foodDashboard,
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: FocuslaneTokens.dividerColor(context),
                width: FocuslaneTokens.dividerW,
              ),
            ),
          ),
          child: TabBar(
            controller: controller,
            labelStyle: theme.textTheme.bodySmall,
            unselectedLabelStyle: theme.textTheme.bodySmall,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: const [
              Tab(text: 'Tendencias', icon: Icon(Icons.trending_up, size: 18)),
              Tab(text: 'Compras', icon: Icon(Icons.shopping_bag, size: 18)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
        side: BorderSide(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FocusSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(label, style: FocusTypography.label(context)),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: FocusTypography.heading2(context).copyWith(
                color: cs.onSurface,
              ),
            ),
            Text(subtitle, style: FocusTypography.caption(context)),
          ],
        ),
      ),
    );
  }
}
