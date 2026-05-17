import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:focuslane/screens/habits/models/habit_model.dart';
import 'package:focuslane/screens/habits/services/habit_firestore_service.dart';
import 'package:focuslane/screens/habits/utils/habit_constants.dart';
import 'package:focuslane/screens/habits/utils/habit_utils.dart';
import 'package:focuslane/screens/habits/widgets/confetti_animation.dart';

class HabitsTableScreen extends StatefulWidget {
  const HabitsTableScreen({super.key});

  @override
  State<HabitsTableScreen> createState() => _HabitsTableScreenState();
}

class _HabitsTableScreenState extends State<HabitsTableScreen> {
  final HabitFirestoreService _habitService = HabitFirestoreService();

  Habit? _selectedHabit;
  bool _editMode = false;
  bool _showArchived = false;

  List<DateTime> _dates = const [];

  static const double _nameColWidth = 140;
  static const double _cellWidth = 64;
  static const double _cellHeight = 52;
  static const EdgeInsets _cellMargin = EdgeInsets.all(4);
  static double get _rowHeight => _cellHeight + _cellMargin.vertical;

  static const double _bottomSafeGap = 100;

  static const int _timelineInitialDays = 180;
  static const int _timelineChunkDays = 120;
  static const double _timelinePrefetchPx = 500;
  static const int _timelineExtraPastDays = 3650;

  List<Habit>? _orderedHabits;
  final Map<String, Map<String, dynamic>> _historyIndexByHabit = {};
  DateTime? _earliestTimelineDate;
  int _loadedTimelineDays = 0;
  int _maxTimelineDays = 0;
  bool _isAppendingTimeline = false;

  final ScrollController _leftV = ScrollController();
  final ScrollController _rightV = ScrollController();
  final ScrollController _horizontal = ScrollController();
  bool _syncingL = false;
  bool _syncingR = false;

  void _syncTimeline(List<Habit> habits) {
    final today = normalizeHabitDate(DateTime.now());
    final earliestTimelineDate = resolveEarliestHabitDate(
      habits,
      extraPastDays: _timelineExtraPastDays,
    );
    final maxTimelineDays = today.difference(earliestTimelineDate).inDays + 1;
    final timelineChanged =
        _earliestTimelineDate != earliestTimelineDate ||
        _maxTimelineDays != maxTimelineDays;

    if (timelineChanged) {
      _earliestTimelineDate = earliestTimelineDate;
      _maxTimelineDays = maxTimelineDays;
    }

    if (_loadedTimelineDays == 0 || timelineChanged) {
      _loadedTimelineDays = math.min(
        _maxTimelineDays,
        math.max(_loadedTimelineDays, _timelineInitialDays),
      );
    }

    if (_loadedTimelineDays > _maxTimelineDays) {
      _loadedTimelineDays = _maxTimelineDays;
    }

    final expectedLastDate = today.subtract(
      Duration(days: _loadedTimelineDays - 1),
    );
    final shouldRebuildDates =
        _dates.isEmpty ||
        _dates.length != _loadedTimelineDays ||
        _dates.first != today ||
        _dates.last != expectedLastDate;

    if (shouldRebuildDates) {
      _dates = _buildTimelineDates(today);
    }
  }

  List<DateTime> _buildTimelineDates(DateTime today) {
    return List<DateTime>.generate(
      _loadedTimelineDays,
      (index) => today.subtract(Duration(days: index)),
      growable: false,
    );
  }

  void _appendTimelineChunkIfNeeded() {
    if (!_horizontal.hasClients || _isAppendingTimeline) {
      return;
    }

    if (_loadedTimelineDays >= _maxTimelineDays) {
      return;
    }

    final remaining =
        _horizontal.position.maxScrollExtent - _horizontal.position.pixels;
    if (remaining > _timelinePrefetchPx) {
      return;
    }

    _isAppendingTimeline = true;
    setState(() {
      _loadedTimelineDays = math.min(
        _maxTimelineDays,
        _loadedTimelineDays + _timelineChunkDays,
      );
      _dates = _buildTimelineDates(normalizeHabitDate(DateTime.now()));
    });
    _isAppendingTimeline = false;
  }

  void _buildHistoryIndexes(List<Habit> habits) {
    _historyIndexByHabit.clear();
    for (final habit in habits) {
      _historyIndexByHabit[habit.id] = buildHabitHistoryKeyIndex(habit.history);
    }
  }

  void _handleHorizontalPointerSignal(PointerSignalEvent event) {
    if (!_horizontal.hasClients || event is! PointerScrollEvent) {
      return;
    }

    final supportsDesktopPointer =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    if (!supportsDesktopPointer) {
      return;
    }

    final step =
        event.scrollDelta.dx != 0 ? event.scrollDelta.dx : event.scrollDelta.dy;
    if (step == 0) {
      return;
    }

    final targetOffset = (_horizontal.offset + step).clamp(
      0.0,
      _horizontal.position.maxScrollExtent,
    );
    if (targetOffset == _horizontal.offset) {
      return;
    }

    _horizontal.jumpTo(targetOffset);
    _appendTimelineChunkIfNeeded();
  }

  @override
  void initState() {
    super.initState();

    _leftV.addListener(() {
      if (_syncingR) return;
      if (!_rightV.hasClients) return;
      _syncingL = true;
      final sharedMax = math.min(
        _leftV.position.maxScrollExtent,
        _rightV.position.maxScrollExtent,
      );
      final t = _leftV.offset.clamp(0.0, sharedMax);
      if ((_rightV.offset - t).abs() > 0.5) _rightV.jumpTo(t);
      _syncingL = false;
    });

    _rightV.addListener(() {
      if (_syncingL) return;
      if (!_leftV.hasClients) return;
      _syncingR = true;
      final sharedMax = math.min(
        _leftV.position.maxScrollExtent,
        _rightV.position.maxScrollExtent,
      );
      final t = _rightV.offset.clamp(0.0, sharedMax);
      if ((_leftV.offset - t).abs() > 0.5) _leftV.jumpTo(t);
      _syncingR = false;
    });

    _horizontal.addListener(_appendTimelineChunkIfNeeded);
  }

  @override
  void dispose() {
    _leftV.dispose();
    _rightV.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  Color _cellBg(dynamic value, ThemeData theme) {
    final status = normalizeHabitStatus(value);
    if (status == habitCompletedValue) {
      return theme.colorScheme.secondaryContainer.withValues(alpha: 0.76);
    }
    if (status == habitMissedValue) {
      return theme.colorScheme.errorContainer.withValues(alpha: 0.82);
    }
    if (status == habitSkippedValue) {
      return theme.colorScheme.tertiaryContainer.withValues(alpha: 0.78);
    }

    final isLight = theme.brightness == Brightness.light;
    final hasValue = value != null;
    final base = theme.colorScheme.surfaceContainerLow;
    final opacity = isLight ? (hasValue ? .35 : .18) : (hasValue ? .40 : .22);
    return base.withValues(alpha: opacity);
  }

  Widget _valueContent(Habit habit, dynamic value, ThemeData theme) {
    if (isHabitCompletedValue(habit, value) && !habit.isQuantitative) {
      return Icon(Icons.check_rounded, color: habit.color, size: 22);
    }
    if (isHabitMissedValue(value)) {
      return Icon(Icons.close_rounded, color: habit.color, size: 22);
    }
    if (isHabitSkippedValue(value)) {
      return Icon(
        Icons.remove_rounded,
        color: theme.colorScheme.onTertiaryContainer,
        size: 20,
      );
    }

    if (habit.isQuantitative && value != null) {
      final numericValue = parseHabitNumericValue(value);
      final displayValue =
          numericValue.abs() >= 1000
              ? formatHabitCompactNumber(numericValue)
              : formatHabitStatNumber(numericValue);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayValue,
            style: TextStyle(color: habit.color, fontWeight: FontWeight.bold),
          ),
          if (habit.unit.isNotEmpty) const SizedBox(height: 2),
          if (habit.unit.isNotEmpty)
            Text(
              habit.unit,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: .6),
              ),
            ),
        ],
      );
    }
    return Text(
      '—',
      style: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: .45),
      ),
    );
  }

  Future<void> _updateHistoryValue(Habit habit, DateTime date) async {
    final theme = Theme.of(context);
    final sec = theme.colorScheme.secondary;
    final key = habitDateKey(date);

    if (!habit.isQuantitative) {
      final result = await showDialog<String>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('¿Qué quieres marcar?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.check_circle_rounded, color: sec),
                    title: const Text('Completado'),
                    onTap: () => Navigator.pop(context, habitCompletedValue),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.cancel_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: const Text('No completado'),
                    onTap: () => Navigator.pop(context, habitMissedValue),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.remove_circle_rounded,
                      color: theme.colorScheme.tertiary,
                    ),
                    title: const Text('Saltado'),
                    onTap: () => Navigator.pop(context, habitSkippedValue),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: TextButton.styleFrom(foregroundColor: sec),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
      );
      if (result != null) {
        await _habitService.updateHabitHistory(habit.id, date, result);
        habit.history[key] = result;

        await _updateStreak(habit);

        if (isHabitCompletedValue(habit, result) && _isToday(date) && mounted) {
          final allHabits = _orderedHabits ?? [];
          final allCompleted = allHabits.every(
            (trackedHabit) => isHabitCompletedValue(
              trackedHabit,
              habitHistoryValueForDate(trackedHabit.history, DateTime.now()),
            ),
          );

          _showConfetti(
            habit: habit,
            isPerfectDay: allCompleted && allHabits.isNotEmpty,
          );
        }

        setState(() {});
      }
    } else {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Introduce un valor'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Ej: 5'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: TextButton.styleFrom(foregroundColor: sec),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  style: TextButton.styleFrom(foregroundColor: sec),
                  child: const Text('Guardar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, habitSkippedValue),
                  style: TextButton.styleFrom(foregroundColor: sec),
                  child: const Text('Saltar'),
                ),
              ],
            ),
      );
      if (result != null) {
        await _habitService.updateHabitHistory(habit.id, date, result);
        habit.history[key] = result;

        await _updateStreak(habit);

        if (isHabitCompletedValue(habit, result) && _isToday(date) && mounted) {
          final allHabits = _orderedHabits ?? [];
          final allCompleted = allHabits.every(
            (trackedHabit) => isHabitCompletedValue(
              trackedHabit,
              habitHistoryValueForDate(trackedHabit.history, DateTime.now()),
            ),
          );

          _showConfetti(
            habit: habit,
            isPerfectDay: allCompleted && allHabits.isNotEmpty,
          );
        }

        setState(() {});
      }
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _updateStreak(Habit habit) async {
    final streaks = computeHabitStreakStats(habit);
    if (streaks.current == habit.currentStreak &&
        streaks.best == habit.bestStreak) {
      return;
    }

    await HabitFirestoreService.updateHabitFields(habit.id, {
      'currentStreak': streaks.current,
      'bestStreak': streaks.best,
    });

    habit.currentStreak = streaks.current;
    habit.bestStreak = streaks.best;
  }

  void _showConfetti({required Habit habit, required bool isPerfectDay}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Stack(
            children: [
              const ConfettiAnimation(),
              HabitCompletedDialog(
                habitName: habit.name,
                isPerfectDay: isPerfectDay,
              ),
            ],
          ),
    );
  }

  void _enterEditMode(Habit habit) {
    setState(() {
      _editMode = true;
      _selectedHabit = habit;
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (!_editMode || _orderedHabits == null) return;
    if (newIndex > oldIndex) newIndex--;
    final h = _orderedHabits!.removeAt(oldIndex);
    _orderedHabits!.insert(newIndex, h);
    await _habitService.updateHabitOrder(_orderedHabits!);
    setState(() {});
  }

  void _showEditOptions() {
    if (_selectedHabit == null) return;
    final h = _selectedHabit!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FocusCard(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Editar hábito'),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.pushNamed(
                          context,
                          '/habits/detail',
                          arguments: h,
                        );
                        if (result == true) setState(() {});
                      },
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    if (h.isActive)
                      ListTile(
                        leading: const Icon(Icons.archive_rounded),
                        title: const Text('Archivar hábito'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _habitService.archiveHabit(h.id);
                          setState(() => _selectedHabit = null);
                        },
                      )
                    else
                      ListTile(
                        leading: const Icon(Icons.unarchive_rounded),
                        title: const Text('Desarchivar hábito'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _habitService.unarchiveHabit(h.id);
                          setState(() => _selectedHabit = null);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _exitEditMode() => setState(() {
    _editMode = false;
    _selectedHabit = null;
  });

  Widget _cell(
    Habit habit,
    Map<String, dynamic> historyIndex,
    DateTime date,
    ThemeData theme,
  ) {
    final value = habitHistoryIndexedValue(historyIndex, date);
    final status = normalizeHabitStatus(value);
    final scheme = theme.colorScheme;
    final borderColor =
        status == habitCompletedValue
            ? scheme.secondary.withValues(alpha: 0.34)
            : status == habitMissedValue
            ? scheme.error.withValues(alpha: 0.34)
            : status == habitSkippedValue
            ? scheme.tertiary.withValues(alpha: 0.34)
            : scheme.outlineVariant.withValues(alpha: 0.72);

    return GestureDetector(
      onTap: () => _updateHistoryValue(habit, date),
      child: Container(
        width: _cellWidth,
        height: _cellHeight,
        margin: _cellMargin,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _cellBg(value, theme),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: _valueContent(habit, value, theme),
      ),
    );
  }

  Widget _buildHabitsPage({
    required BuildContext context,
    required ThemeData theme,
    required List<Habit> habits,
    required _HabitDashboardSummary summary,
    required double nameColWidth,
    required double gridWidth,
    required bool isMobileLayout,
  }) {
    final header = _HabitsHeader(
      summary: summary,
      showArchived: _showArchived,
      editMode: _editMode,
      onCreateHabit: () => Navigator.pushNamed(context, '/habits/create'),
      onToggleArchived:
          () => setState(() {
            _orderedHabits = null;
            _showArchived = !_showArchived;
          }),
    );
    final gap = isMobileLayout ? 10.0 : 16.0;

    if (isMobileLayout) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            SizedBox(height: gap),
            _HabitsSummaryGrid(summary: summary, compact: true),
            SizedBox(height: gap),
            _buildMobileMatrixCard(
              theme: theme,
              habits: habits,
              nameColWidth: nameColWidth,
              gridWidth: gridWidth,
            ),
            SizedBox(height: 20 + MediaQuery.paddingOf(context).bottom),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        SizedBox(height: gap),
        _HabitsSummaryGrid(summary: summary),
        SizedBox(height: gap),
        Expanded(
          child: _buildDesktopMatrixCard(
            theme: theme,
            habits: habits,
            nameColWidth: nameColWidth,
            gridWidth: gridWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopMatrixCard({
    required ThemeData theme,
    required List<Habit> habits,
    required double nameColWidth,
    required double gridWidth,
  }) {
    return FocusCard(
      padding: EdgeInsets.zero,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      child: Row(
        children: [
          _buildNameColumn(
            theme: theme,
            habits: habits,
            nameColWidth: nameColWidth,
            scrollable: true,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, cons) {
                final bodyHeight = math.max(
                  0.0,
                  cons.maxHeight - _rowHeight - 2,
                );
                return _buildHorizontalMatrix(
                  theme: theme,
                  habits: habits,
                  gridWidth: gridWidth,
                  scrollableVertically: true,
                  bodyHeight: bodyHeight,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMatrixCard({
    required ThemeData theme,
    required List<Habit> habits,
    required double nameColWidth,
    required double gridWidth,
  }) {
    return FocusCard(
      padding: EdgeInsets.zero,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameColumn(
            theme: theme,
            habits: habits,
            nameColWidth: nameColWidth,
            scrollable: false,
          ),
          Expanded(
            child: _buildHorizontalMatrix(
              theme: theme,
              habits: habits,
              gridWidth: gridWidth,
              scrollableVertically: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameColumn({
    required ThemeData theme,
    required List<Habit> habits,
    required double nameColWidth,
    required bool scrollable,
  }) {
    final rows = _buildNameRows(habits: habits, scrollable: scrollable);

    return SizedBox(
      width: nameColWidth,
      child: Column(
        children: [
          _buildNameHeader(theme),
          const SizedBox(height: 2),
          if (scrollable) Expanded(child: rows) else rows,
        ],
      ),
    );
  }

  Widget _buildNameHeader(ThemeData theme) {
    return Container(
      height: _rowHeight,
      margin: _cellMargin,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        'Hábito',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildNameRows({
    required List<Habit> habits,
    required bool scrollable,
  }) {
    if (_editMode) {
      final list = ReorderableListView.builder(
        padding: EdgeInsets.only(bottom: scrollable ? _bottomSafeGap : 0),
        shrinkWrap: !scrollable,
        primary: false,
        buildDefaultDragHandles: false,
        onReorder: _onReorder,
        physics:
            scrollable
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
        itemCount: habits.length,
        itemBuilder: (context, index) {
          final habit = habits[index];
          return _NameRow(
            key: ValueKey(habit.id),
            habit: habit,
            editMode: true,
            selected: _selectedHabit?.id == habit.id,
            onTap: () => setState(() => _selectedHabit = habit),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.drag_handle_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        },
      );

      if (!scrollable) {
        return list;
      }

      return PrimaryScrollController(controller: _leftV, child: list);
    }

    if (!scrollable) {
      return Column(
        children: [for (final habit in habits) _buildNameRowForHabit(habit)],
      );
    }

    return ListView.builder(
      controller: _leftV,
      padding: const EdgeInsets.only(bottom: _bottomSafeGap),
      physics: const ClampingScrollPhysics(),
      itemExtent: _rowHeight,
      itemCount: habits.length,
      itemBuilder: (context, index) => _buildNameRowForHabit(habits[index]),
    );
  }

  Widget _buildNameRowForHabit(Habit habit) {
    final todayValue = habitHistoryIndexedValue(
      _historyIndexByHabit[habit.id] ?? const <String, dynamic>{},
      DateTime.now(),
    );
    return _NameRow(
      habit: habit,
      editMode: false,
      todayValue: todayValue,
      onTap:
          () => Navigator.pushNamed(context, '/habits/stats', arguments: habit),
    );
  }

  Widget _buildHorizontalMatrix({
    required ThemeData theme,
    required List<Habit> habits,
    required double gridWidth,
    required bool scrollableVertically,
    double? bodyHeight,
  }) {
    return Listener(
      onPointerSignal: _handleHorizontalPointerSignal,
      child: ScrollConfiguration(
        behavior: const _HabitsTableScrollBehavior(),
        child: Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          notificationPredicate:
              (notification) => notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: gridWidth,
              child: Column(
                children: [
                  _buildDateHeaderRow(theme),
                  const SizedBox(height: 2),
                  if (scrollableVertically)
                    SizedBox(
                      height: bodyHeight ?? 0,
                      child: _buildScrollableGridRows(theme, habits),
                    )
                  else
                    _buildStaticGridRows(theme, habits),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeaderRow(ThemeData theme) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children:
            _dates.map((d) {
              final isToday = _isToday(d);
              return Container(
                width: _cellWidth,
                height: _cellHeight,
                margin: _cellMargin,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isToday
                          ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.42,
                          )
                          : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isToday
                            ? theme.colorScheme.primary.withValues(alpha: 0.38)
                            : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  DateFormat('E\ndd', 'es_ES').format(d),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildScrollableGridRows(ThemeData theme, List<Habit> habits) {
    return ListView.builder(
      controller: _rightV,
      padding: const EdgeInsets.only(bottom: _bottomSafeGap),
      physics: const ClampingScrollPhysics(),
      itemExtent: _rowHeight,
      itemCount: habits.length,
      itemBuilder: (context, row) => _buildGridRow(theme, habits[row]),
    );
  }

  Widget _buildStaticGridRows(ThemeData theme, List<Habit> habits) {
    return Column(
      children: [for (final habit in habits) _buildGridRow(theme, habit)],
    );
  }

  Widget _buildGridRow(ThemeData theme, Habit habit) {
    final historyIndex =
        _historyIndexByHabit[habit.id] ?? const <String, dynamic>{};
    return Row(
      children:
          _dates.map((d) => _cell(habit, historyIndex, d, theme)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stream =
        _showArchived
            ? HabitFirestoreService.getArchivedHabits()
            : HabitFirestoreService.getHabits();

    return AppShell(
      title: 'Hábitos',
      subtitle:
          _showArchived
              ? 'Archivo de hábitos pausados.'
              : 'Matriz diaria, progreso semanal y rachas.',
      activeRoute: AppRoutes.habitsDashboard,
      actions: [
        if (_editMode && _selectedHabit != null) ...[
          FocusIconButton(
            icon: Icons.more_vert_rounded,
            tooltip: 'Opciones',
            onPressed: _showEditOptions,
          ),
        ],
        if (_editMode) ...[
          const SizedBox(width: 10),
          FocusIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Salir de edición',
            isActive: true,
            onPressed: _exitEditMode,
          ),
        ],
        const SizedBox(width: 10),
      ],
      child: SafeArea(
        bottom: true,
        child: StreamBuilder<List<Habit>>(
          stream: stream,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final habits = [
              ...snap.data!..sort((a, b) => a.order.compareTo(b.order)),
            ];
            _orderedHabits = habits;
            _buildHistoryIndexes(habits);
            _syncTimeline(habits);

            final double gridWidth =
                _dates.length * (_cellWidth + _cellMargin.horizontal);

            final summary = _HabitDashboardSummary.fromHabits(habits);

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final padding =
                    width < 720
                        ? FocuslaneTokens.spacing16
                        : width < 1180
                        ? FocuslaneTokens.spacing24
                        : FocuslaneTokens.spacing32;
                final isMobileLayout = width < FocuslaneTokens.mobileBreakpoint;
                final nameColWidth =
                    width < 420
                        ? 136.0
                        : width < 620
                        ? 152.0
                        : _nameColWidth;

                if (habits.isEmpty) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: FocuslaneTokens.containerMaxWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: FocusCard(
                          child: FocusEmptyState(
                            icon:
                                _showArchived
                                    ? Icons.archive_outlined
                                    : Icons.repeat_rounded,
                            message:
                                _showArchived
                                    ? 'No hay hábitos archivados'
                                    : 'No hay hábitos para mostrar',
                            subtitle:
                                _showArchived
                                    ? 'Los hábitos archivados aparecerán aquí.'
                                    : 'Crea tu primer hábito para empezar la matriz.',
                            actionLabel: _showArchived ? null : 'Crear hábito',
                            onAction:
                                _showArchived
                                    ? null
                                    : () => Navigator.pushNamed(
                                      context,
                                      '/habits/create',
                                    ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: FocuslaneTokens.containerMaxWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child:
                          isMobileLayout
                              ? _buildHabitsPage(
                                context: context,
                                theme: theme,
                                habits: habits,
                                summary: summary,
                                nameColWidth: nameColWidth,
                                gridWidth: gridWidth,
                                isMobileLayout: true,
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _HabitsHeader(
                                    summary: summary,
                                    showArchived: _showArchived,
                                    editMode: _editMode,
                                    onCreateHabit:
                                        () => Navigator.pushNamed(
                                          context,
                                          '/habits/create',
                                        ),
                                    onToggleArchived:
                                        () => setState(() {
                                          _orderedHabits = null;
                                          _showArchived = !_showArchived;
                                        }),
                                  ),
                                  const SizedBox(height: 16),
                                  _HabitsSummaryGrid(summary: summary),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: FocusCard(
                                      padding: EdgeInsets.zero,
                                      backgroundColor:
                                          theme
                                              .colorScheme
                                              .surfaceContainerLowest,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: nameColWidth,
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: _rowHeight,
                                                  margin: _cellMargin,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .surfaceContainerLow,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          theme
                                                              .colorScheme
                                                              .outlineVariant,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Hábito',
                                                    style: theme
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          color:
                                                              theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Expanded(
                                                  child:
                                                      _editMode
                                                          ? PrimaryScrollController(
                                                            controller: _leftV,
                                                            child: ReorderableListView.builder(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    bottom:
                                                                        _bottomSafeGap,
                                                                  ),
                                                              itemCount:
                                                                  habits.length,
                                                              buildDefaultDragHandles:
                                                                  false,
                                                              onReorder:
                                                                  _onReorder,
                                                              physics:
                                                                  const ClampingScrollPhysics(),
                                                              itemBuilder: (
                                                                context,
                                                                index,
                                                              ) {
                                                                final habit =
                                                                    habits[index];
                                                                return _NameRow(
                                                                  key: ValueKey(
                                                                    habit.id,
                                                                  ),
                                                                  habit: habit,
                                                                  editMode:
                                                                      true,
                                                                  selected:
                                                                      _selectedHabit
                                                                          ?.id ==
                                                                      habit.id,
                                                                  onTap:
                                                                      () => setState(
                                                                        () =>
                                                                            _selectedHabit =
                                                                                habit,
                                                                      ),
                                                                  trailing: ReorderableDragStartListener(
                                                                    index:
                                                                        index,
                                                                    child: const Padding(
                                                                      padding:
                                                                          EdgeInsets.only(
                                                                            right:
                                                                                6,
                                                                          ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .drag_handle_rounded,
                                                                        size:
                                                                            18,
                                                                        color:
                                                                            Colors.grey,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          )
                                                          : ListView.builder(
                                                            controller: _leftV,
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom:
                                                                      _bottomSafeGap,
                                                                ),
                                                            physics:
                                                                const ClampingScrollPhysics(),
                                                            itemExtent:
                                                                _rowHeight,
                                                            itemCount:
                                                                habits.length,
                                                            itemBuilder: (
                                                              context,
                                                              index,
                                                            ) {
                                                              final habit =
                                                                  habits[index];
                                                              final todayValue =
                                                                  habitHistoryIndexedValue(
                                                                    _historyIndexByHabit[habit
                                                                            .id] ??
                                                                        const <
                                                                          String,
                                                                          dynamic
                                                                        >{},
                                                                    DateTime.now(),
                                                                  );
                                                              return _NameRow(
                                                                habit: habit,
                                                                editMode: false,
                                                                todayValue:
                                                                    todayValue,
                                                                onTap:
                                                                    () => Navigator.pushNamed(
                                                                      context,
                                                                      '/habits/stats',
                                                                      arguments:
                                                                          habit,
                                                                    ),
                                                              );
                                                            },
                                                          ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          Expanded(
                                            child: LayoutBuilder(
                                              builder: (context, cons) {
                                                final bodyHeight =
                                                    cons.maxHeight -
                                                    _rowHeight -
                                                    2;
                                                return Listener(
                                                  onPointerSignal:
                                                      _handleHorizontalPointerSignal,
                                                  child: ScrollConfiguration(
                                                    behavior:
                                                        const _HabitsTableScrollBehavior(),
                                                    child: Scrollbar(
                                                      controller: _horizontal,
                                                      thumbVisibility: true,
                                                      trackVisibility: true,
                                                      interactive: true,
                                                      notificationPredicate:
                                                          (notification) =>
                                                              notification
                                                                  .metrics
                                                                  .axis ==
                                                              Axis.horizontal,
                                                      child: SingleChildScrollView(
                                                        controller: _horizontal,
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        child: SizedBox(
                                                          width: gridWidth,
                                                          child: Column(
                                                            children: [
                                                              SizedBox(
                                                                height:
                                                                    _rowHeight,
                                                                child: Row(
                                                                  children:
                                                                      _dates.map((
                                                                        d,
                                                                      ) {
                                                                        final isToday =
                                                                            _isToday(
                                                                              d,
                                                                            );
                                                                        return Container(
                                                                          width:
                                                                              _cellWidth,
                                                                          height:
                                                                              _cellHeight,
                                                                          margin:
                                                                              _cellMargin,
                                                                          alignment:
                                                                              Alignment.center,
                                                                          decoration: BoxDecoration(
                                                                            color:
                                                                                isToday
                                                                                    ? theme.colorScheme.primaryContainer.withValues(
                                                                                      alpha:
                                                                                          0.42,
                                                                                    )
                                                                                    : theme.colorScheme.surfaceContainerLow,
                                                                            borderRadius: BorderRadius.circular(
                                                                              10,
                                                                            ),
                                                                            border: Border.all(
                                                                              color:
                                                                                  isToday
                                                                                      ? theme.colorScheme.primary.withValues(
                                                                                        alpha:
                                                                                            0.38,
                                                                                      )
                                                                                      : theme.colorScheme.outlineVariant,
                                                                            ),
                                                                          ),
                                                                          child: Text(
                                                                            DateFormat(
                                                                              'E\ndd',
                                                                              'es_ES',
                                                                            ).format(
                                                                              d,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style: TextStyle(
                                                                              color:
                                                                                  isToday
                                                                                      ? theme.colorScheme.primary
                                                                                      : theme.colorScheme.onSurfaceVariant,
                                                                              fontWeight:
                                                                                  FontWeight.w800,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }).toList(),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 2,
                                                              ),
                                                              SizedBox(
                                                                height:
                                                                    bodyHeight,
                                                                child: ListView.builder(
                                                                  controller:
                                                                      _rightV,
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        bottom:
                                                                            _bottomSafeGap,
                                                                      ),
                                                                  physics:
                                                                      const ClampingScrollPhysics(),
                                                                  itemExtent:
                                                                      _rowHeight,
                                                                  itemCount:
                                                                      habits
                                                                          .length,
                                                                  itemBuilder: (
                                                                    context,
                                                                    row,
                                                                  ) {
                                                                    final habit =
                                                                        habits[row];
                                                                    final historyIndex =
                                                                        _historyIndexByHabit[habit
                                                                            .id] ??
                                                                        const <
                                                                          String,
                                                                          dynamic
                                                                        >{};
                                                                    return Row(
                                                                      children:
                                                                          _dates
                                                                              .map(
                                                                                (
                                                                                  d,
                                                                                ) => _cell(
                                                                                  habit,
                                                                                  historyIndex,
                                                                                  d,
                                                                                  theme,
                                                                                ),
                                                                              )
                                                                              .toList(),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HabitDashboardSummary {
  const _HabitDashboardSummary({
    required this.habitCount,
    required this.todayCompleted,
    required this.weeklyCompleted,
    required this.weeklyTotal,
    required this.weeklyProgress,
    required this.maxCurrentStreak,
    required this.bestStreak,
  });

  final int habitCount;
  final int todayCompleted;
  final int weeklyCompleted;
  final int weeklyTotal;
  final double weeklyProgress;
  final int maxCurrentStreak;
  final int bestStreak;

  static _HabitDashboardSummary fromHabits(List<Habit> habits) {
    final today = normalizeHabitDate(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    var weeklyCompleted = 0;
    var weeklyTotal = 0;
    var todayCompleted = 0;
    var maxCurrentStreak = 0;
    var bestStreak = 0;

    for (final habit in habits) {
      final streaks = computeHabitStreakStats(habit);
      if (streaks.current > maxCurrentStreak) {
        maxCurrentStreak = streaks.current;
      }
      if (streaks.best > bestStreak) {
        bestStreak = streaks.best;
      }

      final todayValue = habitHistoryValueForDate(habit.history, today);
      if (isHabitCompletedValue(habit, todayValue)) {
        todayCompleted += 1;
      }

      for (var offset = 0; offset < 7; offset++) {
        final day = weekStart.add(Duration(days: offset));
        weeklyTotal += 1;
        final value = habitHistoryValueForDate(habit.history, day);
        if (isHabitCompletedValue(habit, value)) {
          weeklyCompleted += 1;
        }
      }
    }

    final weeklyProgress =
        weeklyTotal == 0 ? 0.0 : weeklyCompleted / weeklyTotal;
    return _HabitDashboardSummary(
      habitCount: habits.length,
      todayCompleted: todayCompleted,
      weeklyCompleted: weeklyCompleted,
      weeklyTotal: weeklyTotal,
      weeklyProgress: weeklyProgress,
      maxCurrentStreak: maxCurrentStreak,
      bestStreak: bestStreak,
    );
  }
}

class _HabitsHeader extends StatelessWidget {
  const _HabitsHeader({
    required this.summary,
    required this.showArchived,
    required this.editMode,
    required this.onCreateHabit,
    required this.onToggleArchived,
  });

  final _HabitDashboardSummary summary;
  final bool showArchived;
  final bool editMode;
  final VoidCallback onCreateHabit;
  final VoidCallback onToggleArchived;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      backgroundColor: scheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hábitos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                showArchived
                    ? 'Revisa hábitos archivados sin perder su historial.'
                    : 'Marca días, revisa rachas y mantén la matriz ordenada.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(
                    label:
                        showArchived
                            ? '${summary.habitCount} archivados'
                            : '${summary.habitCount} activos',
                    color: scheme.primary,
                  ),
                  FocusBadge(
                    label:
                        '${summary.todayCompleted}/${summary.habitCount} hoy',
                    color: scheme.secondary,
                  ),
                  if (editMode)
                    FocusBadge(
                      label: 'Ordenación activa',
                      color: scheme.tertiary,
                    ),
                ],
              ),
            ],
          );

          final actions = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (!showArchived)
                FocusPrimaryButton(
                  label: 'Crear hábito',
                  icon: Icons.add_rounded,
                  onPressed: onCreateHabit,
                ),
              FocusSecondaryButton(
                label: showArchived ? 'Ver activos' : 'Ver archivados',
                icon:
                    showArchived ? Icons.inbox_rounded : Icons.archive_outlined,
                onPressed: onToggleArchived,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _HabitsSummaryGrid extends StatelessWidget {
  const _HabitsSummaryGrid({required this.summary, this.compact = false});

  final _HabitDashboardSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progressLabel = '${(summary.weeklyProgress * 100).round()}%';

    return ResponsiveGrid(
      minItemWidth: compact ? 154 : 200,
      spacing: compact ? 10 : 16,
      children: [
        FocusStatCard(
          title: 'Progreso semanal',
          value: progressLabel,
          subtitle:
              '${summary.weeklyCompleted}/${summary.weeklyTotal} marcas completas',
          icon: Icons.trending_up_rounded,
          color: scheme.primary,
        ),
        FocusStatCard(
          title: 'Completados hoy',
          value: '${summary.todayCompleted}/${summary.habitCount}',
          subtitle: 'sobre hábitos visibles',
          icon: Icons.today_rounded,
          color: scheme.secondary,
        ),
        FocusStatCard(
          title: 'Racha actual',
          value: '${summary.maxCurrentStreak}',
          subtitle: 'mejor racha activa',
          icon: Icons.local_fire_department_rounded,
          color: scheme.tertiary,
        ),
        FocusStatCard(
          title: 'Mejor racha',
          value: '${summary.bestStreak}',
          subtitle: 'histórico visible',
          icon: Icons.emoji_events_rounded,
          color: scheme.error,
        ),
      ],
    );
  }
}

class _NameRow extends StatelessWidget {
  final Habit habit;
  final bool editMode;
  final bool selected;
  final dynamic todayValue;
  final VoidCallback onTap;
  final Widget? trailing;

  const _NameRow({
    super.key,
    required this.habit,
    required this.editMode,
    this.selected = false,
    this.todayValue,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = habit.color;

    return SizedBox(
      height: _HabitsTableScreenState._rowHeight,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: () {
                if (!editMode) {
                  final state =
                      context
                          .findAncestorStateOfType<_HabitsTableScreenState>();
                  if (state != null) {
                    state._enterEditMode(habit);
                  }
                }
              },
              child: Container(
                margin: _HabitsTableScreenState._cellMargin,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? scheme.primaryContainer.withValues(alpha: 0.35)
                          : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        selected
                            ? scheme.primary.withValues(alpha: 0.34)
                            : scheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child:
                            habit.emoji != null
                                ? Text(
                                  habit.emoji!,
                                  style: const TextStyle(fontSize: 18),
                                )
                                : habit.iconCode != null
                                ? Icon(
                                  HabitIcons.getIcon(habit.iconCode),
                                  color: tone,
                                  size: 18,
                                )
                                : Icon(
                                  Icons.check_circle_outline,
                                  color: tone,
                                  size: 18,
                                ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        habit.name,
                        maxLines: 3,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (!editMode) ...[
                      const SizedBox(width: 4),
                      _TodayStatusBadge(habit: habit, todayValue: todayValue),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (editMode)
            (trailing ??
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                )),
        ],
      ),
    );
  }
}

class _TodayStatusBadge extends StatelessWidget {
  final Habit habit;
  final dynamic todayValue;

  const _TodayStatusBadge({required this.habit, required this.todayValue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = todayValue;

    if (!isHabitLoggedValue(habit, value)) {
      return const SizedBox.shrink();
    }

    if (isHabitCompletedValue(habit, value)) {
      return Tooltip(
        message: 'Completado hoy',
        child: Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
      );
    }

    if (isHabitMissedValue(value)) {
      return Tooltip(
        message: 'No completado',
        child: Icon(
          Icons.cancel_rounded,
          size: 16,
          color: theme.colorScheme.error,
        ),
      );
    }

    if (isHabitSkippedValue(value)) {
      return Tooltip(
        message: 'Saltado',
        child: Icon(
          Icons.remove_circle_rounded,
          size: 16,
          color: theme.colorScheme.tertiary,
        ),
      );
    }

    final progress = computeHabitGoalProgress(habit, value: value);
    return Tooltip(
      message:
          progress.hasGoal
              ? '${formatHabitStatNumber(progress.percent)}% de la meta de hoy'
              : 'Registro cuantitativo guardado',
      child: Icon(
        isHabitCompletedValue(habit, value)
            ? Icons.check_circle_rounded
            : Icons.radio_button_checked_rounded,
        size: 16,
        color:
            isHabitCompletedValue(habit, value)
                ? theme.colorScheme.secondary
                : habit.color,
      ),
    );
  }
}

class _HabitsTableScrollBehavior extends MaterialScrollBehavior {
  const _HabitsTableScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
