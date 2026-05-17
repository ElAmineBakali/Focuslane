import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';

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
    return AppShell(
      title: 'Tareas',
      subtitle: 'Organiza pendientes, fechas limite y prioridades.',
      activeRoute: AppRoutes.tasksDashboard,
      actions: [
        FocusIconButton(
          icon:
              showCompleted
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_outlined,
          tooltip:
              showCompleted ? 'Ocultar completadas' : 'Mostrar completadas',
          isActive: showCompleted,
          onPressed: () => setState(() => showCompleted = !showCompleted),
        ),
        const SizedBox(width: 10),
      ],
      child: StreamBuilder<List<Task>>(
        stream: TaskFirestoreService.getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return PageContainer(
              child: FocusEmptyState(
                icon: Icons.error_outline_rounded,
                message: 'No se pudieron cargar las tareas',
                subtitle: '${snapshot.error}',
                actionLabel: 'Reintentar',
                onAction: () => setState(() {}),
              ),
            );
          }

          final allTasks = snapshot.data ?? const <Task>[];
          final visibleTasks = TaskGrouper.sortTasks(
            allTasks
                .where((task) => showCompleted ? true : !task.completed)
                .toList(),
          );
          final groups = TaskGrouper.groupTasks(visibleTasks);

          return _TasksContent(
            allTasks: allTasks,
            visibleTasks: visibleTasks,
            groups: groups,
            showCompleted: showCompleted,
            expandedGroups: _expandedGroups,
            onToggleCompletedFilter:
                (value) => setState(() => showCompleted = value),
            onToggleGroup:
                (group) => setState(() {
                  _expandedGroups[group] = !(_expandedGroups[group] ?? true);
                }),
          );
        },
      ),
    );
  }
}

class _TasksContent extends StatelessWidget {
  const _TasksContent({
    required this.allTasks,
    required this.visibleTasks,
    required this.groups,
    required this.showCompleted,
    required this.expandedGroups,
    required this.onToggleCompletedFilter,
    required this.onToggleGroup,
  });

  final List<Task> allTasks;
  final List<Task> visibleTasks;
  final Map<TaskGroup, List<Task>> groups;
  final bool showCompleted;
  final Map<TaskGroup, bool> expandedGroups;
  final ValueChanged<bool> onToggleCompletedFilter;
  final ValueChanged<TaskGroup> onToggleGroup;

  @override
  Widget build(BuildContext context) {
    final pendingCount = allTasks.where((task) => !task.completed).length;
    final completedCount = allTasks.where((task) => task.completed).length;
    final overdueCount = allTasks.where(_isTaskOverdue).length;
    final todayCount =
        allTasks
            .where((task) => TaskGrouper.getGroup(task) == TaskGroup.today)
            .length;

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TasksHeader(
              visibleCount: visibleTasks.length,
              showCompleted: showCompleted,
              onNewTask: () => Navigator.pushNamed(context, '/tasks/create'),
              onToggleCompletedFilter: onToggleCompletedFilter,
            ),
            SizedBox(height: FocuslaneTokens.pageGapFor(context)),
            ResponsiveGrid(
              minItemWidth: 200,
              spacing: FocuslaneTokens.gridGapFor(context),
              children: [
                FocusStatCard(
                  title: 'Pendientes',
                  value: '$pendingCount',
                  subtitle: 'por resolver',
                  icon: Icons.radio_button_unchecked_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                FocusStatCard(
                  title: 'Hoy',
                  value: '$todayCount',
                  subtitle: 'con fecha actual',
                  icon: Icons.today_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                FocusStatCard(
                  title: 'Vencidas',
                  value: '$overdueCount',
                  subtitle: 'requieren atencion',
                  icon: Icons.priority_high_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                FocusStatCard(
                  title: 'Completadas',
                  value: '$completedCount',
                  subtitle: 'registradas',
                  icon: Icons.task_alt_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
            SizedBox(height: FocuslaneTokens.pageGapFor(context)),
            _TasksFilterBar(
              showCompleted: showCompleted,
              pendingCount: pendingCount,
              completedCount: completedCount,
              onToggleCompletedFilter: onToggleCompletedFilter,
            ),
            SizedBox(height: FocuslaneTokens.pageGapFor(context)),
            if (visibleTasks.isEmpty)
              FocusCard(
                child: FocusEmptyState(
                  icon: Icons.task_alt_rounded,
                  message:
                      showCompleted
                          ? 'No hay tareas registradas'
                          : 'No hay tareas pendientes',
                  subtitle:
                      showCompleted
                          ? 'Crea una tarea para empezar a organizar tu dia.'
                          : 'Todo lo pendiente esta despejado por ahora.',
                  actionLabel: 'Nueva tarea',
                  onAction: () => Navigator.pushNamed(context, '/tasks/create'),
                ),
              )
            else
              Column(
                children: [
                  for (final group in TaskGroup.values)
                    if ((groups[group] ?? const <Task>[]).isNotEmpty) ...[
                      _TaskGroupPanel(
                        group: group,
                        tasks: groups[group]!,
                        expanded: expandedGroups[group] ?? true,
                        onToggle: () => onToggleGroup(group),
                      ),
                      SizedBox(height: FocuslaneTokens.pageGapFor(context)),
                    ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({
    required this.visibleCount,
    required this.showCompleted,
    required this.onNewTask,
    required this.onToggleCompletedFilter,
  });

  final int visibleCount;
  final bool showCompleted;
  final VoidCallback onNewTask;
  final ValueChanged<bool> onToggleCompletedFilter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final actionRow = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FocusPrimaryButton(
              label: 'Nueva tarea',
              icon: Icons.add_task_rounded,
              onPressed: onNewTask,
            ),
            FocusSecondaryButton(
              label: showCompleted ? 'Ver solo pendientes' : 'Ver completadas',
              icon:
                  showCompleted
                      ? Icons.filter_alt_off_rounded
                      : Icons.done_all_rounded,
              onPressed: () => onToggleCompletedFilter(!showCompleted),
            ),
          ],
        );

        return FocusCard(
          backgroundColor: scheme.surfaceContainerLowest,
          child:
              compact
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TasksHeaderCopy(visibleCount: visibleCount),
                      SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
                      actionRow,
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _TasksHeaderCopy(visibleCount: visibleCount),
                      ),
                      const SizedBox(width: 20),
                      actionRow,
                    ],
                  ),
        );
      },
    );
  }
}

class _TasksHeaderCopy extends StatelessWidget {
  const _TasksHeaderCopy({required this.visibleCount});

  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tareas',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Prioriza el dia, revisa vencimientos y mantén visibles las conexiones con otros modulos.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        FocusBadge(
          label: '$visibleCount tareas visibles',
          color: scheme.primary,
        ),
      ],
    );
  }
}

class _TasksFilterBar extends StatelessWidget {
  const _TasksFilterBar({
    required this.showCompleted,
    required this.pendingCount,
    required this.completedCount,
    required this.onToggleCompletedFilter,
  });

  final bool showCompleted;
  final int pendingCount;
  final int completedCount;
  final ValueChanged<bool> onToggleCompletedFilter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      padding: FocuslaneTokens.cardPaddingFor(context),
      elevated: false,
      backgroundColor: scheme.surfaceContainerLow,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final filters = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                selected: !showCompleted,
                label: Text('Pendientes ($pendingCount)'),
                avatar: const Icon(
                  Icons.radio_button_unchecked_rounded,
                  size: 18,
                ),
                onSelected: (_) => onToggleCompletedFilter(false),
              ),
              ChoiceChip(
                selected: showCompleted,
                label: Text('Todas (${pendingCount + completedCount})'),
                avatar: const Icon(Icons.done_all_rounded, size: 18),
                onSelected: (_) => onToggleCompletedFilter(true),
              ),
              FocusBadge(
                label: '$completedCount completadas',
                color: scheme.tertiary,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FocusSectionHeader(
                  title: 'Filtros',
                  subtitle: 'Vista actual de la lista',
                  icon: Icons.filter_list_rounded,
                ),
                SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
                filters,
              ],
            );
          }

          return Row(
            children: [
              const Expanded(
                child: FocusSectionHeader(
                  title: 'Filtros',
                  subtitle: 'Vista actual de la lista',
                  icon: Icons.filter_list_rounded,
                ),
              ),
              const SizedBox(width: 16),
              filters,
            ],
          );
        },
      ),
    );
  }
}

class _TaskGroupPanel extends StatelessWidget {
  const _TaskGroupPanel({
    required this.group,
    required this.tasks,
    required this.expanded,
    required this.onToggle,
  });

  final TaskGroup group;
  final List<Task> tasks;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = _groupTone(context, group);

    return FocusCard(
      padding: EdgeInsets.zero,
      elevated: false,
      backgroundColor: scheme.surfaceContainerLowest,
      borderSide: BorderSide(color: scheme.outlineVariant),
      child: Column(
        children: [
          Material(
            color: tone.withValues(alpha: 0.08),
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: FocuslaneTokens.isCompact(context) ? 12 : 16,
                  vertical: FocuslaneTokens.isCompact(context) ? 10 : 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: FocuslaneTokens.isCompact(context) ? 30 : 34,
                      height: FocuslaneTokens.isCompact(context) ? 30 : 34,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: tone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.label,
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            _groupSubtitle(group),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    FocusBadge(label: '${tasks.length}', color: tone),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                children: [
                  for (int index = 0; index < tasks.length; index++) ...[
                    _TaskCard(task: tasks[index]),
                    if (index != tasks.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = _isTaskOverdue(task);
    final tone =
        overdue
            ? scheme.error
            : task.completed
            ? scheme.tertiary
            : task.priority.getColor();
    final background =
        overdue
            ? scheme.errorContainer.withValues(alpha: 0.12)
            : task.completed
            ? scheme.tertiaryContainer.withValues(alpha: 0.12)
            : scheme.surfaceContainerLow;

    return FocusCard(
      key: ValueKey(task.id),
      padding: EdgeInsets.all(FocuslaneTokens.isCompact(context) ? 10 : 14),
      elevated: false,
      backgroundColor: background,
      borderSide: BorderSide(
        color:
            overdue
                ? scheme.error.withValues(alpha: 0.32)
                : scheme.outlineVariant.withValues(alpha: 0.78),
      ),
      onTap: () {
        Navigator.pushNamed(context, '/tasks/detail', arguments: task);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final titleBlock = _TaskTitleBlock(task: task, overdue: overdue);
          final actions = _TaskActions(task: task);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TaskCompletionBox(task: task, tone: tone),
                    const SizedBox(width: 12),
                    Expanded(child: titleBlock),
                  ],
                ),
                const SizedBox(height: 12),
                _TaskMetaWrap(task: task, overdue: overdue),
                if (task.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SubtasksList(task: task),
                ],
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TaskCompletionBox(task: task, tone: tone),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleBlock,
                        const SizedBox(height: 10),
                        _TaskMetaWrap(task: task, overdue: overdue),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  actions,
                ],
              ),
              if (task.subtasks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: _SubtasksList(task: task),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TaskCompletionBox extends StatelessWidget {
  const _TaskCompletionBox({required this.task, required this.tone});

  final Task task;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tone.withValues(alpha: 0.24)),
      ),
      child: Checkbox(
        value: task.completed,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: tone, width: 1.4),
        activeColor: tone,
        onChanged: (value) => _setTaskCompleted(task, value ?? false),
      ),
    );
  }
}

class _TaskTitleBlock extends StatelessWidget {
  const _TaskTitleBlock({required this.task, required this.overdue});

  final Task task;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: overdue ? scheme.error : scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  decoration:
                      task.completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (task.isPinned) ...[
              const SizedBox(width: 8),
              Icon(Icons.push_pin_rounded, size: 17, color: scheme.primary),
            ],
            if (task.repeatRule != RepeatRule.none) ...[
              const SizedBox(width: 8),
              Icon(Icons.autorenew_rounded, size: 17, color: scheme.secondary),
            ],
          ],
        ),
        if (task.description.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            task.description.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _TaskMetaWrap extends StatelessWidget {
  const _TaskMetaWrap({required this.task, required this.overdue});

  final Task task;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final origin = _taskOriginLabel(task);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FocusBadge(
          label: task.completed ? 'Completada' : 'Pendiente',
          color: task.completed ? scheme.tertiary : scheme.primary,
        ),
        FocusBadge(
          label: _priorityLabel(task.priority),
          color: task.priority.getColor(),
        ),
        FocusChip(
          label: TaskFormatter.formatDueDate(task.dueDate),
          icon: overdue ? Icons.warning_amber_rounded : Icons.event_rounded,
          color: overdue ? scheme.error : scheme.secondary,
        ),
        FocusChip(
          label: origin,
          icon: Icons.hub_outlined,
          color: scheme.primary,
        ),
        if ((task.category ?? '').trim().isNotEmpty)
          FocusChip(
            label: task.category!.trim(),
            icon: Icons.folder_open_rounded,
            color: scheme.tertiary,
          ),
        for (final tag in task.tags.take(3))
          FocusChip(
            label: tag,
            icon: Icons.label_outline_rounded,
            color: scheme.onSurfaceVariant,
          ),
      ],
    );
  }
}

class _TaskActions extends StatelessWidget {
  const _TaskActions({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FocusIconButton(
          icon: Icons.edit_outlined,
          tooltip: 'Editar',
          onPressed: () {
            Navigator.pushNamed(context, '/tasks/detail', arguments: task);
          },
          isActive: false,
        ),
        const SizedBox(width: 8),
        FocusIconButton(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Eliminar',
          onPressed: () => TaskFirestoreService.deleteTask(task.id),
          isActive: false,
        ),
      ],
    );
  }
}

class _SubtasksList extends StatelessWidget {
  const _SubtasksList({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < task.subtasks.length; index++)
          _SubtaskRow(
            subtask: task.subtasks[index],
            canMoveUp: index > 0,
            canMoveDown: index < task.subtasks.length - 1,
            onToggle: (isDone) async {
              final updatedSubs = List<Subtask>.from(task.subtasks);
              updatedSubs[index] = updatedSubs[index].copyWith(isDone: isDone);
              final updated = task.copyWith(subtasks: updatedSubs);
              await TaskFirestoreService.updateTask(updated);
            },
            onMoveUp: () async {
              if (index <= 0) return;
              final updatedSubs = List<Subtask>.from(task.subtasks);
              final item = updatedSubs.removeAt(index);
              updatedSubs.insert(index - 1, item);
              final updated = task.copyWith(subtasks: updatedSubs);
              await TaskFirestoreService.updateTask(updated);
            },
            onMoveDown: () async {
              if (index >= task.subtasks.length - 1) return;
              final updatedSubs = List<Subtask>.from(task.subtasks);
              final item = updatedSubs.removeAt(index);
              updatedSubs.insert(index + 1, item);
              final updated = task.copyWith(subtasks: updatedSubs);
              await TaskFirestoreService.updateTask(updated);
            },
          ),
      ],
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    required this.subtask,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onToggle,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final Subtask subtask;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<bool> onToggle;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            visualDensity: VisualDensity.compact,
            value: subtask.isDone,
            onChanged: (value) => onToggle(value ?? false),
          ),
          Expanded(
            child: Text(
              subtask.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface,
                decoration: subtask.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          _TinyIconButton(
            icon: Icons.keyboard_arrow_up_rounded,
            tooltip: 'Subir',
            enabled: canMoveUp,
            onPressed: onMoveUp,
          ),
          _TinyIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            tooltip: 'Bajar',
            enabled: canMoveDown,
            onPressed: onMoveDown,
          ),
        ],
      ),
    );
  }
}

class _TinyIconButton extends StatelessWidget {
  const _TinyIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}

Future<void> _setTaskCompleted(Task task, bool completed) async {
  final updated = task.copyWith(completed: completed);
  await TaskFirestoreService.updateTask(updated);

  if (updated.completed && task.repeatRule != RepeatRule.none) {
    final nextDue = _nextDueDate(task.dueDate, task.repeatRule);
    final nextSubtasks =
        task.subtasks
            .map((subtask) => subtask.copyWith(isDone: false))
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

bool _isTaskOverdue(Task task) {
  if (task.dueDate == null || task.completed) return false;
  final now = DateTime.now();
  return task.dueDate!.isBefore(now);
}

Color _groupTone(BuildContext context, TaskGroup group) {
  final scheme = Theme.of(context).colorScheme;
  switch (group) {
    case TaskGroup.overdue:
      return scheme.error;
    case TaskGroup.today:
      return scheme.primary;
    case TaskGroup.tomorrow:
      return scheme.secondary;
    case TaskGroup.thisWeek:
      return scheme.tertiary;
    case TaskGroup.later:
      return scheme.onSurfaceVariant;
    case TaskGroup.noDate:
      return scheme.outline;
  }
}

String _groupSubtitle(TaskGroup group) {
  switch (group) {
    case TaskGroup.overdue:
      return 'Pendientes que ya superaron su fecha limite';
    case TaskGroup.today:
      return 'Compromisos previstos para hoy';
    case TaskGroup.tomorrow:
      return 'Preparacion para el siguiente dia';
    case TaskGroup.thisWeek:
      return 'Plan cercano de la semana';
    case TaskGroup.later:
      return 'Tareas con margen por delante';
    case TaskGroup.noDate:
      return 'Pendientes sin fecha asignada';
  }
}

String _priorityLabel(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'Prioridad alta';
    case TaskPriority.medium:
      return 'Prioridad media';
    case TaskPriority.low:
      return 'Prioridad baja';
  }
}

String _taskOriginLabel(Task task) {
  if ((task.linkedStudyCourseId ?? '').isNotEmpty ||
      (task.syncedStudyTaskId ?? '').isNotEmpty) {
    return 'Estudio';
  }
  if ((task.linkedNoteId ?? '').isNotEmpty) {
    return 'Notas';
  }
  return 'Tareas';
}
