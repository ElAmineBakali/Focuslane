// lib/screens/meditation/sessions/session_edit_screen.dart
import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';

class SessionEditScreen extends StatefulWidget {
  const SessionEditScreen({super.key});
  static const route = '/meditation/session/edit';

  @override
  State<SessionEditScreen> createState() => _SessionEditScreenState();
}

class _SessionEditScreenState extends State<SessionEditScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _tags = TextEditingController();
  int _durationMin = 10;
  DateTime _date = DateTime.now();
  SessionType _type = SessionType.timer;
  MeditationSession? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is MeditationSession && editing == null) {
      editing = arg;
      _title.text = arg.title;
      _notes.text = arg.notes ?? '';
      _tags.text = arg.tags.join(',');
      _durationMin = ((arg.durationSec / 60).round()).clamp(1, 300);
      _date = arg.date;
      _type = arg.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = MeditationFirestoreService.I;
    final durationOptions = [3, 5, 10, 15, 20, 30, 45, 60, 90, 120];
    if (!durationOptions.contains(_durationMin)) {
      _durationMin = durationOptions.first; // 🔒 evita assert del Dropdown
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Nueva sesión' : 'Editar sesión'),
      ),
      body: TaskFormTheme(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
          child: Form(
            key: _form,
            child: ListView(
              children: [
                DropdownButtonFormField<SessionType>(
                  initialValue: _type,
                  items: const [
                    DropdownMenuItem(
                      value: SessionType.timer,
                      child: Text('Temporizador'),
                    ),
                    DropdownMenuItem(
                      value: SessionType.breath,
                      child: Text('Respiración'),
                    ),
                    DropdownMenuItem(
                      value: SessionType.guided,
                      child: Text('Guiada'),
                    ),
                  ],
                  onChanged:
                      (v) => setState(() => _type = v ?? SessionType.timer),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Título (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Duración (min)')),
                    DropdownButton<int>(
                      value: _durationMin,
                      onChanged:
                          (v) =>
                              setState(() => _durationMin = v ?? _durationMin),
                      items:
                          durationOptions
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
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(
                    'Fecha: ${_date.toLocal().toString().split(' ').first}',
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: 'Tags (coma separada)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notas'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () async {
                    final obj = MeditationSession(
                      id: editing?.id ?? '',
                      title: _title.text.trim(),
                      type: _type,
                      durationSec: _durationMin * 60,
                      date: _date,
                      notes:
                          _notes.text.trim().isEmpty
                              ? null
                              : _notes.text.trim(),
                      tags:
                          _tags.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                    );
                    if (editing == null) {
                      await svc.addSession(obj);
                    } else {
                      await svc.updateSession(obj);
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
                      await svc.deleteSession(editing!.id);
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
