import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';
import 'package:mi_dashboard_personal/core/services/notification_service.dart';

class ReminderEditScreen extends StatefulWidget {
  const ReminderEditScreen({super.key});
  static const route = '/meditation/reminder/edit';

  @override
  State<ReminderEditScreen> createState() => _ReminderEditScreenState();
}

class _ReminderEditScreenState extends State<ReminderEditScreen> {
  final _time = TextEditingController(text: '08:30');
  final _days = <int>{1, 2, 3, 4, 5};

  TimeOfDay _parseTime(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p.first) ?? 8;
    final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  int _notifId(String reminderId) => 42000 ^ (reminderId.hashCode & 0x7fffffff);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo recordatorio')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _time,
              decoration: const InputDecoration(labelText: 'Hora (HH:MM)'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  List.generate(7, (i) => i + 1).map((d) {
                    final sel = _days.contains(d);
                    return FilterChip(
                      label: Text(['L', 'M', 'X', 'J', 'V', 'S', 'D'][d - 1]),
                      selected: sel,
                      onSelected: (_) {
                        setState(() => sel ? _days.remove(d) : _days.add(d));
                      },
                    );
                  }).toList(),
            ),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              onPressed: () async {
                final reminder = MeditationReminder(
                  id: '',
                  timeOfDay: _time.text.trim(),
                  daysOfWeek: _days.toList()..sort(),
                  enabled: true,
                );
                // Guardar y obtener id
                final id = await MeditationFirestoreService.I.addReminder(
                  reminder,
                );

                // Programar notificación diaria (simple por ahora)
                await NotificationService.I.scheduleDaily(
                  id: _notifId(id),
                  title: 'Meditación',
                  body: 'Tómate 5—10 min para meditar ðŸ§˜',
                  at: _parseTime(reminder.timeOfDay),
                  useExact: true,
                );

                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

