// lib/screens/meditation/programs/program_day_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/design/widgets/ui_scaffold.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';

class ProgramDayEditScreen extends StatefulWidget {
  const ProgramDayEditScreen({super.key});
  static const route = '/meditation/program/day/edit';

  @override
  State<ProgramDayEditScreen> createState() => _ProgramDayEditScreenState();
}

class _ProgramDayEditScreenState extends State<ProgramDayEditScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _goal = TextEditingController();
  int _dayNumber = 1;
  int _recommendedMin = 10;
  String _status = 'pending';
  MeditationProgram? program;
  ProgramDay? editing;

  String? _guidedId; // NUEVO

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Map) {
      program = arg['program'] as MeditationProgram;
      if (arg['day'] is ProgramDay && editing == null) {
        editing = arg['day'] as ProgramDay;
        _title.text = editing!.title;
        _goal.text = editing!.goal;
        _dayNumber = editing!.dayNumber;
        _recommendedMin = editing!.recommendedDurationSec ~/ 60;
        _status = editing!.status;
        _guidedId = editing!.guidedAudioId;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (program == null) {
      return const Scaffold(body: Center(child: Text('Sin programa')));
    }
    final svc = MeditationFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: Text(editing == null ? 'Nuevo dÃ­a' : 'Editar dÃ­a')),
      body: TaskFormTheme(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
          child: Form(
            key: _form,
            child: ListView(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'TÃ­tulo'),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _goal,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo / guÃ­a',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('DÃ­a #')),
                    DropdownButton<int>(
                      value: _dayNumber,
                      onChanged: (v) => setState(() => _dayNumber = v ?? 1),
                      items:
                          List.generate(60, (i) => i + 1)
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('$e'),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(child: Text('Minutos recomendados')),
                    DropdownButton<int>(
                      value: _recommendedMin,
                      onChanged:
                          (v) => setState(() => _recommendedMin = v ?? 10),
                      items:
                          [5, 10, 15, 20, 25, 30, 40, 45, 60]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('$e'),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  onChanged: (v) => setState(() => _status = v ?? 'pending'),
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(value: 'done', child: Text('Completado')),
                    DropdownMenuItem(value: 'skipped', child: Text('Saltado')),
                  ],
                ),
                const SizedBox(height: 8),

                // ---- GuÃ­a opcional (nullable seguro)
                StreamBuilder<List<GuidedAudio>>(
                  stream: svc.watchGuided(),
                  builder: (context, s) {
                    final list = s.data ?? [];
                    return DropdownButtonFormField<String?>(
                      initialValue:
                          list.any((g) => g.id == _guidedId) ? _guidedId : null,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin guÃ­a'),
                        ),
                        ...list.map(
                          (g) => DropdownMenuItem<String?>(
                            value: g.id,
                            child: Text('GuÃ­a: ${g.title}'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _guidedId = v),
                      decoration: const InputDecoration(
                        labelText: 'GuÃ­a (opcional)',
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () async {
                    if (!_form.currentState!.validate()) return;
                    final day = ProgramDay(
                      id: editing?.id ?? '',
                      dayNumber: _dayNumber,
                      title: _title.text.trim(),
                      goal: _goal.text.trim(),
                      recommendedDurationSec: _recommendedMin * 60,
                      status: _status,
                      guidedAudioId: _guidedId,
                    );
                    if (editing == null) {
                      await svc.addProgramDay(program!.id, day);
                    } else {
                      await svc.updateProgramDay(program!.id, day);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
                if (editing != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                    onPressed: () async {
                      await svc.deleteProgramDay(program!.id, editing!.id);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

