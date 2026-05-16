import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/feedback/focus_feedback.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';

class SessionSummaryScreen extends StatefulWidget {
  const SessionSummaryScreen({super.key, required this.session, this.svc});

  final SessionDoc session;
  final GymFirestoreService? svc;

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  late int _energyValue;
  late int _fatigueValue;
  late int _motivationValue;
  late bool _feelingsSaved;

  @override
  void initState() {
    super.initState();
    _energyValue = widget.session.feelingEnergy ?? 3;
    _fatigueValue = widget.session.feelingFatigue ?? 3;
    _motivationValue = widget.session.feelingMotivation ?? 3;
    _feelingsSaved = widget.session.feelingEnergy != null;
  }

  Future<void> _saveFeelings() async {
    final service = widget.svc;
    if (service == null) return;

    try {
      await service.updateSessionFeelings(
        widget.session.id,
        _energyValue,
        _fatigueValue,
        _motivationValue,
      );
      if (!mounted) return;
      setState(() => _feelingsSaved = true);
      FocusFeedback.showSuccess(context, 'Sensaciones guardadas');
    } catch (error) {
      if (mounted) FocusFeedback.showError(context, 'Error al guardar: $error');
    }
  }

  Future<void> _deleteSession() async {
    final service = widget.svc;
    if (service == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar sesión'),
            content: const Text(
              'La sesión se eliminará del historial y se actualizarán las estadísticas.',
            ),
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

    try {
      await service.deleteSession(widget.session.id);
      if (!mounted) return;
      Navigator.pop(context);
      FocusFeedback.showSuccess(context, 'Sesión eliminada');
    } catch (error) {
      if (mounted)
        FocusFeedback.showError(context, 'Error al eliminar: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Resumen de sesión',
      subtitle: '${widget.session.routineName} - ${widget.session.dayName}',
      activeRoute: AppRoutes.gymDashboard,
      actions: [
        if (widget.svc != null)
          FocusIconButton(
            icon: Icons.delete_forever_rounded,
            tooltip: 'Eliminar sesión',
            onPressed: _deleteSession,
          ),
        const SizedBox(width: 10),
      ],
      child: SingleChildScrollView(
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryHero(session: widget.session),
              const SizedBox(height: 16),
              ResponsiveGrid(
                minItemWidth: 220,
                spacing: 16,
                children: [
                  FocusStatCard(
                    title: 'Volumen total',
                    value: _volumeLabel(widget.session.volumeKg),
                    subtitle: 'Carga acumulada',
                    icon: Icons.monitor_weight_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  FocusStatCard(
                    title: 'Series',
                    value:
                        '${widget.session.exercises.fold<int>(0, (sum, exercise) => sum + exercise.sets.length)}',
                    subtitle: '${widget.session.exercises.length} ejercicios',
                    icon: Icons.repeat_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  FocusStatCard(
                    title: 'Duración',
                    value: '${widget.session.durationMin ?? 0} min',
                    subtitle: 'Tiempo registrado',
                    icon: Icons.timer_rounded,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ],
              ),
              if (widget.session.prList.isNotEmpty) ...[
                const SizedBox(height: 16),
                _PrCard(prs: widget.session.prList),
              ],
              if ((widget.session.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                FocusCard(
                  child: FocusSectionHeader(
                    title: 'Notas',
                    subtitle: widget.session.notes!,
                    icon: Icons.note_rounded,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _ExercisesSummary(exercises: widget.session.exercises),
              const SizedBox(height: 16),
              _FeelingsCard(
                saved: _feelingsSaved,
                energy: _energyValue,
                fatigue: _fatigueValue,
                motivation: _motivationValue,
                canSave: widget.svc != null,
                onEnergyChanged:
                    (value) => setState(() => _energyValue = value),
                onFatigueChanged:
                    (value) => setState(() => _fatigueValue = value),
                onMotivationChanged:
                    (value) => setState(() => _motivationValue = value),
                onSave: _saveFeelings,
              ),
              const SizedBox(height: 18),
              FocusPrimaryButton(
                label: 'Listo',
                icon: Icons.check_rounded,
                fullWidth: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.session});

  final SessionDoc session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FocusCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FocusBadge(label: 'Sesión finalizada', color: scheme.primary),
              const SizedBox(height: 12),
              Text(
                session.dayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                session.routineName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat(
                  'EEEE, d MMMM yyyy - HH:mm',
                  'es_ES',
                ).format(session.date),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
          final icon = Container(
            width: compact ? double.infinity : 154,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
            ),
            child: Icon(
              Icons.verified_rounded,
              color: scheme.primary,
              size: compact ? 46 : 58,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 16), icon],
            );
          }

          return Row(
            children: [Expanded(child: copy), const SizedBox(width: 20), icon],
          );
        },
      ),
    );
  }
}

class _PrCard extends StatelessWidget {
  const _PrCard({required this.prs});

  final List<String> prs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FocusCard(
      backgroundColor: scheme.tertiaryContainer.withValues(alpha: 0.32),
      borderSide: BorderSide(color: scheme.tertiary.withValues(alpha: 0.24)),
      child: FocusSectionHeader(
        title: 'Nuevas marcas personales',
        subtitle: prs.join(', '),
        icon: Icons.emoji_events_rounded,
      ),
    );
  }
}

class _ExercisesSummary extends StatelessWidget {
  const _ExercisesSummary({required this.exercises});

  final List<PerformedExercise> exercises;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FocusSectionHeader(
            title: 'Detalle por ejercicio',
            subtitle: 'Series, peso y volumen',
            icon: Icons.list_alt_rounded,
          ),
          const SizedBox(height: 16),
          if (exercises.isEmpty)
            const FocusEmptyState(
              icon: Icons.fitness_center_rounded,
              message: 'Sin ejercicios registrados',
            )
          else
            Column(
              children: [
                for (final exercise in exercises)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < exercise.sets.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Serie ${i + 1}: ${exercise.sets[i].weight.toStringAsFixed(1)} kg x ${exercise.sets[i].reps} repeticiones${exercise.sets[i].rpe != null ? ' - RPE ${exercise.sets[i].rpe}' : ''}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        const SizedBox(height: 6),
                        FocusBadge(
                          label:
                              'Volumen ${exercise.volumeKg.toStringAsFixed(0)} kg${exercise.bestE1rm != null ? ' - e1RM ${exercise.bestE1rm!.toStringAsFixed(1)} kg' : ''}',
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeelingsCard extends StatelessWidget {
  const _FeelingsCard({
    required this.saved,
    required this.energy,
    required this.fatigue,
    required this.motivation,
    required this.canSave,
    required this.onEnergyChanged,
    required this.onFatigueChanged,
    required this.onMotivationChanged,
    required this.onSave,
  });

  final bool saved;
  final int energy;
  final int fatigue;
  final int motivation;
  final bool canSave;
  final ValueChanged<int> onEnergyChanged;
  final ValueChanged<int> onFatigueChanged;
  final ValueChanged<int> onMotivationChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: saved ? 'Sensaciones registradas' : '¿Cómo te sentiste?',
            subtitle: 'Energía, fatiga y motivación',
            icon: Icons.psychology_rounded,
          ),
          const SizedBox(height: 16),
          _FeelingSlider(
            label: 'Energía',
            value: energy,
            icon: Icons.bolt_rounded,
            onChanged: onEnergyChanged,
          ),
          _FeelingSlider(
            label: 'Fatiga',
            value: fatigue,
            icon: Icons.fitness_center_rounded,
            onChanged: onFatigueChanged,
          ),
          _FeelingSlider(
            label: 'Motivación',
            value: motivation,
            icon: Icons.favorite_rounded,
            onChanged: onMotivationChanged,
          ),
          if (canSave) ...[
            const SizedBox(height: 12),
            FocusPrimaryButton(
              label: saved ? 'Actualizar sensaciones' : 'Guardar sensaciones',
              icon: Icons.save_rounded,
              fullWidth: true,
              onPressed: onSave,
            ),
          ],
        ],
      ),
    );
  }
}

class _FeelingSlider extends StatelessWidget {
  const _FeelingSlider({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final int value;
  final IconData icon;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FocusBadge(label: '$value/5', color: scheme.primary),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toString(),
            onChanged: (newValue) => onChanged(newValue.round()),
          ),
        ],
      ),
    );
  }
}

String _volumeLabel(double value) {
  if (value <= 0) return '0 kg';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} ton';
  return '${value.toStringAsFixed(0)} kg';
}
