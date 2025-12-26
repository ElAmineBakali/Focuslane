import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_dashboard_personal/theme/global_ui_theme.dart';
import '../models/study_models.dart';
import '../services/study_firestore_service.dart';

class TaskEditSheet extends StatefulWidget {
  final StudyFirestoreService svc;
  final StudyTask? initial;
  final String? initialCourseId;

  const TaskEditSheet({super.key, required this.svc, this.initial, this.initialCourseId});

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  String? _courseId;
  StudyItemType _type = StudyItemType.task;
  Priority _priority = Priority.normal;
  TaskStatus _status = TaskStatus.todo;
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.initial;

    _titleController = TextEditingController(text: task?.title ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');

    if (task != null) {
      _courseId = task.courseId;
      _type = task.type;
      _priority = task.priority;
      _status = task.status;
      _dueDate = task.due;
    } else {
      _courseId = widget.initialCourseId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courseId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un curso')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final task = StudyTask(
        id: widget.initial?.id ?? '',
        courseId: _courseId!,
        title: _titleController.text.trim(),
        type: _type,
        priority: _priority,
        status: _status,
        due: _dueDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (widget.initial == null) {
        await widget.svc.createTask(task);
      } else {
        await widget.svc.updateTask(widget.initial!.id, task.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade600));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = widget.initial != null;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StreamBuilder<List<Course>>(
            stream: widget.svc.streamCourses(),
            builder: (context, snapshot) {
              final courses = snapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Icon(
                              _type == StudyItemType.exam
                                  ? Icons.edit_note_rounded
                                  : Icons.assignment_rounded,
                              color: colorScheme.onPrimaryContainer,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Editar tarea' : 'Nueva tarea',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Organiza tus pendientes',
                                  style: AppTypography.caption(context),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Text(
                        'Curso',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (courses.isEmpty)
                        Text(
                          'No hay cursos disponibles',
                          style: GoogleFonts.plusJakartaSans(color: colorScheme.error),
                        )
                      else
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: courses.map((course) {
                            final isSelected = _courseId == course.id;
                            final courseColor = course.color ?? colorScheme.primary;

                            return InkWell(
                              onTap: () => setState(() => _courseId = course.id),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? courseColor.withOpacity(0.14)
                                          : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(
                                    color: isSelected ? courseColor : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: courseColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      course.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight:
                                            isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? courseColor : colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: AppSpacing.lg),

                      ModernTextField(
                        controller: _titleController,
                        label: 'Título*',
                        hint: 'Ej: Entregar ensayo',
                        prefixIcon: Icons.title_rounded,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'El título es obligatorio';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Tipo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _OptionChip(
                              icon: Icons.assignment_rounded,
                              label: 'Tarea',
                              isSelected: _type == StudyItemType.task,
                              onTap: () => setState(() => _type = StudyItemType.task),
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _OptionChip(
                              icon: Icons.edit_note_rounded,
                              label: 'Examen',
                              isSelected: _type == StudyItemType.exam,
                              onTap: () => setState(() => _type = StudyItemType.exam),
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Prioridad',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _OptionChip(
                              icon: Icons.arrow_downward_rounded,
                              label: 'Baja',
                              isSelected: _priority == Priority.low,
                              onTap: () => setState(() => _priority = Priority.low),
                              color: colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _OptionChip(
                              icon: Icons.drag_handle_rounded,
                              label: 'Normal',
                              isSelected: _priority == Priority.normal,
                              onTap: () => setState(() => _priority = Priority.normal),
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _OptionChip(
                              icon: Icons.arrow_upward_rounded,
                              label: 'Alta',
                              isSelected: _priority == Priority.high,
                              onTap: () => setState(() => _priority = Priority.high),
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Estado',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _OptionChip(
                              icon: Icons.radio_button_unchecked_rounded,
                              label: 'Por hacer',
                              isSelected: _status == TaskStatus.todo,
                              onTap: () => setState(() => _status = TaskStatus.todo),
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _OptionChip(
                              icon: Icons.timelapse_rounded,
                              label: 'En progreso',
                              isSelected: _status == TaskStatus.doing,
                              onTap: () => setState(() => _status = TaskStatus.doing),
                              color: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _OptionChip(
                              icon: Icons.check_circle_rounded,
                              label: 'Hecha',
                              isSelected: _status == TaskStatus.done,
                              onTap: () => setState(() => _status = TaskStatus.done),
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Fecha límite',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 2),
                            initialDate: _dueDate ?? now,
                          );
                          if (date != null) {
                            setState(() => _dueDate = date);
                          }
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, color: colorScheme.primary),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  _dueDate != null
                                      ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                      : 'Sin fecha límite',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _dueDate != null
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (_dueDate != null)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => setState(() => _dueDate = null),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      ModernTextField(
                        controller: _notesController,
                        label: 'Notas (opcional)',
                        hint: 'Especificaciones, enlaces, entregables',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 3,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: ModernPrimaryButton(
                              label: isEdit ? 'Guardar cambios' : 'Crear tarea',
                              icon: Icons.check,
                              fullWidth: true,
                              isLoading: _isSaving,
                              onPressed: _isSaving ? null : _saveTask,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _OptionChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : colorScheme.onSurfaceVariant, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
