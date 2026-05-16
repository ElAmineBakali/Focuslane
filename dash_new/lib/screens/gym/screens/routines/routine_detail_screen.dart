import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/feedback/focus_feedback.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/gym/screens/analytics/gym_analytics_screen.dart';
import 'package:focuslane/screens/gym/screens/session/live_session_screen.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/gym/widgets/exercise_picker_sheet.dart';

class RoutineDetailScreen extends StatelessWidget {
  const RoutineDetailScreen({
    super.key,
    required this.svc,
    required this.routine,
  });

  final GymFirestoreService svc;
  final Routine routine;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: routine.name,
      subtitle: 'Detalle de rutina, días y ejercicios.',
      activeRoute: AppRoutes.gymDashboard,
      actions: [
        FocusIconButton(
          icon: Icons.analytics_rounded,
          tooltip: 'Ver progreso',
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GymAnalyticsScreen(svc: svc)),
              ),
        ),
        const SizedBox(width: 10),
        FocusIconButton(
          icon: Icons.add_rounded,
          tooltip: 'Añadir día',
          onPressed: () => _createDaySheet(context),
        ),
        const SizedBox(width: 10),
      ],
      child: _RoutineDetailContent(svc: svc, routine: routine),
    );
  }

  Future<void> _createDaySheet(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => _DayFormSheet(
            title: 'Nuevo día',
            subtitle: routine.name,
            controller: controller,
          ),
    );

    final name = result?.trim() ?? '';
    if (name.isEmpty) return;

    final days =
        await svc.root
            .collection('routines')
            .doc(routine.id)
            .collection('days')
            .get();
    final nextOrder =
        days.docs
            .map((doc) => (doc.data()['order'] as num?)?.toInt() ?? 0)
            .fold<int>(0, (max, value) => value > max ? value : max) +
        1;

    await svc.addDay(routine.id, name, order: nextOrder);
    if (context.mounted) {
      FocusFeedback.showSuccess(context, 'Día creado');
    }
  }
}

class _RoutineDetailContent extends StatelessWidget {
  const _RoutineDetailContent({required this.svc, required this.routine});

  final GymFirestoreService svc;
  final Routine routine;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoutineDay>>(
      stream: svc.streamDays(routine.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PageContainer(
            child: FocusEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudo cargar la rutina',
              subtitle: '${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final days = snapshot.data ?? const <RoutineDay>[];

        return SingleChildScrollView(
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoutineHero(routine: routine, days: days),
                const SizedBox(height: 16),
                FocusSectionHeader(
                  icon: Icons.calendar_view_week_rounded,
                  title: 'Días de entrenamiento',
                  subtitle: '${days.length} días configurados',
                  trailing: FocusPrimaryButton(
                    label: 'Añadir día',
                    icon: Icons.add_rounded,
                    onPressed: () => _createDaySheet(context),
                  ),
                ),
                const SizedBox(height: 16),
                if (days.isEmpty)
                  FocusCard(
                    child: FocusEmptyState(
                      icon: Icons.calendar_today_rounded,
                      message: 'Sin días todavía',
                      subtitle:
                          'Añade el primer día para organizar ejercicios y descansos.',
                      actionLabel: 'Añadir día',
                      onAction: () => _createDaySheet(context),
                    ),
                  )
                else
                  ResponsiveGrid(
                    minItemWidth: 360,
                    spacing: 16,
                    children: [
                      for (var i = 0; i < days.length; i++)
                        _RoutineDayCard(
                          svc: svc,
                          routine: routine,
                          day: days[i],
                          index: i,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createDaySheet(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _DayFormSheet(
            title: 'Nuevo día',
            subtitle: routine.name,
            controller: controller,
          ),
    );

    final name = result?.trim() ?? '';
    if (name.isEmpty) return;

    final col = svc.root
        .collection('routines')
        .doc(routine.id)
        .collection('days');
    final snap = await col.get();
    final nextOrder =
        snap.docs
            .map((doc) => (doc.data()['order'] as num?)?.toInt() ?? 0)
            .fold<int>(0, (max, value) => value > max ? value : max) +
        1;

    await svc.addDay(routine.id, name, order: nextOrder);
    if (context.mounted) {
      FocusFeedback.showSuccess(context, 'Día creado');
    }
  }
}

class _RoutineHero extends StatelessWidget {
  const _RoutineHero({required this.routine, required this.days});

  final Routine routine;
  final List<RoutineDay> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = _routineTone(routine, scheme.primary);

    return FocusCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(
                    label: routine.isDefault ? 'Rutina principal' : 'Rutina',
                    color: tone,
                  ),
                  FocusBadge(
                    label: _splitLabel(routine.splitType),
                    color: scheme.secondary,
                  ),
                  FocusBadge(
                    label: '${routine.restSecDefault}s descanso',
                    color: scheme.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                routine.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (routine.description ?? '').isEmpty
                    ? 'Estructura tus sesiones con ejercicios, series y descanso.'
                    : routine.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );

          final mark = Container(
            width: compact ? double.infinity : 180,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tone.withValues(alpha: 0.24)),
            ),
            child: Column(
              children: [
                Icon(Icons.fitness_center_rounded, color: tone, size: 36),
                const SizedBox(height: 10),
                Text(
                  '${days.length}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'días activos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 16), mark],
            );
          }

          return Row(
            children: [Expanded(child: copy), const SizedBox(width: 20), mark],
          );
        },
      ),
    );
  }
}

class _RoutineDayCard extends StatelessWidget {
  const _RoutineDayCard({
    required this.svc,
    required this.routine,
    required this.day,
    required this.index,
  });

  final GymFirestoreService svc;
  final Routine routine;
  final RoutineDay day;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = _routineTone(routine, scheme.primary);

    return StreamBuilder<List<RoutineExercise>>(
      stream: svc.streamDayExercises(routine.id, day.id),
      builder: (context, snapshot) {
        final exercises = snapshot.data ?? const <RoutineExercise>[];

        return FocusCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'D${index + 1}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: tone,
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
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        _LastDoneSubtitle(
                          svc: svc,
                          routineId: routine.id,
                          dayId: day.id,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Acciones del día',
                    onSelected: (value) => _handleDayMenu(context, value),
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicar'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (exercises.isEmpty)
                _EmptyExercisePreview(
                  onAdd: () => _addExercise(context, exercises.length),
                )
              else
                Column(
                  children: [
                    for (final exercise in exercises.take(4))
                      _ExercisePreviewTile(exercise: exercise, color: tone),
                    if (exercises.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+ ${exercises.length - 4} ejercicios más',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  final start = FocusPrimaryButton(
                    label: 'Iniciar sesión',
                    icon: Icons.play_arrow_rounded,
                    fullWidth: compact,
                    color: tone,
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => LiveSessionScreen(
                                  svc: svc,
                                  routine: routine,
                                  day: day,
                                ),
                          ),
                        ),
                  );
                  final add = FocusSecondaryButton(
                    label: 'Añadir ejercicio',
                    icon: Icons.add_rounded,
                    fullWidth: compact,
                    onPressed: () => _addExercise(context, exercises.length),
                  );
                  if (compact) {
                    return Column(
                      children: [start, const SizedBox(height: 10), add],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: start),
                      const SizedBox(width: 10),
                      Expanded(child: add),
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

  Future<void> _addExercise(BuildContext context, int order) async {
    final exercise = await showModalBottomSheet<RoutineExercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ExercisePickerSheet(
            order: order,
            restDefault: routine.restSecDefault,
          ),
    );
    if (exercise == null) return;

    await svc.addRoutineExercise(routine.id, day.id, exercise);
    if (context.mounted) {
      FocusFeedback.showSuccess(context, 'Ejercicio añadido');
    }
  }

  Future<void> _handleDayMenu(BuildContext context, String value) async {
    if (value == 'duplicate') {
      await svc.duplicateDay(routine.id, day.id);
      if (context.mounted) FocusFeedback.showSuccess(context, 'Día duplicado');
      return;
    }
    if (value == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Eliminar día'),
              content: Text('¿Eliminar "${day.name}" y sus ejercicios?'),
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

      if (confirmed == true) {
        await svc.deleteDayCascade(routine.id, day.id);
        if (context.mounted)
          FocusFeedback.showSuccess(context, 'Día eliminado');
      }
    }
  }
}

class _ExercisePreviewTile extends StatelessWidget {
  const _ExercisePreviewTile({required this.exercise, required this.color});

  final RoutineExercise exercise;
  final Color color;

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
          Icon(Icons.fitness_center_rounded, color: color, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
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
          if (exercise.restSec != null)
            FocusBadge(label: '${exercise.restSec}s', color: color),
        ],
      ),
    );
  }
}

class _EmptyExercisePreview extends StatelessWidget {
  const _EmptyExercisePreview({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.add_circle_outline_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sin ejercicios. Añade el primero para preparar esta sesión.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          TextButton(onPressed: onAdd, child: const Text('Añadir')),
        ],
      ),
    );
  }
}

class _DayFormSheet extends StatelessWidget {
  const _DayFormSheet({
    required this.title,
    required this.subtitle,
    required this.controller,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FocusTextField(
                label: 'Nombre del día',
                hint: 'Pierna, push, torso...',
                controller: controller,
                prefixIcon: Icons.label_rounded,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FocusSecondaryButton(
                      label: 'Cancelar',
                      fullWidth: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FocusPrimaryButton(
                      label: 'Crear día',
                      icon: Icons.check_rounded,
                      fullWidth: true,
                      onPressed: () => Navigator.pop(context, controller.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastDoneSubtitle extends StatelessWidget {
  const _LastDoneSubtitle({
    required this.svc,
    required this.routineId,
    required this.dayId,
  });

  final GymFirestoreService svc;
  final String routineId;
  final String dayId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dayRef = svc.root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: dayRef.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final date =
            _readDate(data?['lastDone']) ?? _readDate(data?['lastDoneLocal']);

        if (date == null) {
          return Text(
            'Sin sesiones todavía',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          );
        }

        final now = DateTime.now();
        final sameDay =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
        return Row(
          children: [
            Icon(
              sameDay ? Icons.check_circle_rounded : Icons.history_rounded,
              size: 14,
              color: sameDay ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                sameDay ? 'Hecho hoy' : 'Hace ${_formatTimeDiff(date, now)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: sameDay ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: sameDay ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value)?.toLocal();
  return null;
}

String _formatTimeDiff(DateTime past, DateTime now) {
  final diff = now.difference(past);
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  if (diff.inMinutes > 0) return '${diff.inMinutes}min';
  return 'un momento';
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

String _splitLabel(String split) {
  switch (split) {
    case 'PPL':
      return 'PPL';
    case 'UL':
      return 'Torso/pierna';
    case 'FB':
      return 'Cuerpo completo';
    default:
      return 'Personalizada';
  }
}
