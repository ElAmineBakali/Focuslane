import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_model.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_constants.dart';
import 'package:mi_dashboard_personal/screens/habits/widgets/confetti_animation.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';

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

  late final List<DateTime> _dates = List.generate(
    30,
    (i) => DateTime.now().subtract(Duration(days: i)),
  );

  static const double _nameColWidth = 140;
  static const double _cellWidth = 64;
  static const double _cellHeight = 52;
  static const EdgeInsets _cellMargin = EdgeInsets.all(4);
  static double get _rowHeight => _cellHeight + _cellMargin.vertical;

     static const double _bottomSafeGap = 100;

  List<Habit>? _orderedHabits;

  final ScrollController _leftV = ScrollController();
  final ScrollController _rightV = ScrollController();
  bool _syncingL = false;
  bool _syncingR = false;

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
  }

  @override
  void dispose() {
    _leftV.dispose();
    _rightV.dispose();
    super.dispose();
  }

  Color _cellBg(dynamic value, ThemeData theme) {
    final isLight = theme.brightness == Brightness.light;
    final hasValue = value != null && value != '-';
    final base = theme.colorScheme.surfaceContainerHighest;
    final op = isLight ? (hasValue ? .35 : .18) : (hasValue ? .40 : .22);
    return base.withOpacity(op);
  }

  Widget _valueContent(Habit habit, dynamic value, ThemeData theme) {
    if (value == '✔️')
      return Icon(Icons.check_rounded, color: habit.color, size: 22);
    if (value == '❌')
      return Icon(Icons.close_rounded, color: habit.color, size: 22);
    final s = value?.toString();
    final isNum = s != null && int.tryParse(s) != null;
    if (habit.isQuantitative && isNum) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            s,
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
      '–',
      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(.45)),
    );
  }

  Future<void> _updateHistoryValue(Habit habit, DateTime date) async {
    final theme = Theme.of(context);
    final sec = theme.colorScheme.secondary;
    final key = DateFormat('yyyy-MM-dd').format(date);

    if (!habit.isQuantitative) {
      final result = await showDialog<String>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('¿Qué quieres marcar?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, '✔️'),
                  style: TextButton.styleFrom(foregroundColor: sec),
                  child: const Icon(Icons.check_rounded),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, '❌'),
                  style: TextButton.styleFrom(foregroundColor: sec),
                  child: const Icon(Icons.close_rounded),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, '-'),
                  style: TextButton.styleFrom(foregroundColor: sec),
                  child: const Text('Saltar'),
                ),
              ],
            ),
      );
      if (result != null) {
        await _habitService.updateHabitHistory(habit.id, date, result);
        habit.history[key] = result;

                 if (result == '✔️' && _isToday(date)) {
          await _updateStreak(habit, true);

                     if (mounted) {
            final allHabits = _orderedHabits ?? [];
            final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final allCompleted = allHabits.every(
              (h) => h.history[todayKey] == '✔️',
            );

            if (allCompleted && allHabits.isNotEmpty) {
              _showConfetti(habit: habit, isPerfectDay: true);
            } else {
              _showConfetti(habit: habit, isPerfectDay: false);
            }
          }
        } else if (result == '❌' && _isToday(date)) {
          await _updateStreak(habit, false);
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
                  onPressed: () => Navigator.pop(context, '-'),
                  style: TextButton.styleFrom(foregroundColor: sec),
                  child: const Text('Saltar'),
                ),
              ],
            ),
      );
      if (result != null) {
        await _habitService.updateHabitHistory(habit.id, date, result);
        habit.history[key] = result;

                 if (result != '-' && _isToday(date)) {
          final value = int.tryParse(result) ?? 0;
          final goalMet =
              value > 0;            await _updateStreak(habit, goalMet);

          if (goalMet && mounted) {
            final allHabits = _orderedHabits ?? [];
            final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final allCompleted = allHabits.every((h) {
              final val = h.history[todayKey];
              if (h.isQuantitative) {
                final v = int.tryParse(val?.toString() ?? '0') ?? 0;
                return v > 0;
              }
              return val == '✔️';
            });

            if (allCompleted && allHabits.isNotEmpty) {
              _showConfetti(habit: habit, isPerfectDay: true);
            } else {
              _showConfetti(habit: habit, isPerfectDay: false);
            }
          }
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

  Future<void> _updateStreak(Habit habit, bool completed) async {
    if (completed) {
      final newStreak = habit.currentStreak + 1;
      final newBest = math.max(habit.bestStreak, newStreak);

      await HabitFirestoreService.updateHabitFields(habit.id, {
        'currentStreak': newStreak,
        'bestStreak': newBest,
      });

      habit.currentStreak = newStreak;
      habit.bestStreak = newBest;
    } else {
      if (habit.currentStreak > 0) {
        await HabitFirestoreService.updateHabitFields(habit.id, {
          'currentStreak': 0,
        });
        habit.currentStreak = 0;
      }
    }
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

  Widget _cell(Habit habit, DateTime date, ThemeData theme) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final value = habit.history[key];
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

    final double gridWidth =
        _dates.length * (_cellWidth + _cellMargin.horizontal);

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
                                     await NotificationService.I.scheduleHabitDailyReminder(
                    picked,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          '👌 Te avisaré todos los días a la hora elegida para revisar hábitos.',
                        ),
                      ),
                    );
                  }
                }
              } else if (value == 'cancel') {
                await NotificationService.I.cancelHabitDailyReminder();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('⏰ Recordatorio diario cancelado.'),
                    ),
                  );
                }
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
            if (snap.hasError)
              return Center(child: Text('Error: ${snap.error}'));
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());

            final habits = [
              ...snap.data!..sort((a, b) => a.order.compareTo(b.order)),
            ];
            _orderedHabits = habits;

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
                                    return _NameRow(
                                      habit: habit,
                                      editMode: false,
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
                      return SingleChildScrollView(
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
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            DateFormat('E\ndd').format(d),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface
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
                                    return Row(
                                      children:
                                          _dates
                                              .map(
                                                (d) => _cell(habit, d, theme),
                                              )
                                              .toList(),
                                    );
                                  },
                                ),
                              ),
                            ],
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
  final VoidCallback onTap;
  final Widget? trailing;

  const _NameRow({
    super.key,
    required this.habit,
    required this.editMode,
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
                                     state?.setState(() {
                    state._editMode = true;
                    state._selectedHabit = habit;
                  });
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
