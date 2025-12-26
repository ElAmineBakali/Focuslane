import 'package:flutter/material.dart';
import '../models/study_models.dart';

class SessionSummaryScreen extends StatelessWidget {
  final StudySession session;
  const SessionSummaryScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de estudio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: Text('Curso: ${session.courseId}'),
            subtitle: Text('Método: ${session.method.name}'),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.timer),
              title: Text('Minutos totales: ${session.minutes}'),
              subtitle: Text(
                [
                  if (session.cycles != null) 'Ciclos: ${session.cycles}',
                  if (session.laps != null) 'Laps: ${session.laps}',
                ].join(' • '),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Config usada: ${session.configSnapshot}'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Listo')),
        ],
      ),
    );
  }
}
