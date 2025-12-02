import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_helpers.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    Widget section(String title, List<Widget> children) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 10),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
        ],
      );
    }

    Widget infoRow(IconData icon, String label) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color.onSurface, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de Tarea')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: color.surfaceContainerHigh,
          elevation: theme.brightness == Brightness.dark ? 2 : 4,
          shadowColor: color.shadow.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                section('Información general', [
                  infoRow(Icons.title, task.title),
                  if (task.description.isNotEmpty)
                    infoRow(Icons.description, task.description),
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        color: task.priority.getColor(),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Prioridad: ${task.priority.label[0].toUpperCase()}${task.priority.label.substring(1)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: color.onSurface,
                        ),
                      ),
                    ],
                  ),
                  infoRow(
                    Icons.category,
                    'Categoría: ${task.category?.isNotEmpty == true ? task.category : 'Sin categoría'}',
                  ),
                  if (task.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.label, color: color.onSurface, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children:
                                  task.tags.map((tag) {
                                    return Chip(
                                      label: Text(tag),
                                      backgroundColor: color.primaryContainer,
                                      labelStyle: TextStyle(
                                        color: color.onPrimaryContainer,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (task.linkedNoteId != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.sticky_note_2_outlined),
                        title: const Text('Ver nota vinculada'),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/notes/editor',
                            arguments: task.linkedNoteId,
                          );
                        },
                      ),
                    ),
                ]),
                section('Fecha y Hora', [
                  infoRow(
                    Icons.calendar_today,
                    task.dueDate != null
                        ? 'Vence: ${TaskFormatter.formatDueDate(task.dueDate)}'
                        : 'Sin fecha límite',
                  ),
                  if (task.remindAt != null)
                    infoRow(
                      Icons.notifications_active,
                      'Recordatorio: ${DateFormat('dd/MM/yy HH:mm').format(task.remindAt!)}',
                    ),
                ]),
                section('Estado', [
                  Row(
                    children: [
                      Icon(
                        task.completed ? Icons.check_circle : Icons.cancel,
                        color:
                            task.completed
                                ? color.primary
                                : color.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        task.completed ? 'Completada' : 'Pendiente',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: color.onSurface,
                        ),
                      ),
                    ],
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
