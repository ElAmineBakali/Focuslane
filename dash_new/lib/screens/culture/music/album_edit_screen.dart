import 'package:flutter/material.dart';
import '../../../services/culture_firestore_service.dart';
import '../../../models/culture_models.dart';
import '../../../widgets/ui_scaffold.dart';

class AlbumEditScreen extends StatefulWidget {
  const AlbumEditScreen({super.key});
  static const route = '/culture/album/edit';

  @override
  State<AlbumEditScreen> createState() => _AlbumEditScreenState();
}

class _AlbumEditScreenState extends State<AlbumEditScreen> {
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _year = TextEditingController();
  final _cover = TextEditingController();
  final _tracks = TextEditingController();
  final _notes = TextEditingController();
  ItemStatus _status = ItemStatus.pending;
  double? _rating;

  Album? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Album && editing == null) {
      editing = arg;
      _title.text = arg.title;
      _artist.text = arg.artist;
      _year.text = arg.year?.toString() ?? '';
      _status = arg.status;
      _rating = arg.rating;
      _cover.text = arg.coverUrl ?? '';
      _tracks.text = arg.favoriteTracks.join(', ');
      _notes.text = arg.notes ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: Text(editing==null? 'Nuevo álbum' : 'Editar álbum')),
      body: TaskFormTheme(
        child: ListView(
          padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Título')),
            TextField(controller: _artist, decoration: const InputDecoration(labelText: 'Artista')),
            TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Año')),
            TextField(controller: _cover, decoration: const InputDecoration(labelText: 'Cover URL (opcional)')),
            TextField(controller: _tracks, decoration: const InputDecoration(labelText: 'Temas favoritos (coma)')),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notas'), maxLines: 3),
            DropdownButtonFormField<ItemStatus>(
              initialValue: _status, decoration: const InputDecoration(labelText: 'Estado'),
              items: ItemStatus.values.map((e)=>DropdownMenuItem(value:e, child: Text(e.name))).toList(),
              onChanged: (v)=>setState(()=>_status=v??ItemStatus.pending),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Valoración (0..10)'),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  controller: TextEditingController(text: _rating?.toStringAsFixed(1) ?? ''),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v)=> _rating = double.tryParse(v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              onPressed: () async {
                final a = Album(
                  id: editing?.id ?? '',
                  title: _title.text.trim(),
                  artist: _artist.text.trim(),
                  year: int.tryParse(_year.text),
                  status: _status,
                  rating: _rating,
                  favoriteTracks: _tracks.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(),
                  coverUrl: _cover.text.trim().isEmpty ? null : _cover.text.trim(),
                  notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                );
                if (editing == null) {
                  await svc.addAlbum(a);
                } else {
                  await svc.updateAlbum(a);
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
