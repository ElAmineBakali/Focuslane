import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/utils/app_links.dart';
import '../../../services/culture_firestore_service.dart';
import '../../../models/culture_models.dart';

class MoviesListScreen extends StatefulWidget {
  const MoviesListScreen({super.key});
  static const route = '/culture/movies';

  @override
  State<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<MoviesListScreen> {
  ItemStatus? _status;

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Películas'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Atajos',
            icon: const Icon(Icons.link_rounded),
            onSelected: (v) {
              if (v == 'netflix') AppLinks.openNetflix();
              if (v == 'cinesa') AppLinks.openCinesa();
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'netflix', child: Text('Netflix')),
                  PopupMenuItem(value: 'cinesa', child: Text('Cinesa')),
                ],
          ),
          PopupMenuButton<ItemStatus?>(
            onSelected: (v) => setState(() => _status = v),
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: null, child: Text('Todas')),
                  ...ItemStatus.values.map(
                    (e) => PopupMenuItem(value: e, child: Text(e.name)),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => Navigator.pushNamed(context, '/culture/movie/edit'),
          ),
        ],
      ),
      body: StreamBuilder<List<Movie>>(
        stream: svc.watchMovies(status: _status),
        builder: (_, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin películas'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = data[i];
              return ListTile(
                leading: const Icon(Icons.local_movies_outlined),
                title: Text(m.title),
                subtitle: Text(
                  '${m.year ?? "—"} • ${m.saga ?? ""} • ${m.status.name}',
                ),
                trailing: Text(m.rating?.toStringAsFixed(1) ?? '-'),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      '/culture/movie',
                      arguments: m,
                    ),
              );
            },
          );
        },
      ),
    );
  }
}
