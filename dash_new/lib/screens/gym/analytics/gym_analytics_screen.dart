import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/gym_firestore_service.dart';
import '../models/gym_models.dart';
import '../session/session_summary_screen.dart';
import '../models/exercise_library_data.dart';

SnackBar _niceBar(String text, {IconData? icon}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    content: Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Expanded(child: Text(text)),
      ],
    ),
    duration: const Duration(seconds: 3),
  );
}

class GymAnalyticsScreen extends StatelessWidget {
  final GymFirestoreService svc;
  const GymAnalyticsScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analíticas'),
        actions: [
          IconButton(
            tooltip: 'Añadir peso',
            icon: const Icon(Icons.monitor_weight),
            onPressed: () => _quickAddWeight(context),
          ),
          IconButton(
            tooltip: 'Añadir medida',
            icon: const Icon(Icons.straighten),
            onPressed: () => _quickAddMeasurement(context),
          ),
          IconButton(
            tooltip: 'Objetivo de peso',
            icon: const Icon(Icons.flag),
            onPressed: () => _setBodyWeightGoal(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: const [
          _KpiRow(),
          SizedBox(height: 12),
          _BodyWeightCard(),
          SizedBox(height: 12),
          _WeeklyVolumeByMuscleCard(),
          SizedBox(height: 12),
          _AdherenceCard(),
          SizedBox(height: 12),
          _RecentSessionsCard(),
          SizedBox(height: 12),
          _RpeNoteCard(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- quick actions (AHORA con formularios bonitos + validación) ---

  Future<void> _quickAddWeight(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Añadir peso (kg)'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ej: 72.4',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                  labelText: 'Peso (kg)',
                ),
                validator: (s) {
                  final v = double.tryParse((s ?? '').replaceAll(',', '.'));
                  if (v == null) return 'Introduce un número válido';
                  if (v <= 0) return 'Debe ser mayor que 0';
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (ok == true) {
      final v = double.parse(ctrl.text.replaceAll(',', '.'));
      await svc.addBodyWeight(v, DateTime.now(), computeTrend: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _niceBar('Peso guardado ✅', icon: Icons.check_circle_rounded),
        );
      }
    }
  }

  Future<void> _quickAddMeasurement(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final muscleCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final siteItems = ['avg', 'left', 'right'];
    String site = 'avg';

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Añadir medida (cm)'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: muscleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Músculo',
                      hintText: 'Ej: brazo',
                      prefixIcon: Icon(Icons.fitness_center_outlined),
                    ),
                    validator:
                        (s) =>
                            (s ?? '').trim().isEmpty
                                ? 'Escribe un músculo'
                                : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: valCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor (cm)',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    validator: (s) {
                      final v = double.tryParse((s ?? '').replaceAll(',', '.'));
                      if (v == null) return 'Número válido';
                      if (v <= 0) return 'Mayor que 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: site,
                    items:
                        siteItems
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (v) => site = v ?? 'avg',
                    decoration: const InputDecoration(
                      labelText: 'Lado',
                      prefixIcon: Icon(Icons.swap_horiz),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (ok == true) {
      final cm = double.parse(valCtrl.text.replaceAll(',', '.'));
      final muscle = muscleCtrl.text.trim();
      await svc.addMeasurement(muscle, cm, DateTime.now(), site: site);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _niceBar('Medida guardada 📏', icon: Icons.check_circle_rounded),
        );
      }
    }
  }

  Future<void> _setBodyWeightGoal(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Objetivo de peso (kg)'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ej: 70.0 (vacío para limpiar)',
                  prefixIcon: Icon(Icons.flag_outlined),
                  labelText: 'Nuevo objetivo',
                ),
                validator: (s) {
                  final t = (s ?? '').trim();
                  if (t.isEmpty) return null; // vacío = limpiar
                  final v = double.tryParse(t.replaceAll(',', '.'));
                  if (v == null) return 'Número válido o deja vacío';
                  if (v <= 0) return 'Mayor que 0';
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (ok == true) {
      final txt = ctrl.text.trim();
      final v = txt.isEmpty ? null : double.parse(txt.replaceAll(',', '.'));
      await svc.setBodyWeightTarget(v);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _niceBar('Objetivo actualizado 🎯', icon: Icons.check_circle_rounded),
        );
      }
    }
  }
}

/// ===== KPIs con sparklines (últimos 30 días) =====
class _KpiRow extends StatelessWidget {
  const _KpiRow();

  @override
  Widget build(BuildContext context) {
    final svc =
        (context.findAncestorWidgetOfExactType<GymAnalyticsScreen>()!).svc;
    final s = Theme.of(context).colorScheme;
    return StreamBuilder<List<SessionDoc>>(
      stream: svc.streamSessions(limit: 180),
      builder: (context, sesSnap) {
        final sessions = sesSnap.data ?? [];
        final now = DateTime.now();
        final from30 = now.subtract(const Duration(days: 30));

        final last30 =
            sessions.where((x) => !x.date.isBefore(from30)).toList()
              ..sort((a, b) => a.date.compareTo(b.date));
        final sessionsCount = last30.length;

        final byWeek = <String, double>{};
        for (final x in sessions) {
          final key = '${x.date.year}-W${_weekNumber(x.date)}';
          byWeek[key] = (byWeek[key] ?? 0) + x.volumeKg;
        }
        final bestWeek =
            byWeek.values.isEmpty
                ? 0.0
                : byWeek.values.reduce((a, b) => a > b ? a : b);

        final sesSpots = <FlSpot>[];
        for (int i = 0; i < last30.length; i++) {
          sesSpots.add(FlSpot(i.toDouble(), 1));
        }

        return StreamBuilder<List<BodyWeightEntry>>(
          stream: svc.streamBodyWeight(limit: 90),
          builder: (context, wSnap) {
            final wList = wSnap.data ?? [];
            final wLast30 =
                wList.where((e) => !e.date.isBefore(from30)).toList();
            double delta30 = 0;
            if (wLast30.isNotEmpty) {
              delta30 = wLast30.last.weight - wLast30.first.weight;
            }
            final weightSpots = <FlSpot>[];
            for (int i = 0; i < wLast30.length; i++) {
              weightSpots.add(FlSpot(i.toDouble(), wLast30[i].weight));
            }

            return Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    title: 'Δ peso 30d',
                    value:
                        '${delta30 >= 0 ? '+' : ''}${delta30.toStringAsFixed(1)} kg',
                    spots: weightSpots,
                    color: s.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiCard(
                    title: 'Sesiones 30d',
                    value: '$sessionsCount',
                    spots: sesSpots,
                    color: s.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiCard(
                    title: 'Mejor semana',
                    value: '${bestWeek.toStringAsFixed(0)} kg',
                    spots:
                        byWeek.entries
                            .mapIndexed((i, e) => FlSpot(i.toDouble(), e.value))
                            .toList(),
                    color: s.tertiary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _weekNumber(DateTime d) {
    final first = DateTime(d.year, 1, 1);
    final days = d.difference(first).inDays + first.weekday;
    return (days / 7).ceil();
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final List<FlSpot> spots;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.spots,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: s.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: LineChart(
                LineChartData(
                  minY: spots.isEmpty ? 0 : null,
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      color: color,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.28),
                            color.withOpacity(0.06),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Peso corporal ----------
class _BodyWeightCard extends StatelessWidget {
  const _BodyWeightCard();

  @override
  Widget build(BuildContext context) {
    final svc =
        (context.findAncestorWidgetOfExactType<GymAnalyticsScreen>()!).svc;
    final s = Theme.of(context).colorScheme;
    return StreamBuilder<List<BodyWeightEntry>>(
      stream: svc.streamBodyWeight(limit: 180),
      builder: (context, snap) {
        return StreamBuilder<GymGoals>(
          stream: svc.streamGoals(),
          builder: (context, g) {
            final target = g.data?.bodyWeightTarget;
            if (!snap.hasData) {
              return const Card(
                child: SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            final list = snap.data!;
            if (list.isEmpty) {
              return const Card(
                child: SizedBox(
                  height: 220,
                  child: Center(child: Text('Añade registros de peso')),
                ),
              );
            }

            final weightSpots = <FlSpot>[];
            final trendSpots = <FlSpot>[];
            for (int i = 0; i < list.length; i++) {
              weightSpots.add(FlSpot(i.toDouble(), list[i].weight));
              if (list[i].trend7 != null)
                trendSpots.add(FlSpot(i.toDouble(), list[i].trend7!));
            }

            final last = list.last.weight;
            final first = list.first.weight;
            final delta = (last - first);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peso corporal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Último: ${last.toStringAsFixed(1)} kg'
                      '${target != null ? ' • Objetivo: ${target.toStringAsFixed(1)} kg' : ''}'
                      ' • Δ ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                      style: TextStyle(color: s.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipRoundedRadius: 8,
                              tooltipPadding: const EdgeInsets.all(8),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: weightSpots,
                              isCurved: true,
                              barWidth: 3,
                              color: s.primary,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    s.primary.withOpacity(0.28),
                                    s.primary.withOpacity(0.06),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            if (trendSpots.isNotEmpty)
                              LineChartBarData(
                                spots: trendSpots,
                                isCurved: true,
                                barWidth: 2,
                                color: s.tertiary,
                                dotData: const FlDotData(show: false),
                              ),
                            if (target != null)
                              LineChartBarData(
                                spots: [
                                  FlSpot(0, target),
                                  FlSpot(list.length.toDouble() - 1, target),
                                ],
                                isCurved: false,
                                color: s.secondary,
                                barWidth: 1.8,
                                dotData: const FlDotData(show: false),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ---------- Volumen semanal por grupo ----------
class _WeeklyVolumeByMuscleCard extends StatelessWidget {
  const _WeeklyVolumeByMuscleCard();

  static const List<String> _muscleOrder = [
    'Pecho',
    'Espalda',
    'Hombros',
    'Bíceps',
    'Tríceps',
    'Piernas',
    'Glúteos',
    'Core',
    'Full body',
    'Cardio',
    'Otros',
  ];

  @override
  Widget build(BuildContext context) {
    final svc =
        (context.findAncestorWidgetOfExactType<GymAnalyticsScreen>()!).svc;
    final s = Theme.of(context).colorScheme;

    final palette = <Color>[
      s.primary,
      s.secondary,
      s.tertiary,
      s.primaryContainer,
      s.secondaryContainer,
      s.tertiaryContainer,
      s.primary.withOpacity(0.7),
      s.secondary.withOpacity(0.7),
      s.tertiary.withOpacity(0.7),
      s.outlineVariant,
    ];

    final idToGroup = {
      for (final e in kExerciseLibrary) e.id: e.muscleGroup.toString(),
    };

    String groupForName(String name) {
      final n = name.toLowerCase();
      for (final e in kExerciseLibrary) {
        if (e.name.toLowerCase() == n) return e.muscleGroup;
      }
      for (final e in kExerciseLibrary) {
        if (n.contains(e.name.toLowerCase())) return e.muscleGroup;
      }
      return 'Otros';
    }

    String groupForExercise(PerformedExercise ex) {
      if (ex.exerciseId != null && idToGroup.containsKey(ex.exerciseId)) {
        return idToGroup[ex.exerciseId]!;
      }
      return groupForName(ex.name);
    }

    return StreamBuilder<List<SessionDoc>>(
      stream: svc.streamSessions(limit: 80),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Card(
            child: SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final sessions = snap.data!;
        if (sessions.isEmpty) {
          return const Card(
            child: SizedBox(
              height: 240,
              child: Center(child: Text('Aún no hay sesiones')),
            ),
          );
        }

        final byWeekGroup = <String, Map<String, double>>{};
        for (final ses in sessions) {
          final weekKey = '${ses.date.year}-W${_weekNumber(ses.date)}';
          byWeekGroup.putIfAbsent(weekKey, () => {});
          final map = byWeekGroup[weekKey]!;

          for (final ex in ses.exercises) {
            final g = groupForExercise(ex);
            final exVol = ex.sets.fold<double>(
              0,
              (a, s) => a + s.weight * s.reps,
            );
            map[g] = (map[g] ?? 0) + exVol;
          }
        }

        final weeks = byWeekGroup.keys.toList()..sort();
        final bars = <BarChartGroupData>[];
        double maxY = 0;

        for (int x = 0; x < weeks.length; x++) {
          final m = byWeekGroup[weeks[x]]!;
          double from = 0;
          final stackItems = <BarChartRodStackItem>[];

          for (int i = 0; i < _muscleOrder.length; i++) {
            final label = _muscleOrder[i];
            final val = m[label] ?? 0;
            if (val <= 0) continue;
            final to = from + val;
            stackItems.add(
              BarChartRodStackItem(from, to, palette[i % palette.length]),
            );
            from = to;
          }
          maxY = from > maxY ? from : maxY;

          bars.add(
            BarChartGroupData(
              x: x,
              barRods: [
                BarChartRodData(
                  toY: from,
                  width: 18,
                  rodStackItems: stackItems,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Volumen semanal por grupo (kg)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY == 0 ? null : maxY * 1.15,
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= weeks.length)
                                return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  weeks[i],
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, _, rod, __) {
                            final wk = weeks[group.x];
                            return BarTooltipItem(
                              '$wk\nTotal: ${rod.toY.toStringAsFixed(0)} kg',
                              const TextStyle(fontWeight: FontWeight.w600),
                            );
                          },
                        ),
                      ),
                      barGroups: bars,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _Legend(muscles: _muscleOrder, colors: palette),
              ],
            ),
          ),
        );
      },
    );
  }

  int _weekNumber(DateTime d) {
    final first = DateTime(d.year, 1, 1);
    final days = d.difference(first).inDays + first.weekday;
    return (days / 7).ceil();
  }
}

class _Legend extends StatelessWidget {
  final List<String> muscles;
  final List<Color> colors;
  const _Legend({required this.muscles, required this.colors});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < muscles.length; i++) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(muscles[i], style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 12),
          ],
        ),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: items);
  }
}

/// ---------- Adherencia y racha ----------
class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard();

  @override
  Widget build(BuildContext context) {
    final svc =
        (context.findAncestorWidgetOfExactType<GymAnalyticsScreen>()!).svc;
    final s = Theme.of(context).colorScheme;
    return StreamBuilder<List<SessionDoc>>(
      stream: svc.streamSessions(limit: 365),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Card(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const Card(
            child: SizedBox(
              height: 120,
              child: Center(child: Text('Registra tus primeras sesiones')),
            ),
          );
        }

        final now = DateTime.now();
        final from30 = now.subtract(const Duration(days: 30));
        final daysWithSession = <DateTime>{};
        for (final x in list) {
          daysWithSession.add(DateTime(x.date.year, x.date.month, x.date.day));
        }

        int streak = 0;
        for (int i = 0; i < 365; i++) {
          final d = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: i));
          if (daysWithSession.contains(d)) {
            streak++;
          } else {
            break;
          }
        }

        int trained = 0;
        for (int i = 0; i < 30; i++) {
          final d = DateTime(
            from30.year,
            from30.month,
            from30.day,
          ).add(Duration(days: i));
          if (daysWithSession.contains(d)) trained++;
        }
        final adherence = trained / 30.0;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: s.secondary,
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
              ),
            ),
            title: Text('Racha: $streak día${streak == 1 ? '' : 's'}'),
            subtitle: Text(
              'Adherencia últimos 30 días: ${(adherence * 100).toStringAsFixed(0)}%',
            ),
          ),
        );
      },
    );
  }
}

/// ---------- Historial reciente ----------
class _RecentSessionsCard extends StatelessWidget {
  const _RecentSessionsCard();

  @override
  Widget build(BuildContext context) {
    final svc =
        (context.findAncestorWidgetOfExactType<GymAnalyticsScreen>()!).svc;
    return StreamBuilder<List<SessionDoc>>(
      stream: svc.streamSessions(limit: 20),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Card(
            child: SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final sessions = snap.data!;
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                leading: Icon(Icons.history),
                title: Text('Historial reciente de sesiones'),
              ),
              if (sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Center(child: Text('Sin sesiones todavía')),
                )
              else
                ...sessions.map(
                  (s) => ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text('${s.routineName} • ${s.dayName}'),
                    subtitle: Text(
                      '${s.date.toLocal()} • ${s.volumeKg.toStringAsFixed(0)} kg • ${s.durationMin} min',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SessionSummaryScreen(session: s),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// ---------- Nota RPE ----------
class _RpeNoteCard extends StatelessWidget {
  const _RpeNoteCard();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: s.tertiary,
          child: const Icon(Icons.info_outline, color: Colors.white),
        ),
        title: const Text('¿Qué es el RPE?'),
        subtitle: const Text(
          'RPE = “Rate of Perceived Exertion”. Escala 1–10 donde 10 es esfuerzo máximo. '
          'Un RPE 8 suele indicar ~2 repeticiones en recámara; 9, ~1; 10, 0.',
        ),
      ),
    );
  }
}

// ===== Helpers =====
extension _MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int i, E e) f) sync* {
    var i = 0;
    for (final e in this) {
      yield f(i++, e);
    }
  }
}

// ignore: unused_element
int _weekNumber(DateTime d) {
  final first = DateTime(d.year, 1, 1);
  final days = d.difference(first).inDays + first.weekday;
  return (days / 7).ceil();
}
