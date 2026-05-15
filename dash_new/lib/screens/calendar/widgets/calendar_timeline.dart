import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_item_widget.dart';

class CalendarWeekHeader extends StatelessWidget {
  const CalendarWeekHeader({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.dayWidth,
    required this.timeAxisWidth,
    required this.weekdayShort,
    required this.humanDate,
    required this.onSelectDay,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final double dayWidth;
  final double timeAxisWidth;
  final String Function(int weekday) weekdayShort;
  final String Function(DateTime day) humanDate;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = timeAxisWidth + (dayWidth * days.length);

    return ScrollConfiguration(
      behavior: const CalendarScrollBehavior(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Row(
            children: [
              SizedBox(
                width: timeAxisWidth,
                child: const Center(child: Text('Hora')),
              ),
              ...days.map((day) {
                final isSelected = DateUtils.isSameDay(day, selectedDay);
                return InkWell(
                  onTap: () => onSelectDay(day),
                  child: Container(
                    width: dayWidth,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? colorScheme.primary.withValues(alpha: .10)
                              : null,
                      border: Border(
                        right: BorderSide(
                          color: colorScheme.outline.withValues(alpha: .35),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekdayShort(day.weekday),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(humanDate(day)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarAllDayRow extends StatelessWidget {
  const CalendarAllDayRow({
    super.key,
    required this.days,
    required this.dayWidth,
    required this.timeAxisWidth,
    required this.itemsFor,
    required this.canMoveItem,
    required this.onMoveItemToDay,
    required this.onTapItem,
    required this.onCreateEvent,
  });

  final List<DateTime> days;
  final double dayWidth;
  final double timeAxisWidth;
  final List<CalendarItem> Function(DateTime day) itemsFor;
  final bool Function(CalendarItem item) canMoveItem;
  final Future<void> Function(CalendarItem item, DateTime day) onMoveItemToDay;
  final ValueChanged<CalendarItem> onTapItem;
  final ValueChanged<DateTime> onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = timeAxisWidth + (dayWidth * days.length);

    return ScrollConfiguration(
      behavior: const CalendarScrollBehavior(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: timeAxisWidth,
                height: 78,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 10),
                child: const Text('Todo el día'),
              ),
              ...days.map((day) {
                final allDay =
                    itemsFor(day)
                      ..retainWhere((event) => event.isAllDay)
                      ..sort((a, b) => a.startAt.compareTo(b.startAt));

                return DragTarget<CalendarItem>(
                  onWillAcceptWithDetails: (data) => canMoveItem(data.data),
                  onAcceptWithDetails:
                      (data) => onMoveItemToDay(data.data, day),
                  builder: (ctx, candidates, _) {
                    final active = candidates.isNotEmpty;
                    return Container(
                      width: dayWidth,
                      height: 78,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            active
                                ? colorScheme.primary.withValues(alpha: .08)
                                : null,
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.outline.withValues(alpha: .35),
                          ),
                          right: BorderSide(
                            color: colorScheme.outline.withValues(alpha: .35),
                          ),
                          bottom: BorderSide(
                            color: colorScheme.outline.withValues(alpha: .35),
                          ),
                        ),
                      ),
                      child:
                          allDay.isEmpty
                              ? InkWell(
                                onTap: () => onCreateEvent(day),
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Tocar para crear',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: allDay.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(width: 6),
                                itemBuilder: (_, index) {
                                  final item = allDay[index];
                                  return CalendarAllDayItemChip(
                                    item: item,
                                    onTap: () => onTapItem(item),
                                    canMove: canMoveItem(item),
                                  );
                                },
                              ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarTimelineSurface extends StatelessWidget {
  const CalendarTimelineSurface({
    super.key,
    required this.days,
    required this.dayWidth,
    required this.timeAxisWidth,
    required this.timelineStartHour,
    required this.timelineEndHour,
    required this.timelineHeight,
    required this.slotHeight,
    required this.itemsFor,
    required this.topFor,
    required this.durationMinutes,
    required this.canMoveItem,
    required this.canResizeItem,
    required this.onMoveItemToSlot,
    required this.onResizeItem,
    required this.onTapItem,
    required this.onCreateEvent,
    this.onPointerSignal,
    this.onScaleUpdate,
  });

  final List<DateTime> days;
  final double dayWidth;
  final double timeAxisWidth;
  final int timelineStartHour;
  final int timelineEndHour;
  final double timelineHeight;
  final double slotHeight;
  final List<CalendarItem> Function(DateTime day) itemsFor;
  final double Function(DateTime time) topFor;
  final int Function(CalendarItem item) durationMinutes;
  final bool Function(CalendarItem item) canMoveItem;
  final bool Function(CalendarItem item) canResizeItem;
  final Future<void> Function(CalendarItem item, DateTime slot)
  onMoveItemToSlot;
  final Future<void> Function(CalendarItem item, int deltaMinutes) onResizeItem;
  final ValueChanged<CalendarItem> onTapItem;
  final ValueChanged<DateTime> onCreateEvent;
  final ValueChanged<PointerSignalEvent>? onPointerSignal;
  final GestureScaleUpdateCallback? onScaleUpdate;

  @override
  Widget build(BuildContext context) {
    final totalWidth = timeAxisWidth + (dayWidth * days.length);

    return ScrollConfiguration(
      behavior: const CalendarScrollBehavior(),
      child: Listener(
        onPointerSignal: onPointerSignal,
        child: GestureDetector(
          onScaleUpdate: onScaleUpdate,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CalendarTimeAxis(
                        timeAxisWidth: timeAxisWidth,
                        timelineHeight: timelineHeight,
                        timelineStartHour: timelineStartHour,
                        timelineEndHour: timelineEndHour,
                        slotHeight: slotHeight,
                      ),
                      ...days.map(
                        (day) => _CalendarTimelineDayColumn(
                          day: day,
                          dayWidth: dayWidth,
                          timelineHeight: timelineHeight,
                          timelineStartHour: timelineStartHour,
                          timelineEndHour: timelineEndHour,
                          slotHeight: slotHeight,
                          itemsFor: itemsFor,
                          topFor: topFor,
                          durationMinutes: durationMinutes,
                          canMoveItem: canMoveItem,
                          canResizeItem: canResizeItem,
                          onMoveItemToSlot: onMoveItemToSlot,
                          onResizeItem: onResizeItem,
                          onTapItem: onTapItem,
                          onCreateEvent: onCreateEvent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarTimeAxis extends StatelessWidget {
  const _CalendarTimeAxis({
    required this.timeAxisWidth,
    required this.timelineHeight,
    required this.timelineStartHour,
    required this.timelineEndHour,
    required this.slotHeight,
  });

  final double timeAxisWidth;
  final double timelineHeight;
  final int timelineStartHour;
  final int timelineEndHour;
  final double slotHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hourCount = timelineEndHour - timelineStartHour + 1;

    return SizedBox(
      width: timeAxisWidth,
      height: timelineHeight,
      child: Column(
        children: List.generate(hourCount, (index) {
          final hour = timelineStartHour + index;
          return Container(
            height: slotHeight,
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: .35),
                ),
                right: BorderSide(
                  color: colorScheme.outline.withValues(alpha: .35),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CalendarTimelineDayColumn extends StatelessWidget {
  const _CalendarTimelineDayColumn({
    required this.day,
    required this.dayWidth,
    required this.timelineHeight,
    required this.timelineStartHour,
    required this.timelineEndHour,
    required this.slotHeight,
    required this.itemsFor,
    required this.topFor,
    required this.durationMinutes,
    required this.canMoveItem,
    required this.canResizeItem,
    required this.onMoveItemToSlot,
    required this.onResizeItem,
    required this.onTapItem,
    required this.onCreateEvent,
  });

  final DateTime day;
  final double dayWidth;
  final double timelineHeight;
  final int timelineStartHour;
  final int timelineEndHour;
  final double slotHeight;
  final List<CalendarItem> Function(DateTime day) itemsFor;
  final double Function(DateTime time) topFor;
  final int Function(CalendarItem item) durationMinutes;
  final bool Function(CalendarItem item) canMoveItem;
  final bool Function(CalendarItem item) canResizeItem;
  final Future<void> Function(CalendarItem item, DateTime slot)
  onMoveItemToSlot;
  final Future<void> Function(CalendarItem item, int deltaMinutes) onResizeItem;
  final ValueChanged<CalendarItem> onTapItem;
  final ValueChanged<DateTime> onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hourCount = timelineEndHour - timelineStartHour + 1;

    final timed =
        itemsFor(day)
          ..retainWhere((event) => !event.isAllDay)
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return SizedBox(
      width: dayWidth,
      height: timelineHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: List.generate(hourCount, (index) {
                final hour = timelineStartHour + index;
                final slot = DateTime(day.year, day.month, day.day, hour);
                return DragTarget<CalendarItem>(
                  onWillAcceptWithDetails: (data) => canMoveItem(data.data),
                  onAcceptWithDetails:
                      (data) => onMoveItemToSlot(data.data, slot),
                  builder: (ctx, candidates, _) {
                    final active = candidates.isNotEmpty;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onCreateEvent(slot),
                      child: Container(
                        height: slotHeight,
                        decoration: BoxDecoration(
                          color:
                              active
                                  ? colorScheme.primary.withValues(alpha: .09)
                                  : null,
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.outline.withValues(alpha: .35),
                            ),
                            right: BorderSide(
                              color: colorScheme.outline.withValues(alpha: .35),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          ...timed.map((item) {
            final top = topFor(item.startAt);
            final height = math.max(
              30.0,
              (durationMinutes(item) / 60.0) * slotHeight - 4,
            );

            if (top > timelineHeight || (top + height) < 0) {
              return const SizedBox.shrink();
            }

            return Positioned(
              left: 3,
              right: 3,
              top: top.clamp(0.0, math.max(0.0, timelineHeight - 26)),
              height: math.min(height, timelineHeight),
              child: CalendarTimedItemCard(
                item: item,
                onTap: () => onTapItem(item),
                canMove: canMoveItem(item),
                canResize: canResizeItem(item),
                onResize: (delta) => onResizeItem(item, delta),
              ),
            );
          }),
        ],
      ),
    );
  }
}
