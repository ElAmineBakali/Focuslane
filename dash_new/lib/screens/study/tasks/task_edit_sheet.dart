import 'package:flutter/material.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';

class TaskEditSheet extends StatefulWidget {
  final StudyFirestoreService svc;
  final StudyTask? initial;
  final String? initialCourseId;
  const TaskEditSheet({
    super.key,
    required this.svc,
    this.initial,
    this.initialCourseId,
  });

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  String? _courseId;
  final _title = TextEditingController();
  final _notes = TextEditingController();
  StudyItemType _type = StudyItemType.task;
  Priority _prio = Priority.normal;
  TaskStatus _status = TaskStatus.todo;
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    if (t != null) {
      _courseId = t.courseId;
      _title.text = t.title;
      _notes.text = t.notes ?? '';
      _type = t.type;
      _prio = t.priority;
      _status = t.status;
      _due = t.due;
    } else {
      _courseId = widget.initialCourseId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SafeArea(
        child: StreamBuilder(
          stream: widget.svc.streamCourses(),
          builder: (context, snap) {
            final courses = snap.data ?? const [];
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? 'Editar' : 'Nueva tarea',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _courseId,
                    items:
                        courses
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _courseId = v),
                    decoration: const InputDecoration(labelText: 'Curso'),
                  ),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  DropdownButtonFormField<StudyItemType>(
                    initialValue: _type,
                    items: const [
                      DropdownMenuItem(
                        value: StudyItemType.task,
                        child: Text('Tarea'),
                      ),
                      DropdownMenuItem(
                        value: StudyItemType.exam,
                        child: Text('Examen'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? _type),
                    decoration: const InputDecoration(labelText: 'Tipo'),
                  ),
                  DropdownButtonFormField<Priority>(
                    initialValue: _prio,
                    items: const [
                      DropdownMenuItem(
                        value: Priority.low,
                        child: Text('Baja'),
                      ),
                      DropdownMenuItem(
                        value: Priority.normal,
                        child: Text('Normal'),
                      ),
                      DropdownMenuItem(
                        value: Priority.high,
                        child: Text('Alta'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _prio = v ?? _prio),
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                  ),
                  DropdownButtonFormField<TaskStatus>(
                    initialValue: _status,
                    items: const [
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
                        child: Text('Hecha'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? _status),
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha límite (opcional)',
                          ),
                          child: Text(_due?.toLocal().toString() ?? '—'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: () async {
                          final now = DateTime.now();
                          final d = await showDatePicker(
                            context: context,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 2),
                            initialDate: _due ?? now,
                          );
                          if (d != null) setState(() => _due = d);
                        },
                      ),
                      if (_due != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _due = null),
                        ),
                    ],
                  ),
                  TextField(
                    controller: _notes,
                    decoration: const InputDecoration(labelText: 'Notas'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final courseId = _courseId;
                          final title = _title.text.trim();
                          if (courseId == null || title.isEmpty) return;
                          final data = StudyTask(
                            id: '',
                            courseId: courseId,
                            title: title,
                            type: _type,
                            due: _due,
                            priority: _prio,
                            status: _status,
                            notes:
                                _notes.text.trim().isEmpty
                                    ? null
                                    : _notes.text.trim(),
                          );
                          if (widget.initial == null) {
                            await widget.svc.createTask(data);
                          } else {
                            await widget.svc.updateTask(
                              widget.initial!.id,
                              data.toMap(),
                            );
                          }
                          if (mounted) Navigator.pop(context);
                        },
                        child: Text(isEdit ? 'Guardar' : 'Crear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
