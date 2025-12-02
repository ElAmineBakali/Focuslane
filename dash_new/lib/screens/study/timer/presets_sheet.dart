import 'package:flutter/material.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';

class PresetsSheet extends StatefulWidget {
  final StudyFirestoreService svc;
  final String? courseId;
  const PresetsSheet({super.key, required this.svc, this.courseId});

  @override
  State<PresetsSheet> createState() => _PresetsSheetState();
}

class _PresetsSheetState extends State<PresetsSheet> {
  final _name = TextEditingController(text: 'Pomodoro 25/5');
  StudyMethod _method = StudyMethod.pomodoro;
  // params por defecto
  final Map<String, dynamic> _params = {
    'work': 25,
    'short': 5,
    'long': 15,
    'cycles': 4,
  };

  void _setDefaults(StudyMethod m) {
    switch (m) {
      case StudyMethod.pomodoro:
        _params
          ..clear()
          ..addAll({'work': 25, 'short': 5, 'long': 15, 'cycles': 4});
        break;
      case StudyMethod.flowtime:
        _params
          ..clear()
          ..addAll({'ratio': 0.2}); // descanso = ratio * trabajo
        break;
      case StudyMethod.timeboxing:
        _params
          ..clear()
          ..addAll({'block': 50, 'rest': 10});
        break;
      case StudyMethod.custom:
        _params
          ..clear()
          ..addAll({
            'sequence': [
              {'label': 'W1', 'work': 40, 'rest': 10},
              {'label': 'W2', 'work': 40, 'rest': 10},
            ],
          });
        break;
      case StudyMethod.simple:
        _params
          ..clear()
          ..addAll({'target': 60}); // minutos
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text(
                  'Presets de estudio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<TimerPreset>>(
                    stream: widget.svc.streamPresets(courseId: widget.courseId),
                    builder: (context, snap) {
                      final presets = snap.data ?? const [];
                      return ListView.builder(
                        controller: controller,
                        itemCount: presets.length,
                        itemBuilder: (_, i) {
                          final p = presets[i];
                          return Card(
                            child: ListTile(
                              title: Text(p.name),
                              subtitle: Text('${p.method.name} • ${p.params}'),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => widget.svc.deletePreset(p.id),
                              ),
                              onTap: () => Navigator.pop(context, p),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del preset',
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<StudyMethod>(
                  initialValue: _method,
                  items:
                      StudyMethod.values
                          .map(
                            (m) =>
                                DropdownMenuItem(value: m, child: Text(m.name)),
                          )
                          .toList(),
                  onChanged: (v) {
                    setState(() {
                      _method = v ?? _method;
                      _setDefaults(_method);
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Método'),
                ),
                const SizedBox(height: 6),
                _ParamsEditor(method: _method, params: _params),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Spacer(),
                    FilledButton(
                      onPressed: () async {
                        final p = TimerPreset(
                          id: '',
                          name:
                              _name.text.trim().isEmpty
                                  ? 'Preset'
                                  : _name.text.trim(),
                          method: _method,
                          params: Map<String, dynamic>.from(_params),
                          courseId: widget.courseId,
                        );
                        await widget.svc.savePreset(p);
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Preset guardado')),
                          );
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).viewPadding.bottom + 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ParamsEditor extends StatefulWidget {
  final StudyMethod method;
  final Map<String, dynamic> params;
  const _ParamsEditor({required this.method, required this.params});

  @override
  State<_ParamsEditor> createState() => _ParamsEditorState();
}

class _ParamsEditorState extends State<_ParamsEditor> {
  @override
  Widget build(BuildContext context) {
    switch (widget.method) {
      case StudyMethod.pomodoro:
        return _numRows([
          _num('Trabajo (min)', 'work'),
          _num('Descanso corto (min)', 'short'),
          _num('Descanso largo (min)', 'long'),
          _num('Ciclos', 'cycles'),
        ]);
      case StudyMethod.flowtime:
        return _numRows([_num('Ratio descanso/trabajo (0.2 = 20%)', 'ratio')]);
      case StudyMethod.timeboxing:
        return _numRows([
          _num('Bloque (min)', 'block'),
          _num('Descanso (min)', 'rest'),
        ]);
      case StudyMethod.custom:
        return Text(
          'Secuencia: edita en Firestore (por sencillez aquí). Actual: ${widget.params['sequence']}',
        );
      case StudyMethod.simple:
        return _numRows([_num('Objetivo (minutos)', 'target')]);
    }
  }

  Widget _numRows(List<Widget> children) => Column(
    children:
        children
            .map(
              (w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: w,
              ),
            )
            .toList(),
  );

  Widget _num(String label, String key) {
    final ctrl = TextEditingController(text: '${widget.params[key] ?? ''}');
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) {
        final n = double.tryParse(v);
        if (n != null) widget.params[key] = n is int ? n : n.toDouble();
      },
    );
  }
}
