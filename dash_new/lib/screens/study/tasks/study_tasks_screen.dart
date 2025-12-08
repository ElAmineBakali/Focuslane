import 'package:flutter/material.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import '../timer/study_timer_screen.dart';
import 'task_edit_sheet.dart';
import '../settings/study_settings_sheet.dart';

class StudyTasksScreen extends StatefulWidget {
  final StudyFirestoreService svc;
  final String? initialCourseId;
  const StudyTasksScreen({super.key, required this.svc, this.initialCourseId});

  @override
  State<StudyTasksScreen> createState() => _StudyTasksScreenState();
}

class _StudyTasksScreenState extends State<StudyTasksScreen> {
  String? _courseId;
  TaskStatus? _status;
  bool _onlyHigh = false;
  String _groupBy = 'date'; // 'date' | 'course'

  @override
  void initState() {
    super.initState();
    _courseId = widget.initialCourseId;
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas y Exámenes'),
        actions: [
          IconButton(
            tooltip: 'Nueva tarea',
            icon: const Icon(Icons.add_task),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder:
                    (_) => TaskEditSheet(svc: svc, initialCourseId: _courseId),
              );
            },
          ),
          IconButton(
            tooltip: 'Ajustes de Study',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => StudySettingsSheet(svc: svc),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _FiltersBar(
            svc: svc,
            selectedCourseId: _courseId,
            onCourseChanged: (v) => setState(() => _courseId = v),
            selectedStatus: _status,
            onStatusChanged: (v) => setState(() => _status = v),
            onlyHigh: _onlyHigh,
            onOnlyHighChanged: (v) => setState(() => _onlyHigh = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.view_agenda_rounded, size: 18),
                const SizedBox(width: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'date', label: Text('Por fecha')),
                    ButtonSegment(value: 'course', label: Text('Por curso')),
                  ],
                  selected: {_groupBy},
                  onSelectionChanged: (s) => setState(() => _groupBy = s.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<StudyTask>>(
              stream: svc.streamTasks(
                courseId: _courseId,
                status: _status,
                highPriorityOnly: _onlyHigh,
              ),
              builder: (context, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final tasks = snap.data!;
                if (tasks.isEmpty)
                  return const Center(child: Text('Nada por aquí'));

                // Grouping
                final Map<String, List<StudyTask>> groups = {};
                if (_groupBy == 'course') {
                  for (final t in tasks) {
                    groups.putIfAbsent(t.courseId, () => []).add(t);
                  }
                } else {
                  String key(DateTime? d) {
                    if (d == null) return 'Sin fecha';
                    final dd = DateTime(d.year, d.month, d.day);
                    return dd.toIso8601String();
                  }

                  for (final t in tasks) {
                    groups.putIfAbsent(key(t.due), () => []).add(t);
                  }
                }

                final entries =
                    groups.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key));

                return CustomScrollView(
                  slivers: [
                    for (final e in entries) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                          child: Text(
                            _groupBy == 'course'
                                ? 'Curso: ${e.key}'
                                : (e.key == 'Sin fecha'
                                    ? e.key
                                    : e.key.substring(0, 10)),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      SliverList.separated(
                        itemBuilder:
                            (_, i) => _TaskCard(
                              task: e.value[i],
                              onEdit: () async {
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder:
                                      (_) => TaskEditSheet(
                                        svc: svc,
                                        initial: e.value[i],
                                      ),
                                );
                              },
                              onChangeStatus: (status) async {
                                await svc.updateTask(e.value[i].id, {
                                  'status': status.name,
                                });
                              },
                              onDelete: () async {
                                await svc.deleteTask(e.value[i].id);
                              },
                              onOpenTimer: () {
                                final t = e.value[i];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => StudyTimerScreen(
                                          svc: svc,
                                          initialCourseId: t.courseId,
                                          initialTaskId: t.id,
                                        ),
                                  ),
                                );
                              },
                            ),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: e.value.length,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final StudyTask task;
  final VoidCallback onOpenTimer;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final ValueChanged<TaskStatus> onChangeStatus;
  const _TaskCard({
    required this.task,
    required this.onOpenTimer,
    required this.onDelete,
    required this.onEdit,
    required this.onChangeStatus,
  });

  Color _priorityColor(BuildContext context) {
    switch (task.priority) {
      case Priority.high:
        return Colors.redAccent;
      case Priority.normal:
        return Theme.of(context).colorScheme.primary;
      case Priority.low:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon =
        task.type == StudyItemType.exam
            ? Icons.event_available
            : Icons.task_alt;
    final prioColor = _priorityColor(context);
    return Card(
      surfaceTintColor: cs.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: prioColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: prioColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (task.syncedTaskId != null && task.syncedTaskId!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sync_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sincronizado',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') onEdit();
                    if (v == 'todo') onChangeStatus(TaskStatus.todo);
                    if (v == 'doing') onChangeStatus(TaskStatus.doing);
                    if (v == 'done') onChangeStatus(TaskStatus.done);
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(
                          value: 'todo',
                          child: Text('Marcar por hacer'),
                        ),
                        PopupMenuItem(
                          value: 'doing',
                          child: Text('Marcar en progreso'),
                        ),
                        PopupMenuItem(
                          value: 'done',
                          child: Text('Marcar hecha'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (task.due != null)
                  _Chip(icon: Icons.event, label: 'Vence: ${task.due}'),
                _Chip(
                  icon: Icons.flag,
                  label: 'Prioridad: ${task.priority.name}',
                ),
                _Chip(icon: Icons.info, label: 'Estado: ${task.status.name}'),
                if ((task.notes ?? '').isNotEmpty)
                  _Chip(icon: Icons.notes, label: 'Notas'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: onOpenTimer,
                  icon: const Icon(Icons.timer),
                  label: const Text('Estudiar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: onEdit, child: const Text('Editar')),
                const Spacer(),
                if (task.status != TaskStatus.done)
                  TextButton.icon(
                    onPressed: () => onChangeStatus(TaskStatus.done),
                    icon: const Icon(Icons.check),
                    label: const Text('Marcar hecha'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final StudyFirestoreService svc;
  final String? selectedCourseId;
  final ValueChanged<String?> onCourseChanged;
  final TaskStatus? selectedStatus;
  final ValueChanged<TaskStatus?> onStatusChanged;
  final bool onlyHigh;
  final ValueChanged<bool> onOnlyHighChanged;

  const _FiltersBar({
    required this.svc,
    required this.selectedCourseId,
    required this.onCourseChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onlyHigh,
    required this.onOnlyHighChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.streamCourses(),
      builder: (context, snap) {
        final courses = snap.data ?? const [];
        // FIX: si el valor seleccionado no existe en items, forzamos null (evita assert del Dropdown)
        final valid = courses.any((c) => c.id == selectedCourseId);
        final dropdownValue = valid ? selectedCourseId : null;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            runSpacing: 8,
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String?>(
                value: dropdownValue, // FIX
                hint: const Text('Curso'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...courses.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: onCourseChanged,
              ),
              DropdownButton<TaskStatus?>(
                value: selectedStatus, // enum => ya válido
                hint: const Text('Estado'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(
                    value: TaskStatus.todo,
                    child: Text('Por hacer'),
                  ),
                  DropdownMenuItem(
                    value: TaskStatus.doing,
                    child: Text('En progreso'),
                  ),
                  DropdownMenuItem(
                    value: TaskStatus.done,
                    child: Text('Hechas'),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
              FilterChip(
                label: const Text('Alta prioridad'),
                selected: onlyHigh,
                onSelected: onOnlyHighChanged,
              ),
            ],
          ),
        );
      },
    );
  }
}
