// lib/screens/meditation/programs/program_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';
import 'program_day_screen.dart';
import 'program_day_edit_screen.dart';

class ProgramDetailScreen extends StatefulWidget {
  const ProgramDetailScreen({super.key});
  static const route = '/meditation/program/detail';

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  MeditationProgram? program;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is MeditationProgram) program = arg;
  }

  @override
  Widget build(BuildContext context) {
    if (program == null) {
      return const Scaffold(body: Center(child: Text('Sin programa')));
    }
    return Scaffold(
      appBar: AppBar(title: Text(program!.name)),
      body: Column(
        children: [
          ListTile(
            title: Text(program!.description),
            subtitle: Text(
              'Nivel: ${program!.level} • ${program!.isActive ? "Activo" : "Inactivo"}',
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<ProgramDay>>(
              stream: MeditationFirestoreService.I.watchProgramDays(
                program!.id,
              ),
              builder: (context, s) {
                final days = s.data ?? [];
                if (s.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (days.isEmpty) {
                  return const Center(child: Text('Añade días al programa'));
                }
                return ListView.separated(
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = days[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${d.dayNumber}')),
                      title: Text(d.title),
                      subtitle: Text(
                        '${d.recommendedDurationSec ~/ 60} min • ${d.status}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            ProgramDayScreen.route,
                            arguments: {'program': program!, 'day': d},
                          ),
                      onLongPress:
                          () => Navigator.pushNamed(
                            context,
                            ProgramDayEditScreen.route,
                            arguments: {'program': program!, 'day': d},
                          ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.pushNamed(
              context,
              ProgramDayEditScreen.route,
              arguments: {'program': program!},
            ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
