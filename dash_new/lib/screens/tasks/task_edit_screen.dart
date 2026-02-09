import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_firestore_service.dart';
import 'package:mi_dashboard_personal/services/reminder_service.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';

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

  bool _enableReminder = false;
  DateTime? _remindDate;
  TimeOfDay? _remindTime;

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

    _enableReminder = widget.task.remindAt != null;
    if (widget.task.remindAt != null) {
      final r = widget.task.remindAt!;
      _remindDate = DateTime(r.year, r.month, r.day);
      _remindTime = TimeOfDay(hour: r.hour, minute: r.minute);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Tarea')),
      body: TaskFormTheme(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, screenPad(context)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Título', style: textTheme.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Introduce un título',
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Título obligatorio'
                              : null,
                ),
                const SizedBox(height: 16),
                Text('Repetición', style: textTheme.titleMedium),
                const SizedBox(height: 5),
                DropdownButtonFormField<RepeatRule>(
                  initialValue: _repeatRule,
                  items:
                      RepeatRule.values.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r.label));
                      }).toList(),
                  onChanged:
                      (v) => setState(() => _repeatRule = v ?? RepeatRule.none),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _isPinned,
                  onChanged: (v) => setState(() => _isPinned = v),
                  title: const Text('Fijar tarea arriba'),
                ),
                Tooltip(
                  message:
                      'Esta opción afectará al módulo Calendario próximamente',
                  child: SwitchListTile(
                    value: _isCalendarVisible,
                    onChanged: null,
                    title: const Text('Mostrar en calendario'),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Subtareas', style: textTheme.titleMedium),
                const SizedBox(height: 6),
                Column(
                  children: [
                    for (int i = 0; i < _subtasks.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _subtasks[i].isDone,
                              onChanged:
                                  (v) => setState(
                                    () =>
                                        _subtasks[i] = _subtasks[i].copyWith(
                                          isDone: v ?? false,
                                        ),
                                  ),
                            ),
                            Expanded(
                              child: TextFormField(
                                initialValue: _subtasks[i].title,
                                onChanged:
                                    (t) =>
                                        _subtasks[i] = _subtasks[i].copyWith(
                                          title: t,
                                        ),
                                decoration: InputDecoration(
                                  hintText: 'Título de subtarea',
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up),
                              onPressed:
                                  i > 0
                                      ? () => setState(() {
                                        final it = _subtasks.removeAt(i);
                                        _subtasks.insert(i - 1, it);
                                      })
                                      : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down),
                              onPressed:
                                  i < _subtasks.length - 1
                                      ? () => setState(() {
                                        final it = _subtasks.removeAt(i);
                                        _subtasks.insert(i + 1, it);
                                      })
                                      : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed:
                                  () => setState(() => _subtasks.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
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
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir subtarea'),
                      ),
                    ),
                  ],
                ),

                Text('Descripción', style: textTheme.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 8,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Escribe una descripción…',
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Categoría (opcional)', style: textTheme.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    hintText: 'Introduce una categoría…',
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Prioridad', style: textTheme.titleMedium),
                const SizedBox(height: 5),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: _selectedPriority,
                  items:
                      TaskPriority.values.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: p.getColor(), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                p.label[0].toUpperCase() + p.label.substring(1),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (val) => setState(() => _selectedPriority = val!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Tags (separadas por coma)', style: textTheme.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    hintText: 'Ej: urgente, reunión, compras',
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Fecha límite', style: textTheme.titleMedium),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Sin fecha seleccionada'
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Elegir fecha'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Text('Hora límite', style: textTheme.titleMedium),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedTime == null
                            ? 'Sin hora seleccionada'
                            : _selectedTime!.format(context),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDueTime,
                      icon: const Icon(Icons.access_time),
                      label: const Text('Elegir hora'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                SwitchListTile(
                  value: _enableReminder,
                  onChanged: (v) {
                    setState(() {
                      _enableReminder = v;
                      if (v) {
                        final now = DateTime.now().add(
                          const Duration(hours: 1),
                        );
                        _remindDate ??=
                            _selectedDate ??
                            DateTime(now.year, now.month, now.day);
                        _remindTime ??=
                            _selectedTime ??
                            TimeOfDay(hour: now.hour, minute: now.minute);
                      }
                    });
                  },
                  title: const Text('Añadir recordatorio'),
                ),
                if (_enableReminder) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _remindDate == null
                              ? 'Elegir fecha'
                              : DateFormat('dd/MM/yyyy').format(_remindDate!),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _remindDate ??
                                (_selectedDate ?? DateTime.now()),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _remindDate = picked);
                          }
                        },
                        icon: const Icon(Icons.event),
                        label: const Text('Fecha recordatorio'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _remindTime == null
                              ? 'Elegir hora'
                              : _remindTime!.format(context),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _remindTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => _remindTime = picked);
                          }
                        },
                        icon: const Icon(Icons.alarm),
                        label: const Text('Hora recordatorio'),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Cambios'),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      DateTime? finalDue;
                      if (_selectedDate != null) {
                        finalDue = _combine(_selectedDate!, _selectedTime);
                      }

                      final remindAt =
                          (_enableReminder && _remindDate != null)
                              ? _combine(_remindDate!, _remindTime)
                              : null;

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
                        completed: widget.task.completed,
                        tags: tags,
                        remindAt: remindAt,
                        order: widget.task.order,
                        isPinned: _isPinned,
                        repeatRule: _repeatRule,
                        subtasks: _subtasks,
                        isCalendarVisible: _isCalendarVisible,
                      );

                      await TaskFirestoreService.updateTask(updatedTask);

                      try {
                        await ReminderService.I.scheduleTaskReminder(
                          updatedTask,
                          previous: widget.task,
                          globalEnabled: true,
                          tasksEnabled: true,
                        );
                      } catch (e) {
                        debugPrint('Error scheduling task reminder: $e');
                      }

                      if (mounted) {
                        Navigator.popUntil(
                          context,
                          ModalRoute.withName('/tasks'),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
