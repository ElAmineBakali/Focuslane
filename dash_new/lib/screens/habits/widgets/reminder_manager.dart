import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_model.dart';

class ReminderManager extends StatefulWidget {
  final List<HabitReminder> reminders;
  final Function(List<HabitReminder>) onRemindersChanged;

  const ReminderManager({
    super.key,
    required this.reminders,
    required this.onRemindersChanged,
  });

  @override
  State<ReminderManager> createState() => _ReminderManagerState();
}

class _ReminderManagerState extends State<ReminderManager> {
  late List<HabitReminder> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = List.from(widget.reminders);
  }

  Future<void> _addReminder() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (time != null) {
      setState(() {
        _reminders.add(
          HabitReminder(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            time: time,
            enabled: true,
          ),
        );
        widget.onRemindersChanged(_reminders);
      });
    }
  }

  void _removeReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
      widget.onRemindersChanged(_reminders);
    });
  }

  void _toggleReminder(int index) {
    setState(() {
      _reminders[index] = _reminders[index].copyWith(
        enabled: !_reminders[index].enabled,
      );
      widget.onRemindersChanged(_reminders);
    });
  }

  Future<void> _editReminder(int index) async {
    final currentReminder = _reminders[index];
    final time = await showTimePicker(
      context: context,
      initialTime: currentReminder.time,
    );

    if (time != null) {
      setState(() {
        _reminders[index] = currentReminder.copyWith(time: time);
        widget.onRemindersChanged(_reminders);
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recordatorios',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configura hasta 5 recordatorios',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child:
                  _reminders.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: cs.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sin recordatorios',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca + para agregar uno',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reminders.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          setState(() {
                            final reminder = _reminders.removeAt(oldIndex);
                            _reminders.insert(newIndex, reminder);
                            widget.onRemindersChanged(_reminders);
                          });
                        },
                        itemBuilder: (context, index) {
                          final reminder = _reminders[index];
                          return Card(
                            key: ValueKey(reminder.id),
                            elevation: 0,
                            color: cs.surfaceContainerHigh,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isMobile ? 12 : 14,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: isMobile ? 40 : 44,
                                height: isMobile ? 40 : 44,
                                decoration: BoxDecoration(
                                  color:
                                      reminder.enabled
                                          ? cs.primaryContainer
                                          : cs.surfaceContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.access_time_rounded,
                                  color:
                                      reminder.enabled
                                          ? cs.onPrimaryContainer
                                          : cs.onSurfaceVariant,
                                  size: isMobile ? 20 : 22,
                                ),
                              ),
                              title: Text(
                                _formatTime(reminder.time),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 15 : 16,
                                  color:
                                      reminder.enabled
                                          ? cs.onSurface
                                          : cs.onSurfaceVariant,
                                ),
                              ),
                              subtitle: Text(
                                reminder.enabled ? 'Activo' : 'Pausado',
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      reminder.enabled
                                          ? Icons.notifications_active_rounded
                                          : Icons.notifications_off_rounded,
                                      size: isMobile ? 20 : 22,
                                    ),
                                    onPressed: () => _toggleReminder(index),
                                    tooltip:
                                        reminder.enabled ? 'Pausar' : 'Activar',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: isMobile ? 20 : 22,
                                    ),
                                    onPressed: () => _removeReminder(index),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                              onTap: () => _editReminder(index),
                            ),
                          );
                        },
                      ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_reminders.length}/5 recordatorios',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      if (_reminders.length < 5)
                        FilledButton.tonalIcon(
                          onPressed: _addReminder,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                        ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Listo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
