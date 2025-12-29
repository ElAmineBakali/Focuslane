import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/gym_firestore_service.dart';
import '../models/gym_models.dart';

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

class BodyweightScreen extends StatefulWidget {
  final GymFirestoreService svc;
  const BodyweightScreen({super.key, required this.svc});

  @override
  State<BodyweightScreen> createState() => _BodyweightScreenState();
}

class _BodyweightScreenState extends State<BodyweightScreen> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = widget.svc;

    return Scaffold(
      appBar: AppBar(title: const Text('Peso corporal')),
      body: StreamBuilder<List<BodyWeightEntry>>(
        stream: svc.streamBodyWeight(),
        builder: (context, snap) {
          final weights = snap.data ?? [];
          final spots = List.generate(
            weights.length,
            (i) => FlSpot(i.toDouble(), weights[i].weight),
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Añadir peso (kg)',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children:
                              {
                                Expanded(
                                  child: TextFormField(
                                    controller: _ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.monitor_weight_outlined,
                                      ),
                                      hintText: 'Ej: 78.3',
                                      labelText: 'Peso (kg)',
                                    ),
                                    validator: (s) {
                                      final v = double.tryParse(
                                        (s ?? '').replaceAll(',', '.'),
                                      );
                                      if (v == null)
                                        return 'Introduce un número válido';
                                      if (v <= 0) return 'Debe ser mayor que 0';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () async {
                                    if (_formKey.currentState?.validate() !=
                                        true)
                                      return;
                                    final v = double.parse(
                                      _ctrl.text.replaceAll(',', '.'),
                                    );
                                    await svc.addBodyWeight(
                                      v,
                                      DateTime.now(),
                                      computeTrend: true,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        _niceBar(
                                          'Peso guardado ✅',
                                          icon: Icons.check_circle_rounded,
                                        ),
                                      );
                                    }
                                    _ctrl.clear();
                                  },
                                  icon: const Icon(Icons.save_outlined),
                                  label: const Text('Guardar'),
                                ),
                              }.toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<GymGoals>(
                stream: svc.streamGoals(),
                builder: (context, goalSnap) {
                  final goal = goalSnap.data;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Objetivo (kg) • línea en gráfica',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Ej: 75.0',
                                    labelText:
                                        'Actual: ${goal?.bodyWeightTarget ?? '-'}',
                                    prefixIcon: const Icon(Icons.flag_outlined),
                                  ),
                                  onSubmitted: (s) async {
                                    final val = double.tryParse(
                                      s.replaceAll(',', '.'),
                                    );
                                    await svc.setBodyWeightTarget(val);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        _niceBar('Objetivo actualizado 🎯'),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await svc.setBodyWeightTarget(null);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      _niceBar('Objetivo eliminado 🧽'),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Quitar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 220,
                    child: StreamBuilder<GymGoals>(
                      stream: svc.streamGoals(),
                      builder: (context, gs) {
                        final target = gs.data?.bodyWeightTarget;
                        return LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: theme.colorScheme.primary.withOpacity(
                                    .12,
                                  ),
                                ),
                              ),
                              if (target != null)
                                LineChartBarData(
                                  spots:
                                      spots.isEmpty
                                          ? [const FlSpot(0, 0)]
                                          : [
                                            FlSpot(0, target),
                                            FlSpot(
                                              (spots.length - 1).toDouble(),
                                              target,
                                            ),
                                          ],
                                  isCurved: false,
                                  color: theme.colorScheme.tertiary,
                                  barWidth: 2,
                                  dotData: const FlDotData(show: false),
                                ),
                            ],
                            titlesData: const FlTitlesData(show: false),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
