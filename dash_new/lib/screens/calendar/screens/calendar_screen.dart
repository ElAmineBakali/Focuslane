import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/calendar/controllers/calendar_controller.dart';
import 'package:focuslane/screens/calendar/controllers/calendar_interaction_controller.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';
import 'package:focuslane/screens/calendar/services/calendar_service.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_agenda_view.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_day_view.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_event_editor.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_month_view.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_year_view.dart';

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
      length: 4,
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
          await CalendarService.I.addEvent(draft);
        } else {
          await CalendarService.I.updateEvent(draft);
        }

        _calendarController.focusEditedDay(when);
      },
      onDelete: (currentEvent) async {
        await CalendarService.I.deleteEvent(currentEvent.id);
        await _interactionController.cancelPlannerNotification(currentEvent.id);
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
    await _interactionController.cancelPlannerNotification(id);
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

  Widget _buildYearTab({bool usePageScroll = false}) {
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
      usePageScroll: usePageScroll,
    );
  }

  Widget _buildMonthTab({bool usePageScroll = false}) {
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
      usePageScroll: usePageScroll,
    );
  }

  Widget _buildDayTab(
    BuildContext context,
    double availableWidth, {
    bool usePageScroll = false,
  }) {
    final selected = _calendarController.selected;
    final day = DateTime(selected.year, selected.month, selected.day);
    final dayWidth = math.max(
      280.0,
      availableWidth - CalendarController.timeAxisWidth - 2,
    );

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
      usePageScroll: usePageScroll,
    );
  }

  Widget _buildAgendaTab({bool usePageScroll = false}) {
    return CalendarAgendaView(
      rows: _calendarController.agendaRows(),
      searchController: _calendarController.agendaSearchCtrl,
      humanDateLong: _calendarController.humanDateLong,
      onTapItem: _handleItemTap,
      onDeletePlanner: _handlePlannerDelete,
      prefs: _calendarController.prefs,
      onTypeToggle: _calendarController.setTypeEnabled,
      onHighOnlyToggle: _calendarController.setHighOnly,
      usePageScroll: usePageScroll,
    );
  }

  Widget _buildActiveTab(
    BuildContext context,
    double availableWidth, {
    required bool usePageScroll,
  }) {
    switch (_calendarController.activeViewIndex) {
      case 0:
        return _buildYearTab(usePageScroll: usePageScroll);
      case 1:
        return _buildMonthTab(usePageScroll: usePageScroll);
      case 2:
        return _buildDayTab(
          context,
          availableWidth,
          usePageScroll: usePageScroll,
        );
      case 3:
      default:
        return _buildAgendaTab(usePageScroll: usePageScroll);
    }
  }

  void _selectView(int index) {
    if (_tabController.index == index) return;
    _tabController.animateTo(index);
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
              child: AppShell(
                title: 'Calendario',
                subtitle: _calendarController.appBarTitle(),
                activeRoute: AppRoutes.calendarDashboard,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final padding = FocuslaneTokens.pagePaddingFor(context);
                    final isMobile = FocuslaneTokens.isCompact(context);
                    final availableWidth = math.max(
                      0.0,
                      constraints.maxWidth - padding.horizontal,
                    );
                    final header = _CalendarWorkspaceHeader(
                      title: 'Calendario',
                      periodLabel: _calendarController.appBarTitle(),
                      activeViewIndex: _calendarController.activeViewIndex,
                      selectedDay: _calendarController.selected,
                      visibleItems: _calendarController.rangeItems.length,
                      onSelectView: _selectView,
                      onPrevious: () => _calendarController.shiftVisible(-1),
                      onNext: () => _calendarController.shiftVisible(1),
                      onToday: _calendarController.goToday,
                      onNewEvent:
                          () => _openEventEditor(
                            defaultDay: _calendarController.selected,
                          ),
                    );

                    return SafeArea(
                      bottom: true,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: FocuslaneTokens.containerMaxWidth,
                          ),
                          child: Padding(
                            padding: padding,
                            child:
                                isMobile
                                    ? SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          header,
                                          const SizedBox(height: 10),
                                          _buildActiveTab(
                                            context,
                                            availableWidth,
                                            usePageScroll: true,
                                          ),
                                          SizedBox(
                                            height:
                                                16 +
                                                MediaQuery.paddingOf(
                                                  context,
                                                ).bottom,
                                          ),
                                        ],
                                      ),
                                    )
                                    : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        header,
                                        const SizedBox(height: 16),
                                        Expanded(
                                          child: TabBarView(
                                            controller: _tabController,
                                            children: [
                                              _buildYearTab(),
                                              _buildMonthTab(),
                                              _buildDayTab(
                                                context,
                                                availableWidth,
                                              ),
                                              _buildAgendaTab(),
                                            ],
                                          ),
                                        ),
                                      ],
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
        );
      },
    );
  }
}

class _CalendarWorkspaceHeader extends StatelessWidget {
  const _CalendarWorkspaceHeader({
    required this.title,
    required this.periodLabel,
    required this.activeViewIndex,
    required this.selectedDay,
    required this.visibleItems,
    required this.onSelectView,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onNewEvent,
  });

  final String title;
  final String periodLabel;
  final int activeViewIndex;
  final DateTime selectedDay;
  final int visibleItems;
  final ValueChanged<int> onSelectView;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onNewEvent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      backgroundColor: scheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          final mobile =
              constraints.maxWidth < FocuslaneTokens.mobileBreakpoint;
          final viewSwitcher = _CalendarViewSwitcher(
            activeIndex: activeViewIndex,
            onSelected: onSelectView,
            compact: mobile,
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FocusIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Anterior',
                onPressed: onPrevious,
              ),
              FocusIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Siguiente',
                onPressed: onNext,
              ),
              FocusSecondaryButton(
                label: 'Hoy',
                icon: Icons.today_rounded,
                onPressed: onToday,
              ),
              FocusPrimaryButton(
                label: 'Nuevo evento',
                icon: Icons.add_rounded,
                onPressed: onNewEvent,
              ),
            ],
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                periodLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(
                    label: '$visibleItems elementos visibles',
                    color: scheme.primary,
                  ),
                  FocusBadge(
                    label:
                        '${selectedDay.day.toString().padLeft(2, '0')}/'
                        '${selectedDay.month.toString().padLeft(2, '0')}/'
                        '${selectedDay.year}',
                    color: scheme.secondary,
                  ),
                ],
              ),
            ],
          );

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        periodLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FocusBadge(
                      label: '$visibleItems visibles',
                      color: scheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                viewSwitcher,
                const SizedBox(height: 10),
                Row(
                  children: [
                    FocusIconButton(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Anterior',
                      onPressed: onPrevious,
                    ),
                    const SizedBox(width: 8),
                    FocusIconButton(
                      icon: Icons.chevron_right_rounded,
                      tooltip: 'Siguiente',
                      onPressed: onNext,
                    ),
                    const SizedBox(width: 8),
                    FocusSecondaryButton(
                      label: 'Hoy',
                      icon: Icons.today_rounded,
                      onPressed: onToday,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FocusPrimaryButton(
                        label: 'Nuevo',
                        icon: Icons.add_rounded,
                        onPressed: onNewEvent,
                        fullWidth: true,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 16),
                viewSwitcher,
                const SizedBox(height: 16),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [viewSwitcher, const SizedBox(height: 14), actions],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarViewSwitcher extends StatelessWidget {
  const _CalendarViewSwitcher({
    required this.activeIndex,
    required this.onSelected,
    this.compact = false,
  });

  final int activeIndex;
  final ValueChanged<int> onSelected;
  final bool compact;

  static const _views = [
    (label: 'Anual', icon: Icons.calendar_view_month_rounded),
    (label: 'Mensual', icon: Icons.calendar_month_rounded),
    (label: 'Día', icon: Icons.today_rounded),
    (label: 'Agenda', icon: Icons.view_agenda_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return DropdownButtonFormField<int>(
        initialValue: activeIndex,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Vista',
          prefixIcon: Icon(Icons.view_module_rounded),
        ),
        items: [
          for (int index = 0; index < _views.length; index++)
            DropdownMenuItem<int>(
              value: index,
              child: Row(
                children: [
                  Icon(_views[index].icon, size: 18),
                  const SizedBox(width: 10),
                  Text(_views[index].label),
                ],
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        for (int index = 0; index < _views.length; index++)
          ChoiceChip(
            selected: activeIndex == index,
            label: Text(_views[index].label),
            avatar: Icon(_views[index].icon, size: 18),
            onSelected: (_) => onSelected(index),
          ),
      ],
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
