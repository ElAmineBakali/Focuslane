import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/calendar/models/calendar_models.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_item_widget.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.itemsFor,
    required this.humanDate,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onTapItem,
    required this.onDeletePlanner,
    required this.onCreateEvent,
    required this.prefs,
    required this.onTypeToggle,
    required this.onHighOnlyToggle,
    this.monthRowHeight = 42,
    this.dayListHeaderHeight = 48,
    this.dayListBodyHeight = 190,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<CalendarItem> Function(DateTime day) itemsFor;
  final String Function(DateTime day) humanDate;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final ValueChanged<CalendarItem> onTapItem;
  final ValueChanged<String> onDeletePlanner;
  final ValueChanged<DateTime> onCreateEvent;
  final PlannerPrefs? prefs;
  final Future<void> Function(CalendarType type, bool value) onTypeToggle;
  final Future<void> Function(bool value) onHighOnlyToggle;
  final double monthRowHeight;
  final double dayListHeaderHeight;
  final double dayListBodyHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedItems = itemsFor(selectedDay);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        CalendarFilterChips(
          prefs: prefs,
          onTypeToggle: onTypeToggle,
          onHighOnlyToggle: onHighOnlyToggle,
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: const CalendarScrollBehavior(),
            child: TableCalendar<CalendarItem>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: focusedDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(day, selectedDay),
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              rowHeight: monthRowHeight,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              eventLoader: itemsFor,
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: const BoxDecoration(),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                todayBuilder: (ctx, day, _) {
                  final cs = Theme.of(ctx).colorScheme;
                  return CalendarDayNumberRing(
                    day: day.day,
                    border: cs.primary,
                    textColor: cs.onSurface,
                  );
                },
                selectedBuilder: (ctx, day, _) {
                  final cs = Theme.of(ctx).colorScheme;
                  return CalendarDayNumberCell(
                    day: day.day,
                    bg: cs.primary,
                    fg: cs.onPrimary,
                  );
                },
                defaultBuilder: (ctx, day, _) {
                  final ymd = DateTime(day.year, day.month, day.day);
                  final isPast = ymd.isBefore(today);
                  if (!isPast) return Center(child: Text('${day.day}'));
                  final cs = Theme.of(ctx).colorScheme;
                  return CalendarDayNumberCell(
                    day: day.day,
                    bg: cs.surfaceContainerHighest.withValues(alpha: .45),
                    fg: cs.onSurface.withValues(alpha: .75),
                  );
                },
                outsideBuilder: (ctx, day, _) {
                  final ymd = DateTime(day.year, day.month, day.day);
                  final isPast = ymd.isBefore(today);
                  final cs = Theme.of(ctx).colorScheme;
                  if (isPast) {
                    return CalendarDayNumberCell(
                      day: day.day,
                      bg: cs.surfaceContainerHighest.withValues(alpha: .45),
                      fg: cs.onSurface.withValues(alpha: .75),
                    );
                  }
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: .7),
                      ),
                    ),
                  );
                },
                markerBuilder: (ctx, day, events) {
                  if (events.isEmpty) return null;
                  final high = events.any(
                    (event) => event.priority == CalendarPriority.high,
                  );
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          events.length.clamp(1, 3),
                          (_) => Container(
                            width: high ? 7 : 5,
                            height: high ? 7 : 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color:
                                  high
                                      ? Colors.redAccent
                                      : colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: dayListHeaderHeight + dayListBodyHeight,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                SizedBox(
                  height: dayListHeaderHeight,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Text(
                        'Eventos del ${humanDate(selectedDay)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: dayListBodyHeight,
                  child: CalendarDayItemList(
                    items: selectedItems,
                    onTap: onTapItem,
                    onDelete: onDeletePlanner,
                    scrollable: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 84),
      ],
    );
  }
}
