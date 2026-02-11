import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/core_daily_stats.dart';
import '../models/core_entity_ref.dart';
import '../models/core_recommendation.dart';
import '../services/core_action_executor.dart';
import '../services/core_aggregation_service.dart';
import '../services/core_deeplink_service.dart';
import '../services/core_recommendation_service.dart';
import '../utils/date_utils.dart';

class CoreHubScreen extends StatefulWidget {
  const CoreHubScreen({super.key});

  @override
  State<CoreHubScreen> createState() => _CoreHubScreenState();
}

class _CoreHubScreenState extends State<CoreHubScreen> {
  final _agg = CoreAggregationService.I;
  final _rec = CoreRecommendationService.I;
  final _deeplink = CoreDeeplinkService.I;
  final _executor = CoreActionExecutor.I;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        if (user == null || user.uid.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Hub de conexiones')),
            body: _LoggedOutHub(),
          );
        }
        final uid = user.uid;
        final today = DateTime.now();
        final todayId = dayIdFromDateTime(today);
        final from = today.subtract(const Duration(days: 6));
        final to = today;



        return Scaffold(
          appBar: AppBar(
            title: const Text('Hub de conexiones'),
            actions: [
              IconButton(
                tooltip: 'Abrir calendario',
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () => Navigator.pushNamed(context, '/calendar'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StreamBuilder<CoreDailyStats>(
                stream: _agg.watchDay(uid, todayId),
                builder: (context, snap) {
                  final stats = snap.data ?? CoreDailyStats(dayId: todayId);
                  final recs = _rec.build(
                    stats,
                    targetKcal: 2000,
                    targetProtein: 150,
                    targetWater: 2400,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: 'Resumen diario', subtitle: 'Hoy ($todayId)'),
                      const SizedBox(height: 8),
                      _DailyMetrics(stats: stats),
                      const SizedBox(height: 12),
                      _SourcesGrid(
                        sources: stats.sources,
                        onTap: (ref) => _deeplink.safeNavigate(context, ref),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(title: 'Recomendaciones accionables'),
                      const SizedBox(height: 8),
                      if (recs.isEmpty)
                        const Text('No hay recomendaciones por ahora.')
                      else
                        ...recs.map(
                          (r) => _RecommendationCard(
                            rec: r,
                            onAction: (a) => _executor.executeAction(
                              context,
                              a,
                              origin: r.references.isNotEmpty ? r.references.first : null,
                            ),
                            onOpen: (ref) => _deeplink.safeNavigate(context, ref),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<CoreDailyStats>>(
                stream: _agg.watchRange(uid, from, to),
                builder: (context, snap) {
                  final days = snap.data ?? const [];
                  if (days.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final kcalAvg = days.map((d) => d.kcal).fold<double>(0, (a, b) => a + b) / days.length;
                  final proteinAvg = days.map((d) => d.protein).fold<double>(0, (a, b) => a + b) / days.length;
                  final workouts = days.map((d) => d.workoutsCount).fold<int>(0, (a, b) => a + b);
                  final studyMin = days.map((d) => d.studyMinutes).fold<int>(0, (a, b) => a + b);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: 'Últimos 7 días'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _Pill(label: 'Kcal promedio', value: '${kcalAvg.toStringAsFixed(0)} kcal'),
                          _Pill(label: 'Proteína promedio', value: '${proteinAvg.toStringAsFixed(0)} g'),
                          _Pill(label: 'Entrenos', value: '$workouts'),
                          _Pill(label: 'Minutos estudio', value: '$studyMin'),
                        ],
                      ),

                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoggedOutHub extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Inicia sesión para ver el Hub'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Ir a login'),
          ),
        ],
      ),
    );
  }
}
class _DailyMetrics extends StatelessWidget {
  const _DailyMetrics({required this.stats});

  final CoreDailyStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        icon: Icons.local_fire_department,
        title: 'Calorías',
        value: '${stats.kcal.toStringAsFixed(0)} kcal',
        subtitle: 'Proteína ${stats.protein.toStringAsFixed(0)} g',
      ),
      _MetricCard(
        icon: Icons.local_drink,
        title: 'Agua',
        value: '${stats.waterMl} ml',
        subtitle: 'Fibra ${stats.fiber.toStringAsFixed(0)} g',
      ),
      _MetricCard(
        icon: Icons.fitness_center,
        title: 'Gym',
        value: '${stats.workoutsCount} sesiones',
        subtitle: '${stats.workoutMinutes} min',
      ),
      _MetricCard(
        icon: Icons.school,
        title: 'Estudio',
        value: '${stats.studyMinutes} min',
        subtitle: '${stats.studySessionsCount} sesiones',
      ),
      _MetricCard(
        icon: Icons.check_circle,
        title: 'Tareas',
        value: '${stats.tasksDone}/${stats.tasksTotal}',
        subtitle: 'Completadas hoy',
      ),
      _MetricCard(
        icon: Icons.payments,
        title: 'Finanzas',
        value: '${stats.financeSpentTotal.toStringAsFixed(2)} EUR',
        subtitle: 'Gasto comida ${stats.financeSpentFood.toStringAsFixed(2)}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final cross = isWide ? 3 : constraints.maxWidth >= 600 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: cross,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isWide ? 3.2 : 2.6,
          children: cards,
        );
      },
    );
  }
}

class _SourcesGrid extends StatelessWidget {
  const _SourcesGrid({required this.sources, required this.onTap});

  final List<CoreEntityRef> sources;
  final ValueChanged<CoreEntityRef> onTap;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Fuentes del día', subtitle: 'Toca para abrir'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sources.map((s) {
            return ActionChip(
              avatar: const Icon(Icons.open_in_new, size: 16),
              label: Text(s.title),
              onPressed: () => onTap(s),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.rec, required this.onAction, required this.onOpen});

  final CoreRecommendation rec;
  final ValueChanged<CoreAction> onAction;
  final ValueChanged<CoreEntityRef> onOpen;

  Color _severityColor(CoreRecommendationSeverity s, BuildContext context) {
    switch (s) {
      case CoreRecommendationSeverity.high:
        return Colors.redAccent;
      case CoreRecommendationSeverity.med:
        return Theme.of(context).colorScheme.secondary;
      case CoreRecommendationSeverity.low:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(rec.severity, context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.bolt, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rec.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rec.references.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: rec.references
                    .map((r) => InputChip(
                          label: Text(r.title),
                          avatar: const Icon(Icons.launch, size: 16),
                          onPressed: () => onOpen(r),
                        ))
                    .toList(),
              ),
            ],
            if (rec.actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rec.actions
                    .map(
                      (a) => ElevatedButton.icon(
                        onPressed: () => onAction(a),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: Text(a.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text(
            subtitle!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
