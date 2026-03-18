import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/calendar/controllers/calendar_controller.dart';
import 'package:mi_dashboard_personal/screens/calendar/models/calendar_models.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_item_widget.dart';

class CalendarYearView extends StatelessWidget {
  const CalendarYearView({
    super.key,
    required this.year,
    required this.stats,
    required this.monthLabel,
    required this.onSelectMonth,
    required this.prefs,
    required this.onTypeToggle,
    required this.onHighOnlyToggle,
  });

  final int year;
  final List<CalendarYearMonthStat> stats;
  final String Function(int month) monthLabel;
  final ValueChanged<int> onSelectMonth;
  final PlannerPrefs? prefs;
  final Future<void> Function(CalendarType type, bool value) onTypeToggle;
  final Future<void> Function(bool value) onHighOnlyToggle;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1400 ? 4 : (width >= 900 ? 3 : 2);

    return Column(
      children: [
        CalendarFilterChips(
          prefs: prefs,
          onTypeToggle: onTypeToggle,
          onHighOnlyToggle: onHighOnlyToggle,
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.36,
            ),
            itemCount: stats.length,
            itemBuilder: (ctx, i) {
              final stat = stats[i];
              return _YearMonthCard(
                monthLabel: monthLabel(stat.month),
                totalItems: stat.totalItems,
                highItems: stat.highItems,
                doneTasks: stat.doneTasks,
                onTap: () => onSelectMonth(stat.month),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _YearMonthCard extends StatelessWidget {
  const _YearMonthCard({
    required this.monthLabel,
    required this.totalItems,
    required this.highItems,
    required this.doneTasks,
    required this.onTap,
  });

  final String monthLabel;
  final int totalItems;
  final int highItems;
  final int doneTasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monthLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text('Eventos: $totalItems'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Alta: $highItems'),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Tasks completadas: $doneTasks',
                  style: TextStyle(color: colorScheme.primary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
