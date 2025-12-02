// lib/screens/meditation/presets/breath_preset_edit_screen.dart
import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';

class BreathPresetEditScreen extends StatefulWidget {
  const BreathPresetEditScreen({super.key});
  static const route = '/meditation/preset/edit';

  @override
  State<BreathPresetEditScreen> createState() => _BreathPresetEditScreenState();
}

class _BreathPresetEditScreenState extends State<BreathPresetEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  int _inhale = 4, _hold = 4, _exhale = 4, _hold2 = 0, _cycles = 6;
  bool _vibration = true;
  String _visual = 'circle';
  BreathPreset? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is BreathPreset && editing == null) {
      editing = arg;
      _name.text = arg.name;
      _inhale = arg.inhale;
      _hold = arg.hold;
      _exhale = arg.exhale;
      _hold2 = arg.hold2;
      _cycles = arg.cycles;
      _vibration = arg.vibration;
      _visual = arg.visualStyle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = MeditationFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Nuevo preset' : 'Editar preset'),
      ),
      body: TaskFormTheme(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
          child: Form(
            key: _form,
            child: ListView(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                _numPicker(
                  'Inhala (s)',
                  _inhale,
                  (v) => setState(() => _inhale = v),
                  [2, 3, 4, 5, 6, 7, 8, 10],
                ),
                _numPicker(
                  'Mantén (s)',
                  _hold,
                  (v) => setState(() => _hold = v),
                  [0, 2, 3, 4, 5, 6, 8, 10],
                ),
                _numPicker(
                  'Exhala (s)',
                  _exhale,
                  (v) => setState(() => _exhale = v),
                  [2, 3, 4, 5, 6, 7, 8, 10],
                ),
                _numPicker(
                  'Mantén 2 (s)',
                  _hold2,
                  (v) => setState(() => _hold2 = v),
                  [0, 2, 3, 4, 5, 6, 8, 10],
                ),
                _numPicker(
                  'Ciclos',
                  _cycles,
                  (v) => setState(() => _cycles = v),
                  [3, 4, 5, 6, 7, 8, 10, 12],
                ),
                SwitchListTile(
                  title: const Text('Vibración'),
                  value: _vibration,
                  onChanged: (v) => setState(() => _vibration = v),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _visual,
                  items: const [
                    DropdownMenuItem(value: 'circle', child: Text('Círculo')),
                    DropdownMenuItem(value: 'dot', child: Text('Punto')),
                    DropdownMenuItem(value: 'wave', child: Text('Ola')),
                  ],
                  onChanged: (v) => setState(() => _visual = v ?? 'circle'),
                  decoration: const InputDecoration(labelText: 'Estilo visual'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () async {
                    if (!_form.currentState!.validate()) return;
                    final p = BreathPreset(
                      id: editing?.id ?? '',
                      name: _name.text.trim(),
                      inhale: _inhale,
                      hold: _hold,
                      exhale: _exhale,
                      hold2: _hold2,
                      cycles: _cycles,
                      vibration: _vibration,
                      visualStyle: _visual,
                    );
                    if (editing == null) {
                      await svc.addPreset(p);
                    } else {
                      await svc.updatePreset(p);
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
                      await svc.deletePreset(editing!.id);
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

  Widget _numPicker(
    String label,
    int value,
    void Function(int) onChanged,
    List<int> options,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: DropdownButton<int>(
        value: value,
        items:
            options
                .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                .toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}
