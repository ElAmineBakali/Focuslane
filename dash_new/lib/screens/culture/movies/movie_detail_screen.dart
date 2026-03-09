import 'package:flutter/material.dart';
import '../../../screens/culture/services/culture_firestore_service.dart';
import '../models/culture_models.dart';
import 'movie_edit_screen.dart';
import '../../../design/widgets/ui_scaffold.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key});
  static const route = '/culture/movie';

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Movie) {
      return const Scaffold(body: Center(child: Text('Sin película')));
    }
    final m = arg;

    return Scaffold(
      appBar: AppBar(
        title: Text(m.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  MovieEditScreen.route,
                  arguments: m,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await svc.deleteMovie(m.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: PaddedListView(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_movies),
              title: Text('${m.year ?? "–"} • ${m.minutes ?? "-"} min'),
              subtitle: Text(
                'Estado: ${m.status.name} • Rating: ${m.rating?.toStringAsFixed(1) ?? "-"}',
              ),
            ),
          ),
          if (m.saga != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.collections),
                title: Text('Saga: ${m.saga}'),
              ),
            ),
          if (m.notes != null && m.notes!.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('Notas'),
                subtitle: Text(m.notes!),
              ),
            ),
          const SizedBox(height: 12),
          const ListTile(
            title: Text('Sugerencias'),
            subtitle: Text(
              '• Marca “vistaâ€ cuando la termines\n• Añade a una colección temática',
            ),
          ),
        ],
      ),
    );
  }
}



