// lib/screens/meditation/sessions/sessions_log_screen.dart
import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';
import 'session_edit_screen.dart';

class SessionsLogScreen extends StatelessWidget {
  const SessionsLogScreen({super.key});
  static const route = '/meditation/sessions';

  @override
  Widget build(BuildContext context) {
    final svc = MeditationFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de sesiones')),
      body: StreamBuilder<List<MeditationSession>>(
        stream: svc.watchSessions(),
        builder: (context, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin sesiones'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final x = data[i];
              final icon =
                  x.type == SessionType.timer
                      ? Icons.timer_outlined
                      : (x.type == SessionType.breath
                          ? Icons.blur_circular_outlined
                          : Icons.headphones_outlined);
              return ListTile(
                leading: Icon(icon),
                title: Text(x.title.isEmpty ? x.type.name : x.title),
                subtitle: Text(
                  "${(x.durationSec / 60).toStringAsFixed(0)} min • ${x.date.toLocal().toString().split('.').first}",
                ),
                trailing: const Icon(Icons.edit),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      SessionEditScreen.route,
                      arguments: x,
                    ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, SessionEditScreen.route),
        child: const Icon(Icons.add),
      ),
    );
  }
}
