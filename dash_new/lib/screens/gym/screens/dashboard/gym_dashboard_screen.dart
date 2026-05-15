import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/gym/screens/routines/routines_list_screen.dart';
import 'package:focuslane/screens/gym/screens/routines/routine_detail_screen.dart';
import 'package:focuslane/screens/gym/screens/session/session_history_screen.dart';
import 'package:focuslane/design/ui/components/focus_card.dart';
import 'package:focuslane/design/ui/components/focus_metric_card.dart';
import 'package:focuslane/design/ui/components/focus_section_title.dart';
import 'package:focuslane/design/ui/components/focus_empty_state.dart';
import 'package:focuslane/design/ui/components/focus_list_tile_compact.dart';
import 'package:focuslane/design/ui/tokens/focuslane_tokens.dart';
import 'package:focuslane/design/ui/components/focus_module_header.dart';
import 'package:focuslane/design/ui/components/responsive_kpi_grid.dart';

class GymDashboardScreen extends StatelessWidget {
  final GymFirestoreService svc;
  final bool embedded;

  const GymDashboardScreen({
    super.key,
    required this.svc,
    this.embedded = false,
  });

  Widget _buildAlerts(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();
    final configAlerts$ = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root')
        .collection('config')
        .doc('alerts')
        .snapshots();
    final subscriptionAlert$ = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root')
        .collection('alerts')
        .doc('subscription')
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: configAlerts$,
      builder: (context, configSnap) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: subscriptionAlert$,
          builder: (context, subSnap) {
            debugPrint('[GymDashboard][alerts] configState=${configSnap.connectionState} subState=${subSnap.connectionState}');
            final configAlert = configSnap.data?.data() ?? const {};
            final subscriptionAlert = subSnap.data?.data() ?? const {};
            debugPrint('[GymDashboard][alerts] config=$configAlert');
            debugPrint('[GymDashboard][alerts] subscription=$subscriptionAlert');

            final showDeficit = configAlert['extremeDeficitWorkout'] == true;
            final subSoon = subscriptionAlert['dueSoon'] == true ||
                configAlert['subscriptionDueSoon'] == true;
            debugPrint('[GymDashboard][alerts] showDeficit=$showDeficit subSoon=$subSoon');
            if (!showDeficit && !subSoon) return const SizedBox.shrink();

            final cards = <Widget>[];
            if (showDeficit) {
              final deficit = (configAlert['deficitKcal'] as num?)?.toDouble() ?? 0;
              cards.add(
                _GymAlertCard(
                  icon: Icons.local_fire_department,
                  title: 'Déficit extremo con entreno fuerte',
                  message: 'Balance energético actual ${deficit.toStringAsFixed(0)} kcal.',
                ),
              );
            }

            if (subSoon) {
              final dueRaw = subscriptionAlert['nextPaymentDate'] ?? configAlert['subscriptionDueAt'];
              DateTime? dueDate;
              if (dueRaw is Timestamp) {
                dueDate = dueRaw.toDate();
              } else if (dueRaw is DateTime) {
                dueDate = dueRaw;
              }
              final amount = (subscriptionAlert['amount'] as num?)?.toDouble();

              String dueLabel = 'pronto';
              if (dueDate != null) {
                final now = DateTime.now();
                final dayNow = DateTime(now.year, now.month, now.day);
                final dayDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
                final dueDays = dayDue.difference(dayNow).inDays;
                dueLabel = dueDays <= 0
                    ? 'hoy'
                    : 'en $dueDays días (${DateFormat('d MMM').format(dueDate)})';
              }

              final amountLabel = amount == null ? '' : ' de ${amount.toStringAsFixed(2)}';
              cards.add(
                _GymAlertCard(
                  icon: Icons.event_available,
                  title: 'Pago próximo',
                  message: 'Suscripción$amountLabel $dueLabel.',
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cards
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: FocuslaneTokens.spacing12),
                        child: c,
                      ))
                  .toList(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final dateLabel = DateFormat('d MMM', 'es').format(now);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar:
          embedded
              ? null
              : FocusModuleHeader(
                title: 'Gimnasio',
                subtitle: 'Rutinas, progreso y objetivos',
                leadingMode: FocusModuleLeadingMode.exitModule,
                actions: const [],
              ),
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          _buildAlerts(context),
          const SizedBox(height: FocuslaneTokens.spacing12),
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
          const SizedBox(height: FocuslaneTokens.spacing8),
          FutureBuilder<Map<String, dynamic>>(
            future: svc.getStatsForDateRange(start, now),
            builder: (context, snap) {
              final data = snap.data;
              debugPrint('[GymDashboard][weekStats] state=${snap.connectionState} data=$data');
              final totalSessions = data?['totalSessions'] as int?;
              final totalVolume = data?['totalVolume'] as double?;
              debugPrint('[GymDashboard][weekStats] totalSessions=$totalSessions totalVolume=$totalVolume');
              final totalSessionsText =
                  totalSessions == null ? '–' : totalSessions.toString();
              final totalVolumeText = totalVolume == null
                  ? '–'
                  : '${(totalVolume / 1000).toStringAsFixed(1)} ton';

              return StreamBuilder<List<BodyWeightEntry>>(
                stream: svc.streamBodyWeight(limit: 1),
                builder: (context, weightSnap) {
                  final weight =
                      weightSnap.data?.isNotEmpty == true
                          ? weightSnap.data!.first.weight
                          : null;
                  debugPrint('[GymDashboard][bodyWeight] state=${weightSnap.connectionState} weight=$weight');

                  return FutureBuilder(
                    future: svc.root.get(),
                    builder: (context, rootSnap) {
                      final rootData = rootSnap.data?.data();
                      final target = (rootData?['bodyWeightTarget'] as num?)?.toDouble();
                      final weightText = weight == null
                          ? '–'
                          : '${weight.toStringAsFixed(1)} kg';
                      final targetText = target == null
                          ? '–'
                          : '${target.toStringAsFixed(1)} kg';

                      return LayoutBuilder(
                        builder: (context, constraints) {
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
                              value: '–',
                              subtitle: 'Actual',
                            ),
                            FocusMetricCard(
                              icon: Icons.monitor_weight,
                              label: 'Peso actual / objetivo',
                              value: weightText,
                              subtitle: targetText,
                            ),
                          ];

                          return ResponsiveKpiGrid(
                            children: cards,
                            childAspectRatio: 1.9,
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
                            debugPrint('[GymDashboard][recentSessions] state=${snap.connectionState} count=${sessions.length}');
                            for (final s in sessions) {
                              debugPrint('[GymDashboard][recentSessions]   session dayName=${s.dayName} routineName=${s.routineName} volumeKg=${s.volumeKg} date=${s.date}');
                            }
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
                                      : '–';

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
                          title: 'Progreso',
                          subtitle: 'Seguimiento de entrenamientos',
                        ),
                        FocusCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Revisa tu historial para seguir volumen y constancia.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: FocuslaneTokens.spacing12),
                              FilledButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SessionHistoryScreen(svc: svc),
                                    ),
                                  );
                                },
                                child: const Text('Abrir historial'),
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
      ),
    );
  }
}

class _GymAlertCard extends StatelessWidget {
  const _GymAlertCard({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer.withOpacity(.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



