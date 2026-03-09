import 'package:flutter/material.dart';
import '../../../screens/culture/services/culture_firestore_service.dart';
import '../models/culture_models.dart';
import '../../../design/widgets/ui_scaffold.dart';

class MovieEditScreen extends StatefulWidget {
  const MovieEditScreen({super.key});
  static const route = '/culture/movie/edit';

  @override
  State<MovieEditScreen> createState() => _MovieEditScreenState();
}

class _MovieEditScreenState extends State<MovieEditScreen> {
  final _title = TextEditingController();
  final _year = TextEditingController();
  final _minutes = TextEditingController();
  final _saga = TextEditingController();
  final _poster = TextEditingController();
  final _notes = TextEditingController();
  ItemStatus _status = ItemStatus.pending;
  double? _rating;

  Movie? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Movie && editing == null) {
      editing = arg;
      _title.text = arg.title;
      _year.text = arg.year?.toString() ?? '';
      _minutes.text = arg.minutes?.toString() ?? '';
      _saga.text = arg.saga ?? '';
      _status = arg.status;
      _rating = arg.rating;
      _poster.text = arg.posterUrl ?? '';
      _notes.text = arg.notes ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Nueva película' : 'Editar película'),
      ),
      body: TaskFormTheme(
        child: ListView(
          padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Año'),
            ),
            TextField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutos'),
            ),
            TextField(
              controller: _saga,
              decoration: const InputDecoration(labelText: 'Saga (opcional)'),
            ),
            TextField(
              controller: _poster,
              decoration: const InputDecoration(
                labelText: 'Poster URL (opcional)',
              ),
            ),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notas'),
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
                final m = Movie(
                  id: editing?.id ?? '',
                  title: _title.text.trim(),
                  year: int.tryParse(_year.text),
                  minutes: int.tryParse(_minutes.text),
                  saga: _saga.text.trim().isEmpty ? null : _saga.text.trim(),
                  status: _status,
                  rating: _rating,
                  posterUrl:
                      _poster.text.trim().isEmpty ? null : _poster.text.trim(),
                  notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                );
                if (editing == null) {
                  await svc.addMovie(m);
                } else {
                  await svc.updateMovie(m);
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



