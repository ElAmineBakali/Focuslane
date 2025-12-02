// lib/screens/meditation/programs/program_day_screen.dart
import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';
import '../guided/guided_player_screen.dart';

class ProgramDayScreen extends StatelessWidget {
  const ProgramDayScreen({super.key});
  static const route = '/meditation/program/day';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final program = args['program'] as MeditationProgram;
    final day = args['day'] as ProgramDay;

    return Scaffold(
      appBar: AppBar(title: Text('${program.name} — Día ${day.dayNumber}')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(day.goal),
            const SizedBox(height: 12),
            Text('Recomendado: ${day.recommendedDurationSec ~/ 60} min'),
            const SizedBox(height: 16),
            if (day.guidedAudioId != null)
              StreamBuilder<List<GuidedAudio>>(
                stream: MeditationFirestoreService.I.watchGuided(),
                builder: (context, s) {
                  final g =
                      (s.data ?? [])
                          .where((x) => x.id == day.guidedAudioId)
                          .cast<GuidedAudio?>()
                          .firstOrNull;
                  if (g == null) return const SizedBox.shrink();
                  return FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Escuchar guía: ${g.title}'),
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          GuidedPlayerScreen.route,
                          arguments: g,
                        ),
                  );
                },
              ),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Marcar completado (crea sesión)'),
              onPressed: () async {
                await MeditationFirestoreService.I.addSession(
                  MeditationSession(
                    id: '',
                    title: '${program.name} — Día ${day.dayNumber}',
                    type: SessionType.guided,
                    durationSec: day.recommendedDurationSec,
                    date: DateTime.now(),
                    notes: day.title,
                  ),
                );
                await MeditationFirestoreService.I.updateProgramDay(
                  program.id,
                  ProgramDay(
                    id: day.id,
                    dayNumber: day.dayNumber,
                    title: day.title,
                    goal: day.goal,
                    recommendedDurationSec: day.recommendedDurationSec,
                    status: 'done',
                    guidedAudioId: day.guidedAudioId,
                  ),
                );
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
