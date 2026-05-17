import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_item_widget.dart';
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
    this.usePageScroll = false,
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
  final bool usePageScroll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedItems = itemsFor(selectedDay);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final calendar = ScrollConfiguration(
      behavior: const CalendarScrollBehavior(),
      child: TableCalendar<CalendarItem>(
        firstDay: DateTime(2020),
        lastDay: DateTime(2100),
        focusedDay: focusedDay,
        locale: 'es_ES',
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(day, selectedDay),
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        rowHeight: monthRowHeight,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          titleTextStyle:
              Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ) ??
              const TextStyle(fontWeight: FontWeight.w900),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle:
              Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ) ??
              const TextStyle(fontWeight: FontWeight.w800),
          weekendStyle:
              Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ) ??
              const TextStyle(fontWeight: FontWeight.w800),
        ),
        eventLoader: itemsFor,
        calendarStyle: CalendarStyle(
          markerDecoration: BoxDecoration(
            color: colorScheme.secondary,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: true,
          cellMargin: const EdgeInsets.all(5),
          weekendTextStyle: TextStyle(color: colorScheme.onSurface),
          defaultTextStyle: TextStyle(color: colorScheme.onSurface),
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
                style: TextStyle(color: cs.onSurface.withValues(alpha: .7)),
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
                        color: high ? Colors.redAccent : colorScheme.secondary,
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
    );

    final monthCard = FocusCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: colorScheme.surfaceContainerLowest,
      child: calendar,
    );

    Widget dayHeader() {
      return SizedBox(
        height: dayListHeaderHeight,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.event_note_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Eventos del ${humanDate(selectedDay)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FocusBadge(
              label: '${selectedItems.length}',
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 12),
          ],
        ),
      );
    }

    final dayPanel = FocusCard(
      padding: EdgeInsets.zero,
      backgroundColor: colorScheme.surfaceContainerLowest,
      child: Column(
        mainAxisSize: usePageScroll ? MainAxisSize.min : MainAxisSize.max,
        children: [
          dayHeader(),
          const Divider(height: 1),
          if (usePageScroll)
            CalendarDayItemList(
              items: selectedItems,
              onTap: onTapItem,
              onDelete: onDeletePlanner,
            )
          else
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
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 760;

        if (usePageScroll) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CalendarFilterChips(
                prefs: prefs,
                onTypeToggle: onTypeToggle,
                onHighOnlyToggle: onHighOnlyToggle,
              ),
              const SizedBox(height: 12),
              monthCard,
              const SizedBox(height: 12),
              dayPanel,
            ],
          );
        }

        if (isCompactHeight) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              CalendarFilterChips(
                prefs: prefs,
                onTypeToggle: onTypeToggle,
                onHighOnlyToggle: onHighOnlyToggle,
              ),
              const SizedBox(height: 12),
              monthCard,
              const SizedBox(height: 12),
              SizedBox(
                height: dayListHeaderHeight + dayListBodyHeight + 1,
                child: dayPanel,
              ),
              SizedBox(height: 16 + bottomPadding),
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
            const SizedBox(height: 12),
            Expanded(child: monthCard),
            const SizedBox(height: 12),
            SizedBox(
              height: dayListHeaderHeight + dayListBodyHeight + 1,
              child: dayPanel,
            ),
            SizedBox(height: 16 + bottomPadding),
          ],
        );
      },
    );
  }
}
