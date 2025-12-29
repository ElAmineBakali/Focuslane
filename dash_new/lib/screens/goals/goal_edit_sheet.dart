import 'package:flutter/material.dart';
import '../goals/services/goals_firestore_service.dart';
import '../goals/models/goals_models.dart';
import '../../widgets/ui_scaffold.dart';

class GoalEditSheet extends StatefulWidget {
  final Goal? initial;
  const GoalEditSheet({super.key, this.initial});

  @override
  State<GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends State<GoalEditSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _progress = TextEditingController();
  final _progressTarget = TextEditingController();
  final _unit = TextEditingController();
  final _tags = TextEditingController();
  String? _colorHex;
  GoalStatus _status = GoalStatus.planned;
  DateTime? _targetDate;

  static const _swatches = <int>[
    0xFF2962FF,
    0xFF00BFA5,
    0xFF43A047,
    0xFFF9A825,
    0xFFEF6C00,
    0xFFE53935,
    0xFF8E24AA,
    0xFF546E7A,
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.initial;
    if (g != null) {
      _title.text = g.title;
      _desc.text = g.description ?? '';
      _progress.text = g.progress?.toString() ?? '';
      _progressTarget.text = g.progressTarget?.toString() ?? '';
      _unit.text = g.unit ?? '';
      _tags.text = g.tags.join(',');
      _status = g.status;
      _targetDate = g.targetDate;
      _colorHex = g.colorHex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return TaskFormTheme(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'Editar meta' : 'Nueva meta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _progress,
                        decoration: const InputDecoration(
                          labelText: 'Progreso',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _progressTarget,
                        decoration: const InputDecoration(
                          labelText: 'Objetivo',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _unit,
                        decoration: const InputDecoration(labelText: 'Unidad'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                DropdownButtonFormField<GoalStatus>(
                  initialValue: _status,
                  items:
                      GoalStatus.values
                          .map(
                            (e) =>
                                DropdownMenuItem(value: e, child: Text(e.name)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _status = v ?? _status),
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(
                    'Fecha objetivo: ${_targetDate != null ? _targetDate!.toLocal().toString().split(" ").first : "—"}',
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _targetDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _targetDate = d);
                  },
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Color',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Sin color'),
                      selected: _colorHex == null || _colorHex!.isEmpty,
                      onSelected: (_) => setState(() => _colorHex = null),
                    ),
                    ..._swatches.map((hex) {
                      final c = Color(hex);
                      final sel =
                          _colorHex ==
                          '0x${hex.toRadixString(16).toUpperCase()}';
                      return ChoiceChip(
                        selected: sel,
                        label: const SizedBox(width: 0, height: 0),
                        avatar: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                        onSelected:
                            (_) => setState(
                              () =>
                                  _colorHex =
                                      '0x${hex.toRadixString(16).toUpperCase()}',
                            ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 8),
                TextFormField(
                  controller: _tags,
                  decoration: const InputDecoration(labelText: 'Tags (coma)'),
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
                        if (!_form.currentState!.validate()) return;
                        final g = Goal(
                          id: widget.initial?.id ?? '',
                          title: _title.text.trim(),
                          description:
                              _desc.text.trim().isEmpty
                                  ? null
                                  : _desc.text.trim(),
                          status: _status,
                          targetDate: _targetDate,
                          progress: double.tryParse(_progress.text),
                          progressTarget: double.tryParse(_progressTarget.text),
                          unit:
                              _unit.text.trim().isEmpty
                                  ? null
                                  : _unit.text.trim(),
                          tags:
                              _tags.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList(),
                          colorHex: _colorHex,
                        );
                        if (widget.initial == null) {
                          await GoalsFirestoreService.I.addGoal(g);
                        } else {
                          await GoalsFirestoreService.I.updateGoal(g);
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      child: Text(isEdit ? 'Guardar' : 'Crear'),
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).viewPadding.bottom + 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
