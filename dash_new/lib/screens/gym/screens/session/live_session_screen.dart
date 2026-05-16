import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';

import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:focuslane/design/ui/feedback/focus_feedback.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';

import 'session_summary_screen.dart';

class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({
    super.key,
    required this.svc,
    required this.routine,
    required this.day,
  });

  final GymFirestoreService svc;
  final Routine routine;
  final RoutineDay day;

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  final Map<String, List<SessionSet>> _performed = {};
  final Map<String, int> _restLeft = {};
  final Map<String, Timer?> _timers = {};
  final _notesCtrl = TextEditingController();
  late final DateTime _startAt;

  String _restNotificationId(String exerciseName) =>
      'ntf_gym_rest_${widget.routine.id}_${widget.day.id}_$exerciseName';

  @override
  void initState() {
    super.initState();
    _startAt = DateTime.now();
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer?.cancel();
    }
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _startRest(String exerciseName, int seconds) async {
    await NotificationsFacade.I.cancelByNotificationId(
      _restNotificationId(exerciseName),
    );

    _timers[exerciseName]?.cancel();
    setState(() => _restLeft[exerciseName] = seconds);

    final when = DateTime.now().add(Duration(seconds: seconds));
    final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';
    await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.gym,
        type: 'REST_TIMER_FINISHED',
        entity: NotificationEntityRef(
          module: NotificationModule.gym,
          kind: 'rest_timer',
          id: '${widget.routine.id}_${widget.day.id}_$exerciseName',
        ),
        content: const NotificationContent(
          title: 'Descanso terminado',
          body: 'Vuelve al ejercicio',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/gym',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.oneShot,
          scheduledAtUtc: when.toUtc(),
          timezone: when.timeZoneName,
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.localOnly,
          channel: AndroidChannelCatalog.gymReminders,
          priority: NotificationPriority.high,
        ),
        dedupeKey:
            'gym:rest:${widget.routine.id}:${widget.day.id}:$exerciseName',
        userId: uid,
        source: 'gym.live_session',
        notificationId: _restNotificationId(exerciseName),
      ),
    );

    _timers[exerciseName] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = (_restLeft[exerciseName] ?? 0) - 1;
      if (left <= 0) {
        timer.cancel();
        setState(() => _restLeft[exerciseName] = 0);
      } else {
        setState(() => _restLeft[exerciseName] = left);
      }
    });
  }

  Future<void> _stopRest(String exerciseName) async {
    _timers[exerciseName]?.cancel();
    setState(() => _restLeft[exerciseName] = 0);
    await NotificationsFacade.I.cancelByNotificationId(
      _restNotificationId(exerciseName),
    );
  }

  Future<void> _addSetDialog(String exerciseName) async {
    final last =
        (_performed[exerciseName] ?? []).isNotEmpty
            ? _performed[exerciseName]!.last
            : null;
    final weightCtrl = TextEditingController(
      text: last == null ? '' : last.weight.toStringAsFixed(1),
    );
    final repsCtrl = TextEditingController(
      text: last == null ? '' : last.reps.toString(),
    );
    final rpeCtrl = TextEditingController(
      text: last?.rpe == null ? '' : last!.rpe!.toStringAsFixed(1),
    );

    final result = await showDialog<SessionSet>(
      context: context,
      builder:
          (dialogContext) => _SetDialog(
            exerciseName: exerciseName,
            weightCtrl: weightCtrl,
            repsCtrl: repsCtrl,
            rpeCtrl: rpeCtrl,
            color: _routineTone(
              widget.routine,
              Theme.of(context).colorScheme.primary,
            ),
          ),
    );

    if (result == null) return;
    setState(() {
      _performed.putIfAbsent(exerciseName, () => []);
      _performed[exerciseName]!.add(result);
    });
  }

  double _sessionVolume() {
    return _performed.values.fold<double>(
      0,
      (total, sets) =>
          total +
          sets.fold<double>(0, (sum, set) => sum + set.weight * set.reps),
    );
  }

  Future<List<String>> _detectPRs(List<PerformedExercise> exercises) async {
    final prs = <String>[];
    for (final exercise in exercises) {
      final bestNow = exercise.bestE1rm;
      if (bestNow == null) continue;
      final historical = await widget.svc.bestE1rmForExercise(exercise.name);
      if (historical == null || bestNow > historical) {
        prs.add(exercise.name);
      }
    }
    return prs;
  }

  Future<void> _saveSession() async {
    final exercises =
        _performed.entries
            .map(
              (entry) => PerformedExercise(name: entry.key, sets: entry.value),
            )
            .toList();
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
    final tone = _routineTone(
      widget.routine,
      Theme.of(context).colorScheme.primary,
    );

    return AppShell(
      title: widget.day.name,
      subtitle: '${widget.routine.name} - sesión activa',
      activeRoute: AppRoutes.gymDashboard,
      actions: [
        FocusIconButton(
          icon: Icons.check_rounded,
          tooltip: 'Finalizar sesión',
          onPressed: _saveSession,
        ),
        const SizedBox(width: 10),
      ],
      child: StreamBuilder<List<RoutineExercise>>(
        stream: widget.svc.streamDayExercises(widget.routine.id, widget.day.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return PageContainer(
              child: FocusEmptyState(
                icon: Icons.error_outline_rounded,
                message: 'No se pudo cargar la sesión',
                subtitle: '${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = snapshot.data ?? const <RoutineExercise>[];
          final activeExercise = _activeExercise(exercises);
          final totalTargetSets = exercises.fold<int>(
            0,
            (sum, exercise) => sum + exercise.targetSets,
          );
          final completedSets = _performed.values.fold<int>(
            0,
            (sum, sets) => sum + sets.length,
          );
          final activeRest = _activeRest();

          return SingleChildScrollView(
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SessionHero(
                    routine: widget.routine,
                    day: widget.day,
                    activeExercise: activeExercise,
                    completedSets: completedSets,
                    totalTargetSets: totalTargetSets,
                    volume: _sessionVolume(),
                    color: tone,
                    onFinish: _saveSession,
                  ),
                  if (activeRest != null) ...[
                    const SizedBox(height: 16),
                    _RestFocusCard(
                      exerciseName: activeRest.exerciseName,
                      secondsLeft: activeRest.seconds,
                      color: tone,
                      onStop: () => _stopRest(activeRest.exerciseName),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (exercises.isEmpty)
                    FocusCard(
                      child: FocusEmptyState(
                        icon: Icons.fitness_center_rounded,
                        message: 'Sin ejercicios',
                        subtitle:
                            'Añade ejercicios en el detalle de la rutina antes de iniciar una sesión completa.',
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (var i = 0; i < exercises.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ExerciseSessionCard(
                              exercise: exercises[i],
                              index: i,
                              color: tone,
                              sets: _performed[exercises[i].name] ?? const [],
                              restLeft: _restLeft[exercises[i].name] ?? 0,
                              onAddSet: () => _addSetDialog(exercises[i].name),
                              onStartRest:
                                  () => _startRest(
                                    exercises[i].name,
                                    exercises[i].restSec ??
                                        widget.routine.restSecDefault,
                                  ),
                              onStopRest: () => _stopRest(exercises[i].name),
                              onCopySet:
                                  (set) => _copySet(exercises[i].name, set),
                              onDeleteSet:
                                  (setIndex) =>
                                      _deleteSet(exercises[i].name, setIndex),
                              onDeleteExercise:
                                  () => _deleteExercise(context, exercises[i]),
                            ),
                          ),
                        FocusCard(
                          child: FocusTextField(
                            label: 'Notas de la sesión',
                            hint: 'Sensaciones, ajustes o recordatorios',
                            controller: _notesCtrl,
                            prefixIcon: Icons.note_rounded,
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FocusPrimaryButton(
                          label: 'Finalizar sesión',
                          icon: Icons.check_rounded,
                          fullWidth: true,
                          color: tone,
                          onPressed: _saveSession,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  RoutineExercise? _activeExercise(List<RoutineExercise> exercises) {
    for (final exercise in exercises) {
      final done = _performed[exercise.name]?.length ?? 0;
      if (done < exercise.targetSets) return exercise;
    }
    return exercises.isEmpty ? null : exercises.last;
  }

  ({String exerciseName, int seconds})? _activeRest() {
    for (final entry in _restLeft.entries) {
      if (entry.value > 0)
        return (exerciseName: entry.key, seconds: entry.value);
    }
    return null;
  }

  void _copySet(String exerciseName, SessionSet set) {
    setState(() {
      _performed.putIfAbsent(exerciseName, () => []);
      _performed[exerciseName]!.add(
        SessionSet(weight: set.weight, reps: set.reps, rpe: set.rpe),
      );
    });
  }

  void _deleteSet(String exerciseName, int index) {
    setState(() {
      final sets = _performed[exerciseName];
      if (sets == null || index < 0 || index >= sets.length) return;
      sets.removeAt(index);
    });
  }

  Future<void> _deleteExercise(
    BuildContext context,
    RoutineExercise exercise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar ejercicio'),
            content: Text('¿Eliminar "${exercise.name}" de este día?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    await widget.svc.deleteRoutineExercise(
      widget.routine.id,
      widget.day.id,
      exercise.id,
    );
    setState(() {
      _performed.remove(exercise.name);
      _restLeft.remove(exercise.name);
    });
    await NotificationsFacade.I.cancelByNotificationId(
      _restNotificationId(exercise.name),
    );
    if (context.mounted) {
      FocusFeedback.showSuccess(context, 'Ejercicio eliminado');
    }
  }
}

class _SessionHero extends StatelessWidget {
  const _SessionHero({
    required this.routine,
    required this.day,
    required this.activeExercise,
    required this.completedSets,
    required this.totalTargetSets,
    required this.volume,
    required this.color,
    required this.onFinish,
  });

  final Routine routine;
  final RoutineDay day;
  final RoutineExercise? activeExercise;
  final int completedSets;
  final int totalTargetSets;
  final double volume;
  final Color color;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress =
        totalTargetSets == 0
            ? 0.0
            : (completedSets / totalTargetSets).clamp(0.0, 1.0);

    return FocusCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FocusBadge(label: 'Sesión activa', color: color),
              const SizedBox(height: 12),
              Text(
                day.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                activeExercise == null
                    ? routine.name
                    : 'Ejercicio actual: ${activeExercise!.name}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(
                    label: '$completedSets/$totalTargetSets series',
                    color: scheme.secondary,
                  ),
                  FocusBadge(
                    label: _volumeLabel(volume),
                    color: scheme.tertiary,
                  ),
                  FocusBadge(
                    label: '${routine.restSecDefault}s descanso base',
                    color: color,
                  ),
                ],
              ),
            ],
          );
          final ring = Column(
            children: [
              FocusProgressRing(
                value: progress,
                size: compact ? 122 : 150,
                strokeWidth: 11,
                color: color,
                label: '${(progress * 100).round()}%',
                subtitle: 'progreso',
              ),
              const SizedBox(height: 12),
              FocusPrimaryButton(
                label: 'Finalizar',
                icon: Icons.check_rounded,
                color: color,
                fullWidth: compact,
                onPressed: onFinish,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 18), Center(child: ring)],
            );
          }

          return Row(
            children: [Expanded(child: copy), const SizedBox(width: 24), ring],
          );
        },
      ),
    );
  }
}

class _RestFocusCard extends StatelessWidget {
  const _RestFocusCard({
    required this.exerciseName,
    required this.secondsLeft,
    required this.color,
    required this.onStop,
  });

  final String exerciseName;
  final int secondsLeft;
  final Color color;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');

    return FocusCard(
      backgroundColor: scheme.surfaceContainerLowest,
      borderSide: BorderSide(color: color.withValues(alpha: 0.28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Descanso',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exerciseName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            '$minutes:$seconds',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          FocusSecondaryButton(
            label: 'Parar descanso',
            icon: Icons.stop_rounded,
            onPressed: onStop,
          ),
        ],
      ),
    );
  }
}

class _ExerciseSessionCard extends StatelessWidget {
  const _ExerciseSessionCard({
    required this.exercise,
    required this.index,
    required this.color,
    required this.sets,
    required this.restLeft,
    required this.onAddSet,
    required this.onStartRest,
    required this.onStopRest,
    required this.onCopySet,
    required this.onDeleteSet,
    required this.onDeleteExercise,
  });

  final RoutineExercise exercise;
  final int index;
  final Color color;
  final List<SessionSet> sets;
  final int restLeft;
  final VoidCallback onAddSet;
  final VoidCallback onStartRest;
  final VoidCallback onStopRest;
  final ValueChanged<SessionSet> onCopySet;
  final ValueChanged<int> onDeleteSet;
  final VoidCallback onDeleteExercise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final complete = sets.length >= exercise.targetSets;
    final progress =
        exercise.targetSets == 0
            ? 0.0
            : (sets.length / exercise.targetSets).clamp(0.0, 1.0);

    return FocusCard(
      borderSide: BorderSide(
        color: complete ? color.withValues(alpha: 0.40) : scheme.outlineVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
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
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${exercise.targetSets} series x ${exercise.targetReps} repeticiones',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Acciones',
                onSelected: (value) {
                  if (value == 'delete') onDeleteExercise();
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          FocusProgressBar(value: progress, color: color),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FocusBadge(
                label: '${sets.length}/${exercise.targetSets} series',
                color: color,
              ),
              if (exercise.restSec != null)
                FocusBadge(
                  label: '${exercise.restSec}s descanso',
                  color: scheme.secondary,
                ),
              if ((exercise.tempo ?? '').isNotEmpty)
                FocusBadge(
                  label: 'Tempo ${exercise.tempo}',
                  color: scheme.tertiary,
                ),
              if (exercise.targetRPE != null)
                FocusBadge(
                  label: 'RPE ${exercise.targetRPE}',
                  color: scheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final add = FocusPrimaryButton(
                label: 'Completar serie',
                icon: Icons.add_rounded,
                fullWidth: compact,
                color: color,
                onPressed: onAddSet,
              );
              final rest = FocusSecondaryButton(
                label: restLeft > 0 ? '${restLeft}s' : 'Iniciar descanso',
                icon: Icons.timer_rounded,
                fullWidth: compact,
                onPressed: restLeft > 0 ? null : onStartRest,
              );
              final stop = FocusSecondaryButton(
                label: 'Parar',
                icon: Icons.stop_rounded,
                fullWidth: compact,
                onPressed: restLeft > 0 ? onStopRest : null,
              );

              if (compact) {
                return Column(
                  children: [
                    add,
                    const SizedBox(height: 10),
                    rest,
                    if (restLeft > 0) ...[const SizedBox(height: 10), stop],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: add),
                  const SizedBox(width: 10),
                  Expanded(child: rest),
                  if (restLeft > 0) ...[
                    const SizedBox(width: 10),
                    Expanded(child: stop),
                  ],
                ],
              );
            },
          ),
          if (sets.isEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                'Sin series registradas en este ejercicio.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Column(
              children: [
                for (var i = 0; i < sets.length; i++)
                  _SetRow(
                    index: i,
                    set: sets[i],
                    color: color,
                    onCopy: () => onCopySet(sets[i]),
                    onDelete: () => onDeleteSet(i),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.22)),
              ),
              child: Text(
                'Volumen: ${sets.fold<double>(0, (sum, set) => sum + set.weight * set.reps).toStringAsFixed(0)} kg',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.color,
    required this.onCopy,
    required this.onDelete,
  });

  final int index;
  final SessionSet set;
  final Color color;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                  '${set.weight.toStringAsFixed(1)} kg x ${set.reps} repeticiones',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'e1RM ${set.e1rm.toStringAsFixed(1)} kg${set.rpe == null ? '' : ' - RPE ${set.rpe}'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar serie',
            onPressed: onCopy,
            icon: const Icon(Icons.content_copy_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Eliminar serie',
            onPressed: onDelete,
            icon: Icon(Icons.delete_rounded, size: 20, color: scheme.error),
          ),
        ],
      ),
    );
  }
}

class _SetDialog extends StatelessWidget {
  const _SetDialog({
    required this.exerciseName,
    required this.weightCtrl,
    required this.repsCtrl,
    required this.rpeCtrl,
    required this.color,
  });

  final String exerciseName;
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController rpeCtrl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nueva serie',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exerciseName,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightCtrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Peso',
                      suffixText: 'kg',
                      prefixIcon: Icon(Icons.monitor_weight_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Repeticiones',
                      prefixIcon: Icon(Icons.repeat_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rpeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'RPE opcional',
                hintText: '1-10',
                prefixIcon: Icon(Icons.trending_up_rounded),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            final set = SessionSet(
              weight:
                  double.tryParse(weightCtrl.text.replaceAll(',', '.')) ?? 0,
              reps: int.tryParse(repsCtrl.text) ?? 0,
              rpe:
                  rpeCtrl.text.trim().isEmpty
                      ? null
                      : double.tryParse(rpeCtrl.text.replaceAll(',', '.')),
            );
            Navigator.pop(context, set);
          },
          style: FilledButton.styleFrom(backgroundColor: color),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

Color _routineTone(Routine routine, Color fallback) {
  final hex = routine.colorHex;
  if (hex == null || hex.trim().isEmpty) return fallback;
  try {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse(value, radix: 16));
  } catch (_) {
    return fallback;
  }
}

String _volumeLabel(double value) {
  if (value <= 0) return '0 kg';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} ton';
  return '${value.toStringAsFixed(0)} kg';
}
