// lib/screens/gym/measurements_screen.dart
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

class MeasurementsScreen extends StatefulWidget {
  final GymFirestoreService svc;
  const MeasurementsScreen({super.key, required this.svc});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  final _muscles = const ['brazo', 'pecho', 'espalda', 'cintura', 'pierna'];
  String _selected = 'brazo';
  final _valCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _valCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = widget.svc;

    return Scaffold(
      appBar: AppBar(title: const Text('Medidas (cm)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selected,
                      items:
                          _muscles
                              .map(
                                (m) =>
                                    DropdownMenuItem(value: m, child: Text(m)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selected = v!),
                      decoration: const InputDecoration(
                        labelText: 'Músculo',
                        prefixIcon: Icon(Icons.fitness_center_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      controller: _valCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valor (cm)',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      validator: (s) {
                        final v = double.tryParse(
                          (s ?? '').replaceAll(',', '.'),
                        );
                        if (v == null) return 'Número válido';
                        if (v <= 0) return 'Mayor que 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() != true) return;
                      final v = double.parse(
                        _valCtrl.text.replaceAll(',', '.'),
                      );
                      await svc.addMeasurement(_selected, v, DateTime.now());
                      _valCtrl.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _niceBar(
                            'Medida guardada 📏',
                            icon: Icons.check_circle_rounded,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MeasurementEntry>>(
              stream: svc.streamMeasurements(muscle: _selected),
              builder: (context, snap) {
                final data = snap.data ?? [];
                final spots = List.generate(
                  data.length,
                  (i) => FlSpot(i.toDouble(), data[i].valueCm),
                );
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: LineChart(
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
                          ],
                          titlesData: const FlTitlesData(show: false),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
