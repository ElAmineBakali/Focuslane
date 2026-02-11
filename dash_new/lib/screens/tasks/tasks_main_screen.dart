import 'package:flutter/material.dart';
import 'task_model.dart';
import 'task_firestore_service.dart';
import 'task_helpers.dart';
import 'package:mi_dashboard_personal/services/reminder_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_dashboard_personal/core/constants/core_routes.dart';

class TasksMainScreen extends StatefulWidget {
  const TasksMainScreen({super.key, this.startWithChecklist = true});
  final bool startWithChecklist;
  @override
  State<TasksMainScreen> createState() => _TasksMainScreenState();
}

class _TasksMainScreenState extends State<TasksMainScreen> {
  int _tab = 1;
  @override
  void initState() {
    super.initState();
    _tab = widget.startWithChecklist ? 1 : 0;
  }

  bool showCompleted = false;
  String sortBy = 'manual';

  final Map<TaskGroup, bool> _expandedGroups = {
    TaskGroup.overdue: true,
    TaskGroup.today: true,
    TaskGroup.tomorrow: true,
    TaskGroup.thisWeek: true,
    TaskGroup.later: false,
    TaskGroup.noDate: false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TabTextButton(
              label: 'Checklist',
              selected: _tab == 1,
              onTap: () => setState(() => _tab = 1),
            ),
            const SizedBox(width: 18),
            _TabTextButton(
              label: 'Tareas',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
          ],
        ),
        centerTitle: true,
        actions:
            _tab == 0
                ? [
                  IconButton(
                    tooltip: 'Abrir Hub',
                    icon: const Icon(Icons.hub_outlined),
                    onPressed: () => Navigator.pushNamed(context, CoreRoutes.coreHub),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_alt, color: theme.iconTheme.color),
                    onPressed: () => _showFilterDialog(context),
                  ),
                ]
                : [
                  IconButton(
                    tooltip: 'Abrir Hub',
                    icon: const Icon(Icons.hub_outlined),
                    onPressed: () => Navigator.pushNamed(context, CoreRoutes.coreHub),
                  ),
                  IconButton(
                    tooltip: 'Marcar todo',
                    icon: const Icon(Icons.done_all),
                    onPressed: () => _Checklist.checkAll(context),
                  ),
                  IconButton(
                    tooltip: 'Desmarcar todo',
                    icon: const Icon(Icons.close_fullscreen),
                    onPressed: () => _Checklist.uncheckAll(context),
                  ),
                ],
      ),

      body: _tab == 0 ? _buildTasksBody(theme) : const _ChecklistToday(),

      floatingActionButton:
          _tab == 0
              ? FloatingActionButton(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                onPressed: () {
                  Navigator.pushNamed(context, '/tasks/create');
                },
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildTasksBody(ThemeData theme) {
    return StreamBuilder<List<Task>>(
      stream: TaskFirestoreService.getTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No hay datos'));
        }

        List<Task> allTasks = snapshot.data!;

        List<Task> tasks =
            allTasks
                .where((task) => showCompleted ? true : !task.completed)
                .toList();

        tasks = TaskGrouper.sortTasks(tasks);

        final groups = TaskGrouper.groupTasks(tasks);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (groups[TaskGroup.overdue]!.isNotEmpty)
              _buildCollapsibleTaskGroup(
                context,
                theme,
                TaskGroup.overdue,
                groups[TaskGroup.overdue]!,
                isDark ? cs.errorContainer : cs.error.withOpacity(0.1),
              ),
            if (groups[TaskGroup.today]!.isNotEmpty)
              _buildCollapsibleTaskGroup(
                context,
                theme,
                TaskGroup.today,
                groups[TaskGroup.today]!,
                isDark
                    ? cs.primaryContainer.withOpacity(0.3)
                    : cs.primary.withOpacity(0.08),
              ),
            if (groups[TaskGroup.tomorrow]!.isNotEmpty)
              _buildCollapsibleTaskGroup(
                context,
                theme,
                TaskGroup.tomorrow,
                groups[TaskGroup.tomorrow]!,
                isDark
                    ? cs.secondaryContainer.withOpacity(0.3)
                    : cs.secondary.withOpacity(0.08),
              ),
            if (groups[TaskGroup.thisWeek]!.isNotEmpty)
              _buildCollapsibleTaskGroup(
                context,
                theme,
                TaskGroup.thisWeek,
                groups[TaskGroup.thisWeek]!,
                isDark
                    ? cs.tertiaryContainer.withOpacity(0.3)
                    : cs.tertiary.withOpacity(0.08),
              ),
            if (groups[TaskGroup.later]!.isNotEmpty)
              _buildCollapsibleTaskGroup(
                context,
                theme,
                TaskGroup.later,
                groups[TaskGroup.later]!,
                isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh,
              ),
            if (groups[TaskGroup.noDate]!.isNotEmpty)
              _buildCollapsibleTaskGroup(
                context,
                theme,
                TaskGroup.noDate,
                groups[TaskGroup.noDate]!,
                isDark ? cs.surfaceContainerHigh : cs.surfaceContainer,
              ),

            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    showCompleted
                        ? 'No hay tareas'
                        : 'No hay tareas pendientes',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCollapsibleTaskGroup(
    BuildContext context,
    ThemeData theme,
    TaskGroup group,
    List<Task> tasks,
    Color? headerColor,
  ) {
    final cs = theme.colorScheme;
    final isExpanded = _expandedGroups[group] ?? true;

    return Column(
      children: [
        Material(
          color: headerColor,
          child: InkWell(
            onTap: () {
              setState(() {
                _expandedGroups[group] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.label.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder:
                (context, index) =>
                    _buildTaskCard(context, theme, tasks[index]),
          ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, ThemeData theme, Task task) {
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasReminder = task.remindAt != null;
    final hasRepeat = task.repeatRule != RepeatRule.none;
    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.completed;

    final cardColor =
        isOverdue
            ? (isDark
                ? cs.errorContainer.withOpacity(0.3)
                : cs.error.withOpacity(0.1))
            : cs.surface;

    final textColor =
        isOverdue ? (isDark ? cs.onErrorContainer : cs.error) : cs.onSurface;

    return Card(
      key: ValueKey(task.id),
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isDark ? 2 : 1,
      shadowColor: cs.shadow.withOpacity(0.1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: task.priority.getColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Checkbox(
              visualDensity: VisualDensity.compact,
              value: task.completed,
              onChanged: (val) async {
                final previous = task;
                final updated = task.copyWith(completed: val ?? false);
                await TaskFirestoreService.updateTask(updated);

                if (updated.completed) {
                  try {
                    await ReminderService.I.cancelTaskReminder(task.id);
                  } catch (e) {
                    debugPrint('Error canceling task reminder: $e');
                  }
                  if (task.repeatRule != RepeatRule.none) {
                    final nextDue = _nextDueDate(task.dueDate, task.repeatRule);
                    final nextRemind = _nextDateFrom(
                      task.remindAt,
                      task.repeatRule,
                    );
                    final nextSubtasks =
                        task.subtasks
                            .map((s) => s.copyWith(isDone: false))
                            .toList();
                    final nextTask = task.copyWith(
                      id: '',
                      completed: false,
                      dueDate: nextDue,
                      remindAt: nextRemind,
                      subtasks: nextSubtasks,
                    );
                    final newId = await TaskFirestoreService.addTask(nextTask);
                    if (newId != null) {
                      final withId = nextTask.copyWith(id: newId);
                      try {
                        await ReminderService.I.scheduleTaskReminder(withId);
                      } catch (e) {
                        debugPrint('Error scheduling next repeated task: $e');
                      }
                    }
                  }
                } else {
                  try {
                    await ReminderService.I.scheduleTaskReminder(
                      updated,
                      previous: previous,
                      globalEnabled: true,
                      tasksEnabled: true,
                    );
                  } catch (e) {
                    debugPrint('Error scheduling task reminder: $e');
                  }
                }
              },
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  decoration:
                      task.completed ? TextDecoration.lineThrough : null,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (task.isPinned)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.push_pin, size: 16, color: cs.primary),
              ),
            if (hasRepeat)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.autorenew, size: 16, color: cs.secondary),
              ),
            if (hasReminder)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.notifications_active,
                  size: 16,
                  color: cs.secondary,
                ),
              ),
            if (task.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.label,
                  size: 16,
                  color: cs.primary.withOpacity(0.7),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TaskFormatter.formatDueDate(task.dueDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isOverdue ? textColor : cs.onSurfaceVariant,
              ),
            ),
            if (task.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children:
                      task.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 6),
              Column(
                children: [
                  for (int i = 0; i < task.subtasks.length; i++)
                    _SubtaskRow(
                      subtask: task.subtasks[i],
                      canMoveUp: i > 0,
                      canMoveDown: i < task.subtasks.length - 1,
                      onToggle: (isDone) async {
                        final updatedSubs = List<Subtask>.from(task.subtasks);
                        updatedSubs[i] = updatedSubs[i].copyWith(
                          isDone: isDone,
                        );
                        final updated = task.copyWith(subtasks: updatedSubs);
                        await TaskFirestoreService.updateTask(updated);
                      },
                      onMoveUp: () async {
                        if (i <= 0) return;
                        final updatedSubs = List<Subtask>.from(task.subtasks);
                        final item = updatedSubs.removeAt(i);
                        updatedSubs.insert(i - 1, item);
                        final updated = task.copyWith(subtasks: updatedSubs);
                        await TaskFirestoreService.updateTask(updated);
                      },
                      onMoveDown: () async {
                        if (i >= task.subtasks.length - 1) return;
                        final updatedSubs = List<Subtask>.from(task.subtasks);
                        final item = updatedSubs.removeAt(i);
                        updatedSubs.insert(i + 1, item);
                        final updated = task.copyWith(subtasks: updatedSubs);
                        await TaskFirestoreService.updateTask(updated);
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.delete_outline, color: cs.onSurfaceVariant),
          onPressed: () async {
            try {
              await ReminderService.I.cancelTaskReminder(task.id);
            } catch (e) {
              debugPrint('Error canceling task reminder on delete: $e');
            }
            await TaskFirestoreService.deleteTask(task.id);
          },
          tooltip: 'Eliminar',
        ),
        onTap: () {
          Navigator.pushNamed(context, '/tasks/detail', arguments: task);
        },
      ),
    );
  }

  DateTime? _nextDueDate(DateTime? current, RepeatRule rule) {
    if (current == null) return null;
    switch (rule) {
      case RepeatRule.daily:
        return current.add(const Duration(days: 1));
      case RepeatRule.weekly:
        return current.add(const Duration(days: 7));
      case RepeatRule.monthly:
        return DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
      case RepeatRule.none:
        return null;
    }
  }

  DateTime? _nextDateFrom(DateTime? current, RepeatRule rule) {
    if (current == null) return null;
    switch (rule) {
      case RepeatRule.daily:
        return current.add(const Duration(days: 1));
      case RepeatRule.weekly:
        return current.add(const Duration(days: 7));
      case RepeatRule.monthly:
        return DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
      case RepeatRule.none:
        return null;
    }
  }

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          /*           title: Text(
            'Filtros y Orden',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ), */
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Mostrar completadas',
                  style: theme.textTheme.bodyLarge,
                ),
                activeThumbColor: theme.colorScheme.secondary,
                value: showCompleted,
                onChanged: (val) {
                  setState(() => showCompleted = val);
                  Navigator.pop(context);
                },
              ),
              /* const SizedBox(height: 12),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ordenar por:',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sortBy,
                    isExpanded: true,
                    dropdownColor: theme.colorScheme.surface,
                    style: theme.textTheme.bodyMedium,
                    iconEnabledColor: theme.iconTheme.color,
                    onChanged: (val) {
                      setState(() => sortBy = val!);
                      Navigator.pop(context);
                    },
                    items: const [
                      DropdownMenuItem(value: 'smart', child: Text('Agrupación inteligente')),
                      DropdownMenuItem(value: 'manual', child: Text('Orden manual')),
                      DropdownMenuItem(value: 'dateAsc', child: Text('Fecha ascendente')),
                      DropdownMenuItem(value: 'dateDesc', child: Text('Fecha descendente')),
                      DropdownMenuItem(value: 'priorityHigh', child: Text('Prioridad alta')),
                      DropdownMenuItem(value: 'priorityLow', child: Text('Prioridad baja')),
                    ],
                  ),
                ),
              ), */
            ],
          ),
        );
      },
    );
  }
}

class _TabTextButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabTextButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      color: selected ? cs.primary : cs.onSurface,
      decoration: selected ? TextDecoration.underline : TextDecoration.none,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(label, style: style),
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  final Subtask subtask;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<bool> onToggle;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _SubtaskRow({
    required this.subtask,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onToggle,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(
            visualDensity: VisualDensity.compact,
            value: subtask.isDone,
            onChanged: (v) => onToggle(v ?? false),
          ),
          Expanded(
            child: Text(
              subtask.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration: subtask.isDone ? TextDecoration.lineThrough : null,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            visualDensity: VisualDensity.compact,
            onPressed: canMoveUp ? onMoveUp : null,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            visualDensity: VisualDensity.compact,
            onPressed: canMoveDown ? onMoveDown : null,
          ),
        ],
      ),
    );
  }
}

class _Checklist {
  static CollectionReference<Map<String, dynamic>> _col() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('checklist')
        .doc('data')
        .collection('items');
  }

  static Stream<List<_ChecklistItem>> watchToday() {
    return _col()
        .orderBy('order')
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => _ChecklistItem.fromDoc(d.id, d.data()))
                  .toList(),
        );
  }

  static Future<void> add(String text) async {
    final col = _col();
    final snap = await col.get();
    final next = snap.size;
    await col.add({'text': text, 'done': false, 'order': next});
  }

  static Future<void> toggle(_ChecklistItem it) async {
    await _col().doc(it.id).update({'done': !it.done});
  }

  static Future<void> remove(_ChecklistItem it) async {
    await _col().doc(it.id).delete();
    final items = await _col().orderBy('order').get();
    int i = 0;
    for (final d in items.docs) {
      await d.reference.update({'order': i++});
    }
  }

  static Future<void> reorder(
    int oldIndex,
    int newIndex,
    List<_ChecklistItem> list,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    for (int i = 0; i < list.length; i++) {
      await _col().doc(list[i].id).update({'order': i});
    }
  }

  static Future<void> setColor(_ChecklistItem it, String? hex) async {
    await _col().doc(it.id).update({'color': hex});
  }

  static const int _kBatchLimit = 450;

  static Future<void> checkAll(BuildContext context) async {
    await _setAll(done: true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Todo marcado ✅'),
        ),
      );
    }
  }

  static Future<void> uncheckAll(BuildContext context) async {
    await _setAll(done: false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Todo desmarcado ✨'),
        ),
      );
    }
  }

  static Future<void> _setAll({required bool done}) async {
    final qs = await _col().get();
    for (var i = 0; i < qs.docs.length; i += _kBatchLimit) {
      final slice = qs.docs.skip(i).take(_kBatchLimit);
      final batch = FirebaseFirestore.instance.batch();
      for (final d in slice) {
        batch.update(d.reference, {'done': done});
      }
      await batch.commit();
    }
  }
}

class _ChecklistItem {
  final String id;
  final String text;
  final bool done;
  final int order;
  final String? colorHex;

  _ChecklistItem({
    required this.id,
    required this.text,
    required this.done,
    required this.order,
    required this.colorHex,
  });

  static _ChecklistItem fromDoc(String id, Map<String, dynamic> m) {
    return _ChecklistItem(
      id: id,
      text: (m['text'] ?? '').toString(),
      done: (m['done'] ?? false) as bool,
      order: (m['order'] ?? 0) as int,
      colorHex: m['color'] as String?,
    );
  }
}

class _ChecklistToday extends StatefulWidget {
  const _ChecklistToday();
  @override
  State<_ChecklistToday> createState() => _ChecklistTodayState();
}

class _ChecklistTodayState extends State<_ChecklistToday> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_ChecklistItem>>(
      stream: _Checklist.watchToday(),
      builder: (context, snap) {
        final items = snap.data ?? const <_ChecklistItem>[];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Nuevo ítem rápido',
                        prefixIcon: Icon(Icons.add_task),
                      ),
                      onSubmitted: (s) async {
                        final t = s.trim();
                        if (t.isEmpty) return;
                        await _Checklist.add(t);
                        _ctrl.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final t = _ctrl.text.trim();
                      if (t.isEmpty) return;
                      await _Checklist.add(t);
                      _ctrl.clear();
                    },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
                itemCount: items.length,
                onReorder: (o, n) async => _Checklist.reorder(o, n, items),
                buildDefaultDragHandles: false,
                itemBuilder: (c, i) {
                  final it = items[i];
                  final color = _colorFromHex(it.colorHex);
                  final tileBg = color?.withOpacity(0.12);
                  return Card(
                    key: ValueKey(it.id),
                    color: tileBg ?? Theme.of(context).cardColor,
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReorderableDragStartListener(
                            index: i,
                            child: const Icon(Icons.drag_handle_rounded),
                          ),
                          const SizedBox(width: 6),
                          _ColorPill(color: color),
                        ],
                      ),
                      title: Text(
                        it.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration:
                              it.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ColorMenuButton(
                            current: color,
                            onPick:
                                (c) =>
                                    _Checklist.setColor(it, _hexFromColor(c)),
                            onClear: () => _Checklist.setColor(it, null),
                          ),
                          Checkbox(
                            visualDensity: VisualDensity.compact,
                            value: it.done,
                            onChanged: (_) => _Checklist.toggle(it),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _Checklist.remove(it),
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
    );
  }
}

const List<Color> _kPalette = [
  Color(0xFFFF8A80),
  Color(0xFFFFC400),
  Color(0xFFFFF176),
  Color(0xFFA5D6A7),
  Color(0xFF66BB6A),
  Color(0xFF80DEEA),
  Color(0xFF81D4FA),
  Color(0xFF64B5F6),
  Color(0xFFCE93D8),
  Color(0xFFF48FB1),
  Color(0xFFBCAAA4),
  Color(0xFFCFD8DC),
];

String? _hexFromColor(Color? c) =>
    c == null
        ? null
        : '#${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

Color? _colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (v == null) return null;
  return Color(v);
}

class _ColorPill extends StatelessWidget {
  final Color? color;
  const _ColorPill({this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color == null ? cs.outlineVariant : color!.withOpacity(.9),
          width: 1,
        ),
      ),
    );
  }
}

class _ColorMenuButton extends StatelessWidget {
  final Color? current;
  final ValueChanged<Color?> onPick;
  final VoidCallback onClear;

  const _ColorMenuButton({
    required this.current,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Color?>(
      tooltip: 'Color',
      icon: const Icon(Icons.palette_outlined),
      itemBuilder: (context) {
        return <PopupMenuEntry<Color?>>[
          PopupMenuItem<Color?>(
            enabled: false,
            child: SizedBox(
              width: 220,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _kPalette)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onPick(c);
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                (current == c)
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.black26,
                            width: current == c ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<Color?>(
            value: null,
            onTap: onClear,
            child: const Text('Sin color'),
          ),
        ];
      },
    );
  }
}
