import 'package:flutter/material.dart';
import '../../../services/culture_firestore_service.dart';
import '../../../models/culture_models.dart';
import '../../../widgets/ui_scaffold.dart';

class GameEditScreen extends StatefulWidget {
  const GameEditScreen({super.key});
  static const route = '/culture/game/edit';

  @override
  State<GameEditScreen> createState() => _GameEditScreenState();
}

class _GameEditScreenState extends State<GameEditScreen> {
  final _title = TextEditingController();
  final _platform = TextEditingController(text: 'PC');
  final _cover = TextEditingController();
  final _notes = TextEditingController();
  final _hours = TextEditingController(text: '0');
  final _progress = TextEditingController(text: '0');
  final _difficulty = TextEditingController();
  ItemStatus _status = ItemStatus.pending;
  double? _rating;

  Game? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Game && editing == null) {
      editing = arg;
      _title.text = arg.title;
      _platform.text = arg.platform;
      _cover.text = arg.coverUrl ?? '';
      _notes.text = arg.notes ?? '';
      _hours.text = arg.hours.toStringAsFixed(1);
      _progress.text = arg.progressPct.toString();
      _status = arg.status;
      _rating = arg.rating;
      _difficulty.text = arg.difficulty?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Nuevo juego' : 'Editar juego'),
      ),
      body: TaskFormTheme(
        child: ListView(
          padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej. Elden Ring',
              ),
            ),
            TextField(
              controller: _platform,
              decoration: const InputDecoration(labelText: 'Plataforma'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hours,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Horas'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _progress,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Progreso %'),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _difficulty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Dificultad (1..5)'),
            ),
            TextField(
              controller: _cover,
              decoration: const InputDecoration(
                labelText: 'Cover URL (opcional)',
              ),
            ),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 3,
            ),
            DropdownButtonFormField<ItemStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Estado'),
              items:
                  ItemStatus.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
              onChanged:
                  (v) => setState(() => _status = v ?? ItemStatus.pending),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Valoración (0..10)'),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  controller: TextEditingController(
                    text: _rating?.toStringAsFixed(1) ?? '',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => _rating = double.tryParse(v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              onPressed: () async {
                final g = Game(
                  id: editing?.id ?? '',
                  title: _title.text.trim(),
                  platform: _platform.text.trim(),
                  status: _status,
                  rating: _rating,
                  hours: double.tryParse(_hours.text) ?? 0.0,
                  progressPct: int.tryParse(_progress.text) ?? 0,
                  tags: const [],
                  coverUrl:
                      _cover.text.trim().isEmpty ? null : _cover.text.trim(),
                  notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                  difficulty: int.tryParse(_difficulty.text),
                );
                if (editing == null) {
                  await svc.addGame(g);
                } else {
                  await svc.updateGame(g);
                }
                if (mounted) Navigator.pop(context);
              },
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
