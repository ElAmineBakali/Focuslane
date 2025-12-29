import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';

class PresetsSheet extends StatefulWidget {
  final StudyFirestoreService svc;
  final String? courseId;
  const PresetsSheet({super.key, required this.svc, this.courseId});

  @override
  State<PresetsSheet> createState() => _PresetsSheetState();
}

class _PresetsSheetState extends State<PresetsSheet> {
  final _name = TextEditingController(text: 'Pomodoro 25/5');
  StudyMethod _method = StudyMethod.pomodoro;
  final Map<String, dynamic> _params = {
    'work': 25,
    'short': 5,
    'long': 15,
    'cycles': 4,
  };

  void _setDefaults(StudyMethod m) {
    switch (m) {
      case StudyMethod.pomodoro:
        _params
          ..clear()
          ..addAll({'work': 25, 'short': 5, 'long': 15, 'cycles': 4});
        break;
      case StudyMethod.flowtime:
        _params
          ..clear()
          ..addAll({'ratio': 0.2});
        break;
      case StudyMethod.timeboxing:
        _params
          ..clear()
          ..addAll({'block': 50, 'rest': 10});
        break;
      case StudyMethod.custom:
        _params
          ..clear()
          ..addAll({
            'sequence': [
              {'label': 'W1', 'work': 40, 'rest': 10},
              {'label': 'W2', 'work': 40, 'rest': 10},
            ],
          });
        break;
      case StudyMethod.simple:
        _params
          ..clear()
          ..addAll({'target': 60});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.15),
                            Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Presets de estudio',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mis Presets',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    StreamBuilder<List<TimerPreset>>(
                      stream: widget.svc.streamPresets(
                        courseId: widget.courseId,
                      ),
                      builder: (context, snap) {
                        final presets = snap.data ?? const [];
                        if (presets.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay presets guardados',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Crea uno nuevo en la sección de abajo',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children:
                              presets.map((p) {
                                final methodIcon = _getMethodIcon(p.method);
                                final methodColor = _getMethodColor(
                                  p.method,
                                  context,
                                );

                                return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            methodColor.withOpacity(0.1),
                                            methodColor.withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: methodColor.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          onTap:
                                              () => Navigator.pop(context, p),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: methodColor
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    methodIcon,
                                                    color: methodColor,
                                                    size: 24,
                                                  ),
                                                ),

                                                const SizedBox(width: 16),

                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        p.name,
                                                        style:
                                                            GoogleFonts.plusJakartaSans(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _formatMethodName(
                                                          p.method,
                                                        ),
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 13,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                IconButton(
                                                  icon: Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: Colors.red.shade400,
                                                  ),
                                                  onPressed:
                                                      () => widget.svc
                                                          .deletePreset(p.id),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: -0.1, end: 0);
                              }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Crear Nuevo Preset',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.08),
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nombre',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _name,
                            decoration: InputDecoration(
                              hintText: 'Ej: Pomodoro 25/5',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: GoogleFonts.plusJakartaSans(),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'Método de estudio',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                StudyMethod.values.map((m) {
                                  final isSelected = _method == m;
                                  final color = _getMethodColor(m, context);

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _method = m;
                                        _setDefaults(_method);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient:
                                            isSelected
                                                ? LinearGradient(
                                                  colors: [
                                                    color.withOpacity(0.3),
                                                    color.withOpacity(0.15),
                                                  ],
                                                )
                                                : null,
                                        color:
                                            !isSelected
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.surface
                                                : null,
                                        borderRadius: BorderRadius.circular(12),
                                        border:
                                            isSelected
                                                ? Border.all(
                                                  color: color,
                                                  width: 2,
                                                )
                                                : Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline
                                                      .withOpacity(0.2),
                                                ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getMethodIcon(m),
                                            size: 18,
                                            color:
                                                isSelected
                                                    ? color
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatMethodName(m),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                              fontSize: 14,
                                              color: isSelected ? color : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),

                          const SizedBox(height: 20),

                          _ParamsEditor(method: _method, params: _params),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final p = TimerPreset(
                                  id: '',
                                  name:
                                      _name.text.trim().isEmpty
                                          ? 'Preset'
                                          : _name.text.trim(),
                                  method: _method,
                                  params: Map<String, dynamic>.from(_params),
                                  courseId: widget.courseId,
                                );
                                await widget.svc.savePreset(p);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Preset guardado correctamente',
                                        style: GoogleFonts.plusJakartaSans(),
                                      ),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  _name.clear();
                                  _name.text = 'Pomodoro 25/5';
                                }
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.save_rounded),
                              label: Text(
                                'Guardar preset',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: MediaQuery.of(context).viewPadding.bottom + 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getMethodIcon(StudyMethod method) {
    switch (method) {
      case StudyMethod.pomodoro:
        return Icons.timer_rounded;
      case StudyMethod.flowtime:
        return Icons.waves_rounded;
      case StudyMethod.timeboxing:
        return Icons.grid_view_rounded;
      case StudyMethod.custom:
        return Icons.tune_rounded;
      case StudyMethod.simple:
        return Icons.play_circle_rounded;
    }
  }

  Color _getMethodColor(StudyMethod method, BuildContext context) {
    switch (method) {
      case StudyMethod.pomodoro:
        return Colors.red;
      case StudyMethod.flowtime:
        return Colors.blue;
      case StudyMethod.timeboxing:
        return Colors.purple;
      case StudyMethod.custom:
        return Colors.orange;
      case StudyMethod.simple:
        return Colors.green;
    }
  }

  String _formatMethodName(StudyMethod method) {
    switch (method) {
      case StudyMethod.pomodoro:
        return 'Pomodoro';
      case StudyMethod.flowtime:
        return 'Flowtime';
      case StudyMethod.timeboxing:
        return 'Timeboxing';
      case StudyMethod.custom:
        return 'Personalizado';
      case StudyMethod.simple:
        return 'Simple';
    }
  }
}

class _ParamsEditor extends StatefulWidget {
  final StudyMethod method;
  final Map<String, dynamic> params;
  const _ParamsEditor({required this.method, required this.params});

  @override
  State<_ParamsEditor> createState() => _ParamsEditorState();
}

class _ParamsEditorState extends State<_ParamsEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parámetros',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: _buildParamsForMethod(),
        ),
      ],
    );
  }

  Widget _buildParamsForMethod() {
    switch (widget.method) {
      case StudyMethod.pomodoro:
        return Column(
          children: [
            _num('Trabajo (min)', 'work', Icons.work_outline_rounded),
            const SizedBox(height: 12),
            _num('Descanso corto (min)', 'short', Icons.coffee_outlined),
            const SizedBox(height: 12),
            _num('Descanso largo (min)', 'long', Icons.hotel_rounded),
            const SizedBox(height: 12),
            _num('Ciclos', 'cycles', Icons.repeat_rounded),
          ],
        );
      case StudyMethod.flowtime:
        return _num(
          'Ratio descanso/trabajo (ej: 0.2 = 20%)',
          'ratio',
          Icons.waves_rounded,
        );
      case StudyMethod.timeboxing:
        return Column(
          children: [
            _num('Bloque (min)', 'block', Icons.grid_view_rounded),
            const SizedBox(height: 12),
            _num('Descanso (min)', 'rest', Icons.free_breakfast_rounded),
          ],
        );
      case StudyMethod.custom:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Secuencia personalizada: edita los detalles en Firestore',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        );
      case StudyMethod.simple:
        return _num('Objetivo (minutos)', 'target', Icons.flag_rounded);
    }
  }

  Widget _num(String label, String key, IconData icon) {
    final ctrl = TextEditingController(text: '${widget.params[key] ?? ''}');
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                onChanged: (v) {
                  final n = double.tryParse(v);
                  if (n != null) {
                    widget.params[key] = n;
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
