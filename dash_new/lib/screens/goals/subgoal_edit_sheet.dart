import 'package:flutter/material.dart';
import '../goals/services/goals_firestore_service.dart';
import '../goals/models/goals_models.dart';
import '../../widgets/ui_scaffold.dart';

class SubGoalEditSheet extends StatefulWidget {
  final String goalId;
  final SubGoal? initial;
  const SubGoalEditSheet({super.key, required this.goalId, this.initial});

  @override
  State<SubGoalEditSheet> createState() => _SubGoalEditSheetState();
}

class _SubGoalEditSheetState extends State<SubGoalEditSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _progress = TextEditingController();
  final _progressTarget = TextEditingController();
  final _unit = TextEditingController();
  final _section = TextEditingController();
  GoalStatus _status = GoalStatus.planned;
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    if (x != null) {
      _title.text = x.title;
      _desc.text = x.description ?? '';
      _progress.text = x.progress?.toString() ?? '';
      _progressTarget.text = x.progressTarget?.toString() ?? '';
      _unit.text = x.unit ?? '';
      _section.text = x.section ?? '';
      _status = x.status;
      _due = x.dueDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return TaskFormTheme(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? 'Editar sub-objetivo' : 'Nuevo sub-objetivo',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v)=> (v==null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _progress,
                        decoration: const InputDecoration(labelText: 'Progreso'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _progressTarget,
                        decoration: const InputDecoration(labelText: 'Objetivo'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        controller: _unit,
                        decoration: const InputDecoration(labelText: 'Unidad'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _section,
                  decoration: const InputDecoration(labelText: 'Sección (agrupación)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<GoalStatus>(
                  initialValue: _status,
                  items: GoalStatus.values
                      .map((e)=>DropdownMenuItem(value: e, child: Text(e.name)))
                      .toList(),
                  onChanged: (v)=> setState(()=> _status = v ?? _status),
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text('Fecha: ${_due != null ? _due!.toLocal().toString().split(" ").first : "—"}'),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _due ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(()=> _due = d);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancelar')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        if (!_form.currentState!.validate()) return;
                        final sg = SubGoal(
                          id: widget.initial?.id ?? '',
                          title: _title.text.trim(),
                          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                          status: _status,
                          dueDate: _due,
                          progress: double.tryParse(_progress.text),
                          progressTarget: double.tryParse(_progressTarget.text),
                          unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
                          section: _section.text.trim().isEmpty ? null : _section.text.trim(),
                        );
                        if (widget.initial == null) {
                          await GoalsFirestoreService.I.addSubGoal(widget.goalId, sg);
                        } else {
                          await GoalsFirestoreService.I.updateSubGoal(widget.goalId, sg);
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      child: Text(isEdit ? 'Guardar' : 'Crear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
