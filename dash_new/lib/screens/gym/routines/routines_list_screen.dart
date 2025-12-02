import 'package:flutter/material.dart';
import '../services/gym_firestore_service.dart';
import '../models/gym_models.dart';
import 'routine_detail_screen.dart';

class RoutinesListScreen extends StatelessWidget {
  final GymFirestoreService svc;
  const RoutinesListScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis rutinas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newRoutineSheet(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Routine>>(
        stream: svc.streamRoutines(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final routines = snap.data!;
          if (routines.isEmpty) {
            return const Center(
              child: Text('Crea tu primera rutina con el botón +'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: routines.length,
            itemBuilder: (_, i) {
              final r = routines[i];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.fitness_center, color: r.color),
                  title: Text(r.name),
                  subtitle: Text(
                    [
                      if (r.isDefault) 'Predeterminada',
                      if ((r.description ?? '').isNotEmpty) r.description!,
                      'Split: ${r.splitType} • Descanso: ${r.restSecDefault}s',
                    ].join(' • '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'default') await svc.setDefaultRoutine(r.id);
                      if (v == 'edit') await _editRoutineSheet(context, r);
                      if (v == 'dup') await svc.duplicateRoutine(r.id);
                      if (v == 'del') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text('Eliminar rutina'),
                                content: Text(
                                  '¿Eliminar "${r.name}" y todo su contenido?',
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
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                        );
                        if (ok == true) await svc.deleteRoutineCascade(r.id);
                      }
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(
                            value: 'default',
                            child: Text('Hacer predeterminada'),
                          ),
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'dup', child: Text('Duplicar')),
                          PopupMenuItem(value: 'del', child: Text('Eliminar')),
                        ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => RoutineDetailScreen(svc: svc, routine: r),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------- NUEVA RUTINA: SHEET BONITO (sin hex) ----------------

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
      colorHex: res.colorHex, // seguimos guardando hex por compatibilidad
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

    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineDetailScreen(svc: svc, routine: created),
      ),
    );
  }

  // ---------------- EDITAR RUTINA: SHEET BONITO (sin hex) ----------------

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
            showDefaultToggle:
                false, // al editar no cambiamos aquí predeterminada
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

// ===================== SHEET Y MODELO DE FORMULARIO =====================

class _RoutineFormResult {
  final String name;
  final String? description;
  final String splitType; // PPL / UL / FB / Custom
  final int restSecDefault;
  final String colorHex; // #RRGGBB (sin alpha) – seguimos guardando así
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

  // Paleta (elige las que te molen; sin pedir HEX)
  static const _palette = <Color>[
    Color(0xFF6750A4), // primary md3-ish
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

    // Si hay colorHex inicial, úsalo; si no, primero de la paleta
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

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + viewInsets,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: PPL, Torso/Pierna…',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (s) {
                  final t = (s ?? '').trim();
                  if (t.isEmpty) return 'Pon un nombre';
                  if (t.length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Split',
                  hintText: 'Opcional',
                  prefixIcon: Icon(Icons.view_week_outlined),
                ),
              ),
              const SizedBox(height: 8),
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
                decoration: const InputDecoration(
                  labelText: 'Split',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _restCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Descanso por defecto (s)',
                  hintText: 'Ej: 90',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: (s) {
                  if ((s ?? '').trim().isEmpty) return 'Indica segundos';
                  final v = int.tryParse((s ?? '').trim());
                  if (v == null) return 'Número entero';
                  if (v < 0) return 'No negativo';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Color',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _palette.map((c) {
                      final selected = c.value == _selected.value;
                      return InkWell(
                        onTap: () => setState(() => _selected = c),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (selected)
                                BoxShadow(
                                  color: cs.primary.withOpacity(.35),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                            ],
                            border:
                                selected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : Border.all(color: Colors.transparent),
                          ),
                          child:
                              selected
                                  ? const Icon(
                                    Icons.check,
                                    size: 20,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                      );
                    }).toList(),
              ),
              if (widget.showDefaultToggle) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  title: const Text('Marcar como predeterminada'),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(
                      widget.title.startsWith('Editar') ? 'Guardar' : 'Crear',
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

    // Guardamos como #RRGGBB (sin alpha) para ser 100% compatibles con tu modelo/servicio
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

// ===================== helpers de color =====================

Color _hexToColor(String hex) {
  var h = hex.replaceAll('#', '').toUpperCase();
  if (h.length == 6) h = 'FF$h'; // añade alpha si no viene
  // computed where needed; avoid unused local
  return Color(int.parse(h, radix: 16));
}

String _rgbToHex(int argb) {
  final rgb = argb & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
