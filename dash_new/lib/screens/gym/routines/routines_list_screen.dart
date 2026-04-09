import 'package:flutter/material.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gym_firestore_service.dart';
import '../models/gym_models.dart';
import 'routine_detail_screen.dart';
import '../../../design/ui/components/focus_module_header.dart';

class RoutinesListScreen extends StatelessWidget {
  final GymFirestoreService svc;
  const RoutinesListScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            leading: FocusModuleHeader.buildLeading(
              context,
              mode: FocusModuleLeadingMode.backToModuleDashboard,
              backRouteName: AppRoutes.gymDashboard,
            ),
            leadingWidth: 96,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Mis Rutinas',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      s.primaryContainer,
                      s.secondaryContainer.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<List<Routine>>(
              stream: svc.streamRoutines(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final routines = snap.data!;
                if (routines.isEmpty) {
                  return SizedBox(
                    height: 400,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center_rounded,
                            size: 80,
                            color: s.primary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sin rutinas aún',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: s.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca el botón + para crear tu primera rutina',
                            style: TextStyle(color: s.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: routines.length,
                  itemBuilder: (_, i) {
                    final r = routines[i];
                    return _buildRoutineCard(context, r, s)
                        .animate()
                        .fadeIn(delay: (50 * i).ms, duration: 400.ms)
                        .slideX(begin: 0.2, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newRoutineSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Rutina'),
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, Routine r, ColorScheme s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [r.color.withOpacity(0.15), r.color.withOpacity(0.05)],
        ),
        border: Border.all(
          color: r.isDefault ? r.color : s.outlineVariant.withOpacity(0.5),
          width: r.isDefault ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoutineDetailScreen(svc: svc, routine: r),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: r.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: r.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  r.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: s.onSurface,
                                  ),
                                ),
                              ),
                              if (r.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: s.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ACTIVA',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: s.onPrimaryContainer,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if ((r.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              r.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: s.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                        if (v == 'default') await svc.setDefaultRoutine(r.id);
                        if (v == 'edit') await _editRoutineSheet(context, r);
                        if (v == 'dup') await svc.duplicateRoutine(r.id);
                        if (v == 'del') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: Text(
                                    'Eliminar rutina',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  content: Text(
                                    '¿Eliminar "${r.name}" y todo su contenido?',
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: s.error,
                                      ),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                          );
                          if (ok == true) await svc.deleteRoutineCascade(r.id);
                        }
                      },
                      itemBuilder:
                          (_) => [
                            const PopupMenuItem(
                              value: 'default',
                              child: Row(
                                children: [
                                  Icon(Icons.star_rounded, size: 20),
                                  SizedBox(width: 12),
                                  Text('Hacer predeterminada'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 20),
                                  SizedBox(width: 12),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'dup',
                              child: Row(
                                children: [
                                  Icon(Icons.content_copy_rounded, size: 20),
                                  SizedBox(width: 12),
                                  Text('Duplicar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(Icons.splitscreen_rounded, r.splitType, s),
                    _buildInfoChip(
                      Icons.timer_rounded,
                      '${r.restSecDefault}s descanso',
                      s,
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

  Widget _buildInfoChip(IconData icon, String label, ColorScheme s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: s.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: s.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: s.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _newRoutineSheet(BuildContext context) async {
    final res = await showModalBottomSheet<_RoutineFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RoutineFormSheet(title: 'Nueva rutina'),
    );

    if (res == null) return;

    final id = await svc.createRoutine(
      name: res.name,
      description: res.description,
      splitType: res.splitType,
      restSecDefault: res.restSecDefault,
      colorHex: res.colorHex,
      isDefault: res.isDefault,
    );

    final created = Routine(
      id: id,
      name: res.name,
      description: res.description,
      splitType: res.splitType,
      restSecDefault: res.restSecDefault,
      colorHex: res.colorHex,
      isDefault: res.isDefault,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineDetailScreen(svc: svc, routine: created),
      ),
    );
  }

  Future<void> _editRoutineSheet(BuildContext context, Routine r) async {
    final res = await showModalBottomSheet<_RoutineFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (_) => _RoutineFormSheet(
            title: 'Editar rutina',
            initial: _RoutineFormResult(
              name: r.name,
              description: r.description,
              splitType: r.splitType,
              restSecDefault: r.restSecDefault,
              colorHex: r.colorHex ?? _rgbToHex(r.color.value),
              isDefault: r.isDefault,
            ),
            showDefaultToggle: false,
          ),
    );

    if (res == null) return;

    await svc.updateRoutine(r.id, {
      'name': res.name,
      'description': res.description,
      'splitType': res.splitType,
      'restSecDefault': res.restSecDefault,
      'colorHex': res.colorHex,
    });
  }
}

class _RoutineFormResult {
  final String name;
  final String? description;
  final String splitType;
  final int restSecDefault;
  final String colorHex;
  final bool isDefault;

  _RoutineFormResult({
    required this.name,
    required this.description,
    required this.splitType,
    required this.restSecDefault,
    required this.colorHex,
    required this.isDefault,
  });
}

class _RoutineFormSheet extends StatefulWidget {
  final String title;
  final _RoutineFormResult? initial;
  final bool showDefaultToggle;

  const _RoutineFormSheet({
    required this.title,
    this.initial,
    this.showDefaultToggle = true,
  });

  @override
  State<_RoutineFormSheet> createState() => _RoutineFormSheetState();
}

class _RoutineFormSheetState extends State<_RoutineFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _restCtrl = TextEditingController(text: '90');
  String _split = 'Custom';
  bool _isDefault = false;

  static const _palette = <Color>[
    Color(0xFF6750A4),
    Color(0xFF1E88E5),
    Color(0xFFD81B60),
    Color(0xFFF57C00),
    Color(0xFF2E7D32),
    Color(0xFF00897B),
    Color(0xFF546E7A),
    Color(0xFF9C27B0),
    Color(0xFF26A69A),
    Color(0xFF3949AB),
  ];
  late Color _selected;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _nameCtrl.text = i?.name ?? '';
    _descCtrl.text = i?.description ?? '';
    _split = i?.splitType ?? 'Custom';
    _restCtrl.text = '${i?.restSecDefault ?? 90}';
    _isDefault = i?.isDefault ?? false;

    if (i?.colorHex != null) {
      _selected = _hexToColor(i!.colorHex);
    } else {
      _selected = _palette.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _restCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
        bottom: 20 + viewInsets,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Nombre de la rutina',
                  hintText: 'Ej: PPL, Torso/Pierna, Full Body',
                  prefixIcon: const Icon(Icons.fitness_center_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                ),
                validator: (s) {
                  final t = (s ?? '').trim();
                  if (t.isEmpty) return 'Pon un nombre';
                  if (t.length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(fontSize: 16),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Detalles de tu rutina...',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _split,
                items: const [
                  DropdownMenuItem(
                    value: 'PPL',
                    child: Text('PPL (Push/Pull/Legs)'),
                  ),
                  DropdownMenuItem(value: 'UL', child: Text('Upper/Lower')),
                  DropdownMenuItem(value: 'FB', child: Text('Full Body')),
                  DropdownMenuItem(
                    value: 'Custom',
                    child: Text('Personalizada'),
                  ),
                ],
                onChanged: (v) => setState(() => _split = v ?? 'Custom'),
                decoration: InputDecoration(
                  labelText: 'Tipo de split',
                  prefixIcon: const Icon(Icons.splitscreen_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _restCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Descanso por defecto',
                  hintText: '90',
                  suffixText: 'segundos',
                  prefixIcon: const Icon(Icons.timer_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                ),
                validator: (s) {
                  if ((s ?? '').trim().isEmpty) return 'Indica segundos';
                  final v = int.tryParse((s ?? '').trim());
                  if (v == null) return 'Número entero';
                  if (v < 0) return 'No negativo';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Color de la rutina',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children:
                    _palette.map((c) {
                      final selected = c.value == _selected.value;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 50 : 44,
                          height: selected ? 50 : 44,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (selected)
                                BoxShadow(
                                  color: c.withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                            ],
                            border:
                                selected
                                    ? Border.all(color: cs.surface, width: 3)
                                    : null,
                          ),
                          child:
                              selected
                                  ? const Icon(
                                    Icons.check_rounded,
                                    size: 24,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                      );
                    }).toList(),
              ),
              if (widget.showDefaultToggle) ...[
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: SwitchListTile(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    title: Text(
                      'Marcar como predeterminada',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: const Text(
                      'Se usará por defecto en tus sesiones',
                    ),
                    secondary: Icon(Icons.star_rounded, color: cs.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.title.startsWith('Editar')
                            ? 'Guardar'
                            : 'Crear rutina',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final rgb = _selected.value & 0x00FFFFFF;
    final hex = '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

    Navigator.pop(
      context,
      _RoutineFormResult(
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        splitType: _split,
        restSecDefault: int.parse(_restCtrl.text.trim()),
        colorHex: hex,
        isDefault: _isDefault,
      ),
    );
  }
}

Color _hexToColor(String hex) {
  var h = hex.replaceAll('#', '').toUpperCase();
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

String _rgbToHex(int argb) {
  final rgb = argb & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}


