import 'package:flutter/material.dart';
import '../../../models/culture_models.dart';
import 'album_edit_screen.dart';
import '../../../services/culture_firestore_service.dart';
import '../../../widgets/ui_scaffold.dart';

class AlbumDetailScreen extends StatelessWidget {
  const AlbumDetailScreen({super.key});
  static const route = '/culture/album';

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Album)
      return const Scaffold(body: Center(child: Text('Sin álbum')));
    final a = arg;

    return Scaffold(
      appBar: AppBar(
        title: Text('${a.artist} • ${a.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  AlbumEditScreen.route,
                  arguments: a,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await svc.deleteAlbum(a.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: PaddedListView(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.album),
              title: Text('${a.year ?? "—"}'),
              subtitle: Text(
                'Estado: ${a.status.name} • Rating: ${a.rating?.toStringAsFixed(1) ?? "-"}',
              ),
            ),
          ),
          if (a.favoriteTracks.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Temas favoritos'),
                subtitle: Text(a.favoriteTracks.join(' • ')),
              ),
            ),
          if (a.notes != null && a.notes!.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('Notas'),
                subtitle: Text(a.notes!),
              ),
            ),
        ],
      ),
    );
  }
}
