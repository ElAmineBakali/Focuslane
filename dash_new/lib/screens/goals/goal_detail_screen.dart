import 'package:flutter/material.dart';
import '../goals/services/goals_firestore_service.dart';
import '../goals/models/goals_models.dart';
import 'goal_edit_sheet.dart';
import 'subgoal_edit_sheet.dart';

class GoalDetailScreen extends StatelessWidget {
  final Goal goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final svc = GoalsFirestoreService.I;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        actions: [
          IconButton(
            tooltip: 'Editar meta',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => GoalEditSheet(initial: goal),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuevo sub-objetivo',
        onPressed:
            () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => SubGoalEditSheet(goalId: goal.id),
            ),
        child: const Icon(Icons.add_task),
      ),
      body: StreamBuilder<List<SubGoal>>(
        stream: svc.watchSubGoals(goal.id),
        builder: (context, s) {
          final subs = (s.data ?? []);
          final sections = <String, List<SubGoal>>{};
          for (final sg in subs) {
            final key =
                (sg.section == null || sg.section!.trim().isEmpty)
                    ? 'General'
                    : sg.section!.trim();
            sections.putIfAbsent(key, () => []).add(sg);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _GoalHeaderCard(goal: goal),
              const SizedBox(height: 12),
              if (sections.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Sin sub-objetivos'),
                    subtitle: Text('Añade el primero con el botón +'),
                  ),
                ),
              ...sections.entries.map(
                (e) =>
                    _SectionList(title: e.key, items: e.value, goalId: goal.id),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _GoalHeaderCard extends StatelessWidget {
  final Goal goal;
  const _GoalHeaderCard({required this.goal});

  double? _pct() {
    if (goal.progress != null &&
        goal.progressTarget != null &&
        goal.progressTarget! > 0) {
      return (goal.progress! / goal.progressTarget!).clamp(0, 1.0);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pct = _pct();
    final color =
        (goal.colorHex != null)
            ? Color(int.parse(goal.colorHex!))
            : Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: const Icon(Icons.flag, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if ((goal.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(goal.description!),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text(goal.status.name),
                ),
                if (goal.targetDate != null)
                  Chip(
                    avatar: const Icon(Icons.event, size: 18),
                    label: Text(
                      'Límite: ${goal.targetDate!.toLocal().toString().split(' ').first}',
                    ),
                  ),
                if (goal.progressTarget != null)
                  Chip(
                    avatar: const Icon(Icons.speed_outlined, size: 18),
                    label: Text(
                      'Progreso ${goal.progress?.toStringAsFixed(1) ?? 0} / ${goal.progressTarget} ${goal.unit ?? ""}',
                    ),
                  ),
              ],
            ),
            if (pct != null) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(value: pct, minHeight: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  final String title;
  final List<SubGoal> items;
  final String goalId;

  const _SectionList({
    required this.title,
    required this.items,
    required this.goalId,
  });

  @override
  Widget build(BuildContext context) {
    final svc = GoalsFirestoreService.I;
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        children: [
          for (final sg in items)
            ListTile(
              leading: Checkbox(
                value: sg.isDone,
                onChanged:
                    (_) => svc.setSubGoalStatus(
                      goalId,
                      sg.id,
                      sg.isDone ? GoalStatus.inProgress : GoalStatus.completed,
                    ),
              ),
              title: Text(
                sg.title,
                style: TextStyle(
                  decoration: sg.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((sg.description ?? '').isNotEmpty) Text(sg.description!),
                  if (sg.dueDate != null)
                    Text(
                      'Fecha: ${sg.dueDate!.toLocal().toString().split(" ").first}',
                    ),
                  if (sg.progressTarget != null)
                    Text(
                      'Progreso: ${(sg.progress ?? 0).toStringAsFixed(1)} / ${sg.progressTarget} ${sg.unit ?? ""}',
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder:
                          (_) => SubGoalEditSheet(goalId: goalId, initial: sg),
                    );
                  } else if (v == 'del') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('Eliminar sub-objetivo'),
                            content: Text('¿Eliminar "${sg.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                    );
                    if (ok == true) await svc.deleteSubGoal(goalId, sg.id);
                  } else if (v == 'plus') {
                    await svc.bumpSubGoalProgress(goalId, sg.id, 1);
                  } else if (v == 'minus') {
                    await svc.bumpSubGoalProgress(goalId, sg.id, -1);
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'plus', child: Text('Progreso +1')),
                      PopupMenuItem(value: 'minus', child: Text('Progreso -1')),
                      PopupMenuItem(value: 'del', child: Text('Eliminar')),
                    ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
