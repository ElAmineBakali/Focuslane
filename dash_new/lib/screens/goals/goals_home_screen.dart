 import 'package:flutter/material.dart';
import '../goals/services/goals_firestore_service.dart';
import '../goals/models/goals_models.dart';
import '../../widgets/ui_scaffold.dart';
import 'goal_edit_sheet.dart';
import 'goal_detail_screen.dart';  
class GoalsHomeScreen extends StatefulWidget {
  const GoalsHomeScreen({super.key});
  static const route = '/goals';

  @override
  State<GoalsHomeScreen> createState() => _GoalsHomeScreenState();
}

class _GoalsHomeScreenState extends State<GoalsHomeScreen> {
  @override
  void initState() {
    super.initState();
         GoalsFirestoreService.I.backfillGoalsOrder();
  }

  @override
  Widget build(BuildContext context) {
    final svc = GoalsFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const GoalEditSheet(),
                ),
          ),
        ],
      ),
      body: StreamBuilder<List<Goal>>(
        stream: svc.watchGoals(),
        builder: (_, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) {
            return const Center(
              child: Text('Crea tu primera meta con el botón +'),
            );
          }
          return ReorderableListView.builder(
            padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
            itemCount: data.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              final list = List<Goal>.from(data);
              final moved = list.removeAt(oldIndex);
              list.insert(newIndex, moved);
              await svc.updateGoalsOrder(list);
            },
            buildDefaultDragHandles: false,
            itemBuilder: (_, i) {
              final x = data[i];
              final num? pct =
                  (x.progress != null &&
                          x.progressTarget != null &&
                          x.progressTarget! > 0)
                      ? (x.progress! / x.progressTarget!).clamp(0, 1.0)
                      : null;
              return Card(
                key: ValueKey(x.id),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReorderableDragStartListener(
                        index: i,
                        child: const Icon(Icons.drag_handle),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor:
                            (x.colorHex != null)
                                ? Color(int.parse(x.colorHex!))
                                : Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.flag, color: Colors.white),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GoalDetailScreen(goal: x),
                      ),
                    );
                  },
                  title: Text(x.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (x.targetDate != null)
                        Text(
                          'Límite: ${x.targetDate!.toLocal().toString().split(' ').first}',
                        ),
                      if (x.progressTarget != null)
                        Text(
                          'Progreso: ${x.progress?.toStringAsFixed(1) ?? "0"} / ${x.progressTarget} ${x.unit ?? ""}',
                        ),
                      if (pct != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0, 1).toDouble(),
                            minHeight: 6,
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => GoalEditSheet(initial: x),
                        );
                      } else if (v == 'del') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text('Eliminar meta'),
                                content: Text('¿Eliminar "${x.title}"?'),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                        );
                        if (ok == true) {
                          await GoalsFirestoreService.I.deleteGoal(x.id);
                        }
                      }
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'del', child: Text('Eliminar')),
                        ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
