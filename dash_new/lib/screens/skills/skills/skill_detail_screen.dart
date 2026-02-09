import 'package:flutter/material.dart';

import '../services/skills_firestore_service.dart';
import '../models/skills_models.dart';

import 'session_timer_screen.dart';
import '../projects/project_board_screen.dart';
import 'skill_edit_screen.dart';

class SkillDetailScreen extends StatefulWidget {
  const SkillDetailScreen({super.key});
  static const route = '/skills/detail';

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen>
    with SingleTickerProviderStateMixin {
  Skill? skill;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Skill) skill = arg;
  }

  @override
  Widget build(BuildContext context) {
    final svc = SkillsFirestoreService.I;
    if (skill == null) {
      return const Scaffold(body: Center(child: Text('Sin habilidad')));
    }
    final s = skill!;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Roadmap'),
            Tab(text: 'Sesiones'),
            Tab(text: 'Proyectos'),
            Tab(text: 'Recursos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  SkillEditScreen.route,
                  arguments: s,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  SessionTimerScreen.route,
                  arguments: s,
                ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ROADMAP / SKILL TREE
          StreamBuilder<List<SubSkill>>(
            stream: svc.watchSubSkills(s.id),
            builder: (_, snap) {
              final nodes = snap.data ?? [];
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Árbol de sub-skills',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ...nodes.map(
                      (n) => CheckboxListTile(
                        value: n.unlocked,
                        onChanged:
                            (v) => svc.updateSubSkill(
                              s.id,
                              SubSkill(
                                id: n.id,
                                name: n.name,
                                parentId: n.parentId,
                                unlocked: v ?? false,
                                order: n.order,
                              ),
                            ),
                        title: Text(n.name),
                        subtitle:
                            n.parentId != null
                                ? Text('Depende de: ${n.parentId}')
                                : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir sub-skill'),
                      onPressed: () async {
                        final name = await _promptStr('Nombre del sub-skill');
                        if (name == null || name.trim().isEmpty) return;
                        final parent = await _promptStr(
                          'ID del padre (opcional)',
                        );
                        await svc.addSubSkill(
                          s.id,
                          SubSkill(
                            id: '',
                            name: name.trim(),
                            parentId:
                                (parent?.trim().isEmpty ?? true)
                                    ? null
                                    : parent!.trim(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // SESIONES / BITÁCORA
          StreamBuilder<List<PracticeSession>>(
            stream: svc.watchSessions(s.id),
            builder: (_, snap) {
              final data = snap.data ?? [];
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (data.isEmpty) {
                return const Center(child: Text('Aún no hay sesiones'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: data.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final x = data[i];
                  return ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: Text(
                      '${x.minutes} min • ${x.objective.isNotEmpty ? x.objective : 'Sesión'}',
                    ),
                    subtitle: Text(
                      '${x.start.toLocal().toString().split(".").first} • Dificultad ${x.difficulty}/5 • Energía ${x.energy}/5',
                    ),
                    trailing:
                        x.nextMicroTask != null
                            ? const Icon(Icons.arrow_forward)
                            : null,
                  );
                },
              );
            },
          ),

          // PROYECTOS (resumen)
          _ProjectsPreview(skill: s),

          // RECURSOS
          _ResourcesView(skill: s),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: const Text('Board de proyectos'),
                onPressed:
                    () => Navigator.pushNamed(
                      context,
                      ProjectBoardScreen.route,
                      arguments: s,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar sesión'),
                onPressed:
                    () => Navigator.pushNamed(
                      context,
                      SessionTimerScreen.route,
                      arguments: s,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptStr(String title) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: TextField(controller: c, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, c.text),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }
}

class _ProjectsPreview extends StatelessWidget {
  const _ProjectsPreview({required this.skill});
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final svc = SkillsFirestoreService.I;
    return StreamBuilder<List<Project>>(
      stream: svc.watchProjects(skill.id),
      builder: (_, snap) {
        final data = snap.data ?? [];
        final ideas = data.where((e) => e.state == ProjectState.idea).toList();
        final doing = data.where((e) => e.state == ProjectState.doing).toList();
        final blocked =
            data.where((e) => e.state == ProjectState.blocked).toList();
        final done = data.where((e) => e.state == ProjectState.done).toList();

        Widget col(String title, List<Project> items) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  ...items
                      .take(4)
                      .map(
                        (p) => ListTile(
                          dense: true,
                          title: Text(p.title),
                          subtitle:
                              p.dueDate != null
                                  ? Text(
                                    'Fecha: ${p.dueDate!.toLocal().toString().split(" ").first}',
                                  )
                                  : null,
                        ),
                      ),
                  if (items.length > 4)
                    Text(
                      '+ ${items.length - 4} más',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              col('Ideas', ideas),
              const SizedBox(width: 8),
              col('En curso', doing),
              const SizedBox(width: 8),
              col('Bloqueado', blocked),
              const SizedBox(width: 8),
              col('Hecho', done),
            ],
          ),
        );
      },
    );
  }
}

class _ResourcesView extends StatelessWidget {
  const _ResourcesView({required this.skill});
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final svc = SkillsFirestoreService.I;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final titleCtl = TextEditingController();
    final urlCtl = TextEditingController();
    final noteCtl = TextEditingController();

    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: svc.watchResources(skill.id),
            builder: (_, snap) {
              final items = (snap.data ?? []);
              if (items.isEmpty) {
                return const Center(child: Text('Sin recursos aún'));
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = items[i];
                  return ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(r.title),
                    subtitle: Text(
                      r.url + (r.note != null ? ' • ${r.note}' : ''),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => svc.deleteResource(skill.id, r.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            children: [
              // Fila 1: título
              TextField(controller: titleCtl, decoration: deco('Título')),
              const SizedBox(height: 8),
              // Fila 2: url
              TextField(controller: urlCtl, decoration: deco('URL')),
              const SizedBox(height: 8),
              // Fila 3: nota + botón añadir
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: noteCtl,
                      decoration: deco('Nota'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleCtl.text.trim().isEmpty ||
                          urlCtl.text.trim().isEmpty) {
                        return;
                      }
                      await svc.addResource(
                        skill.id,
                        ResourceLink(
                          id: '',
                          title: titleCtl.text.trim(),
                          url: urlCtl.text.trim(),
                          note:
                              noteCtl.text.trim().isEmpty
                                  ? null
                                  : noteCtl.text.trim(),
                        ),
                      );
                      titleCtl.clear();
                      urlCtl.clear();
                      noteCtl.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
