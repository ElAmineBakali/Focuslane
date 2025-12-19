 import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/gym/services/gym_firestore_service.dart';
import '../models/gym_models.dart';
import '../widgets/exercise_picker_sheet.dart';

class RoutineBuilderScreen extends StatefulWidget {
  final GymFirestoreService svc;
  final Routine routine;
  const RoutineBuilderScreen({
    super.key,
    required this.svc,
    required this.routine,
  });

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  final _controllerName = TextEditingController();
  final _formKey = GlobalKey<FormState>();

     static const _palette = <Color>[
    Color(0xFF6750A4),      Color(0xFF386641),
    Color(0xFF1E88E5),
    Color(0xFFD81B60),
    Color(0xFFF57C00),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
    Color(0xFF9C27B0),
    Color(0xFF2E7D32),
  ];

  Color _selectedColor = const Color(0xFF6750A4);

  @override
  void initState() {
    super.initState();
    _controllerName.text = widget.routine.name;

         try {
      final cInt = (widget.routine as dynamic).color as int?;
      if (cInt != null) _selectedColor = Color(cInt);
    } catch (_) {
      try {
        final hex = (widget.routine as dynamic).colorHex as String?;
        if (hex != null && hex.length >= 7) {
          final v = int.parse(hex.substring(1), radix: 16);
          _selectedColor = Color(0xFF000000 | v);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controllerName.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    if (_formKey.currentState?.validate() != true) return;
    final name = _controllerName.text.trim();

    final changes = <String, dynamic>{};
    if (name.isNotEmpty && name != widget.routine.name) changes['name'] = name;

         final argb = _selectedColor.value;
    final rgb = argb & 0x00FFFFFF;
    final hex = '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
    changes['color'] = argb;
    changes['colorHex'] = hex;

    if (changes.isNotEmpty) {
      await widget.svc.updateRoutine(widget.routine.id, changes);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    final s = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de rutina'),
        actions: [
          IconButton(
            tooltip: 'Guardar cambios',
            onPressed: _saveAndClose,
            icon: const Icon(Icons.save_alt_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datos de la rutina',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _controllerName,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.edit_outlined),
                          hintText: 'Ej: Push/Pull/Legs',
                        ),
                        validator: (s) {
                          if ((s ?? '').trim().isEmpty) return 'Pon un nombre';
                          if ((s ?? '').trim().length < 3)
                            return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Color de la rutina',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _palette.map((c) {
                              final selected = c.value == _selectedColor.value;
                              return InkWell(
                                onTap: () => setState(() => _selectedColor = c),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      if (selected)
                                        BoxShadow(
                                          color: s.primary.withOpacity(.4),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                    ],
                                    border:
                                        selected
                                            ? Border.all(
                                              color: s.onPrimary,
                                              width: 2,
                                            )
                                            : Border.all(
                                              color: Colors.transparent,
                                            ),
                                  ),
                                  child:
                                      selected
                                          ? const Icon(
                                            Icons.check,
                                            size: 20,
                                            color: Colors.white,
                                          )
                                          : null,
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RoutineDay>>(
              stream: svc.streamDays(widget.routine.id),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final days = snap.data!;
                if (days.isEmpty) {
                  return const Center(
                    child: Text('Crea al menos un día en la rutina'),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    MediaQuery.of(context).viewPadding.bottom + 110,
                  ),
                  itemCount: days.length,
                  itemBuilder: (c, i) {
                    final d = days[i];
                    return Card(
                      child: ExpansionTile(
                        title: Text('${d.order}. ${d.name}'),
                        children: [
                          StreamBuilder<List<RoutineExercise>>(
                            stream: svc.streamDayExercises(
                              widget.routine.id,
                              d.id,
                            ),
                            builder: (context, exSnap) {
                              if (!exSnap.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final exercises = exSnap.data!;
                              return Column(
                                children: [
                                  if (exercises.isEmpty)
                                    const ListTile(
                                      title: Text('Sin ejercicios'),
                                    ),
                                  ReorderableListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: exercises.length,
                                    onReorder: (oldIndex, newIndex) async {
                                      if (newIndex > oldIndex) newIndex--;
                                      final ordered = [...exercises];
                                      final item = ordered.removeAt(oldIndex);
                                      ordered.insert(newIndex, item);
                                      await svc.reorderExercises(
                                        widget.routine.id,
                                        d.id,
                                        ordered.map((e) => e.id).toList(),
                                      );
                                    },
                                    itemBuilder: (_, idx) {
                                      final e = exercises[idx];
                                      return ListTile(
                                        key: ValueKey(e.id),
                                        leading: const Icon(
                                          Icons.drag_handle_rounded,
                                        ),
                                        title: Text(e.name),
                                        subtitle: Text(
                                          [
                                            '${e.targetSets} x ${e.targetReps}',
                                            if (e.restSec != null)
                                              'Descanso: ${e.restSec}s',
                                            if ((e.tempo ?? '').isNotEmpty)
                                              'Tempo: ${e.tempo}',
                                            if (e.targetRPE != null)
                                              'RPE: ${e.targetRPE}',
                                            if (e.targetPercent1RM != null)
                                              '%1RM: ${e.targetPercent1RM}',
                                          ].join(' • '),
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (v) async {
                                            if (v == 'dup') {
                                              await svc.duplicateExercise(
                                                widget.routine.id,
                                                d.id,
                                                e.id,
                                              );
                                            }
                                            if (v == 'edit') {
                                              await _editExerciseDialog(
                                                context,
                                                e,
                                                onSave: (fields) async {
                                                  await svc
                                                      .updateRoutineExercise(
                                                        widget.routine.id,
                                                        d.id,
                                                        e.id,
                                                        fields,
                                                      );
                                                },
                                              );
                                            }
                                          },
                                          itemBuilder:
                                              (_) => const [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Editar'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'dup',
                                                  child: Text('Duplicar'),
                                                ),
                                              ],
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.add),
                                    title: const Text('Añadir ejercicio'),
                                    onTap: () async {
                                      final picked = await showModalBottomSheet<
                                        RoutineExercise
                                      >(
                                        context: context,
                                        isScrollControlled: true,
                                        builder:
                                            (_) => ExercisePickerSheet(
                                              order: exercises.length,
                                              restDefault:
                                                  widget.routine.restSecDefault,
                                            ),
                                      );
                                      if (picked != null) {
                                        await svc.addRoutineExercise(
                                          widget.routine.id,
                                          d.id,
                                          picked,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
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

  Future<void> _editExerciseDialog(
    BuildContext context,
    RoutineExercise e, {
    required Future<void> Function(Map<String, dynamic>) onSave,
  }) async {
    final setsCtrl = TextEditingController(text: '${e.targetSets}');
    final repsCtrl = TextEditingController(text: '${e.targetReps}');
    final restCtrl = TextEditingController(text: e.restSec?.toString() ?? '');
    final tempoCtrl = TextEditingController(text: e.tempo ?? '');
    final rpeCtrl = TextEditingController(text: e.targetRPE?.toString() ?? '');
    final p1rmCtrl = TextEditingController(
      text: e.targetPercent1RM?.toString() ?? '',
    );
    final notesCtrl = TextEditingController(text: e.notes ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Editar ${e.name}'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: setsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Series objetivo',
                    ),
                  ),
                  TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Reps objetivo',
                    ),
                  ),
                  TextField(
                    controller: restCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Descanso (s)',
                    ),
                  ),
                  TextField(
                    controller: tempoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tempo (p. ej. 3-1-1)',
                    ),
                  ),
                  TextField(
                    controller: rpeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'RPE objetivo',
                    ),
                  ),
                  TextField(
                    controller: p1rmCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '%1RM objetivo',
                    ),
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
    if (ok == true) {
      final fields = <String, dynamic>{
        'targetSets': int.tryParse(setsCtrl.text) ?? e.targetSets,
        'targetReps': int.tryParse(repsCtrl.text) ?? e.targetReps,
        'restSec':
            restCtrl.text.trim().isEmpty ? null : int.tryParse(restCtrl.text),
        'tempo': tempoCtrl.text.trim().isEmpty ? null : tempoCtrl.text.trim(),
        'targetRPE':
            rpeCtrl.text.trim().isEmpty ? null : double.tryParse(rpeCtrl.text),
        'targetPercent1RM':
            p1rmCtrl.text.trim().isEmpty
                ? null
                : double.tryParse(p1rmCtrl.text),
        'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      };
      await onSave(fields);
    }
  }
}
