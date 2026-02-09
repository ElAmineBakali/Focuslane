import 'dart:async';
import 'package:flutter/material.dart';

import '../services/skills_firestore_service.dart';
import '../models/skills_models.dart';

class SessionTimerScreen extends StatefulWidget {
  const SessionTimerScreen({super.key});
  static const route = '/skills/session';

  @override
  State<SessionTimerScreen> createState() => _SessionTimerScreenState();
}

class _SessionTimerScreenState extends State<SessionTimerScreen> {
  Skill? skill;
  String? _subSkillId;
  final _objective = TextEditingController();

  SessionMode _mode = SessionMode.timer;
  int _minutes = 0;
  Timer? _timer;
  bool _running = false;

  // quick review
  int _difficulty = 3;
  int _energy = 3;
  final _notes = TextEditingController();
  final Map<String, TextEditingController> _metricCtrls = {};
  final Map<String, int> _rubric = {
    'técnica': 3,
    'consistencia': 3,
    'creatividad': 3,
    'teoría': 3,
    'presentación': 3,
  };
  final _nextTask = TextEditingController();

  DateTime? _startAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Skill) {
      skill = arg;
      for (final k in arg.metricsConfig.keys) {
        _metricCtrls[k] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _metricCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (skill == null) {
      return const Scaffold(body: Center(child: Text('Sin habilidad')));
    }
    final svc = SkillsFirestoreService.I;
    final s = skill!;

    return Scaffold(
      appBar: AppBar(title: Text('Sesión • ${s.name}')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            // Selección de sub-skill
            StreamBuilder<List<SubSkill>>(
              stream: svc.watchSubSkills(s.id),
              builder: (_, snap) {
                final nodes = snap.data ?? [];
                return DropdownButtonFormField<String?>(
                  initialValue: _subSkillId,
                  decoration: const InputDecoration(
                    labelText: 'Sub-skill (opcional)',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('—'),
                    ),
                    ...nodes.map(
                      (n) => DropdownMenuItem<String?>(
                        value: n.id,
                        child: Text(n.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _subSkillId = v),
                );
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _objective,
              decoration: const InputDecoration(
                labelText: 'Objetivo de la sesión',
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                DropdownButton<SessionMode>(
                  value: _mode,
                  onChanged: (v) => setState(() => _mode = v ?? _mode),
                  items:
                      SessionMode.values
                          .map(
                            (m) =>
                                DropdownMenuItem(value: m, child: Text(m.name)),
                          )
                          .toList(),
                ),
                const SizedBox(width: 12),
                Text(
                  '$_minutes min',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Pausar' : 'Iniciar'),
                  onPressed: () {
                    if (_running) {
                      _timer?.cancel();
                      setState(() => _running = false);
                    } else {
                      _startAt ??= DateTime.now();
                      _timer ??= Timer.periodic(const Duration(minutes: 1), (
                        _,
                      ) {
                        setState(() => _minutes += 1);
                      });
                      setState(() => _running = true);
                    }
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Finalizar'),
                  onPressed:
                      _minutes == 0 && !_running
                          ? null
                          : () async {
                            _timer?.cancel();
                            setState(() => _running = false);
                            await _saveSession(context);
                          },
                ),
              ],
            ),

            const Divider(height: 24),
            Text(
              'Quick review',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Expanded(
                  child: _slider(
                    'Dificultad',
                    _difficulty,
                    (v) => setState(() => _difficulty = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _slider(
                    'Energía',
                    _energy,
                    (v) => setState(() => _energy = v),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 3,
            ),

            const SizedBox(height: 8),
            if (s.metricsConfig.isNotEmpty) ...[
              Text(
                'Métricas de la sesión',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              ...s.metricsConfig.entries.map(
                (e) => TextField(
                  controller: _metricCtrls[e.key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '${e.key} (${e.value})',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            Text(
              'Rúbrica (1–5)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children:
                  _rubric.keys
                      .map(
                        (k) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 110, child: Text(k)),
                            DropdownButton<int>(
                              value: _rubric[k],
                              items:
                                  [1, 2, 3, 4, 5]
                                      .map(
                                        (i) => DropdownMenuItem(
                                          value: i,
                                          child: Text('$i'),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _rubric[k] = v ?? 3),
                            ),
                          ],
                        ),
                      )
                      .toList(),
            ),

            const SizedBox(height: 8),
            TextField(
              controller: _nextTask,
              decoration: const InputDecoration(
                labelText: 'Siguiente micro-tarea (opcional)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(String label, int value, void Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value/5'),
        Slider(
          min: 1,
          max: 5,
          divisions: 4,
          value: value.toDouble(),
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ],
    );
  }

  Future<void> _saveSession(BuildContext context) async {
    final svc = SkillsFirestoreService.I;
    final s = skill!;
    final now = DateTime.now();
    final start = _startAt ?? now.subtract(Duration(minutes: _minutes));
    final end = now;

    final metrics = <String, num>{};
    for (final e in _metricCtrls.entries) {
      final v = double.tryParse(e.value.text.trim());
      if (v != null) metrics[e.key] = v;
    }

    final ss = PracticeSession(
      id: '',
      skillId: s.id,
      subSkillId: _subSkillId,
      mode: _mode,
      start: start,
      end: end,
      minutes: _minutes,
      objective: _objective.text.trim(),
      difficulty: _difficulty,
      energy: _energy,
      notes: _notes.text.trim(),
      metrics: metrics,
      nextMicroTask:
          _nextTask.text.trim().isEmpty ? null : _nextTask.text.trim(),
    );
    await svc.addSession(ss);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sesión guardada')));
      Navigator.pop(context);
    }
  }
}
