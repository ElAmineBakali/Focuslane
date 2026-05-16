import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/gym/screens/analytics/gym_analytics_screen.dart';
import 'package:focuslane/screens/gym/screens/routines/routine_detail_screen.dart';
import 'package:focuslane/screens/gym/screens/routines/routines_list_screen.dart';
import 'package:focuslane/screens/gym/screens/session/live_session_screen.dart';
import 'package:focuslane/screens/gym/screens/session/session_history_screen.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';

class GymDashboardScreen extends StatelessWidget {
  const GymDashboardScreen({
    super.key,
    required this.svc,
    this.embedded = false,
    this.onOpenSection,
  });

  final GymFirestoreService svc;
  final bool embedded;
  final ValueChanged<int>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final content = FutureBuilder<Map<String, dynamic>>(
      future: svc.getStatsForDateRange(start, now),
      builder: (context, statsSnap) {
        return StreamBuilder<List<SessionDoc>>(
          stream: svc.streamSessions(limit: 6),
          builder: (context, sessionsSnap) {
            return StreamBuilder<Routine?>(
              stream: svc.streamDefaultRoutine(),
              builder: (context, routineSnap) {
                return StreamBuilder<List<BodyWeightEntry>>(
                  stream: svc.streamBodyWeight(limit: 1),
                  builder: (context, weightSnap) {
                    return FutureBuilder<
                      DocumentSnapshot<Map<String, dynamic>>
                    >(
                      future: svc.root.get(),
                      builder: (context, rootSnap) {
                        final stats = statsSnap.data ?? const {};
                        final sessions =
                            sessionsSnap.data ?? const <SessionDoc>[];
                        final routine = routineSnap.data;
                        final weight =
                            weightSnap.data?.isNotEmpty == true
                                ? weightSnap.data!.last.weight
                                : null;
                        final target =
                            (rootSnap.data?.data()?['bodyWeightTarget'] as num?)
                                ?.toDouble();

                        return _GymDashboardContent(
                          svc: svc,
                          stats: stats,
                          sessions: sessions,
                          routine: routine,
                          weight: weight,
                          targetWeight: target,
                          onOpenSection: onOpenSection,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );

    if (embedded) return content;

    return AppShell(
      title: 'Gimnasio',
      subtitle: 'Panel de entrenamiento, descanso y progreso.',
      activeRoute: AppRoutes.gymDashboard,
      child: content,
    );
  }
}

class _GymDashboardContent extends StatelessWidget {
  const _GymDashboardContent({
    required this.svc,
    required this.stats,
    required this.sessions,
    required this.routine,
    required this.weight,
    required this.targetWeight,
    required this.onOpenSection,
  });

  final GymFirestoreService svc;
  final Map<String, dynamic> stats;
  final List<SessionDoc> sessions;
  final Routine? routine;
  final double? weight;
  final double? targetWeight;
  final ValueChanged<int>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final totalSessions = (stats['totalSessions'] as num?)?.toInt() ?? 0;
    final totalVolume = (stats['totalVolume'] as num?)?.toDouble() ?? 0;
    final avgDuration = (stats['avgDuration'] as num?)?.toDouble() ?? 0;
    final lastSession = sessions.isEmpty ? null : sessions.first;

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GymAlerts(),
            _NextSessionCard(
              svc: svc,
              routine: routine,
              lastSession: lastSession,
              weeklySessions: totalSessions,
              onOpenRoutines:
                  () => _openSectionOrPush(
                    context,
                    sectionIndex: 1,
                    builder: (_) => RoutinesListScreen(svc: svc),
                  ),
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 220,
              spacing: 16,
              children: [
                FocusStatCard(
                  title: 'Entrenos esta semana',
                  value: '$totalSessions',
                  subtitle: 'Últimos 7 días',
                  icon: Icons.fitness_center_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  onTap:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 4,
                        builder: (_) => SessionHistoryScreen(svc: svc),
                      ),
                ),
                FocusStatCard(
                  title: 'Volumen total',
                  value: _volumeLabel(totalVolume),
                  subtitle: 'Carga acumulada',
                  icon: Icons.monitor_weight_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 3,
                        builder: (_) => GymAnalyticsScreen(svc: svc),
                      ),
                ),
                FocusStatCard(
                  title: 'Duración media',
                  value: '${avgDuration.toStringAsFixed(0)} min',
                  subtitle: 'Por sesión',
                  icon: Icons.timer_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 3,
                        builder: (_) => GymAnalyticsScreen(svc: svc),
                      ),
                ),
                FocusStatCard(
                  title: 'Peso corporal',
                  value:
                      weight == null
                          ? 'Sin dato'
                          : '${weight!.toStringAsFixed(1)} kg',
                  subtitle:
                      targetWeight == null
                          ? 'Sin objetivo'
                          : 'Objetivo ${targetWeight!.toStringAsFixed(1)} kg',
                  icon: Icons.scale_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  onTap:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 3,
                        builder: (_) => GymAnalyticsScreen(svc: svc),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 960;
                final weekly = _WeeklyRoutineCard(
                  svc: svc,
                  routine: routine,
                  onOpenRoutines:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 1,
                        builder: (_) => RoutinesListScreen(svc: svc),
                      ),
                );
                final recent = _RecentSessionsCard(
                  sessions: sessions,
                  onOpenHistory:
                      () => _openSectionOrPush(
                        context,
                        sectionIndex: 4,
                        builder: (_) => SessionHistoryScreen(svc: svc),
                      ),
                );

                if (!wide) {
                  return Column(
                    children: [weekly, const SizedBox(height: 16), recent],
                  );
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: weekly),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: recent),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _ProgressPromptCard(
              onOpenProgress:
                  () => _openSectionOrPush(
                    context,
                    sectionIndex: 3,
                    builder: (_) => GymAnalyticsScreen(svc: svc),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSectionOrPush(
    BuildContext context, {
    required int sectionIndex,
    required WidgetBuilder builder,
  }) {
    final handler = onOpenSection;
    if (handler != null) {
      handler(sectionIndex);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }
}

class _GymAlerts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();

    final root = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root');
    final configAlerts = root.collection('config').doc('alerts').snapshots();
    final subscriptionAlert =
        root.collection('alerts').doc('subscription').snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: configAlerts,
      builder: (context, configSnap) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: subscriptionAlert,
          builder: (context, subSnap) {
            final config = configSnap.data?.data() ?? const {};
            final subscription = subSnap.data?.data() ?? const {};
            final showDeficit = config['extremeDeficitWorkout'] == true;
            final subSoon =
                subscription['dueSoon'] == true ||
                config['subscriptionDueSoon'] == true;
            if (!showDeficit && !subSoon) return const SizedBox.shrink();

            final cards = <Widget>[];
            if (showDeficit) {
              final deficit = (config['deficitKcal'] as num?)?.toDouble() ?? 0;
              cards.add(
                _InlineAlert(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Déficit extremo con entreno fuerte',
                  message:
                      'Balance energético actual ${deficit.toStringAsFixed(0)} kcal.',
                ),
              );
            }

            if (subSoon) {
              final dueRaw =
                  subscription['nextPaymentDate'] ??
                  config['subscriptionDueAt'];
              DateTime? dueDate;
              if (dueRaw is Timestamp) dueDate = dueRaw.toDate();
              if (dueRaw is DateTime) dueDate = dueRaw;
              final amount = (subscription['amount'] as num?)?.toDouble();
              final amountLabel =
                  amount == null ? '' : ' de ${amount.toStringAsFixed(2)}';
              final dueLabel =
                  dueDate == null
                      ? 'pronto'
                      : DateFormat('d MMM', 'es_ES').format(dueDate);
              cards.add(
                _InlineAlert(
                  icon: Icons.event_available_rounded,
                  title: 'Pago próximo',
                  message: 'Suscripción$amountLabel prevista para $dueLabel.',
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(children: cards),
            );
          },
        );
      },
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({
    required this.svc,
    required this.routine,
    required this.lastSession,
    required this.weeklySessions,
    required this.onOpenRoutines,
  });

  final GymFirestoreService svc;
  final Routine? routine;
  final SessionDoc? lastSession;
  final int weeklySessions;
  final VoidCallback onOpenRoutines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      backgroundColor: scheme.surfaceContainerLowest,
      child:
          routine == null
              ? _EmptyHero(onOpenRoutines: onOpenRoutines)
              : StreamBuilder<List<RoutineDay>>(
                stream: svc.streamDays(routine!.id),
                builder: (context, daysSnap) {
                  final days = daysSnap.data ?? const <RoutineDay>[];
                  final nextDay =
                      days.isEmpty
                          ? null
                          : days[DateTime.now().weekday % days.length];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 760;
                      final copy = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FocusBadge(
                            label:
                                weeklySessions > 0
                                    ? '$weeklySessions sesiones esta semana'
                                    : 'Semana sin sesiones',
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            nextDay == null
                                ? 'Rutina lista para construir'
                                : 'Próxima sesión',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nextDay == null
                                ? 'Añade días y ejercicios para convertir "${routine!.name}" en una semana entrenable.'
                                : '${routine!.name} - ${nextDay.name}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lastSession == null
                                ? 'Todavía no hay sesiones guardadas.'
                                : 'Última sesión: ${lastSession!.dayName}, ${DateFormat('d MMM', 'es_ES').format(lastSession!.date)}.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      );

                      final action = Column(
                        crossAxisAlignment:
                            compact
                                ? CrossAxisAlignment.stretch
                                : CrossAxisAlignment.end,
                        children: [
                          _HeroMark(color: routine!.color),
                          const SizedBox(height: 14),
                          if (nextDay == null)
                            FocusPrimaryButton(
                              label: 'Abrir rutina',
                              icon: Icons.list_alt_rounded,
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => RoutineDetailScreen(
                                            svc: svc,
                                            routine: routine!,
                                          ),
                                    ),
                                  ),
                            )
                          else
                            FocusPrimaryButton(
                              label: 'Iniciar sesión',
                              icon: Icons.play_arrow_rounded,
                              fullWidth: compact,
                              color: routine!.color,
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => LiveSessionScreen(
                                            svc: svc,
                                            routine: routine!,
                                            day: nextDay,
                                          ),
                                    ),
                                  ),
                            ),
                        ],
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [copy, const SizedBox(height: 18), action],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: copy),
                          const SizedBox(width: 24),
                          action,
                        ],
                      );
                    },
                  );
                },
              ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.onOpenRoutines});

  final VoidCallback onOpenRoutines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gimnasio',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Crea tu rutina principal para organizar días, ejercicios, descanso y progreso.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        );
        final action = FocusPrimaryButton(
          label: 'Crear rutina',
          icon: Icons.add_rounded,
          fullWidth: compact,
          onPressed: onOpenRoutines,
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [copy, const SizedBox(height: 16), action],
          );
        }
        return Row(
          children: [Expanded(child: copy), const SizedBox(width: 16), action],
        );
      },
    );
  }
}

class _WeeklyRoutineCard extends StatelessWidget {
  const _WeeklyRoutineCard({
    required this.svc,
    required this.routine,
    required this.onOpenRoutines,
  });

  final GymFirestoreService svc;
  final Routine? routine;
  final VoidCallback onOpenRoutines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Rutina semanal',
            subtitle: routine?.name ?? 'Sin rutina principal',
            icon: Icons.calendar_view_week_rounded,
            trailing: TextButton(
              onPressed: onOpenRoutines,
              child: const Text('Ver rutinas'),
            ),
          ),
          const SizedBox(height: 16),
          if (routine == null)
            const _InlineEmpty(
              icon: Icons.event_busy_rounded,
              title: 'No hay rutina activa',
              subtitle: 'Elige una rutina como principal para verla aquí.',
            )
          else
            StreamBuilder<List<RoutineDay>>(
              stream: svc.streamDays(routine!.id),
              builder: (context, snap) {
                final days = snap.data ?? const <RoutineDay>[];
                if (days.isEmpty) {
                  return const _InlineEmpty(
                    icon: Icons.add_task_rounded,
                    title: 'Rutina sin días',
                    subtitle: 'Añade días de entrenamiento y ejercicios.',
                  );
                }

                return ResponsiveGrid(
                  minItemWidth: 180,
                  spacing: 12,
                  children: [
                    for (var i = 0; i < days.length; i++)
                      _RoutineDayPreview(
                        day: days[i],
                        index: i,
                        color: routine!.color,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => LiveSessionScreen(
                                      svc: svc,
                                      routine: routine!,
                                      day: days[i],
                                    ),
                              ),
                            ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 12),
          Text(
            'Toca un día para abrir la sesión activa con sus ejercicios reales.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _RoutineDayPreview extends StatelessWidget {
  const _RoutineDayPreview({
    required this.day,
    required this.index,
    required this.color,
    required this.onTap,
  });

  final RoutineDay day;
  final int index;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FocusCard(
      onTap: onTap,
      elevated: false,
      padding: const EdgeInsets.all(14),
      backgroundColor: scheme.surfaceContainerLow,
      borderSide: BorderSide(color: color.withValues(alpha: 0.24)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Iniciar entrenamiento',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.play_arrow_rounded, color: color, size: 22),
        ],
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  const _RecentSessionsCard({
    required this.sessions,
    required this.onOpenHistory,
  });

  final List<SessionDoc> sessions;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final recent = sessions.take(5).toList(growable: false);
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Últimas sesiones',
            subtitle: 'Historial reciente',
            icon: Icons.history_rounded,
            trailing: TextButton(
              onPressed: onOpenHistory,
              child: const Text('Abrir'),
            ),
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            const _InlineEmpty(
              icon: Icons.history_toggle_off_rounded,
              title: 'Sin sesiones recientes',
              subtitle: 'Completa una sesión para ver volumen y duración.',
            )
          else
            Column(
              children: [
                for (final session in recent) _SessionPreview(session: session),
              ],
            ),
        ],
      ),
    );
  }
}

class _SessionPreview extends StatelessWidget {
  const _SessionPreview({required this.session});

  final SessionDoc session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              color: scheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.dayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${session.routineName} - ${DateFormat('d MMM', 'es_ES').format(session.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FocusBadge(
            label: _volumeLabel(session.volumeKg),
            color: scheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _ProgressPromptCard extends StatelessWidget {
  const _ProgressPromptCard({required this.onOpenProgress});

  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FocusCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FocusSectionHeader(
                title: 'Progreso',
                subtitle: 'Volumen, peso corporal y sensaciones',
                icon: Icons.analytics_rounded,
              ),
              const SizedBox(height: 10),
              Text(
                'Revisa tendencias reales de sesiones, marcas personales y medidas corporales desde el panel de progreso.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
          final button = FocusSecondaryButton(
            label: 'Ver progreso',
            icon: Icons.trending_up_rounded,
            fullWidth: compact,
            onPressed: onOpenProgress,
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 14), button],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.fitness_center_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }
}

String _volumeLabel(double value) {
  if (value <= 0) return '0 kg';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} ton';
  return '${value.toStringAsFixed(0)} kg';
}
