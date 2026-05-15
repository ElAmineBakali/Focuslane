import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CalendarFilterChips(
          prefs: prefs,
          onTypeToggle: onTypeToggle,
          onHighOnlyToggle: onHighOnlyToggle,
        ),
        const SizedBox(height: 12),
        FocusCard(
          padding: const EdgeInsets.all(14),
          elevated: false,
          backgroundColor: scheme.surfaceContainerLow,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final title = Row(
                children: [
                  Icon(Icons.view_day_rounded, color: scheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      humanDateLong(day),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              );
              final zoom = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Zoom',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: compact ? 180 : 160,
                    child: Slider(
                      value: slotHeight,
                      min: 34,
                      max: 120,
                      onChanged: onSlotHeightChanged,
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: zoom),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 16),
                  zoom,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FocusCard(
            padding: EdgeInsets.zero,
            backgroundColor: scheme.surfaceContainerLowest,
            child: Column(
              children: [
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
            ),
          ),
        ),
      ],
    );
  }
}
