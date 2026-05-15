import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/study/screens/timer/study_timer_screen.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';

import 'task_edit_sheet.dart';

class StudyTasksScreen extends StatefulWidget {
  const StudyTasksScreen({
    super.key,
    required this.svc,
    this.initialCourseId,
    this.embedded = false,
  });

  final StudyFirestoreService svc;
  final String? initialCourseId;
  final bool embedded;

  @override
  State<StudyTasksScreen> createState() => _StudyTasksScreenState();
}

class _StudyTasksScreenState extends State<StudyTasksScreen> {
  String? _courseId;
  TaskStatus? _status;
  bool _onlyHigh = false;
  String _groupBy = 'date';

  @override
  void initState() {
    super.initState();
    _courseId = widget.initialCourseId;
  }

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<Course>>(
      stream: widget.svc.streamCourses(),
      builder: (context, coursesSnap) {
        return StreamBuilder<List<StudyTask>>(
          stream: widget.svc.streamTasks(
            courseId: _courseId,
            status: _status,
            highPriorityOnly: _onlyHigh,
          ),
          builder: (context, tasksSnap) {
            if (coursesSnap.hasError || tasksSnap.hasError) {
              return PageContainer(
                child: FocusEmptyState(
                  icon: Icons.error_outline_rounded,
                  message: 'No se pudieron cargar las tareas',
                  subtitle: '${coursesSnap.error ?? tasksSnap.error}',
                ),
              );
            }
            if (!coursesSnap.hasData || !tasksSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return _StudyTasksContent(
              svc: widget.svc,
              courses: coursesSnap.data ?? const <Course>[],
              tasks: tasksSnap.data ?? const <StudyTask>[],
              selectedCourseId: _courseId,
              selectedStatus: _status,
              onlyHigh: _onlyHigh,
              groupBy: _groupBy,
              onCourseChanged: (value) => setState(() => _courseId = value),
              onStatusChanged: (value) => setState(() => _status = value),
              onOnlyHighChanged: (value) => setState(() => _onlyHigh = value),
              onGroupByChanged: (value) => setState(() => _groupBy = value),
            );
          },
        );
      },
    );

    if (widget.embedded) return content;

    return AppShell(
      title: 'Estudio',
      subtitle: 'Tareas y exámenes.',
      activeRoute: AppRoutes.studyDashboard,
      child: content,
    );
  }
}

class _StudyTasksContent extends StatelessWidget {
  const _StudyTasksContent({
    required this.svc,
    required this.courses,
    required this.tasks,
    required this.selectedCourseId,
    required this.selectedStatus,
    required this.onlyHigh,
    required this.groupBy,
    required this.onCourseChanged,
    required this.onStatusChanged,
    required this.onOnlyHighChanged,
    required this.onGroupByChanged,
  });

  final StudyFirestoreService svc;
  final List<Course> courses;
  final List<StudyTask> tasks;
  final String? selectedCourseId;
  final TaskStatus? selectedStatus;
  final bool onlyHigh;
  final String groupBy;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<TaskStatus?> onStatusChanged;
  final ValueChanged<bool> onOnlyHighChanged;
  final ValueChanged<String> onGroupByChanged;

  @override
  Widget build(BuildContext context) {
    final courseById = {for (final course in courses) course.id: course};
    final pending = tasks.where((task) => task.status != TaskStatus.done);
    final exams = tasks.where((task) => task.type == StudyItemType.exam);
    final grouped = _groupTasks(tasks, courseById);

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TasksHeader(
              total: tasks.length,
              pending: pending.length,
              exams: exams.length,
              onCreate: () => _openEditor(context),
            ),
            const SizedBox(height: 16),
            _FiltersPanel(
              courses: courses,
              selectedCourseId: selectedCourseId,
              selectedStatus: selectedStatus,
              onlyHigh: onlyHigh,
              groupBy: groupBy,
              onCourseChanged: onCourseChanged,
              onStatusChanged: onStatusChanged,
              onOnlyHighChanged: onOnlyHighChanged,
              onGroupByChanged: onGroupByChanged,
            ),
            const SizedBox(height: 16),
            if (tasks.isEmpty)
              FocusCard(
                child: FocusEmptyState(
                  icon: Icons.task_alt_rounded,
                  message: 'No hay tareas con estos filtros',
                  subtitle: 'Crea una tarea o ajusta los filtros activos.',
                  actionLabel: 'Nueva tarea',
                  onAction: () => _openEditor(context),
                ),
              )
            else
              Column(
                children: [
                  for (final entry in grouped.entries) ...[
                    _TaskGroup(
                      title: entry.key,
                      tasks: entry.value,
                      courseById: courseById,
                      onEdit: (task) => _openEditor(context, task: task),
                      onDelete: (task) => _deleteTask(context, task),
                      onStatus:
                          (task, status) =>
                              _changeStatus(context, task, status),
                      onTimer:
                          (task) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => StudyTimerScreen(
                                    svc: svc,
                                    initialCourseId: task.courseId,
                                    initialTaskId: task.id,
                                  ),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Map<String, List<StudyTask>> _groupTasks(
    List<StudyTask> source,
    Map<String, Course> courseById,
  ) {
    final groups = <String, List<StudyTask>>{};
    for (final task in source) {
      final key =
          groupBy == 'course'
              ? courseById[task.courseId]?.name ?? 'Curso eliminado'
              : _dateGroupLabel(task.due);
      groups.putIfAbsent(key, () => <StudyTask>[]).add(task);
    }

    final entries =
        groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(entries);
  }

  Future<void> _openEditor(BuildContext context, {StudyTask? task}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => TaskEditSheet(
            svc: svc,
            initial: task,
            initialCourseId: task == null ? selectedCourseId : null,
          ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    StudyTask task,
    TaskStatus status,
  ) async {
    await svc.updateTask(task.id, {'status': status.name});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Estado actualizado a ${_statusLabel(status)}')),
    );
  }

  Future<void> _deleteTask(BuildContext context, StudyTask task) async {
    await svc.deleteTask(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tarea eliminada')));
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({
    required this.total,
    required this.pending,
    required this.exams,
    required this.onCreate,
  });

  final int total;
  final int pending;
  final int exams;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tareas y exámenes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Filtra por curso, revisa entregas y cambia el estado sin salir de Estudio.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(label: '$total visibles', color: scheme.primary),
                  FocusBadge(
                    label: '$pending pendientes',
                    color: scheme.secondary,
                  ),
                  FocusBadge(label: '$exams exámenes', color: scheme.tertiary),
                ],
              ),
            ],
          );
          final action = FocusPrimaryButton(
            label: 'Nueva tarea',
            icon: Icons.add_task_rounded,
            onPressed: onCreate,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 16), action],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.courses,
    required this.selectedCourseId,
    required this.selectedStatus,
    required this.onlyHigh,
    required this.groupBy,
    required this.onCourseChanged,
    required this.onStatusChanged,
    required this.onOnlyHighChanged,
    required this.onGroupByChanged,
  });

  final List<Course> courses;
  final String? selectedCourseId;
  final TaskStatus? selectedStatus;
  final bool onlyHigh;
  final String groupBy;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<TaskStatus?> onStatusChanged;
  final ValueChanged<bool> onOnlyHighChanged;
  final ValueChanged<String> onGroupByChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      elevated: false,
      backgroundColor: scheme.surfaceContainerLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FocusSectionHeader(
            title: 'Filtros',
            subtitle: 'Curso, estado, prioridad y agrupacion',
            icon: Icons.filter_list_rounded,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Todos los cursos'),
                selected: selectedCourseId == null,
                onSelected: (selected) {
                  if (selected) onCourseChanged(null);
                },
              ),
              for (final course in courses)
                FilterChip(
                  label: Text(course.name),
                  selected: selectedCourseId == course.id,
                  avatar: CircleAvatar(
                    radius: 6,
                    backgroundColor: course.color ?? scheme.primary,
                  ),
                  onSelected:
                      (selected) =>
                          onCourseChanged(selected ? course.id : null),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'all',
                    label: Text('Todas'),
                    icon: Icon(Icons.select_all_rounded),
                  ),
                  ButtonSegment(
                    value: 'todo',
                    label: Text('Por hacer'),
                    icon: Icon(Icons.radio_button_unchecked_rounded),
                  ),
                  ButtonSegment(
                    value: 'doing',
                    label: Text('En progreso'),
                    icon: Icon(Icons.pending_rounded),
                  ),
                  ButtonSegment(
                    value: 'done',
                    label: Text('Completadas'),
                    icon: Icon(Icons.check_circle_rounded),
                  ),
                ],
                selected: {_statusValue(selectedStatus)},
                onSelectionChanged:
                    (selection) =>
                        onStatusChanged(_statusFromValue(selection.first)),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'date',
                    label: Text('Fecha'),
                    icon: Icon(Icons.event_rounded),
                  ),
                  ButtonSegment(
                    value: 'course',
                    label: Text('Curso'),
                    icon: Icon(Icons.school_rounded),
                  ),
                ],
                selected: {groupBy},
                onSelectionChanged:
                    (selection) => onGroupByChanged(selection.first),
              ),
              FilterChip(
                label: const Text('Solo alta prioridad'),
                selected: onlyHigh,
                avatar: const Icon(Icons.priority_high_rounded),
                onSelected: onOnlyHighChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskGroup extends StatelessWidget {
  const _TaskGroup({
    required this.title,
    required this.tasks,
    required this.courseById,
    required this.onEdit,
    required this.onDelete,
    required this.onStatus,
    required this.onTimer,
  });

  final String title;
  final List<StudyTask> tasks;
  final Map<String, Course> courseById;
  final ValueChanged<StudyTask> onEdit;
  final ValueChanged<StudyTask> onDelete;
  final void Function(StudyTask task, TaskStatus status) onStatus;
  final ValueChanged<StudyTask> onTimer;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: FocusSectionHeader(
              title: title,
              subtitle: '${tasks.length} elementos',
              icon: Icons.folder_open_rounded,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                for (final task in tasks) ...[
                  _StudyTaskTile(
                    task: task,
                    course: courseById[task.courseId],
                    onEdit: () => onEdit(task),
                    onDelete: () => onDelete(task),
                    onStatus: (status) => onStatus(task, status),
                    onTimer: () => onTimer(task),
                  ),
                  if (task != tasks.last) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyTaskTile extends StatelessWidget {
  const _StudyTaskTile({
    required this.task,
    required this.course,
    required this.onEdit,
    required this.onDelete,
    required this.onStatus,
    required this.onTimer,
  });

  final StudyTask task;
  final Course? course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatus;
  final VoidCallback onTimer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = _priorityColor(context, task.priority);
    final courseTone = course?.color ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 660;
          final title = _TaskTitle(
            task: task,
            course: course,
            tone: courseTone,
          );
          final chips = _TaskChips(task: task, tone: tone);
          final actions = _TaskActions(
            task: task,
            onEdit: onEdit,
            onDelete: onDelete,
            onStatus: onStatus,
            onTimer: onTimer,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 12),
                chips,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), chips],
                ),
              ),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _TaskTitle extends StatelessWidget {
  const _TaskTitle({
    required this.task,
    required this.course,
    required this.tone,
  });

  final StudyTask task;
  final Course? course;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            task.type == StudyItemType.exam
                ? Icons.school_rounded
                : Icons.assignment_rounded,
            color: tone,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                course?.name ?? 'Curso eliminado',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskChips extends StatelessWidget {
  const _TaskChips({required this.task, required this.tone});

  final StudyTask task;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FocusChip(
          label: task.type == StudyItemType.exam ? 'Examen' : 'Tarea',
          icon:
              task.type == StudyItemType.exam
                  ? Icons.school_rounded
                  : Icons.assignment_rounded,
          color: scheme.primary,
        ),
        FocusChip(
          label: _priorityLabel(task.priority),
          icon: Icons.flag_rounded,
          color: tone,
        ),
        FocusChip(
          label: _statusLabel(task.status),
          icon: _statusIcon(task.status),
          color: _statusColor(task.status, scheme),
        ),
        FocusChip(
          label:
              task.due == null
                  ? 'Sin fecha'
                  : DateFormat('d MMM yyyy', 'es_ES').format(task.due!),
          icon: Icons.event_rounded,
          color: scheme.secondary,
        ),
        if ((task.notes ?? '').trim().isNotEmpty)
          FocusChip(
            label: 'Notas',
            icon: Icons.notes_rounded,
            color: scheme.tertiary,
          ),
        if ((task.syncedTaskId ?? '').trim().isNotEmpty)
          FocusChip(
            label: 'Sincronizada',
            icon: Icons.sync_rounded,
            color: scheme.primary,
          ),
      ],
    );
  }
}

class _TaskActions extends StatelessWidget {
  const _TaskActions({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatus,
    required this.onTimer,
  });

  final StudyTask task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatus;
  final VoidCallback onTimer;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        FocusSecondaryButton(
          label: 'Editar',
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
        FocusPrimaryButton(
          label: 'Estudiar',
          icon: Icons.timer_outlined,
          onPressed: onTimer,
        ),
        PopupMenuButton<String>(
          tooltip: 'Mas acciones',
          onSelected: (value) {
            if (value == 'todo') onStatus(TaskStatus.todo);
            if (value == 'doing') onStatus(TaskStatus.doing);
            if (value == 'done') onStatus(TaskStatus.done);
            if (value == 'delete') onDelete();
          },
          itemBuilder:
              (_) => const [
                PopupMenuItem(value: 'todo', child: Text('Marcar por hacer')),
                PopupMenuItem(
                  value: 'doing',
                  child: Text('Marcar en progreso'),
                ),
                PopupMenuItem(value: 'done', child: Text('Marcar completada')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.more_vert_rounded),
          ),
        ),
      ],
    );
  }
}

String _dateGroupLabel(DateTime? date) {
  if (date == null) return 'Sin fecha';
  final now = DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return 'Hoy';
  if (day == today.add(const Duration(days: 1))) return 'Mañana';
  if (day.isBefore(today)) return 'Vencidas';
  return DateFormat('d MMM yyyy', 'es_ES').format(date);
}

Color _priorityColor(BuildContext context, Priority priority) {
  final scheme = Theme.of(context).colorScheme;
  switch (priority) {
    case Priority.high:
      return scheme.error;
    case Priority.normal:
      return scheme.primary;
    case Priority.low:
      return scheme.tertiary;
  }
}

String _priorityLabel(Priority priority) {
  switch (priority) {
    case Priority.high:
      return 'Prioridad alta';
    case Priority.normal:
      return 'Prioridad media';
    case Priority.low:
      return 'Prioridad baja';
  }
}

String _statusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return 'Por hacer';
    case TaskStatus.doing:
      return 'En progreso';
    case TaskStatus.done:
      return 'Completada';
  }
}

IconData _statusIcon(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return Icons.radio_button_unchecked_rounded;
    case TaskStatus.doing:
      return Icons.pending_rounded;
    case TaskStatus.done:
      return Icons.check_circle_rounded;
  }
}

Color _statusColor(TaskStatus status, ColorScheme scheme) {
  switch (status) {
    case TaskStatus.todo:
      return scheme.outline;
    case TaskStatus.doing:
      return scheme.secondary;
    case TaskStatus.done:
      return scheme.primary;
  }
}

String _statusValue(TaskStatus? status) {
  if (status == null) return 'all';
  return status.name;
}

TaskStatus? _statusFromValue(String value) {
  switch (value) {
    case 'todo':
      return TaskStatus.todo;
    case 'doing':
      return TaskStatus.doing;
    case 'done':
      return TaskStatus.done;
    default:
      return null;
  }
}
