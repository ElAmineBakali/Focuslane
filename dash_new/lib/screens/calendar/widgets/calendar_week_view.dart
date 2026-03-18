import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/calendar/models/calendar_models.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_item_widget.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_timeline.dart';

class CalendarWeekView extends StatelessWidget {
  const CalendarWeekView({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.itemsFor,
    required this.canMoveItem,
    required this.canResizeItem,
    required this.durationMinutes,
    required this.topFor,
    required this.onSelectDay,
    required this.onMoveItemToDay,
    required this.onMoveItemToSlot,
    required this.onResizeItem,
    required this.onTapItem,
    required this.onCreateEvent,
    required this.weekdayShort,
    required this.humanDate,
    required this.prefs,
    required this.onTypeToggle,
    required this.onHighOnlyToggle,
    required this.timeAxisWidth,
    required this.dayWidth,
    required this.slotHeight,
    required this.timelineHeight,
    required this.timelineStartHour,
    required this.timelineEndHour,
    this.onPointerSignal,
    this.onScaleUpdate,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final List<CalendarItem> Function(DateTime day) itemsFor;
  final bool Function(CalendarItem item) canMoveItem;
  final bool Function(CalendarItem item) canResizeItem;
  final int Function(CalendarItem item) durationMinutes;
  final double Function(DateTime time) topFor;
  final ValueChanged<DateTime> onSelectDay;
  final Future<void> Function(CalendarItem item, DateTime day) onMoveItemToDay;
  final Future<void> Function(CalendarItem item, DateTime slot)
  onMoveItemToSlot;
  final Future<void> Function(CalendarItem item, int deltaMinutes) onResizeItem;
  final ValueChanged<CalendarItem> onTapItem;
  final ValueChanged<DateTime> onCreateEvent;
  final String Function(int weekday) weekdayShort;
  final String Function(DateTime day) humanDate;
  final PlannerPrefs? prefs;
  final Future<void> Function(CalendarType type, bool value) onTypeToggle;
  final Future<void> Function(bool value) onHighOnlyToggle;
  final double timeAxisWidth;
  final double dayWidth;
  final double slotHeight;
  final double timelineHeight;
  final int timelineStartHour;
  final int timelineEndHour;
  final ValueChanged<PointerSignalEvent>? onPointerSignal;
  final GestureScaleUpdateCallback? onScaleUpdate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CalendarFilterChips(
          prefs: prefs,
          onTypeToggle: onTypeToggle,
          onHighOnlyToggle: onHighOnlyToggle,
        ),
        CalendarWeekHeader(
          days: days,
          selectedDay: selectedDay,
          dayWidth: dayWidth,
          timeAxisWidth: timeAxisWidth,
          weekdayShort: weekdayShort,
          humanDate: humanDate,
          onSelectDay: onSelectDay,
        ),
        CalendarAllDayRow(
          days: days,
          dayWidth: dayWidth,
          timeAxisWidth: timeAxisWidth,
          itemsFor: itemsFor,
          canMoveItem: canMoveItem,
          onMoveItemToDay: onMoveItemToDay,
          onTapItem: onTapItem,
          onCreateEvent: onCreateEvent,
        ),
        const Divider(height: 1),
        Expanded(
          child: CalendarTimelineSurface(
            days: days,
            dayWidth: dayWidth,
            timeAxisWidth: timeAxisWidth,
            timelineStartHour: timelineStartHour,
            timelineEndHour: timelineEndHour,
            timelineHeight: timelineHeight,
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
            onPointerSignal: onPointerSignal,
            onScaleUpdate: onScaleUpdate,
          ),
        ),
      ],
    );
  }
}
