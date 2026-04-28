import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_firestore_service.dart';
import '../utils/task_helpers.dart';

class TasksMainScreen extends StatefulWidget {
  const TasksMainScreen({super.key});
  @override
  State<TasksMainScreen> createState() => _TasksMainScreenState();
}

class _TasksMainScreenState extends State<TasksMainScreen> {
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
        title: const Text('Tareas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt, color: theme.iconTheme.color),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),

      body: _buildTasksBody(theme),

      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        onPressed: () {
          Navigator.pushNamed(context, '/tasks/create');
        },
        child: const Icon(Icons.add),
      ),
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
                final updated = task.copyWith(completed: val ?? false);
                await TaskFirestoreService.updateTask(updated);

                if (updated.completed) {
                  if (task.repeatRule != RepeatRule.none) {
                    final nextDue = _nextDueDate(task.dueDate, task.repeatRule);
                    final nextSubtasks =
                        task.subtasks
                            .map((s) => s.copyWith(isDone: false))
                            .toList();
                    final nextTask = Task(
                      id: '',
                      title: task.title,
                      description: task.description,
                      priority: task.priority,
                      category: task.category,
                      completed: false,
                      order: task.order,
                      tags: task.tags,
                      dueDate: nextDue,
                      remindAt: null,
                      isPinned: task.isPinned,
                      repeatRule: task.repeatRule,
                      subtasks: nextSubtasks,
                      isCalendarVisible: task.isCalendarVisible,
                      linkedNoteId: task.linkedNoteId,
                      linkedStudyCourseId: task.linkedStudyCourseId,
                      syncedStudyTaskId: task.syncedStudyTaskId,
                    );
                    await TaskFirestoreService.addTask(nextTask);
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
