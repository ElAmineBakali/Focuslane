import 'package:flutter/material.dart';
import '../services/skills_firestore_service.dart';
import '../models/skills_models.dart';
import 'package:mi_dashboard_personal/utils/app_links.dart';
import '../skills/skill_edit_screen.dart';
import '../skills/skill_detail_screen.dart';

class SkillsHomeScreen extends StatelessWidget {
  const SkillsHomeScreen({super.key});
  static const route = '/skills';

  @override
  Widget build(BuildContext context) {
    final svc = SkillsFirestoreService.I;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habilidades'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.link_rounded),
            onSelected: (v) {
              if (v == 'GuitarTuna') AppLinks.openGuitarTuna();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'GuitarTuna', child: Text('GuitarTuna')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.pushNamed(context, '/skills/analytics'),
          ),
        ],
      ),
      body: StreamBuilder<List<Skill>>(
        stream: svc.watchSkills(),
        builder: (_, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) {
            return const Center(child: Text('Crea tu primera habilidad con el botón +'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (_, i) {
              final x = data[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(skillLevelLabel(x.currentLevel)[0]),
                  ),
                  title: Text(x.name),
                  subtitle: Text(
                    '${skillLevelLabel(x.currentLevel)} • ${x.totalHours.toStringAsFixed(1)}h • racha ${x.streakDays}d',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, SkillDetailScreen.route, arguments: x),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva habilidad'),
        onPressed: () => Navigator.pushNamed(context, SkillEditScreen.route),
      ),
    );
  }
}
