// lib/screens/meditation/programs/programs_screen.dart
import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';
import 'program_detail_screen.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});
  static const route = '/meditation/programs';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programas')),
      body: StreamBuilder<List<MeditationProgram>>(
        stream: MeditationFirestoreService.I.watchPrograms(),
        builder: (context, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin programas'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = data[i];
              return ListTile(
                leading: Text(
                  p.emoji ?? '🧘',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(p.name),
                subtitle: Text(
                  '${p.level} • ${p.isActive ? "Activo" : "Inactivo"}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      ProgramDetailScreen.route,
                      arguments: p,
                    ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _askForName(context);
          if (name == null || name.trim().isEmpty) return;
          final id = await MeditationFirestoreService.I.addProgram(
            MeditationProgram(
              id: '',
              name: name.trim(),
              description: '',
              level: 'beginner',
              isActive: true,
            ),
          );
          if (context.mounted) {
            final p = MeditationProgram(
              id: id,
              name: name.trim(),
              description: '',
            );
            Navigator.pushNamed(
              context,
              ProgramDetailScreen.route,
              arguments: p,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<String?> _askForName(BuildContext context) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Nuevo programa'),
            content: TextField(
              controller: c,
              decoration: const InputDecoration(labelText: 'Nombre'),
              autofocus: true,
              onSubmitted: (_) => Navigator.pop(ctx, c.text),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, c.text),
                child: const Text('Crear'),
              ),
            ],
          ),
    );
  }
}
