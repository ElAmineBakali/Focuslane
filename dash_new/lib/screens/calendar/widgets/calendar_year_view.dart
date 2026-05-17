import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/calendar/controllers/calendar_controller.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_item_widget.dart';

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
    this.usePageScroll = false,
  });

  final int year;
  final List<CalendarYearMonthStat> stats;
  final String Function(int month) monthLabel;
  final ValueChanged<int> onSelectMonth;
  final PlannerPrefs? prefs;
  final Future<void> Function(CalendarType type, bool value) onTypeToggle;
  final Future<void> Function(bool value) onHighOnlyToggle;
  final bool usePageScroll;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols =
        width < 520
            ? 1
            : width >= 1400
            ? 4
            : (width >= 900 ? 3 : 2);
    final grid = GridView.builder(
      shrinkWrap: usePageScroll,
      physics:
          usePageScroll
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: width < 520 ? 1.95 : 1.42,
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
    );

    if (usePageScroll) {
      return Column(
        children: [
          CalendarFilterChips(
            prefs: prefs,
            onTypeToggle: onTypeToggle,
            onHighOnlyToggle: onHighOnlyToggle,
          ),
          grid,
        ],
      );
    }

    return Column(
      children: [
        CalendarFilterChips(
          prefs: prefs,
          onTypeToggle: onTypeToggle,
          onHighOnlyToggle: onHighOnlyToggle,
        ),
        Expanded(child: grid),
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
    return FocusCard(
      onTap: onTap,
      elevated: false,
      backgroundColor: colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  monthLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FocusBadge(
                label: '$totalItems eventos',
                color: colorScheme.primary,
              ),
              FocusBadge(
                label: '$highItems alta prioridad',
                color: colorScheme.error,
              ),
            ],
          ),
          const Spacer(),
          FocusChip(
            label: '$doneTasks tareas completadas',
            icon: Icons.task_alt_rounded,
            color: colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}
