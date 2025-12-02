import 'package:flutter/material.dart';
import '../services/skills_firestore_service.dart';
import '../models/skills_models.dart';

class SkillsAnalyticsScreen extends StatelessWidget {
  const SkillsAnalyticsScreen({super.key});
  static const route = '/skills/analytics';

  @override
  Widget build(BuildContext context) {
    final svc = SkillsFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: const Text('Analíticas de habilidades')),
      body: StreamBuilder<List<Skill>>(
        stream: svc.watchSkills(),
        builder: (_, s) {
          final skills = s.data ?? [];
          if (skills.isEmpty) return const Center(child: Text('Sin habilidades aún'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: skills.length,
            itemBuilder: (_, i) {
              final k = skills[i];
              return FutureBuilder<Map<String, dynamic>>(
                future: svc.kpisForSkill(k.id),
                builder: (_, fs) {
                  final m = fs.data ?? const {};
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.insights),
                      title: Text(k.name),
                      subtitle: Text('Horas ${m['totalHours']?.toStringAsFixed(1) ?? '0.0'} • '
                          'Días activos ${m['activeDays'] ?? 0} • Sesiones ${m['sessions'] ?? 0}'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
