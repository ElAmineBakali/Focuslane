import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import 'task_edit_sheet.dart';
import '../timer/study_timer_screen.dart';

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
  String _groupBy = 'date';
  @override
  void initState() {
    super.initState();
    _courseId = widget.initialCourseId;
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tareas y Exámenes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            tooltip: 'Nueva tarea',
            icon: const Icon(Icons.add_task),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder:
                    (_) => TaskEditSheet(svc: svc, initialCourseId: _courseId),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.view_agenda_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Agrupar por:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'date',
                        label: Text('Fecha'),
                        icon: Icon(Icons.calendar_today, size: 16),
                      ),
                      ButtonSegment(
                        value: 'course',
                        label: Text('Curso'),
                        icon: Icon(Icons.school, size: 16),
                      ),
                    ],
                    selected: {_groupBy},
                    onSelectionChanged:
                        (s) => setState(() => _groupBy = s.first),
                    style: ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Course>>(
              stream: svc.streamCourses(),
              builder: (context, coursesSnap) {
                return StreamBuilder<List<StudyTask>>(
                  stream: svc.streamTasks(
                    courseId: _courseId,
                    status: _status,
                    highPriorityOnly: _onlyHigh,
                  ),
                  builder: (context, snap) {
                    if (!snap.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final courseMap = <String, String>{};
                    if (coursesSnap.hasData) {
                      for (final course in coursesSnap.data!) {
                        courseMap[course.id] = course.name;
                      }
                    }

                    final tasks = snap.data!;
                    if (tasks.isEmpty)
                      return Center(
                        child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt_rounded,
                                  size: 120,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '¡Todo despejado!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay tareas que coincidan con tus filtros',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                FilledButton.icon(
                                  onPressed: () async {
                                    await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder:
                                          (_) => TaskEditSheet(
                                            svc: svc,
                                            initialCourseId: _courseId,
                                          ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Crear nueva tarea'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(begin: const Offset(0.8, 0.8)),
                      );

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

                    return AnimationLimiter(
                      child: CustomScrollView(
                        slivers: [
                          for (final e in entries) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                child: Text(
                                      _groupBy == 'course'
                                          ? courseMap[e.key] ??
                                              'Curso desconocido'
                                          : (e.key == 'Sin fecha'
                                              ? e.key
                                              : e.key.substring(0, 10)),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: -0.1, end: 0),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  i,
                                ) {
                                  return AnimationConfiguration.staggeredList(
                                    position: i,
                                    duration: const Duration(milliseconds: 400),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _TaskCard(
                                            task: e.value[i],
                                            onEdit: () async {
                                              await showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder:
                                                    (_) => TaskEditSheet(
                                                      svc: svc,
                                                      initial: e.value[i],
                                                    ),
                                              );
                                            },
                                            onChangeStatus: (status) async {
                                              await svc.updateTask(
                                                e.value[i].id,
                                                {'status': status.name},
                                              );
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.check_circle,
                                                        color:
                                                            colorScheme
                                                                .onPrimary,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        'Estado actualizado a ${status.name}',
                                                      ),
                                                    ],
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            },
                                            onDelete: () async {
                                              await svc.deleteTask(
                                                e.value[i].id,
                                              );
                                              if (!context.mounted) return;
                                              final cs =
                                                  Theme.of(context).colorScheme;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.delete_outline,
                                                        color: cs.onError,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        'Tarea eliminada',
                                                      ),
                                                    ],
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            },
                                            onOpenTimer: () {
                                              final t = e.value[i];
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => StudyTimerScreen(
                                                        svc: svc,
                                                        initialCourseId:
                                                            t.courseId,
                                                        initialTaskId: t.id,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }, childCount: e.value.length),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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
        return Theme.of(context).colorScheme.error;
      case Priority.normal:
        return Theme.of(context).colorScheme.primary;
      case Priority.low:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon =
        task.type == StudyItemType.exam
            ? Icons.school_rounded
            : Icons.assignment_rounded;
    final prioColor = _priorityColor(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: prioColor.withOpacity(0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [prioColor.withOpacity(0.08), cs.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: prioColor.withOpacity(.15),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: prioColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: prioColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        if (task.syncedTaskId != null &&
                            task.syncedTaskId!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sync_rounded,
                                  size: 14,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sincronizado',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (v) async {
                      if (v == 'edit') onEdit();
                      if (v == 'todo') onChangeStatus(TaskStatus.todo);
                      if (v == 'doing') onChangeStatus(TaskStatus.doing);
                      if (v == 'done') onChangeStatus(TaskStatus.done);
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 12),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'todo',
                            child: Row(
                              children: [
                                Icon(Icons.circle_outlined),
                                SizedBox(width: 12),
                                Text('Por hacer'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'doing',
                            child: Row(
                              children: [
                                Icon(Icons.pending_outlined),
                                SizedBox(width: 12),
                                Text('En progreso'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'done',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline),
                                SizedBox(width: 12),
                                Text('Hecha'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red),
                                SizedBox(width: 12),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (task.due != null)
                    _ModernChip(
                      icon: Icons.event_rounded,
                      label: _formatDueDate(task.due!),
                      color: _isDueSoon(task.due!) ? cs.error : cs.tertiary,
                    ),
                  _ModernChip(
                    icon: Icons.flag_rounded,
                    label: task.priority.name.toUpperCase(),
                    color: prioColor,
                  ),
                  _ModernChip(
                    icon: _statusIcon(task.status),
                    label: _statusLabel(task.status),
                    color: _statusColor(task.status, cs),
                  ),
                  if ((task.notes ?? '').isNotEmpty)
                    _ModernChip(
                      icon: Icons.notes_rounded,
                      label: 'Notas',
                      color: cs.secondary,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onOpenTimer,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: prioColor,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.timer_rounded),
                      label: Text(
                        'Estudiar',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (task.status != TaskStatus.done)
                    IconButton.filledTonal(
                      onPressed: () => onChangeStatus(TaskStatus.done),
                      icon: const Icon(Icons.check_circle_rounded),
                      tooltip: 'Marcar como hecha',
                      style: IconButton.styleFrom(
                        backgroundColor: cs.secondaryContainer,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff < 0) return 'Vencida';
    return '${diff}d';
  }

  bool _isDueSoon(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    return diff <= 2;
  }

  IconData _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.circle_outlined;
      case TaskStatus.doing:
        return Icons.pending_outlined;
      case TaskStatus.done:
        return Icons.check_circle_rounded;
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'Por hacer';
      case TaskStatus.doing:
        return 'En progreso';
      case TaskStatus.done:
        return 'Hecha';
    }
  }

  Color _statusColor(TaskStatus status, ColorScheme cs) {
    switch (status) {
      case TaskStatus.todo:
        return cs.outline;
      case TaskStatus.doing:
        return cs.secondary;
      case TaskStatus.done:
        return cs.primary;
    }
  }
}

class _ModernChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ModernChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
    return StreamBuilder<List<Course>>(
      stream: svc.streamCourses(),
      builder: (context, snap) {
        final courses = snap.data ?? const <Course>[];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.book_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Curso',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                    avatar:
                        selectedCourseId == null
                            ? const Icon(Icons.check_circle, size: 18)
                            : null,
                  ),
                  ...courses.map((course) {
                    final isSelected = selectedCourseId == course.id;
                    return FilterChip(
                      label: Text(course.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        onCourseChanged(selected ? course.id : null);
                      },
                      avatar:
                          isSelected
                              ? const Icon(Icons.check_circle, size: 18)
                              : Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: course.color ?? Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estado',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'all',
                      label: Text('Todos'),
                      icon: Icon(Icons.select_all_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 'todo',
                      label: Text('Por hacer'),
                      icon: Icon(Icons.radio_button_unchecked, size: 18),
                    ),
                    ButtonSegment(
                      value: 'doing',
                      label: Text('En progreso'),
                      icon: Icon(Icons.pending_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 'done',
                      label: Text('Completadas'),
                      icon: Icon(Icons.check_circle_rounded, size: 18),
                    ),
                  ],
                  selected: {
                    selectedStatus == null
                        ? 'all'
                        : selectedStatus == TaskStatus.todo
                        ? 'todo'
                        : selectedStatus == TaskStatus.doing
                        ? 'doing'
                        : 'done',
                  },
                  onSelectionChanged: (Set<String> newSelection) {
                    final value = newSelection.first;
                    if (value == 'all') {
                      onStatusChanged(null);
                    } else if (value == 'todo') {
                      onStatusChanged(TaskStatus.todo);
                    } else if (value == 'doing') {
                      onStatusChanged(TaskStatus.doing);
                    } else {
                      onStatusChanged(TaskStatus.done);
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.priority_high_rounded,
                          size: 16,
                          color: onlyHigh ? colorScheme.onError : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        const Text('Solo alta prioridad'),
                      ],
                    ),
                    selected: onlyHigh,
                    onSelected: onOnlyHighChanged,
                    selectedColor: Colors.red.shade600,
                    checkmarkColor: colorScheme.onError,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
