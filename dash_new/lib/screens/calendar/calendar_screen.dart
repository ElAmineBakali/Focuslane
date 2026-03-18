import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_dashboard_personal/core/services/notification_service.dart';
import 'package:mi_dashboard_personal/screens/calendar/controllers/calendar_controller.dart';
import 'package:mi_dashboard_personal/screens/calendar/controllers/calendar_interaction_controller.dart';
import 'package:mi_dashboard_personal/screens/calendar/models/calendar_models.dart';
import 'package:mi_dashboard_personal/screens/calendar/services/calendar_service.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_agenda_view.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_day_view.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_event_editor.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_month_view.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_week_view.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_year_view.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  static const route = '/calendar';

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CalendarController _calendarController;
  late final CalendarInteractionController _interactionController;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController(initialViewIndex: 1);
    _interactionController = CalendarInteractionController();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: _calendarController.activeViewIndex,
    );
    _tabController.addListener(_onTabChange);
    _calendarController.start();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) return;
    _calendarController.setActiveView(_tabController.index);
  }

  void _showWriteError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showWriteSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1300),
      ),
    );
  }

  Future<void> _openEventEditor({
    CalendarEvent? event,
    DateTime? defaultDay,
  }) async {
    await showCalendarEventEditor(
      context: context,
      event: event,
      defaultDay: defaultDay,
      humanDateTime: _calendarController.humanDateTime,
      onSave: (draft, isNew, when) async {
        if (isNew) {
          final newId = await CalendarService.I.addEvent(draft);
          final fixed = CalendarEvent(
            id: newId ?? draft.id,
            title: draft.title,
            type: draft.type,
            priority: draft.priority,
            start: draft.start,
            end: draft.end,
            allDay: draft.allDay,
            notes: draft.notes,
            relatedActionId: draft.relatedActionId,
            relatedTxId: draft.relatedTxId,
            dedupeKey: draft.dedupeKey,
            completed: draft.completed,
          );
          await _interactionController.syncPlannerNotification(fixed);
        } else {
          await CalendarService.I.updateEvent(draft);
          await _interactionController.syncPlannerNotification(draft);
        }

        _calendarController.focusEditedDay(when);
      },
      onDelete: (currentEvent) async {
        await CalendarService.I.deleteEvent(currentEvent.id);
        await NotificationService.I.cancel(currentEvent.id.hashCode);
      },
    );
  }

  Future<void> _handleItemTap(CalendarItem item) async {
    if (item.isEditable && item.sourceModule == CalendarSourceModule.planner) {
      await _openEventEditor(event: item.toEvent());
      return;
    }
    await _openDeepLink(item);
  }

  Future<void> _openDeepLink(CalendarItem item) async {
    final link = item.deepLink;
    try {
      await Navigator.of(context).pushNamed(
        link.routeName,
        arguments: link.arguments.isEmpty ? null : link.arguments,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el detalle de este elemento'),
        ),
      );
    }
  }

  Future<void> _handlePlannerDelete(String id) async {
    await CalendarService.I.deleteEvent(id);
    await NotificationService.I.cancel(id.hashCode);
  }

  Future<void> _moveItemToSlot(CalendarItem item, DateTime slot) async {
    await _interactionController.moveItemToSlot(
      item,
      slot,
      onSuccess: _showWriteSuccess,
      onError: _showWriteError,
    );
  }

  Future<void> _moveItemToDay(CalendarItem item, DateTime day) async {
    await _interactionController.moveItemToDay(
      item,
      day,
      onSuccess: _showWriteSuccess,
      onError: _showWriteError,
    );
  }

  Future<void> _resizeItem(CalendarItem item, int deltaMinutes) async {
    await _interactionController.resizeItem(
      item,
      deltaMinutes,
      onSuccess: _showWriteSuccess,
      onError: _showWriteError,
    );
  }

  void _onTimelinePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final withCtrl =
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
    if (!withCtrl) return;
    final step = event.scrollDelta.dy > 0 ? -6.0 : 6.0;
    _calendarController.setSlotHeight(_calendarController.slotHeight + step);
  }

  void _onTimelineScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount <= 1) return;
    _calendarController.setSlotHeight(
      _calendarController.slotHeight * details.scale,
    );
  }

  Widget _buildYearTab() {
    final focused = _calendarController.focused;
    return CalendarYearView(
      year: focused.year,
      stats: _calendarController.yearStats(focused.year),
      monthLabel: _calendarController.monthLabel,
      onSelectMonth: (month) {
        final target = DateTime(focused.year, month, 1);
        _calendarController.jumpToMonth(target);
        _tabController.animateTo(1);
      },
      prefs: _calendarController.prefs,
      onTypeToggle: _calendarController.setTypeEnabled,
      onHighOnlyToggle: _calendarController.setHighOnly,
    );
  }

  Widget _buildMonthTab() {
    return CalendarMonthView(
      focusedDay: _calendarController.focused,
      selectedDay: _calendarController.selected,
      itemsFor: _calendarController.itemsFor,
      humanDate: _calendarController.humanDate,
      onDaySelected: _calendarController.onDaySelected,
      onPageChanged: _calendarController.onMonthPageChanged,
      onTapItem: _handleItemTap,
      onDeletePlanner: _handlePlannerDelete,
      onCreateEvent: (day) => _openEventEditor(defaultDay: day),
      prefs: _calendarController.prefs,
      onTypeToggle: _calendarController.setTypeEnabled,
      onHighOnlyToggle: _calendarController.setHighOnly,
      monthRowHeight: CalendarController.monthRowHeight,
      dayListHeaderHeight: CalendarController.dayListHeaderHeight,
      dayListBodyHeight: CalendarController.dayListBodyHeight,
    );
  }

  Widget _buildWeekTab() {
    final days = _calendarController.weekDays(_calendarController.selected);
    return CalendarWeekView(
      days: days,
      selectedDay: _calendarController.selected,
      itemsFor: _calendarController.itemsFor,
      canMoveItem: _interactionController.canMoveItem,
      canResizeItem: _interactionController.canResizeItem,
      durationMinutes: _interactionController.durationMinutes,
      topFor: _calendarController.topFor,
      onSelectDay: _calendarController.selectDay,
      onMoveItemToDay: _moveItemToDay,
      onMoveItemToSlot: _moveItemToSlot,
      onResizeItem: _resizeItem,
      onTapItem: _handleItemTap,
      onCreateEvent: (day) => _openEventEditor(defaultDay: day),
      weekdayShort: _calendarController.weekdayShort,
      humanDate: _calendarController.humanDate,
      prefs: _calendarController.prefs,
      onTypeToggle: _calendarController.setTypeEnabled,
      onHighOnlyToggle: _calendarController.setHighOnly,
      timeAxisWidth: CalendarController.timeAxisWidth,
      dayWidth: CalendarController.weekDayColumnWidth,
      slotHeight: _calendarController.slotHeight,
      timelineHeight: _calendarController.timelineHeight,
      timelineStartHour: CalendarController.timelineStartHour,
      timelineEndHour: CalendarController.timelineEndHour,
      onPointerSignal: _onTimelinePointerSignal,
      onScaleUpdate: _onTimelineScaleUpdate,
    );
  }

  Widget _buildDayTab(BuildContext context) {
    final selected = _calendarController.selected;
    final day = DateTime(selected.year, selected.month, selected.day);
    final dayWidth = math.max(280.0, MediaQuery.sizeOf(context).width - 94);

    return CalendarDayView(
      day: day,
      dayWidth: dayWidth,
      slotHeight: _calendarController.slotHeight,
      timelineHeight: _calendarController.timelineHeight,
      timelineStartHour: CalendarController.timelineStartHour,
      timelineEndHour: CalendarController.timelineEndHour,
      timeAxisWidth: CalendarController.timeAxisWidth,
      itemsFor: _calendarController.itemsFor,
      canMoveItem: _interactionController.canMoveItem,
      canResizeItem: _interactionController.canResizeItem,
      durationMinutes: _interactionController.durationMinutes,
      topFor: _calendarController.topFor,
      onMoveItemToDay: _moveItemToDay,
      onMoveItemToSlot: _moveItemToSlot,
      onResizeItem: _resizeItem,
      onTapItem: _handleItemTap,
      onCreateEvent: (value) => _openEventEditor(defaultDay: value),
      onSlotHeightChanged: _calendarController.setSlotHeight,
      humanDateLong: _calendarController.humanDateLong,
      prefs: _calendarController.prefs,
      onTypeToggle: _calendarController.setTypeEnabled,
      onHighOnlyToggle: _calendarController.setHighOnly,
      onPointerSignal: _onTimelinePointerSignal,
      onScaleUpdate: _onTimelineScaleUpdate,
    );
  }

  Widget _buildAgendaTab() {
    return CalendarAgendaView(
      rows: _calendarController.agendaRows(),
      searchController: _calendarController.agendaSearchCtrl,
      humanDateLong: _calendarController.humanDateLong,
      onTapItem: _handleItemTap,
      onDeletePlanner: _handlePlannerDelete,
      prefs: _calendarController.prefs,
      onTypeToggle: _calendarController.setTypeEnabled,
      onHighOnlyToggle: _calendarController.setHighOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _calendarController,
      builder: (context, _) {
        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyT): _CalendarTodayIntent(),
            SingleActivator(LogicalKeyboardKey.keyN): _CalendarNewIntent(),
            SingleActivator(
              LogicalKeyboardKey.arrowLeft,
            ): _CalendarShiftVisibleIntent(-1),
            SingleActivator(
              LogicalKeyboardKey.arrowRight,
            ): _CalendarShiftVisibleIntent(1),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _CalendarTodayIntent: CallbackAction<_CalendarTodayIntent>(
                onInvoke: (_) {
                  _calendarController.goToday();
                  return null;
                },
              ),
              _CalendarNewIntent: CallbackAction<_CalendarNewIntent>(
                onInvoke: (_) {
                  _openEventEditor(defaultDay: _calendarController.selected);
                  return null;
                },
              ),
              _CalendarShiftVisibleIntent:
                  CallbackAction<_CalendarShiftVisibleIntent>(
                    onInvoke: (intent) {
                      _calendarController.shiftVisible(intent.delta);
                      return null;
                    },
                  ),
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(_calendarController.appBarTitle()),
                  actions: [
                    IconButton(
                      tooltip: 'Anterior',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _calendarController.shiftVisible(-1),
                    ),
                    IconButton(
                      tooltip: 'Siguiente',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _calendarController.shiftVisible(1),
                    ),
                    IconButton(
                      tooltip: 'Hoy',
                      icon: const Icon(Icons.today),
                      onPressed: _calendarController.goToday,
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Anual', icon: Icon(Icons.calendar_view_month)),
                      Tab(text: 'Mensual', icon: Icon(Icons.calendar_month)),
                      Tab(text: 'Semanal', icon: Icon(Icons.view_week)),
                      Tab(text: 'Dia', icon: Icon(Icons.today)),
                      Tab(text: 'Agenda', icon: Icon(Icons.view_agenda)),
                    ],
                  ),
                ),
                body: SafeArea(
                  bottom: true,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildYearTab(),
                      _buildMonthTab(),
                      _buildWeekTab(),
                      _buildDayTab(context),
                      _buildAgendaTab(),
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton.extended(
                  onPressed:
                      () => _openEventEditor(
                        defaultDay: _calendarController.selected,
                      ),
                  icon: const Icon(Icons.add),
                  label: const Text('Evento'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CalendarTodayIntent extends Intent {
  const _CalendarTodayIntent();
}

class _CalendarNewIntent extends Intent {
  const _CalendarNewIntent();
}

class _CalendarShiftVisibleIntent extends Intent {
  const _CalendarShiftVisibleIntent(this.delta);

  final int delta;
}
