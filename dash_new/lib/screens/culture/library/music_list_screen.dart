import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/shared/app_links.dart';
import '../../../screens/culture/services/culture_firestore_service.dart';
import '../models/culture_models.dart';

class MusicListScreen extends StatefulWidget {
  const MusicListScreen({super.key});
  static const route = '/culture/music';

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  ItemStatus? _status;

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Música (Álbumes)'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.link_rounded),
            onSelected: (v) {
              if (v == 'sc') AppLinks.openSoundCloud();
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'sc', child: Text('SoundCloud')),
                ],
          ),
          PopupMenuButton<ItemStatus?>(
            onSelected: (v) => setState(() => _status = v),
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: null, child: Text('Todos')),
                  ...ItemStatus.values.map(
                    (e) => PopupMenuItem(value: e, child: Text(e.name)),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => Navigator.pushNamed(context, '/culture/album/edit'),
          ),
        ],
      ),
      body: StreamBuilder<List<Album>>(
        stream: svc.watchAlbums(status: _status),
        builder: (_, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin álbumes'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final a = data[i];
              return ListTile(
                leading: const Icon(Icons.album_outlined),
                title: Text(a.title),
                subtitle: Text('${a.artist} • ${a.status.name}'),
                trailing: Text(a.rating?.toStringAsFixed(1) ?? '-'),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      '/culture/album',
                      arguments: a,
                    ),
              );
            },
          );
        },
      ),
    );
  }
}



