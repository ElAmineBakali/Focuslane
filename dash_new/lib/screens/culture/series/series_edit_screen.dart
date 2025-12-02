import 'package:flutter/material.dart';
import '../../../services/culture_firestore_service.dart';
import '../../../models/culture_models.dart';

class SeriesEditScreen extends StatefulWidget {
  const SeriesEditScreen({super.key});
  static const route = '/culture/series/edit';

  @override
  State<SeriesEditScreen> createState() => _SeriesEditScreenState();
}

class _SeriesEditScreenState extends State<SeriesEditScreen> {
  final _title = TextEditingController();
  final _platform = TextEditingController();
  final _poster = TextEditingController();
  ItemStatus _status = ItemStatus.pending;
  double? _rating;

  Series? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Series && editing == null) {
      editing = arg;
      _title.text = arg.title;
      _platform.text = arg.platform ?? '';
      _status = arg.status;
      _rating = arg.rating;
      _poster.text = arg.posterUrl ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Nueva serie' : 'Editar serie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _platform,
              decoration: const InputDecoration(labelText: 'Plataforma'),
            ),
            TextField(
              controller: _poster,
              decoration: const InputDecoration(
                labelText: 'Poster URL (opcional)',
              ),
            ),
            DropdownButtonFormField<ItemStatus>(
              initialValue: _status,
              items:
                  ItemStatus.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
              onChanged:
                  (v) => setState(() => _status = v ?? ItemStatus.pending),
              decoration: const InputDecoration(labelText: 'Estado'),
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
            FilledButton(
              onPressed: () async {
                final x = Series(
                  id: editing?.id ?? '',
                  title: _title.text.trim(),
                  platform:
                      _platform.text.trim().isEmpty
                          ? null
                          : _platform.text.trim(),
                  status: _status,
                  rating: _rating,
                  posterUrl:
                      _poster.text.trim().isEmpty ? null : _poster.text.trim(),
                );
                if (editing == null) {
                  await svc.addSeries(x);
                } else {
                  await svc.updateSeries(x);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
