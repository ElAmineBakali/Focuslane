// lib/screens/meditation/presets/breath_presets_screen.dart
import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';
import 'breath_preset_edit_screen.dart';

class BreathPresetsScreen extends StatelessWidget {
  const BreathPresetsScreen({super.key});
  static const route = '/meditation/presets';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presets de respiración')),
      body: StreamBuilder<List<BreathPreset>>(
        stream: MeditationFirestoreService.I.watchPresets(),
        builder: (context, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin presets'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = data[i];
              return ListTile(
                leading: const Icon(Icons.blur_circular_outlined),
                title: Text(p.name),
                subtitle: Text(
                  'In ${p.inhale} • Hold ${p.hold} • Ex ${p.exhale} • Hold ${p.hold2} • ${p.cycles} ciclos',
                ),
                trailing: const Icon(Icons.edit),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      BreathPresetEditScreen.route,
                      arguments: p,
                    ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.pushNamed(context, BreathPresetEditScreen.route),
        child: const Icon(Icons.add),
      ),
    );
  }
}
