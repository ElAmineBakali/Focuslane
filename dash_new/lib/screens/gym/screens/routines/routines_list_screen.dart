import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/feedback/focus_feedback.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/gym/models/gym_models.dart';
import 'package:focuslane/screens/gym/screens/routines/routine_detail_screen.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';

class RoutinesListScreen extends StatelessWidget {
  const RoutinesListScreen({
    super.key,
    required this.svc,
    this.embedded = false,
  });

  final GymFirestoreService svc;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = _RoutinesContent(svc: svc);

    if (embedded) return content;

    return AppShell(
      title: 'Rutinas',
      subtitle: 'Divisiones, días y descansos.',
      activeRoute: AppRoutes.gymDashboard,
      actions: [
        FocusIconButton(
          icon: Icons.add_rounded,
          tooltip: 'Nueva rutina',
          onPressed: () => _newRoutineSheet(context),
        ),
        const SizedBox(width: 10),
      ],
      child: content,
    );
  }

  Future<void> _newRoutineSheet(BuildContext context) async {
    final result = await _showRoutineForm(context, title: 'Nueva rutina');
    if (result == null || !context.mounted) return;

    final id = await svc.createRoutine(
      name: result.name,
      description: result.description,
      splitType: result.splitType,
      restSecDefault: result.restSecDefault,
      colorHex: result.colorHex,
      isDefault: result.isDefault,
    );

    final created = Routine(
      id: id,
      name: result.name,
      description: result.description,
      splitType: result.splitType,
      restSecDefault: result.restSecDefault,
      colorHex: result.colorHex,
      isDefault: result.isDefault,
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineDetailScreen(svc: svc, routine: created),
      ),
    );
  }
}

class _RoutinesContent extends StatelessWidget {
  const _RoutinesContent({required this.svc});

  final GymFirestoreService svc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Routine>>(
      stream: svc.streamRoutines(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PageContainer(
            child: FocusEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudieron cargar las rutinas',
              subtitle: '${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final routines = snapshot.data ?? const <Routine>[];

        return SingleChildScrollView(
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FocusSectionHeader(
                  icon: Icons.list_alt_rounded,
                  title: 'Rutinas',
                  subtitle: 'Gestiona divisiones, días y descansos.',
                  trailing: FocusPrimaryButton(
                    label: 'Nueva rutina',
                    icon: Icons.add_rounded,
                    onPressed: () => _newRoutineSheet(context),
                  ),
                ),
                const SizedBox(height: 16),
                if (routines.isEmpty)
                  FocusCard(
                    child: FocusEmptyState(
                      icon: Icons.fitness_center_rounded,
                      message: 'Sin rutinas todavía',
                      subtitle:
                          'Crea una rutina principal y añade días de entrenamiento.',
                      actionLabel: 'Crear rutina',
                      onAction: () => _newRoutineSheet(context),
                    ),
                  )
                else
                  ResponsiveGrid(
                    minItemWidth: 320,
                    spacing: 16,
                    children: [
                      for (final routine in routines)
                        _RoutineCard(
                          svc: svc,
                          routine: routine,
                          onOpen:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => RoutineDetailScreen(
                                        svc: svc,
                                        routine: routine,
                                      ),
                                ),
                              ),
                          onEdit: () => _editRoutineSheet(context, routine),
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

  Future<void> _newRoutineSheet(BuildContext context) async {
    final result = await _showRoutineForm(context, title: 'Nueva rutina');
    if (result == null || !context.mounted) return;

    final id = await svc.createRoutine(
      name: result.name,
      description: result.description,
      splitType: result.splitType,
      restSecDefault: result.restSecDefault,
      colorHex: result.colorHex,
      isDefault: result.isDefault,
    );

    final created = Routine(
      id: id,
      name: result.name,
      description: result.description,
      splitType: result.splitType,
      restSecDefault: result.restSecDefault,
      colorHex: result.colorHex,
      isDefault: result.isDefault,
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineDetailScreen(svc: svc, routine: created),
      ),
    );
  }

  Future<void> _editRoutineSheet(BuildContext context, Routine routine) async {
    final result = await _showRoutineForm(
      context,
      title: 'Editar rutina',
      initial: _RoutineFormResult(
        name: routine.name,
        description: routine.description,
        splitType: routine.splitType,
        restSecDefault: routine.restSecDefault,
        colorHex: routine.colorHex ?? _colorToHex(routine.color),
        isDefault: routine.isDefault,
      ),
      showDefaultToggle: false,
    );
    if (result == null) return;

    await svc.updateRoutine(routine.id, {
      'name': result.name,
      'description': result.description,
      'splitType': result.splitType,
      'restSecDefault': result.restSecDefault,
      'colorHex': result.colorHex,
    });
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.svc,
    required this.routine,
    required this.onOpen,
    required this.onEdit,
  });

  final GymFirestoreService svc;
  final Routine routine;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = _routineTone(routine, scheme.primary);

    return StreamBuilder<List<RoutineDay>>(
      stream: svc.streamDays(routine.id),
      builder: (context, daysSnap) {
        final days = daysSnap.data ?? const <RoutineDay>[];
        return FocusCard(
          onTap: onOpen,
          borderSide: BorderSide(
            color:
                routine.isDefault
                    ? tone.withValues(alpha: 0.44)
                    : scheme.outlineVariant,
            width: routine.isDefault ? 1.4 : 1,
          ),
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
                    child: Icon(Icons.fitness_center_rounded, color: tone),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _splitLabel(routine.splitType),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Acciones',
                    onSelected: (value) => _handleMenu(context, value),
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(
                            value: 'default',
                            child: Text('Hacer predeterminada'),
                          ),
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
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
              const SizedBox(height: 14),
              if ((routine.description ?? '').isNotEmpty)
                Text(
                  routine.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if ((routine.description ?? '').isNotEmpty)
                const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(
                    label: routine.isDefault ? 'Principal' : 'Rutina',
                    color: tone,
                  ),
                  FocusBadge(
                    label: '${days.length} días',
                    color: scheme.secondary,
                  ),
                  FocusBadge(
                    label: '${routine.restSecDefault}s descanso',
                    color: scheme.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _RoutineProgress(days: days, color: tone),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      days.isEmpty
                          ? 'Añade días para empezar'
                          : 'Próxima acción: iniciar día',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: tone),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleMenu(BuildContext context, String value) async {
    if (value == 'default') {
      await svc.setDefaultRoutine(routine.id);
      return;
    }
    if (value == 'edit') {
      onEdit();
      return;
    }
    if (value == 'duplicate') {
      await svc.duplicateRoutine(routine.id);
      if (context.mounted) {
        FocusFeedback.showSuccess(context, 'Rutina duplicada');
      }
      return;
    }
    if (value == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Eliminar rutina'),
              content: Text('¿Eliminar "${routine.name}" y todo su contenido?'),
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
        await svc.deleteRoutineCascade(routine.id);
        if (context.mounted) {
          FocusFeedback.showSuccess(context, 'Rutina eliminada');
        }
      }
    }
  }
}

class _RoutineProgress extends StatelessWidget {
  const _RoutineProgress({required this.days, required this.color});

  final List<RoutineDay> days;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = days.take(7).toList(growable: false);

    if (visible.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          'Semana sin estructura todavía',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < visible.length; i++)
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'D${i + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  visible[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RoutineFormResult {
  const _RoutineFormResult({
    required this.name,
    required this.description,
    required this.splitType,
    required this.restSecDefault,
    required this.colorHex,
    required this.isDefault,
  });

  final String name;
  final String? description;
  final String splitType;
  final int restSecDefault;
  final String colorHex;
  final bool isDefault;
}

Future<_RoutineFormResult?> _showRoutineForm(
  BuildContext context, {
  required String title,
  _RoutineFormResult? initial,
  bool showDefaultToggle = true,
}) {
  return showModalBottomSheet<_RoutineFormResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => _RoutineFormSheet(
          title: title,
          initial: initial,
          showDefaultToggle: showDefaultToggle,
        ),
  );
}

class _RoutineFormSheet extends StatefulWidget {
  const _RoutineFormSheet({
    required this.title,
    this.initial,
    required this.showDefaultToggle,
  });

  final String title;
  final _RoutineFormResult? initial;
  final bool showDefaultToggle;

  @override
  State<_RoutineFormSheet> createState() => _RoutineFormSheetState();
}

class _RoutineFormSheetState extends State<_RoutineFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _restCtrl = TextEditingController(text: '90');
  var _split = 'Custom';
  var _isDefault = false;
  late Color _selected;

  static const _palette = <Color>[
    Color(0xFF5B7CFA),
    Color(0xFF16A085),
    Color(0xFFE67E22),
    Color(0xFFC0392B),
    Color(0xFF8E44AD),
    Color(0xFF2C3E50),
    Color(0xFF2E7D32),
    Color(0xFFD81B60),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameCtrl.text = initial?.name ?? '';
    _descriptionCtrl.text = initial?.description ?? '';
    _restCtrl.text = '${initial?.restSecDefault ?? 90}';
    _split = initial?.splitType ?? 'Custom';
    _isDefault = initial?.isDefault ?? false;
    _selected =
        initial?.colorHex == null
            ? _palette.first
            : _hexToColor(initial!.colorHex);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _restCtrl.dispose();
    super.dispose();
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                FocusTextField(
                  label: 'Nombre de la rutina',
                  hint: 'PPL, torso/pierna, full body...',
                  controller: _nameCtrl,
                  prefixIcon: Icons.fitness_center_rounded,
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'Pon un nombre';
                    if (text.length < 3) return 'Mínimo 3 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                FocusTextField(
                  label: 'Descripción',
                  hint: 'Objetivo, frecuencia o notas',
                  controller: _descriptionCtrl,
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _split,
                  decoration: InputDecoration(
                    labelText: 'Tipo de división',
                    prefixIcon: const Icon(Icons.splitscreen_rounded),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'PPL',
                      child: Text('PPL - empuje, tirón, pierna'),
                    ),
                    DropdownMenuItem(value: 'UL', child: Text('Torso/pierna')),
                    DropdownMenuItem(
                      value: 'FB',
                      child: Text('Cuerpo completo'),
                    ),
                    DropdownMenuItem(
                      value: 'Custom',
                      child: Text('Personalizada'),
                    ),
                  ],
                  onChanged:
                      (value) => setState(() => _split = value ?? 'Custom'),
                ),
                const SizedBox(height: 14),
                FocusTextField(
                  label: 'Descanso por defecto',
                  hint: '90',
                  suffix: 'segundos',
                  controller: _restCtrl,
                  prefixIcon: Icons.timer_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final seconds = int.tryParse((value ?? '').trim());
                    if (seconds == null) return 'Indica un número entero';
                    if (seconds < 0) return 'No puede ser negativo';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'Color',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final color in _palette)
                      _ColorSwatch(
                        color: color,
                        selected: color.value == _selected.value,
                        onTap: () => setState(() => _selected = color),
                      ),
                  ],
                ),
                if (widget.showDefaultToggle) ...[
                  const SizedBox(height: 16),
                  FocusCard(
                    elevated: false,
                    padding: EdgeInsets.zero,
                    backgroundColor: scheme.surfaceContainerLow,
                    child: SwitchListTile(
                      value: _isDefault,
                      onChanged: (value) => setState(() => _isDefault = value),
                      title: const Text('Marcar como principal'),
                      subtitle: const Text(
                        'Se usará como rutina semanal por defecto.',
                      ),
                      secondary: Icon(
                        Icons.star_rounded,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
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
                        label:
                            widget.title.startsWith('Editar')
                                ? 'Guardar'
                                : 'Crear rutina',
                        icon: Icons.check_rounded,
                        fullWidth: true,
                        color: _selected,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    Navigator.pop(
      context,
      _RoutineFormResult(
        name: _nameCtrl.text.trim(),
        description:
            _descriptionCtrl.text.trim().isEmpty
                ? null
                : _descriptionCtrl.text.trim(),
        splitType: _split,
        restSecDefault: int.parse(_restCtrl.text.trim()),
        colorHex: _colorToHex(_selected),
        isDefault: _isDefault,
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: selected ? 44 : 38,
        height: selected ? 44 : 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
            width: 2,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : null,
        ),
        child:
            selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
      ),
    );
  }
}

Color _routineTone(Routine routine, Color fallback) {
  final hex = routine.colorHex;
  if (hex == null || hex.trim().isEmpty) return fallback;
  try {
    return _hexToColor(hex);
  } catch (_) {
    return fallback;
  }
}

Color _hexToColor(String value) {
  var hex = value.replaceAll('#', '').trim();
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

String _colorToHex(Color color) {
  final rgb = color.value & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

String _splitLabel(String split) {
  switch (split) {
    case 'PPL':
      return 'Empuje, tirón y pierna';
    case 'UL':
      return 'Torso y pierna';
    case 'FB':
      return 'Cuerpo completo';
    default:
      return 'Personalizada';
  }
}
