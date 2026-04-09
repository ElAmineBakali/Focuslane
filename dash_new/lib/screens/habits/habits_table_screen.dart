import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:focuslane/screens/habits/habit_model.dart';
import 'package:focuslane/screens/habits/habit_firestore_service.dart';
import 'package:focuslane/screens/habits/habit_constants.dart';
import 'package:focuslane/screens/habits/habit_utils.dart';
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

    final expectedLastDate =
        today.subtract(Duration(days: _loadedTimelineDays - 1));
    final shouldRebuildDates = _dates.isEmpty ||
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

    final supportsDesktopPointer = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    if (!supportsDesktopPointer) {
      return;
    }

    final step = event.scrollDelta.dx != 0
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
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
      return theme.colorScheme.secondaryContainer.withOpacity(0.72);
    }
    if (status == habitMissedValue) {
      return theme.colorScheme.errorContainer.withOpacity(0.82);
    }
    if (status == habitSkippedValue) {
      return theme.colorScheme.tertiaryContainer.withOpacity(0.78);
    }

    final isLight = theme.brightness == Brightness.light;
    final hasValue = value != null;
    final base = theme.colorScheme.surfaceContainerHighest;
    final opacity = isLight ? (hasValue ? .35 : .18) : (hasValue ? .40 : .22);
    return base.withOpacity(opacity);
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
      final displayValue = numericValue.abs() >= 1000
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
                color: theme.colorScheme.onSurface.withOpacity(.6),
              ),
            ),
        ],
      );
    }
    return Text(
      '—',
      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(.45)),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, habitCompletedValue),
                  style: TextButton.styleFrom(foregroundColor: sec),
                  child: const Icon(Icons.check_rounded),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, habitMissedValue),
                  style: TextButton.styleFrom(foregroundColor: sec),
                  child: const Icon(Icons.close_rounded),
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

          _showConfetti(habit: habit, isPerfectDay: allCompleted && allHabits.isNotEmpty);
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

          _showConfetti(habit: habit, isPerfectDay: allCompleted && allHabits.isNotEmpty);
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
    if (streaks.current == habit.currentStreak && streaks.best == habit.bestStreak) {
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
      builder:
          (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
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
        ),
        child: _valueContent(habit, value, theme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stream =
        _showArchived
            ? HabitFirestoreService.getArchivedHabits()
            : HabitFirestoreService.getHabits();

    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.light
              ? const Color.fromARGB(255, 255, 255, 255)
              : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hábitos'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Recordatorios',
            icon: const Icon(Icons.notifications_active_outlined),
            onSelected: (value) async {
              if (value == 'schedule') {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 21, minute: 0),
                );
                if (picked != null) {
                  final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';
                  final now = DateTime.now();
                  final first = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    picked.hour,
                    picked.minute,
                  );
                  final entity = const NotificationEntityRef(
                    module: NotificationModule.habits,
                    kind: 'daily_review',
                    id: 'master',
                  );

                  await NotificationsFacade.I.cancelByEntity(entity);
                  await NotificationsFacade.I.scheduleIntent(
                    NotificationIntent(
                      module: NotificationModule.habits,
                      type: 'HABITS_DAILY_REVIEW',
                      entity: entity,
                      content: const NotificationContent(
                        title: 'Recordatorio de habitos',
                        body: 'Toca para revisar tus habitos de hoy',
                      ),
                      action: const NotificationAction(
                        kind: NotificationActionKind.openRoute,
                        route: '/habits',
                      ),
                      schedule: NotificationSchedule(
                        kind: NotificationScheduleKind.daily,
                        scheduledAtUtc: first.toUtc(),
                        timezone: first.timeZoneName,
                        hour: picked.hour,
                        minute: picked.minute,
                      ),
                      delivery: const NotificationDelivery(
                        kind: NotificationDeliveryKind.localOnly,
                        channel: AndroidChannelCatalog.habitsReminders,
                        priority: NotificationPriority.high,
                      ),
                      dedupeKey:
                          'habits:daily_review:${picked.hour}:${picked.minute}',
                      userId: uid,
                      source: 'habits.menu',
                      notificationId:
                          'ntf_habits_daily_review_${picked.hour}_${picked.minute}',
                    ),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Te avisare todos los dias a la hora elegida para revisar habitos.',
                      ),
                    ),
                  );
                }
              } else if (value == 'cancel') {
                await NotificationsFacade.I.cancelByEntity(
                  const NotificationEntityRef(
                    module: NotificationModule.habits,
                    kind: 'daily_review',
                    id: 'master',
                  ),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Recordatorio diario cancelado.'),
                  ),
                );
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(
                    value: 'schedule',
                    child: Text('Programar recordatorio'),
                  ),
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancelar recordatorio'),
                  ),
                ],
          ),
          IconButton(
            tooltip: _showArchived ? 'Ver activos' : 'Ver archivados',
            onPressed:
                () => setState(() {
                  _orderedHabits = null;
                  _showArchived = !_showArchived;
                }),
            icon: Icon(
              _showArchived ? Icons.inbox_rounded : Icons.archive_outlined,
            ),
          ),
          if (_editMode && _selectedHabit != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showEditOptions,
            ),
          if (_editMode)
            IconButton(icon: const Icon(Icons.close), onPressed: _exitEditMode),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/habits/create'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
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

            if (habits.isEmpty) {
              return const Center(child: Text('No hay hábitos para mostrar.'));
            }

            return Row(
              children: [
                SizedBox(
                  width: _nameColWidth,
                  child: Column(
                    children: [
                      SizedBox(height: _rowHeight),
                      const SizedBox(height: 2),
                      Expanded(
                        child:
                            _editMode
                                ? PrimaryScrollController(
                                  controller: _leftV,
                                  child: ReorderableListView.builder(
                                    padding: const EdgeInsets.only(
                                      bottom: _bottomSafeGap,
                                    ),
                                    itemCount: habits.length,
                                    buildDefaultDragHandles: false,
                                    onReorder: _onReorder,
                                    physics: const ClampingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final habit = habits[index];
                                      return _NameRow(
                                        key: ValueKey(habit.id),
                                        habit: habit,
                                        editMode: true,
                                        onTap:
                                            () => setState(
                                              () => _selectedHabit = habit,
                                            ),
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
                                  ),
                                )
                                : ListView.builder(
                                  controller: _leftV,
                                  padding: const EdgeInsets.only(
                                    bottom: _bottomSafeGap,
                                  ),
                                  physics: const ClampingScrollPhysics(),
                                  itemExtent: _rowHeight,
                                  itemCount: habits.length,
                                  itemBuilder: (context, index) {
                                    final habit = habits[index];
                                    final todayValue = habitHistoryIndexedValue(
                                      _historyIndexByHabit[habit.id] ??
                                          const <String, dynamic>{},
                                      DateTime.now(),
                                    );
                                    return _NameRow(
                                      habit: habit,
                                      editMode: false,
                                      todayValue: todayValue,
                                      onTap:
                                          () => Navigator.pushNamed(
                                            context,
                                            '/habits/stats',
                                            arguments: habit,
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
                      final bodyHeight = cons.maxHeight - _rowHeight - 2;
                      return Listener(
                        onPointerSignal: _handleHorizontalPointerSignal,
                        child: ScrollConfiguration(
                          behavior: const _HabitsTableScrollBehavior(),
                          child: Scrollbar(
                            controller: _horizontal,
                            thumbVisibility: true,
                            trackVisibility: true,
                            interactive: true,
                            notificationPredicate: (notification) =>
                                notification.metrics.axis == Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: _horizontal,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: gridWidth,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: _rowHeight,
                                      child: Row(
                                        children:
                                            _dates.map((d) {
                                              return Container(
                                                width: _cellWidth,
                                                height: _cellHeight,
                                                margin: _cellMargin,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                      .withOpacity(.25),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  DateFormat('E\ndd').format(d),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(.8),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    SizedBox(
                                      height: bodyHeight,
                                      child: ListView.builder(
                                        controller: _rightV,
                                        padding: const EdgeInsets.only(
                                          bottom: _bottomSafeGap,
                                        ),
                                        physics: const ClampingScrollPhysics(),
                                        itemExtent: _rowHeight,
                                        itemCount: habits.length,
                                        itemBuilder: (context, row) {
                                          final habit = habits[row];
                                          final historyIndex =
                                              _historyIndexByHabit[habit.id] ??
                                              const <String, dynamic>{};
                                          return Row(
                                            children:
                                                _dates
                                                    .map(
                                                      (d) => _cell(
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
            );
          },
        ),
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  final Habit habit;
  final bool editMode;
  final dynamic todayValue;
  final VoidCallback onTap;
  final Widget? trailing;

  const _NameRow({
    super.key,
    required this.habit,
    required this.editMode,
    this.todayValue,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: Row(
                  children: [
                    if (habit.emoji != null)
                      Text(habit.emoji!, style: const TextStyle(fontSize: 20))
                    else if (habit.iconCode != null)
                      Icon(
                        HabitIcons.getIcon(habit.iconCode),
                        color: habit.color,
                        size: 20,
                      )
                    else
                      Icon(
                        Icons.check_circle_outline,
                        color: habit.color,
                        size: 20,
                      ),
                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        habit.name,
                        maxLines: 3,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: habit.color,
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
      message: progress.hasGoal
          ? '${formatHabitStatNumber(progress.percent)}% de la meta de hoy'
          : 'Registro cuantitativo guardado',
      child: Icon(
        isHabitCompletedValue(habit, value)
            ? Icons.check_circle_rounded
            : Icons.radio_button_checked_rounded,
        size: 16,
        color: isHabitCompletedValue(habit, value)
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


