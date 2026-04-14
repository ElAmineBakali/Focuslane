import 'package:flutter/material.dart';
import 'models/calendar_models.dart';
import 'package:focuslane/screens/calendar/screens/calendar/services/calendar_service.dart';
import 'timetable_editor_screen.dart';

class TimetablesListScreen extends StatelessWidget {
  const TimetablesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = CalendarService.I;
    return Scaffold(
      appBar: AppBar(title: const Text('Horarios (semanales)')),
      body: StreamBuilder<List<Timetable>>(
        stream: svc.watchTimetables(),
        initialData: const <Timetable>[],
        builder: (context, s) {
          final data = s.data ?? const <Timetable>[];
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sin horarios'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Crear horario'),
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TimetableEditorScreen(),
                          ),
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final t = data[i];
              return ListTile(
                leading: const Icon(Icons.view_week),
                title: Text(t.name),
                subtitle: Text(
                  '${t.days.join(', ')} • ${t.startHour}—${t.endHour} • ${t.slotMinutes}\'',
                ),
                trailing: Icon(t.isDefault ? Icons.star : Icons.chevron_right),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TimetableEditorScreen(timetable: t),
                      ),
                    ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TimetableEditorScreen()),
            ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}




