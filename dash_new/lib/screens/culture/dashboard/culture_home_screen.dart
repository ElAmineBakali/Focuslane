import 'package:flutter/material.dart';
import '../../../services/culture_firestore_service.dart';

class CultureHomeScreen extends StatelessWidget {
  const CultureHomeScreen({super.key});
  static const route = '/culture';

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cultura'),
        actions: [
          IconButton(
            tooltip: 'Analíticas',
            icon: const Icon(Icons.insights),
            onPressed: () => Navigator.pushNamed(context, '/culture/analytics'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        child: Column(
          children: [
            // ── Botón "azul" dentro del grid/lista ───────────────────────
            _addTile(context),

            const SizedBox(height: 12),

            FutureBuilder<Map<String, dynamic>>(
              future: svc.quickKpis(),
              builder: (_, snap) {
                final m =
                    snap.data ??
                    const {
                      'booksDone': 0,
                      'moviesDone': 0,
                      'seriesDone': 0,
                      'gameHours': 0.0,
                    };
                final items = [
                  _kpiSmall(context, 'Libros terminados', '${m['booksDone']}'),
                  _kpiSmall(context, 'Películas vistas', '${m['moviesDone']}'),
                  _kpiSmall(
                    context,
                    'Series completadas',
                    '${m['seriesDone']}',
                  ),
                  _kpiSmall(
                    context,
                    'Horas juegos',
                    (m['gameHours'] as double).toStringAsFixed(1),
                  ),
                ];
                return _kpiResponsive(items);
              },
            ),

            const SizedBox(height: 12),
            _nav(context, 'Libros', Icons.menu_book, '/culture/books'),
            _nav(context, 'Series / Anime', Icons.tv, '/culture/series'),
            _nav(context, 'Películas', Icons.local_movies, '/culture/movies'),
            _nav(context, 'Música', Icons.album, '/culture/music'),
            _nav(context, 'Juegos', Icons.sports_esports, '/culture/games'),
            _nav(
              context,
              'Colecciones',
              Icons.collections_bookmark,
              '/culture/collections',
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── Helpers UI ─────────────────

  // Card “azul” de añadir (sustituye al FAB)
  Widget _addTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primary, // azul del tema
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAddSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.add, color: cs.onPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Añadir',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.expand_more, color: cs.onPrimary),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget it(String label, IconData icon, String route) {
          return ListTile(
            leading: Icon(icon),
            title: Text(label),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, route);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              it('Libro', Icons.menu_book_outlined, '/culture/book/edit'),
              it('Serie/Anime', Icons.tv_outlined, '/culture/series/edit'),
              it(
                'Película',
                Icons.local_movies_outlined,
                '/culture/movie/edit',
              ),
              it('Álbum', Icons.album_outlined, '/culture/album/edit'),
              it('Juego', Icons.sports_esports_outlined, '/culture/game/edit'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiSmall(BuildContext context, String title, String value) {
    final w = MediaQuery.of(context).size.width;
    final cardW = w < 480 ? (w - 16 - 8) / 2 : 220.0;
    return SizedBox(
      width: cardW,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.star, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiResponsive(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isNarrow = w < 520;
        if (!isNarrow) {
          return Wrap(spacing: 8, runSpacing: 8, children: items);
        }
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += 2) {
          if (i + 1 < items.length) {
            rows.add(
              Row(
                children: [
                  Expanded(child: items[i]),
                  const SizedBox(width: 8),
                  Expanded(child: items[i + 1]),
                ],
              ),
            );
          } else {
            rows.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: (w / 2) - 4),
                  Expanded(child: items[i]),
                ],
              ),
            );
          }
          rows.add(const SizedBox(height: 8));
        }
        return Column(children: rows);
      },
    );
  }

  Widget _nav(BuildContext ctx, String title, IconData icon, String route) =>
      Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(ctx, route),
        ),
      );
}
