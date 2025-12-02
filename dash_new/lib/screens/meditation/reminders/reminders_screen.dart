import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';
import 'reminder_edit_screen.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});
  static const route = '/meditation/reminders';

  TimeOfDay _parseTime(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p.first) ?? 8;
    final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }

  int _notifId(String reminderId) {
    // id estable y aislado para meditación
    return 42000 ^ (reminderId.hashCode & 0x7fffffff);
  }

  Future<void> _scheduleOrCancel(MeditationReminder r, bool enable) async {
    final id = _notifId(r.id);
    if (enable) {
      await NotificationService.I.scheduleDaily(
        id: id,
        title: 'Meditación',
        body: 'Tómate 5–10 min para meditar 🧘',
        at: _parseTime(r.timeOfDay),
        useExact: true,
      );
    } else {
      await NotificationService.I.cancel(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios')),
      body: StreamBuilder<List<MeditationReminder>>(
        stream: MeditationFirestoreService.I.watchReminders(),
        builder: (context, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin recordatorios'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = data[i];
              return SwitchListTile(
                value: r.enabled,
                onChanged: (enabled) async {
                  final newR = MeditationReminder(
                    id: r.id,
                    timeOfDay: r.timeOfDay,
                    daysOfWeek: r.daysOfWeek,
                    enabled: enabled,
                  );
                  await MeditationFirestoreService.I.updateReminder(newR);
                  // Programa/cancela al vuelo (diario; los días de la semana
                  // se implementarán en el siguiente paso con acciones).
                  await _scheduleOrCancel(newR, enabled);
                },
                title: Text(r.timeOfDay),
                subtitle: Text('Días: ${r.daysOfWeek.join(", ")}'),
                secondary: const Icon(Icons.notifications_active_outlined),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, ReminderEditScreen.route),
        child: const Icon(Icons.add),
      ),
    );
  }
}
