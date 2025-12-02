// lib/screens/meditation/guided/guided_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';

class GuidedEditScreen extends StatefulWidget {
  const GuidedEditScreen({super.key});
  static const route = '/meditation/guided/edit';

  @override
  State<GuidedEditScreen> createState() => _GuidedEditScreenState();
}

class _GuidedEditScreenState extends State<GuidedEditScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _url = TextEditingController();
  int _minutes = 10;
  GuidedAudio? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is GuidedAudio && editing == null) {
      editing = arg;
      _title.text = arg.title;
      _url.text = arg.url;
      _minutes = (arg.durationSec / 60).round();
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = MeditationFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Nuevo audio' : 'Editar audio'),
      ),
      body: TaskFormTheme(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
          child: Form(
            key: _form,
            child: ListView(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _url,
                  decoration: const InputDecoration(
                    labelText: 'URL o asset',
                    helperText:
                        'Ejemplos: https://...  ó  assets/audio/guided/mi_audio.mp3',
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Duración (min)')),
                    DropdownButton<int>(
                      value: _minutes,
                      onChanged: (v) => setState(() => _minutes = v ?? 10),
                      items:
                          [3, 5, 8, 10, 12, 15, 20, 30]
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
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () async {
                    if (!_form.currentState!.validate()) return;
                    final obj = GuidedAudio(
                      id: editing?.id ?? '',
                      title: _title.text.trim(),
                      durationSec: _minutes * 60,
                      url: _url.text.trim(),
                    );
                    if (editing == null) {
                      await svc.addGuided(obj);
                    } else {
                      await svc.updateGuided(obj);
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
                      await svc.deleteGuided(editing!.id);
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
