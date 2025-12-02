import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';
import 'watchlist_edit_screen.dart';
import 'symbol_edit_screen.dart';

class WatchlistsScreen extends StatelessWidget {
  const WatchlistsScreen({super.key});
  static const route = '/trading/watchlists';

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => Navigator.pushNamed(context, WatchlistEditScreen.route),
          ),
        ],
      ),
      body: StreamBuilder<List<Watchlist>>(
        stream: svc.watchWatchlists(),
        builder: (_, s) {
          final lists = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (lists.isEmpty)
            return const Center(child: Text('Crea tu primera watchlist'));
          return ListView.separated(
            itemCount: lists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final wl = lists[i];
              return ExpansionTile(
                leading: const Icon(Icons.star_border),
                title: Text(wl.name),
                children: [
                  StreamBuilder<List<WatchSymbol>>(
                    stream: svc.watchSymbols(wl.id),
                    builder: (_, s2) {
                      final syms = s2.data ?? [];
                      if (s2.connectionState == ConnectionState.waiting) {
                        return const ListTile(title: Text('Cargando...'));
                      }
                      return Column(
                        children: [
                          ...syms.map(
                            (x) => ListTile(
                              leading: CircleAvatar(
                                child: Text('${x.priority}'),
                              ),
                              title: Text(x.ticker),
                              subtitle: x.note != null ? Text(x.note!) : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed:
                                        () => Navigator.pushNamed(
                                          context,
                                          SymbolEditScreen.route,
                                          arguments: {'wl': wl, 'sym': x},
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed:
                                        () => svc.deleteSymbol(wl.id, x.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.add),
                            title: const Text('Añadir símbolo'),
                            onTap:
                                () => Navigator.pushNamed(
                                  context,
                                  SymbolEditScreen.route,
                                  arguments: {'wl': wl},
                                ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                  OverflowBar(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar lista'),
                        onPressed:
                            () => Navigator.pushNamed(
                              context,
                              WatchlistEditScreen.route,
                              arguments: wl,
                            ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar'),
                        onPressed:
                            () => TradingFirestoreService.I.deleteWatchlist(
                              wl.id,
                            ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
