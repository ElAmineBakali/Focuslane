import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_firestore_service.dart';
import 'package:focuslane/design/widgets/ui_scaffold.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();
  final _categoryController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  bool _isPinned = false;
  RepeatRule _repeatRule = RepeatRule.none;
  final bool _isCalendarVisible = true;
  final List<Subtask> _subtasks = [];

  DateTime _combine(DateTime d, TimeOfDay? t) =>
      DateTime(d.year, d.month, d.day, t?.hour ?? 9, t?.minute ?? 0);

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    DateTime? finalDue;
    if (_dueDate != null) {
      finalDue = _combine(_dueDate!, _dueTime);
    }

    final tags =
        _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

    final task = Task(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      dueDate: finalDue,
      priority: _priority,
      category:
          _categoryController.text.trim().isNotEmpty
              ? _categoryController.text.trim()
              : null,
      completed: false,
      tags: tags,
      remindAt: null,
      isPinned: _isPinned,
      repeatRule: _repeatRule,
      subtasks: _subtasks,
      isCalendarVisible: _isCalendarVisible,
    );

    await TaskFirestoreService.addTask(task);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Tarea')),
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
                              ? 'Escribe un título'
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
                  controller: _descController,
                  minLines: 4,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Escribe una descripción',
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
                    hintText: 'Ej: Trabajo, Personal',
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

                Text('Prioridad', style: textTheme.titleMedium),
                const SizedBox(height: 5),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
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
                  onChanged: (value) => setState(() => _priority = value!),
                  decoration: InputDecoration(
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
                        _dueDate == null
                            ? 'Sin fecha seleccionada'
                            : DateFormat('dd/MM/yyyy').format(_dueDate!),
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
                        _dueTime == null
                            ? 'Sin hora seleccionada'
                            : _dueTime!.format(context),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDueTime,
                      icon: const Icon(Icons.access_time),
                      label: const Text('Elegir hora'),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Crear Tarea'),
                    onPressed: _saveTask,
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
