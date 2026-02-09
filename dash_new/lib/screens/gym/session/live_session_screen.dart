import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gym_firestore_service.dart';
import '../services/gym_notification_service.dart';
import 'session_summary_screen.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';
import '../../../ui/components/focus_module_header.dart';

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
  final Map<String, List<SessionSet>> _performed = {};
  final Map<String, int> _restLeft = {};
  final Map<String, Timer?> _timers = {};
  final _notesCtrl = TextEditingController();
  late final DateTime _startAt;

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
    await NotificationService.I.cancel(_restNotifId(exName));

    _timers[exName]?.cancel();
    setState(() => _restLeft[exName] = seconds);

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
      } else {
        setState(() => _restLeft[exName] = left);
      }
    });
  }

  void _stopRest(String exName) async {
    _timers[exName]?.cancel();
    setState(() => _restLeft[exName] = 0);
    await NotificationService.I.cancel(_restNotifId(exName));
  }

  Future<void> _addSetDialog(String exName) async {
    final s = Theme.of(context).colorScheme;
    final last =
        (_performed[exName] ?? []).isNotEmpty ? _performed[exName]!.last : null;
    final wCtrl = TextEditingController(
      text: last?.weight.toStringAsFixed(1) ?? '',
    );
    final rCtrl = TextEditingController(text: last?.reps.toString() ?? '');
    final rpeCtrl = TextEditingController(text: last?.rpe?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.routine.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add_circle_rounded,
                    color: widget.routine.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva serie',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        exName,
                        style: TextStyle(
                          fontSize: 13,
                          color: s.onSurfaceVariant,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: wCtrl,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'Peso',
                          suffixText: 'kg',
                          prefixIcon: const Icon(Icons.fitness_center_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: s.surfaceContainerHighest.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'Reps',
                          prefixIcon: const Icon(Icons.repeat_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: s.surfaceContainerHighest.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rpeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'RPE (opcional)',
                    hintText: '1-10',
                    prefixIcon: const Icon(Icons.trending_up_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: s.surfaceContainerHighest.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Añadir'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.routine.color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
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
    final exercises =
        _performed.entries.map((kv) {
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

    await GymNotificationService.I.scheduleInactivityReminder();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(session: doc, svc: widget.svc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    final s = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: false,
            pinned: true,
            expandedHeight: 160,
                leading: FocusModuleHeader.buildLeading(
                  context,
                  mode: FocusModuleLeadingMode.backToModuleDashboard,
                  backRouteName: AppRoutes.gymDashboard,
                ),
                leadingWidth: 96,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16,
                bottom: 16,
                right: 16,
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      widget.day.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_filled_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'En vivo',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.routine.color,
                      widget.routine.color.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: 160,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  onPressed: _saveSession,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text('Guardar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: widget.routine.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<List<RoutineExercise>>(
              stream: svc.streamDayExercises(widget.routine.id, widget.day.id),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final exs = snap.data!;
                if (exs.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: s.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 64,
                          color: s.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin ejercicios',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: s.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Añade ejercicios a este día para empezar',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: s.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (int i = 0; i < exs.length; i++)
                      _exerciseCard(exs[i], i)
                          .animate()
                          .fadeIn(delay: (50 * i).ms, duration: 400.ms)
                          .slideY(begin: 0.2, end: 0),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Notas de la sesión',
                          hintText: 'Cómo te sentiste, observaciones...',
                          prefixIcon: const Icon(Icons.note_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: s.surfaceContainerHighest.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(RoutineExercise e, int index) {
    final exName = e.name;
    final sets = _performed[exName] ?? const [];
    final restLeft = _restLeft[exName] ?? 0;
    final s = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [s.surfaceContainerHighest, s.surfaceContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.routine.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.routine.color,
                        widget.routine.color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
                        exName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: s.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildMetaChip(
                            '${e.targetSets} × ${e.targetReps}',
                            Icons.repeat_rounded,
                            s,
                          ),
                          if (e.restSec != null)
                            _buildMetaChip(
                              '${e.restSec}s',
                              Icons.timer_rounded,
                              s,
                            ),
                          if ((e.tempo ?? '').isNotEmpty)
                            _buildMetaChip(e.tempo!, Icons.speed_rounded, s),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: s.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) async {
                    if (v == 'del') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              title: Text(
                                'Eliminar ejercicio',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              content: Text('¿Eliminar "$exName" de este día?'),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: s.error,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                      );
                      if (ok == true) {
                        await widget.svc.deleteRoutineExercise(
                          widget.routine.id,
                          widget.day.id,
                          e.id,
                        );
                        setState(() {
                          _performed.remove(exName);
                          _restLeft.remove(exName);
                        });
                        await NotificationService.I.cancel(
                          _restNotifId(exName),
                        );
                      }
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(
                          value: 'del',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 20),
                              SizedBox(width: 12),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            if (e.targetRPE != null || e.targetPercent1RM != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (e.targetRPE != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: s.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'RPE ${e.targetRPE}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: s.onTertiaryContainer,
                        ),
                      ),
                    ),
                  if (e.targetRPE != null && e.targetPercent1RM != null)
                    const SizedBox(width: 8),
                  if (e.targetPercent1RM != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: s.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${e.targetPercent1RM}% 1RM',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: s.onSecondaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Serie'),
                  onPressed: () => _addSetDialog(exName),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.routine.color,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: Icon(
                    restLeft > 0 ? Icons.timer_rounded : Icons.timer_outlined,
                    size: 20,
                  ),
                  label: Text(restLeft > 0 ? '${restLeft}s' : 'Descansar'),
                  onPressed:
                      restLeft > 0
                          ? null
                          : () => _startRest(exName, e.restSec ?? 90),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (restLeft > 0)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.stop_rounded, size: 20),
                    label: const Text('Parar'),
                    onPressed: () => _stopRest(exName),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
            if (sets.isEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Añade tu primera serie',
                  style: TextStyle(
                    fontSize: 14,
                    color: s.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: s.surfaceContainerHigh.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < sets.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: s.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: widget.routine.color.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: widget.routine.color,
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
                                    '${sets[i].weight.toStringAsFixed(1)} kg × ${sets[i].reps} reps',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: s.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'e1RM: ${sets[i].e1rm.toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: s.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.content_copy_rounded,
                                size: 20,
                              ),
                              tooltip: 'Copiar',
                              onPressed: () {
                                setState(() {
                                  final set = sets[i];
                                  _performed.putIfAbsent(exName, () => []);
                                  _performed[exName]!.add(
                                    SessionSet(
                                      weight: set.weight,
                                      reps: set.reps,
                                      rpe: set.rpe,
                                    ),
                                  );
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_rounded,
                                size: 20,
                                color: s.error,
                              ),
                              tooltip: 'Eliminar',
                              onPressed: () {
                                setState(() {
                                  _performed[exName]!.removeAt(i);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.routine.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.routine.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 18,
                      color: widget.routine.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Volumen: ${sets.fold<double>(0, (a, s) => a + s.weight * s.reps).toStringAsFixed(0)} kg',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.routine.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label, IconData icon, ColorScheme s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: s.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: s.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
