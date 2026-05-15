import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/design/widgets/ui_scaffold.dart';

import '../models/task_model.dart';
import '../services/task_firestore_service.dart';

class TaskEditScreen extends StatefulWidget {
  final Task task;

  const TaskEditScreen({super.key, required this.task});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late TaskPriority _selectedPriority;

  late bool _isPinned;
  late RepeatRule _repeatRule;
  late bool _isCalendarVisible;
  late List<Subtask> _subtasks;

  DateTime _combine(DateTime d, TimeOfDay? t) =>
      DateTime(d.year, d.month, d.day, t?.hour ?? 9, t?.minute ?? 0);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _categoryController = TextEditingController(
      text: widget.task.category ?? '',
    );
    _tagsController = TextEditingController(text: widget.task.tags.join(', '));

    _selectedDate = widget.task.dueDate;
    _selectedTime =
        widget.task.dueDate != null
            ? TimeOfDay.fromDateTime(widget.task.dueDate!)
            : null;
    _selectedPriority = widget.task.priority;
    _isPinned = widget.task.isPinned;
    _repeatRule = widget.task.repeatRule;
    _isCalendarVisible = widget.task.isCalendarVisible;
    _subtasks = List<Subtask>.from(widget.task.subtasks);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    DateTime? finalDue;
    if (_selectedDate != null) {
      finalDue = _combine(_selectedDate!, _selectedTime);
    }

    final tags =
        _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

    final updatedTask = Task(
      id: widget.task.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: finalDue,
      priority: _selectedPriority,
      category:
          _categoryController.text.isNotEmpty
              ? _categoryController.text.trim()
              : null,
      reminderTime: widget.task.reminderTime,
      completed: widget.task.completed,
      tags: tags,
      remindAt: widget.task.remindAt,
      order: widget.task.order,
      isPinned: _isPinned,
      repeatRule: _repeatRule,
      subtasks: _subtasks,
      isCalendarVisible: _isCalendarVisible,
      linkedNoteId: widget.task.linkedNoteId,
      linkedStudyCourseId: widget.task.linkedStudyCourseId,
      syncedStudyTaskId: widget.task.syncedStudyTaskId,
    );

    await TaskFirestoreService.updateTask(updatedTask);

    if (mounted) {
      Navigator.popUntil(context, ModalRoute.withName('/tasks'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 720 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('Editar tarea')),
      body: TaskFormTheme(
        child: SingleChildScrollView(
          child: PageContainer(
            maxWidth: 960,
            padding: EdgeInsets.fromLTRB(
              horizontal,
              18,
              horizontal,
              screenPad(context),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TaskFormIntro(
                    title: 'Editar tarea',
                    subtitle:
                        'Actualiza los detalles sin cambiar la conexion con tus datos reales.',
                    icon: Icons.edit_note_rounded,
                  ),
                  const SizedBox(height: 18),
                  FocusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FocusSectionHeader(
                          title: 'Contenido',
                          subtitle: 'Nombre, descripcion y clasificacion',
                          icon: Icons.notes_rounded,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _titleController,
                          decoration: _inputDecoration(
                            context,
                            label: 'Titulo',
                            hint: 'Introduce un titulo',
                            icon: Icons.title_rounded,
                          ),
                          validator:
                              (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Titulo obligatorio'
                                      : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 5,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: _inputDecoration(
                            context,
                            label: 'Descripcion',
                            hint: 'Escribe una descripcion',
                            icon: Icons.subject_rounded,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ResponsiveFieldRow(
                          children: [
                            TextFormField(
                              controller: _categoryController,
                              decoration: _inputDecoration(
                                context,
                                label: 'Categoria opcional',
                                hint: 'Introduce una categoria',
                                icon: Icons.folder_open_rounded,
                              ),
                            ),
                            TextFormField(
                              controller: _tagsController,
                              decoration: _inputDecoration(
                                context,
                                label: 'Etiquetas',
                                hint: 'Ej: urgente, reunion, compras',
                                icon: Icons.label_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FocusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FocusSectionHeader(
                          title: 'Planificacion',
                          subtitle: 'Prioridad, repeticion y fecha limite',
                          icon: Icons.event_available_rounded,
                        ),
                        const SizedBox(height: 18),
                        _ResponsiveFieldRow(
                          children: [
                            DropdownButtonFormField<TaskPriority>(
                              initialValue: _selectedPriority,
                              items:
                                  TaskPriority.values.map((priority) {
                                    return DropdownMenuItem(
                                      value: priority,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.flag_rounded,
                                            color: priority.getColor(),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_priorityLabel(priority)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  (value) => setState(
                                    () => _selectedPriority = value!,
                                  ),
                              decoration: _inputDecoration(
                                context,
                                label: 'Prioridad',
                                icon: Icons.flag_rounded,
                              ),
                            ),
                            DropdownButtonFormField<RepeatRule>(
                              initialValue: _repeatRule,
                              items:
                                  RepeatRule.values.map((rule) {
                                    return DropdownMenuItem(
                                      value: rule,
                                      child: Text(rule.label),
                                    );
                                  }).toList(),
                              onChanged:
                                  (value) => setState(
                                    () =>
                                        _repeatRule = value ?? RepeatRule.none,
                                  ),
                              decoration: _inputDecoration(
                                context,
                                label: 'Repeticion',
                                icon: Icons.autorenew_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ResponsiveFieldRow(
                          children: [
                            _DateTimePickerTile(
                              label: 'Fecha limite',
                              value:
                                  _selectedDate == null
                                      ? 'Sin fecha seleccionada'
                                      : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_selectedDate!),
                              icon: Icons.calendar_today_rounded,
                              onPressed: _pickDueDate,
                            ),
                            _DateTimePickerTile(
                              label: 'Hora limite',
                              value:
                                  _selectedTime == null
                                      ? 'Sin hora seleccionada'
                                      : _selectedTime!.format(context),
                              icon: Icons.access_time_rounded,
                              onPressed: _pickDueTime,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SwitchPanel(
                          isPinned: _isPinned,
                          isCalendarVisible: _isCalendarVisible,
                          onPinnedChanged:
                              (value) => setState(() => _isPinned = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FocusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FocusSectionHeader(
                          title: 'Subtareas',
                          subtitle: 'Pasos pequeños dentro de la tarea',
                          icon: Icons.checklist_rounded,
                          trailing: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _subtasks.add(
                                  Subtask(
                                    id:
                                        DateTime.now().microsecondsSinceEpoch
                                            .toString(),
                                    title: '',
                                    isDone: false,
                                  ),
                                );
                              });
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Añadir'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_subtasks.isEmpty)
                          _InlineEmptyPanel(
                            icon: Icons.playlist_add_check_rounded,
                            title: 'Sin subtareas',
                            subtitle: 'Puedes añadir pasos opcionales.',
                          )
                        else
                          Column(
                            children: [
                              for (int i = 0; i < _subtasks.length; i++)
                                _EditableSubtaskRow(
                                  subtask: _subtasks[i],
                                  canMoveUp: i > 0,
                                  canMoveDown: i < _subtasks.length - 1,
                                  onDoneChanged:
                                      (value) => setState(
                                        () =>
                                            _subtasks[i] = _subtasks[i]
                                                .copyWith(isDone: value),
                                      ),
                                  onTitleChanged:
                                      (text) =>
                                          _subtasks[i] = _subtasks[i].copyWith(
                                            title: text,
                                          ),
                                  onMoveUp:
                                      i > 0
                                          ? () => setState(() {
                                            final item = _subtasks.removeAt(i);
                                            _subtasks.insert(i - 1, item);
                                          })
                                          : null,
                                  onMoveDown:
                                      i < _subtasks.length - 1
                                          ? () => setState(() {
                                            final item = _subtasks.removeAt(i);
                                            _subtasks.insert(i + 1, item);
                                          })
                                          : null,
                                  onDelete:
                                      () =>
                                          setState(() => _subtasks.removeAt(i)),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _FormActions(
                    primaryLabel: 'Guardar cambios',
                    primaryIcon: Icons.save_rounded,
                    onPrimary: _saveChanges,
                    onCancel: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableSubtaskRow extends StatelessWidget {
  const _EditableSubtaskRow({
    required this.subtask,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onDoneChanged,
    required this.onTitleChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  final Subtask subtask;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<bool> onDoneChanged;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final field = Row(
            children: [
              Checkbox(
                value: subtask.isDone,
                onChanged: (value) => onDoneChanged(value ?? false),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: subtask.title,
                  onChanged: onTitleChanged,
                  decoration: _inputDecoration(
                    context,
                    label: 'Titulo de subtarea',
                    icon: Icons.short_text_rounded,
                  ),
                ),
              ),
            ],
          );
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SmallIconButton(
                icon: Icons.keyboard_arrow_up_rounded,
                tooltip: 'Subir',
                onPressed: canMoveUp ? onMoveUp : null,
              ),
              _SmallIconButton(
                icon: Icons.keyboard_arrow_down_rounded,
                tooltip: 'Bajar',
                onPressed: canMoveDown ? onMoveDown : null,
              ),
              _SmallIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Eliminar subtarea',
                onPressed: onDelete,
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                field,
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: field),
              const SizedBox(width: 8),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

class _TaskFormIntro extends StatelessWidget {
  const _TaskFormIntro({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      backgroundColor: scheme.surfaceContainerLowest,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveFieldRow extends StatelessWidget {
  const _ResponsiveFieldRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620 || children.length == 1) {
          return Column(
            children: [
              for (int index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const SizedBox(height: 14),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }
}

class _DateTimePickerTile extends StatelessWidget {
  const _DateTimePickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FocuslaneTokens.borderColor(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SwitchPanel extends StatelessWidget {
  const _SwitchPanel({
    required this.isPinned,
    required this.isCalendarVisible,
    required this.onPinnedChanged,
  });

  final bool isPinned;
  final bool isCalendarVisible;
  final ValueChanged<bool> onPinnedChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: isPinned,
            onChanged: onPinnedChanged,
            title: const Text('Fijar tarea arriba'),
            secondary: const Icon(Icons.push_pin_outlined),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Tooltip(
            message: 'Esta opcion afectara al modulo Calendario proximamente',
            child: SwitchListTile(
              value: isCalendarVisible,
              onChanged: null,
              title: const Text('Mostrar en calendario'),
              secondary: const Icon(Icons.calendar_month_outlined),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineEmptyPanel extends StatelessWidget {
  const _InlineEmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormActions extends StatelessWidget {
  const _FormActions({
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.onCancel,
  });

  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              FocusPrimaryButton(
                label: primaryLabel,
                icon: primaryIcon,
                onPressed: onPrimary,
                fullWidth: true,
              ),
              const SizedBox(height: 10),
              FocusSecondaryButton(
                label: 'Cancelar',
                icon: Icons.close_rounded,
                onPressed: onCancel,
                fullWidth: true,
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FocusSecondaryButton(
              label: 'Cancelar',
              icon: Icons.close_rounded,
              onPressed: onCancel,
            ),
            const SizedBox(width: 12),
            FocusPrimaryButton(
              label: primaryLabel,
              icon: primaryIcon,
              onPressed: onPrimary,
            ),
          ],
        );
      },
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  IconData? icon,
}) {
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 19),
    filled: true,
    fillColor: scheme.surfaceContainerHigh,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: FocuslaneTokens.borderColor(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.primary),
    ),
  );
}

String _priorityLabel(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'Alta';
    case TaskPriority.medium:
      return 'Media';
    case TaskPriority.low:
      return 'Baja';
  }
}
