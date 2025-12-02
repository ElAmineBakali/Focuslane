// lib/screens/meditation/guided/guided_library_screen.dart
import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';
import 'guided_player_screen.dart';
import 'guided_edit_screen.dart';

class GuidedLibraryScreen extends StatelessWidget {
  const GuidedLibraryScreen({super.key});
  static const route = '/meditation/guided';

  @override
  Widget build(BuildContext context) {
    final svc = MeditationFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditación guiada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Añadir audio',
            onPressed:
                () => Navigator.pushNamed(context, GuidedEditScreen.route),
          ),
        ],
      ),
      body: StreamBuilder<List<GuidedAudio>>(
        stream: svc.watchGuided(),
        builder: (context, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) {
            return const Center(
              child: Text('Sin audios. Pulsa + para añadir uno.'),
            );
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final g = data[i];
              return Dismissible(
                key: ValueKey(g.id),
                background: Container(color: Colors.redAccent),
                confirmDismiss: (_) async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: const Text('Eliminar'),
                          content: Text('¿Eliminar "${g.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                  );
                  return ok ?? false;
                },
                onDismissed: (_) => svc.deleteGuided(g.id),
                child: ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(g.title),
                  subtitle: Text(
                    '${(g.durationSec / 60).round()} min  •  ${g.url.startsWith("assets/") ? "Asset" : "URL"}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          GuidedEditScreen.route,
                          arguments: g,
                        ),
                  ),
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        GuidedPlayerScreen.route,
                        arguments: g,
                      ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, GuidedEditScreen.route),
        child: const Icon(Icons.add),
      ),
    );
  }
}
