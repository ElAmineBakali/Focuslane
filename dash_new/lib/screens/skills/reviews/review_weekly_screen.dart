import 'package:flutter/material.dart';
import '../services/skills_firestore_service.dart';
import '../models/skills_models.dart';

class ReviewWeeklyScreen extends StatefulWidget {
  const ReviewWeeklyScreen({super.key});
  static const route = '/skills/review/weekly';

  @override
  State<ReviewWeeklyScreen> createState() => _ReviewWeeklyScreenState();
}

class _ReviewWeeklyScreenState extends State<ReviewWeeklyScreen> {
  Skill? skill;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Skill) skill = arg;
  }

  @override
  Widget build(BuildContext context) {
    final svc = SkillsFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Revisión semanal${skill != null ? ' • ${skill!.name}' : ''}',
        ),
      ),
      body:
          skill == null
              ? const Center(
                child: Text('Abre desde una habilidad para ver su revisión'),
              )
              : FutureBuilder<Map<String, dynamic>>(
                future: svc.kpisForSkill(skill!.id),
                builder: (_, s) {
                  final m = s.data ?? const {};
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _kpi(
                            'Horas',
                            (m['totalHours'] ?? 0.0).toStringAsFixed(1),
                          ),
                          _kpi('Días activos', '${m['activeDays'] ?? 0}'),
                          _kpi('Sesiones', '${m['sessions'] ?? 0}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preguntas gatillo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• ¿Qué desbloqueaste esta semana?\n'
                        '• ¿Qué costó más? ¿Por qué?\n'
                        '• ¿Qué tipo de sesión te hizo avanzar?\n'
                        '• ¿Cuál es el siguiente micro-paso claro?',
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Widget _kpi(String t, String v) => SizedBox(
    width: 220,
    child: Card(child: ListTile(title: Text(t), subtitle: Text(v))),
  );
}
