import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/utils/app_links.dart';
import '../../../services/culture_firestore_service.dart';
import '../../../models/culture_models.dart';

class GamesListScreen extends StatefulWidget {
  const GamesListScreen({super.key});
  static const route = '/culture/games';

  @override
  State<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  ItemStatus? _status;

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juegos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.link_rounded),
            onSelected: (v) {
              if (v == 'Discord') AppLinks.openDiscord();
              if (v == 'PlayStationApp') AppLinks.openPlayStationApp();
              if (v == 'steam') AppLinks.openSteam();
              if (v == 'chess') AppLinks.openChess();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Discord', child: Text('Discord')),
              PopupMenuItem(value: 'PlayStationApp', child: Text('PS App')),
              PopupMenuItem(value: 'steam', child: Text('Steam')),
              PopupMenuItem(value: 'chess', child: Text('Chess')),
            ],
          ),
          PopupMenuButton<ItemStatus?>(
            onSelected: (v) => setState(() => _status = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todos')),
              ...ItemStatus.values.map((e) => PopupMenuItem(value: e, child: Text(e.name))),
            ],
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: () => Navigator.pushNamed(context, '/culture/game/edit')),
        ],
      ),
      body: StreamBuilder<List<Game>>(
        stream: svc.watchGames(status: _status),
        builder: (_, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (data.isEmpty) return const Center(child: Text('Sin juegos'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final g = data[i];
              return ListTile(
                leading: const Icon(Icons.sports_esports),
                title: Text(g.title),
                subtitle: Text('${g.platform} • ${g.status.name} • ${g.progressPct}%'),
                trailing: Text('${g.hours.toStringAsFixed(1)} h'),
                onTap: () => Navigator.pushNamed(context, '/culture/game', arguments: g),
              );
            },
          );
        },
      ),
    );
  }
}
