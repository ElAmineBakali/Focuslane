// lib/screens/finance/assets/asset_edit_sheet.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/models/finance_models.dart';
import 'package:mi_dashboard_personal/screens/finance/services/finance_firestore_service.dart';
import '../../../widgets/ui_scaffold.dart';

class AssetEditSheet extends StatefulWidget {
  final AssetItem? initial;
  const AssetEditSheet({super.key, this.initial});

  @override
  State<AssetEditSheet> createState() => _AssetEditSheetState();
}

class _AssetEditSheetState extends State<AssetEditSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _value = TextEditingController();
  final _currency = TextEditingController(text: 'EUR');
  final _address = TextEditingController();
  final _notes = TextEditingController();

  /// almacenamos el string ARGB como en otros módulos (p.ej. '0xFF2962FF')
  final _colorHex = TextEditingController();

  AssetKind _kind = AssetKind.other;
  DateTime? _acquiredAt;

  /// misma paleta que usamos en Study
  static const _swatches = <int>[
    0xFF2962FF,
    0xFF00BFA5,
    0xFF43A047,
    0xFFF9A825,
    0xFFEF6C00,
    0xFFE53935,
    0xFF8E24AA,
    0xFF546E7A,
  ];

  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    if (x != null) {
      _name.text = x.name;
      _value.text = x.estValue?.toString() ?? '';
      _currency.text = x.currency ?? 'EUR';
      _address.text = x.address ?? '';
      _notes.text = x.notes ?? '';
      _kind = x.kind;
      _acquiredAt = x.acquiredAt;
      _colorHex.text = x.colorHex ?? '';
    }
  }

  Color? _selectedColorOrNull() {
    final raw = _colorHex.text.trim();
    if (raw.isEmpty) return null;
    try {
      return Color(int.parse(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final previewColor = _selectedColorOrNull();

    return TaskFormTheme(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'Editar activo' : 'Nuevo activo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),

                DropdownButtonFormField<AssetKind>(
                  initialValue: _kind,
                  items: const [
                    DropdownMenuItem(
                      value: AssetKind.house,
                      child: Text('Vivienda'),
                    ),
                    DropdownMenuItem(
                      value: AssetKind.car,
                      child: Text('Vehículo'),
                    ),
                    DropdownMenuItem(
                      value: AssetKind.land,
                      child: Text('Terreno'),
                    ),
                    DropdownMenuItem(
                      value: AssetKind.other,
                      child: Text('Otro'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _kind = v ?? _kind),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _value,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor estimado',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _currency,
                        decoration: const InputDecoration(labelText: 'Divisa'),
                      ),
                    ),
                  ],
                ),

                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación (dirección)',
                    helperText:
                        'Escribe la calle/ciudad. El icono abrirá Maps.',
                  ),
                ),

                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notas'),
                  maxLines: 3,
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(
                    'Adquirido: ${_acquiredAt != null ? _acquiredAt!.toLocal().toString().split(" ").first : "—"}',
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _acquiredAt ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _acquiredAt = d);
                  },
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Color',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Sin color'),
                      selected: _colorHex.text.trim().isEmpty,
                      onSelected: (_) => setState(() => _colorHex.text = ''),
                    ),
                    ..._swatches.map((hex) {
                      final c = Color(hex);
                      final sel = previewColor?.value == c.value;
                      return ChoiceChip(
                        selected: sel,
                        label: const SizedBox(width: 0, height: 0),
                        avatar: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                        onSelected:
                            (_) => setState(
                              () =>
                                  _colorHex.text =
                                      '0x${hex.toRadixString(16).toUpperCase()}',
                            ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Vista previa:'),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          previewColor ?? Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        if (!_form.currentState!.validate()) return;

                        final a = AssetItem(
                          id: widget.initial?.id ?? '',
                          name: _name.text.trim(),
                          kind: _kind,
                          estValue: double.tryParse(_value.text),
                          currency:
                              _currency.text.trim().isEmpty
                                  ? null
                                  : _currency.text.trim(),
                          address:
                              _address.text.trim().isEmpty
                                  ? null
                                  : _address.text.trim(),
                          notes:
                              _notes.text.trim().isEmpty
                                  ? null
                                  : _notes.text.trim(),
                          acquiredAt: _acquiredAt,
                          colorHex:
                              _colorHex.text.trim().isEmpty
                                  ? null
                                  : _colorHex.text.trim(),
                        );

                        if (widget.initial == null) {
                          await FinanceAssetsFirestoreService.I.addAsset(a);
                        } else {
                          await FinanceAssetsFirestoreService.I.updateAsset(a);
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      child: Text(isEdit ? 'Guardar' : 'Crear'),
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
}
