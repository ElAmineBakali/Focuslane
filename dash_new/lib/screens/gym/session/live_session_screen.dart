import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gym_firestore_service.dart';
import '../models/gym_models.dart';
import 'session_summary_screen.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart'; // 🔔

class LiveSessionScreen extends StatefulWidget {
  final GymFirestoreService svc;
  final Routine routine;
  final RoutineDay day;

  const LiveSessionScreen({
    super.key,
    required this.svc,
    required this.routine,
    required this.day,
  });

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  final Map<String, List<SessionSet>> _performed = {}; // exName -> sets
  final Map<String, int> _restLeft = {}; // exName -> seconds
  final Map<String, Timer?> _timers = {};
  final _notesCtrl = TextEditingController();
  late final DateTime _startAt;

  // ---- IDs fijos para notificaciones programadas ----
  static const int _inactivityId = 22001; // aviso X días sin entrenar
  static const int _inactivityDays = 3;   // puedes cambiarlo rápido aquí

  int _restNotifId(String exName) =>
      ('gym_rest_${widget.routine.id}_${widget.day.id}_$exName').hashCode;

  @override
  void initState() {
    super.initState();
    _startAt = DateTime.now();
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t?.cancel();
    }
    _notesCtrl.dispose();
    super.dispose();
  }

  void _startRest(String exName, int seconds) async {
    // cancela notificación previa de ese ejercicio si la hubiera
    await NotificationService.I.cancel(_restNotifId(exName));

    _timers[exName]?.cancel();
    setState(() => _restLeft[exName] = seconds);

    // 🔔 programa fin de descanso (exacto)
    final when = DateTime.now().add(Duration(seconds: seconds));
    await NotificationService.I.scheduleOnce(
      id: _restNotifId(exName),
      title: 'Descanso terminado',
      body: 'Siguiente serie: $exName',
      whenLocal: when,
      useExact: true,
    );

    _timers[exName] = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = (_restLeft[exName] ?? 0) - 1;
      if (left <= 0) {
        t.cancel();
        setState(() => _restLeft[exName] = 0);
        // No cancelamos la notificación: debe sonar aunque cierres la app.
      } else {
        setState(() => _restLeft[exName] = left);
      }
    });
  }

  void _stopRest(String exName) async {
    _timers[exName]?.cancel();
    setState(() => _restLeft[exName] = 0);
    // 🔔 si paras el descanso, cancelamos la noti
    await NotificationService.I.cancel(_restNotifId(exName));
  }

  Future<void> _addSetDialog(String exName) async {
    final last = (_performed[exName] ?? []).isNotEmpty ? _performed[exName]!.last : null;
    final wCtrl = TextEditingController(text: last?.weight.toStringAsFixed(1) ?? '');
    final rCtrl = TextEditingController(text: last?.reps.toString() ?? '');
    final rpeCtrl = TextEditingController(text: last?.rpe?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Añadir serie – $exName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: wCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Peso (kg)')),
            TextField(controller: rCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps')),
            TextField(controller: rpeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'RPE (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Añadir')),
        ],
      ),
    );
    if (ok == true) {
      final set = SessionSet(
        weight: double.tryParse(wCtrl.text) ?? 0,
        reps: int.tryParse(rCtrl.text) ?? 0,
        rpe: rpeCtrl.text.trim().isEmpty ? null : double.tryParse(rpeCtrl.text),
      );
      setState(() {
        _performed.putIfAbsent(exName, () => []);
        _performed[exName]!.add(set);
      });
    }
  }

  double _sessionVolume() {
    return _performed.values.fold<double>(
      0,
      (a, sets) => a + sets.fold<double>(0, (x, s) => x + s.weight * s.reps),
    );
  }

  Future<List<String>> _detectPRs(List<PerformedExercise> list) async {
    final prs = <String>[];
    for (final e in list) {
      final bestNow = e.bestE1rm;
      if (bestNow == null) continue;
      final hist = await widget.svc.bestE1rmForExercise(e.name);
      if (hist == null || bestNow > hist) {
        prs.add(e.name);
      }
    }
    return prs;
  }

  Future<void> _saveSession() async {
    final exercises = _performed.entries.map((kv) {
      return PerformedExercise(name: kv.key, sets: kv.value);
    }).toList();

    final prs = await _detectPRs(exercises);

    final minutes = DateTime.now().difference(_startAt).inMinutes;

    final doc = SessionDoc(
      id: '',
      routineId: widget.routine.id,
      routineName: widget.routine.name,
      dayId: widget.day.id,
      dayName: widget.day.name,
      date: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      durationMin: minutes,
      volumeKg: _sessionVolume(),
      prList: prs,
      exercises: exercises,
    );

    await widget.svc.saveSession(doc);
    await widget.svc.markDayCompleted(widget.routine.id, widget.day.id);

    // 🔔 Reprograma aviso de inactividad (X días sin entrenar)
    await NotificationService.I.cancel(_inactivityId);
    final base = DateTime.now().add(Duration(days: _inactivityDays));
    final at = DateTime(base.year, base.month, base.day, 10, 0); // 10:00
    await NotificationService.I.scheduleOnce(
      id: _inactivityId,
      title: 'Vuelve al gym',
      body: 'Llevas $_inactivityDays días sin entrenar. ¡Toca sesión!',
      whenLocal: at,
      useExact: false,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(session: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    return Scaffold(
      appBar: AppBar(
        title: Text('Sesión – ${widget.day.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar sesión',
            onPressed: _saveSession,
          ),
        ],
      ),
      body: StreamBuilder<List<RoutineExercise>>(
        stream: svc.streamDayExercises(widget.routine.id, widget.day.id),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final exs = snap.data!;
          if (exs.isEmpty) return const Center(child: Text('Añade ejercicios a este día'));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final e in exs) _exerciseCard(e),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notas de la sesión'),
                maxLines: 3,
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _exerciseCard(RoutineExercise e) {
    final exName = e.name;
    final sets = _performed[exName] ?? const [];
    final restLeft = _restLeft[exName] ?? 0;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  exName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar ejercicio del día',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Eliminar ejercicio'),
                      content: Text('¿Eliminar "$exName" de este día?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await widget.svc.deleteRoutineExercise(widget.routine.id, widget.day.id, e.id);
                    setState(() {
                      _performed.remove(exName);
                      _restLeft.remove(exName);
                    });
                    await NotificationService.I.cancel(_restNotifId(exName));
                  }
                },
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              ),
              if (e.targetRPE != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(label: Text('RPE ${e.targetRPE}')),
                ),
              if (e.targetPercent1RM != null)
                Chip(label: Text('%1RM ${e.targetPercent1RM}')),
            ]),
            const SizedBox(height: 4),
            Text('${e.targetSets} x ${e.targetReps}'
                '${e.restSec != null ? ' • Descanso: ${e.restSec}s' : ''}'
                '${(e.tempo ?? '').isNotEmpty ? ' • Tempo: ${e.tempo}' : ''}'),
            const SizedBox(height: 8),
            Wrap(
              runSpacing: 8,
              spacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir serie'),
                  onPressed: () => _addSetDialog(exName),
                ),
                OutlinedButton(
                  onPressed: () => _startRest(exName, e.restSec ?? 90),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary,
                    side: BorderSide(color: theme.colorScheme.secondary),
                  ),
                  child: Text(restLeft > 0 ? 'Descanso: ${restLeft}s' : 'Iniciar descanso'),
                ),
                if (restLeft > 0)
                  TextButton(
                    onPressed: () => _stopRest(exName),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                    ),
                    child: const Text('Parar'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (sets.isEmpty)
              const Text('Sin series aún.')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < sets.length; i++)
                    ListTile(
                      dense: true,
                      leading: Text('#${i + 1}'),
                      title: Text('${sets[i].weight.toStringAsFixed(1)} kg  ×  ${sets[i].reps} reps'),
                      subtitle: Text('E1RM: ${sets[i].e1rm.toStringAsFixed(1)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copiar a nueva serie',
                            onPressed: () {
                              setState(() {
                                final s = sets[i];
                                _performed.putIfAbsent(exName, () => []);
                                _performed[exName]!.add(SessionSet(weight: s.weight, reps: s.reps, rpe: s.rpe));
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: 'Eliminar serie',
                            onPressed: () {
                              setState(() {
                                _performed[exName]!.removeAt(i);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Volumen $exName: ${sets.fold<double>(0, (a, s) => a + s.weight * s.reps).toStringAsFixed(1)} kg',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
