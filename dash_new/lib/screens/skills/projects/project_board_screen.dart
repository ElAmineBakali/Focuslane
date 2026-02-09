import 'package:flutter/material.dart';

import '../services/skills_firestore_service.dart';
import '../models/skills_models.dart';

class ProjectBoardScreen extends StatefulWidget {
  const ProjectBoardScreen({super.key});
  static const route = '/skills/projects';

  @override
  State<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends State<ProjectBoardScreen> {
  Skill? skill;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Skill) skill = arg;
  }

  @override
  Widget build(BuildContext context) {
    if (skill == null) {
      return const Scaffold(body: Center(child: Text('Sin habilidad')));
    }
    final svc = SkillsFirestoreService.I;
    final s = skill!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Proyectos • ${s.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(context, svc, s),
          ),
        ],
      ),
      body: StreamBuilder<List<Project>>(
        stream: svc.watchProjects(s.id),
        builder: (_, snap) {
          final data = snap.data ?? [];
          final ideas =
              data.where((e) => e.state == ProjectState.idea).toList();
          final doing =
              data.where((e) => e.state == ProjectState.doing).toList();
          final blocked =
              data.where((e) => e.state == ProjectState.blocked).toList();
          final done = data.where((e) => e.state == ProjectState.done).toList();

          Widget col(
            String title,
            ProjectState state,
            List<Project> items,
          ) => Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final p = items[i];
                          return Card(
                            child: ListTile(
                              title: Text(p.title),
                              subtitle: Text(
                                (p.dueDate != null
                                        ? 'Fecha: ${p.dueDate!.toLocal().toString().split(" ").first} • '
                                        : '') +
                                    (p.description.isNotEmpty
                                        ? p.description
                                        : ''),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v.startsWith('move:')) {
                                    final st = ProjectState.values.firstWhere(
                                      (e) => e.name == v.substring(5),
                                    );
                                    await svc.updateProject(
                                      Project(
                                        id: p.id,
                                        skillId: p.skillId,
                                        title: p.title,
                                        description: p.description,
                                        state: st,
                                        dueDate: p.dueDate,
                                        checklist: p.checklist,
                                        evidenceUrls: p.evidenceUrls,
                                      ),
                                    );
                                  } else if (v == 'edit') {
                                    _openEditor(context, svc, s, editing: p);
                                  } else if (v == 'delete') {
                                    await svc.deleteProject(s.id, p.id);
                                  }
                                },
                                itemBuilder:
                                    (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar'),
                                      ),
                                      const PopupMenuDivider(),
                                      ...ProjectState.values.map(
                                        (st) => PopupMenuItem(
                                          value: 'move:${st.name}',
                                          child: Text(
                                            'Mover a ${_titleFor(st)}',
                                          ),
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Eliminar'),
                                      ),
                                    ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                col('Ideas', ProjectState.idea, ideas),
                const SizedBox(width: 8),
                col('En curso', ProjectState.doing, doing),
                const SizedBox(width: 8),
                col('Bloqueado', ProjectState.blocked, blocked),
                const SizedBox(width: 8),
                col('Hecho', ProjectState.done, done),
              ],
            ),
          );
        },
      ),
    );
  }

  String _titleFor(ProjectState s) {
    switch (s) {
      case ProjectState.idea:
        return 'Ideas';
      case ProjectState.doing:
        return 'En curso';
      case ProjectState.blocked:
        return 'Bloqueado';
      case ProjectState.done:
        return 'Hecho';
    }
  }

  void _openEditor(
    BuildContext context,
    SkillsFirestoreService svc,
    Skill s, {
    Project? editing,
  }) {
    final title = TextEditingController(text: editing?.title ?? '');
    final desc = TextEditingController(text: editing?.description ?? '');
    final due = ValueNotifier<DateTime?>(editing?.dueDate);
    final state = ValueNotifier<ProjectState>(
      editing?.state ?? ProjectState.idea,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  editing == null ? 'Nuevo proyecto' : 'Editar proyecto',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<ProjectState>(
                        value: state.value,
                        items:
                            ProjectState.values
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(_titleFor(e)),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => state.value = v ?? state.value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueListenableBuilder<DateTime?>(
                        valueListenable: due,
                        builder:
                            (_, d, __) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.event),
                              title: Text(
                                'Fecha: ${d != null ? d.toLocal().toString().split(" ").first : "—"}',
                              ),
                              onTap: () async {
                                final pick = await showDatePicker(
                                  context: context,
                                  initialDate: d ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (pick != null) due.value = pick;
                              },
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () async {
                    final obj = Project(
                      id: editing?.id ?? '',
                      skillId: s.id,
                      title: title.text.trim(),
                      description: desc.text.trim(),
                      state: state.value,
                      dueDate: due.value,
                      checklist: editing?.checklist ?? const [],
                      evidenceUrls: editing?.evidenceUrls ?? const [],
                    );
                    if (editing == null) {
                      await svc.addProject(obj);
                    } else {
                      await svc.updateProject(obj);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }
}
