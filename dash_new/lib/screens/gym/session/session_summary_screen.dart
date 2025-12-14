import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gym_models.dart';
import '../services/gym_firestore_service.dart';

class SessionSummaryScreen extends StatefulWidget {
  final SessionDoc session;
  final GymFirestoreService? svc;

  const SessionSummaryScreen({
    super.key,
    required this.session,
    this.svc,
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  // Valores de sensaciones (por defecto si ya existen)
  late int _energyValue;
  late int _fatigueValue;
  late int _motivationValue;
  bool _feelingsSaved = false;

  @override
  void initState() {
    super.initState();
    _energyValue = widget.session.feelingEnergy ?? 3;
    _fatigueValue = widget.session.feelingFatigue ?? 3;
    _motivationValue = widget.session.feelingMotivation ?? 3;
    _feelingsSaved = widget.session.feelingEnergy != null;
  }

  Future<void> _saveFeelings() async {
    if (widget.svc == null) return;

    try {
      await widget.svc!.updateSessionFeelings(
        widget.session.id,
        _energyValue,
        _fatigueValue,
        _motivationValue,
      );
      setState(() => _feelingsSaved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sensaciones guardadas'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSession() async {
    if (widget.svc == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar sesión?'),
        content: const Text(
          'Esta acción eliminará la sesión del historial y actualizará las estadísticas. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.svc!.deleteSession(widget.session.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sesión eliminada'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de sesión'),
        actions: [
          if (widget.svc != null)
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded),
              tooltip: 'Eliminar sesión',
              onPressed: _deleteSession,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${widget.session.routineName} — ${widget.session.dayName}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Fecha: ${widget.session.date} • Duración: ${widget.session.durationMin ?? 0} min',
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.scale),
              title: Text(
                'Volumen total: ${widget.session.volumeKg.toStringAsFixed(1)} kg',
              ),
              subtitle: Text(
                'Series: ${widget.session.exercises.fold<int>(0, (a, e) => a + e.sets.length)}',
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.session.prList.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events),
                title: const Text('¡Nuevos PRs!'),
                subtitle: Text(widget.session.prList.join(', ')),
              ),
            ),
          const SizedBox(height: 8),
          if ((widget.session.notes ?? '').isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.note),
                title: const Text('Notas'),
                subtitle: Text(widget.session.notes!),
              ),
            ),
          const SizedBox(height: 12),
          const Text('Detalle por ejercicio'),
          const SizedBox(height: 4),
          ...widget.session.exercises.map(
            (e) => Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    for (int i = 0; i < e.sets.length; i++)
                      Text(
                        'Set ${i + 1}: ${e.sets[i].weight.toStringAsFixed(1)} kg × ${e.sets[i].reps} reps'
                        '${e.sets[i].rpe != null ? ' • RPE ${e.sets[i].rpe}' : ''}',
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Volumen: ${e.volumeKg.toStringAsFixed(1)} kg'
                      '${e.bestE1rm != null ? ' • Mejor E1RM: ${e.bestE1rm!.toStringAsFixed(1)}' : ''}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 🧠 Sección de sensaciones post-entrenamiento
          if (!_feelingsSaved) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: s.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.psychology_rounded,
                            color: s.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Cómo te sentiste?',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Registra tus sensaciones del entreno',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: s.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Energía
                    _buildFeelingSlider(
                      'Energía',
                      _energyValue,
                      Icons.bolt_rounded,
                      Colors.green,
                      (v) => setState(() => _energyValue = v),
                    ),
                    const SizedBox(height: 20),

                    // Fatiga física
                    _buildFeelingSlider(
                      'Fatiga física',
                      _fatigueValue,
                      Icons.fitness_center_rounded,
                      Colors.orange,
                      (v) => setState(() => _fatigueValue = v),
                    ),
                    const SizedBox(height: 20),

                    // Motivación
                    _buildFeelingSlider(
                      'Motivación',
                      _motivationValue,
                      Icons.favorite_rounded,
                      Colors.blue,
                      (v) => setState(() => _motivationValue = v),
                    ),
                    const SizedBox(height: 24),

                    if (widget.svc != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saveFeelings,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Guardar sensaciones'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Mostrar sensaciones ya guardadas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology_rounded, color: s.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Sensaciones registradas',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Energía: $_energyValue/5'),
                    Text('Fatiga: $_fatigueValue/5'),
                    Text('Motivación: $_motivationValue/5'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingSlider(
    String label,
    int value,
    IconData icon,
    Color color,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toString(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              return Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: value == i + 1 ? FontWeight.w700 : FontWeight.normal,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
