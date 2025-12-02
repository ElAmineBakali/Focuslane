import 'package:flutter/material.dart';
import '../models/gym_models.dart';

class SessionSummaryScreen extends StatelessWidget {
  final SessionDoc session;
  const SessionSummaryScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de sesión')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${session.routineName} — ${session.dayName}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Fecha: ${session.date} • Duración: ${session.durationMin ?? 0} min'),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.scale),
              title: Text('Volumen total: ${session.volumeKg.toStringAsFixed(1)} kg'),
              subtitle: Text('Series: ${session.exercises.fold<int>(0, (a, e) => a + e.sets.length)}'),
            ),
          ),
          const SizedBox(height: 8),
          if (session.prList.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events),
                title: const Text('¡Nuevos PRs!'),
                subtitle: Text(session.prList.join(', ')),
              ),
            ),
          const SizedBox(height: 8),
          if ((session.notes ?? '').isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.note),
                title: const Text('Notas'),
                subtitle: Text(session.notes!),
              ),
            ),
          const SizedBox(height: 12),
          const Text('Detalle por ejercicio'),
          const SizedBox(height: 4),
          ...session.exercises.map((e) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      for (int i = 0; i < e.sets.length; i++)
                        Text('Set ${i + 1}: ${e.sets[i].weight.toStringAsFixed(1)} kg × ${e.sets[i].reps} reps'
                            '${e.sets[i].rpe != null ? ' • RPE ${e.sets[i].rpe}' : ''}'),
                      const SizedBox(height: 4),
                      Text('Volumen: ${e.volumeKg.toStringAsFixed(1)} kg'
                          '${e.bestE1rm != null ? ' • Mejor E1RM: ${e.bestE1rm!.toStringAsFixed(1)}' : ''}',
                          style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
          // ✅ CAMBIO: antes hacía popUntil(isFirst). Ahora solo pop()
          // para volver a la pantalla anterior (RoutineDetailScreen) y ver el check.
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }
}
