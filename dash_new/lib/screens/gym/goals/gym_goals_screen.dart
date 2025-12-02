// lib/screens/gym/gym_goals_screen.dart
import 'package:flutter/material.dart';
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

class GymGoalsScreen extends StatelessWidget {
  final GymFirestoreService svc;
  const GymGoalsScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Objetivos')),
      body: StreamBuilder<GymGoals>(
        stream: svc.streamGoals(),
        builder: (context, snap) {
          final g = snap.data ?? const GymGoals();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Objetivo de peso corporal (kg)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Actual: ${g.bodyWeightTarget?.toStringAsFixed(1) ?? '-'}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Ej: 75.0',
                                  labelText: 'Nuevo objetivo',
                                  prefixIcon: Icon(Icons.flag_outlined),
                                ),
                                validator: (s) {
                                  if ((s ?? '').trim().isEmpty) {
                                    return 'Introduce un valor o usa Quitar';
                                  }
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
                                if (formKey.currentState?.validate() != true)
                                  return;
                                final v = double.parse(
                                  ctrl.text.replaceAll(',', '.'),
                                );
                                await svc.setBodyWeightTarget(v);
                                ctrl.clear();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    _niceBar(
                                      'Objetivo actualizado 🎯',
                                      icon: Icons.check_circle_rounded,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Guardar'),
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
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Próximamente: objetivos por ejercicio (peso/reps/volumen)…',
              ),
            ],
          );
        },
      ),
    );
  }
}
