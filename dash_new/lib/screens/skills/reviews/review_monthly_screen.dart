import 'package:flutter/material.dart';
import '../services/skills_firestore_service.dart';
import '../models/skills_models.dart';

class ReviewMonthlyScreen extends StatefulWidget {
  const ReviewMonthlyScreen({super.key});
  static const route = '/skills/review/monthly';

  @override
  State<ReviewMonthlyScreen> createState() => _ReviewMonthlyScreenState();
}

class _ReviewMonthlyScreenState extends State<ReviewMonthlyScreen> {
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
          'Revisión mensual${skill != null ? ' • ${skill!.name}' : ''}',
        ),
      ),
      body:
          skill == null
              ? const Center(
                child: Text('Abre desde una habilidad para ver su revisión'),
              )
              : FutureBuilder<Map<String, double>>(
                future: svc.sessionsBySubSkill(skill!.id),
                builder: (_, s) {
                  final map = s.data ?? const {};
                  final entries =
                      map.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Text(
                        'Reparto por sub-skill (min)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...entries.map(
                        (e) => ListTile(
                          leading: const Icon(Icons.label_outline),
                          title: Text(e.key == '—' ? 'General' : e.key),
                          trailing: Text(e.value.toStringAsFixed(0)),
                        ),
                      ),
                      const Divider(height: 24),
                      const Text(
                        '• ¿Qué hitos cumpliste?\n• ¿Tu nivel estimado cambió?\n• ¿Qué aprenderás el mes siguiente?',
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
