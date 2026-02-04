import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../gym/services/gym_firestore_service.dart';
import '../../gym/models/gym_models.dart';
import '../../gym/routines/routines_list_screen.dart';
import '../../gym/routines/routine_detail_screen.dart';
import '../../gym/session/session_history_screen.dart';
import '../../gym/goals/gym_goals_screen.dart';
import '../../../ui/components/focus_card.dart';
import '../../../ui/components/focus_metric_card.dart';
import '../../../ui/components/focus_section_title.dart';
import '../../../ui/components/focus_empty_state.dart';
import '../../../ui/components/focus_list_tile_compact.dart';
import '../../../ui/tokens/focuslane_tokens.dart';

class GymDashboardScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymDashboardScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final dateLabel = DateFormat('d MMM', 'es').format(now);

    return SingleChildScrollView(
      padding: FocuslaneTokens.pagePaddingCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionTitle(
            title: 'Resumen del día',
            subtitle: 'Actualizado $dateLabel',
            action: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionHistoryScreen(svc: svc),
                  ),
                );
              },
              child: const Text('Ver historial'),
            ),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: svc.getStatsForDateRange(start, now),
            builder: (context, snap) {
              final data = snap.data;
              final totalSessions = data?['totalSessions'] as int?;
              final totalVolume = data?['totalVolume'] as double?;
              final totalSessionsText =
                  totalSessions == null ? '—' : totalSessions.toString();
              final totalVolumeText = totalVolume == null
                  ? '—'
                  : '${(totalVolume / 1000).toStringAsFixed(1)} ton';

              return StreamBuilder<List<BodyWeightEntry>>(
                stream: svc.streamBodyWeight(limit: 1),
                builder: (context, weightSnap) {
                  final weight =
                      weightSnap.data?.isNotEmpty == true
                          ? weightSnap.data!.first.weight
                          : null;

                  return FutureBuilder(
                    future: svc.root.get(),
                    builder: (context, rootSnap) {
                      final rootData = rootSnap.data?.data() as Map<String, dynamic>?;
                      final target = (rootData?['bodyWeightTarget'] as num?)?.toDouble();
                      final weightText = weight == null
                          ? '—'
                          : '${weight.toStringAsFixed(1)} kg';
                      final targetText = target == null
                          ? '—'
                          : '${target.toStringAsFixed(1)} kg';

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 1200
                              ? 4
                              : constraints.maxWidth >= 600
                                  ? 2
                                  : 1;

                          final cards = [
                            FocusMetricCard(
                              icon: Icons.fitness_center,
                              label: 'Entrenos esta semana',
                              value: totalSessionsText,
                              subtitle: 'Últimos 7 días',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SessionHistoryScreen(svc: svc),
                                  ),
                                );
                              },
                            ),
                            FocusMetricCard(
                              icon: Icons.auto_graph,
                              label: 'Volumen total',
                              value: totalVolumeText,
                              subtitle: 'Últimos 7 días',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SessionHistoryScreen(svc: svc),
                                  ),
                                );
                              },
                            ),
                            const FocusMetricCard(
                              icon: Icons.bolt,
                              label: 'Racha',
                              value: '—',
                              subtitle: 'Actual',
                            ),
                            FocusMetricCard(
                              icon: Icons.monitor_weight,
                              label: 'Peso actual / objetivo',
                              value: weightText,
                              subtitle: targetText,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GymGoalsScreen(svc: svc),
                                  ),
                                );
                              },
                            ),
                          ];

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: FocuslaneTokens.spacing12,
                            crossAxisSpacing: FocuslaneTokens.spacing12,
                            childAspectRatio: constraints.maxWidth >= 600 ? 3.2 : 2.8,
                            children: cards,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: FocuslaneTokens.spacing16),
          FocusSectionTitle(
            title: 'Rutina semanal',
            subtitle: 'Tu planificación principal',
            action: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoutinesListScreen(svc: svc),
                  ),
                );
              },
              child: const Text('Ver rutinas'),
            ),
          ),
          StreamBuilder<Routine?>(
            stream: svc.streamDefaultRoutine(),
            builder: (context, snap) {
              final routine = snap.data;
              if (routine == null) {
                return FocusCard(
                  maxHeight: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aún no tienes una rutina principal',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: FocuslaneTokens.spacing8),
                      Text(
                        'Crea una rutina para organizar tu semana.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: FocuslaneTokens.spacing12),
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoutinesListScreen(svc: svc),
                            ),
                          );
                        },
                        child: const Text('Crear rutina'),
                      ),
                    ],
                  ),
                );
              }

              return StreamBuilder<List<RoutineDay>>(
                stream: svc.streamDays(routine.id),
                builder: (context, daysSnap) {
                  final days = daysSnap.data ?? const [];
                  return FocusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: FocuslaneTokens.spacing8),
                        if (days.isEmpty)
                          Text(
                            'Añade días y ejercicios para estructurar tu semana.',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          Wrap(
                            spacing: FocuslaneTokens.spacing8,
                            runSpacing: FocuslaneTokens.spacing8,
                            children: days.take(6).map((d) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: FocuslaneTokens.spacing8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: FocuslaneTokens.accentSurface(
                                    context,
                                    opacity: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    FocuslaneTokens.radius12,
                                  ),
                                  border: Border.all(
                                    color: FocuslaneTokens.borderColor(context),
                                    width: FocuslaneTokens.borderW,
                                  ),
                                ),
                                child: Text(
                                  d.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: FocuslaneTokens.spacing12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoutineDetailScreen(
                                    svc: svc,
                                    routine: routine,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Abrir rutina'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: FocuslaneTokens.spacing16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FocusSectionTitle(
                          title: 'Últimos entrenos',
                          subtitle: 'Sesiones recientes',
                        ),
                        StreamBuilder<List<SessionDoc>>(
                          stream: svc.streamSessions(limit: 5),
                          builder: (context, snap) {
                            final sessions = snap.data ?? const [];
                            if (sessions.isEmpty) {
                              return const FocusEmptyState(
                                icon: Icons.history,
                                message: 'Sin entrenos recientes',
                              );
                            }

                            return FocusCard(
                              child: Column(
                                children: sessions.map((s) {
                                  final date = DateFormat('d MMM', 'es')
                                      .format(s.date);
                                  final subtitle =
                                      '${s.routineName} · $date';
                                  final volume = s.volumeKg > 0
                                      ? '${(s.volumeKg / 1000).toStringAsFixed(1)} ton'
                                      : '—';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: FocusListTileCompact(
                                      title: s.dayName,
                                      subtitle: subtitle,
                                      trailing: Text(
                                        volume,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: FocuslaneTokens.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FocusSectionTitle(
                          title: 'Objetivos',
                          subtitle: 'Metas y seguimiento',
                        ),
                        FocusCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Define tus objetivos de fuerza y peso.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: FocuslaneTokens.spacing12),
                              FilledButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GymGoalsScreen(svc: svc),
                                    ),
                                  );
                                },
                                child: const Text('Abrir objetivos'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
