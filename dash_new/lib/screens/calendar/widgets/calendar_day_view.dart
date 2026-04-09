import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_item_widget.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_timeline.dart';

class CalendarDayView extends StatelessWidget {
  const CalendarDayView({
    super.key,
    required this.day,
    required this.dayWidth,
    required this.slotHeight,
    required this.timelineHeight,
    required this.timelineStartHour,
    required this.timelineEndHour,
    required this.timeAxisWidth,
    required this.itemsFor,
    required this.canMoveItem,
    required this.canResizeItem,
    required this.durationMinutes,
    required this.topFor,
    required this.onMoveItemToDay,
    required this.onMoveItemToSlot,
    required this.onResizeItem,
    required this.onTapItem,
    required this.onCreateEvent,
    required this.onSlotHeightChanged,
    required this.humanDateLong,
    required this.prefs,
    required this.onTypeToggle,
    required this.onHighOnlyToggle,
    this.onPointerSignal,
    this.onScaleUpdate,
  });

  final DateTime day;
  final double dayWidth;
  final double slotHeight;
  final double timelineHeight;
  final int timelineStartHour;
  final int timelineEndHour;
  final double timeAxisWidth;
  final List<CalendarItem> Function(DateTime day) itemsFor;
  final bool Function(CalendarItem item) canMoveItem;
  final bool Function(CalendarItem item) canResizeItem;
  final int Function(CalendarItem item) durationMinutes;
  final double Function(DateTime time) topFor;
  final Future<void> Function(CalendarItem item, DateTime day) onMoveItemToDay;
  final Future<void> Function(CalendarItem item, DateTime slot)
  onMoveItemToSlot;
  final Future<void> Function(CalendarItem item, int deltaMinutes) onResizeItem;
  final ValueChanged<CalendarItem> onTapItem;
  final ValueChanged<DateTime> onCreateEvent;
  final ValueChanged<double> onSlotHeightChanged;
  final String Function(DateTime day) humanDateLong;
  final PlannerPrefs? prefs;
  final Future<void> Function(CalendarType type, bool value) onTypeToggle;
  final Future<void> Function(bool value) onHighOnlyToggle;
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Dia ${humanDateLong(day)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const Text('Zoom'),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: Slider(
                  value: slotHeight,
                  min: 34,
                  max: 120,
                  onChanged: onSlotHeightChanged,
                ),
              ),
            ],
          ),
        ),
        CalendarAllDayRow(
          days: [day],
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
            days: [day],
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

