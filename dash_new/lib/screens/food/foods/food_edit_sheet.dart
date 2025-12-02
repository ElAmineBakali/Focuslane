import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

class FoodEditSheet extends StatefulWidget {
  final FoodFirestoreService svc;
  final Food? initial;
  const FoodEditSheet({super.key, required this.svc, this.initial});

  @override
  State<FoodEditSheet> createState() => _FoodEditSheetState();
}

class _FoodEditSheetState extends State<FoodEditSheet> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _unitSize = TextEditingController(text: '100');
  final _kcal = TextEditingController(text: '0');
  final _p = TextEditingController(text: '0');
  final _c = TextEditingController(text: '0');
  final _f = TextEditingController(text: '0');
  final _fib = TextEditingController(text: '0');
  final _na = TextEditingController(text: '0');
  final _colorHex = TextEditingController();
  UnitKind _perUnit = UnitKind.g;
  bool _isSupp = false;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    if (f != null) {
      _name.text = f.name;
      _brand.text = f.brand ?? '';
      _unitSize.text = f.unitSize.toString();
      _kcal.text = f.kcal.toString();
      _p.text = f.protein.toString();
      _c.text = f.carbs.toString();
      _f.text = f.fat.toString();
      _fib.text = f.fiber.toString();
      _na.text = f.sodium.toString();
      _perUnit = f.perUnit;
      _isSupp = f.isSupplement;
      _colorHex.text = f.colorHex ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: TaskFormTheme(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'Editar alimento' : 'Nuevo alimento',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),

              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _brand,
                decoration: const InputDecoration(labelText: 'Marca (opcional)'),
              ),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _unitSize,
                      decoration: const InputDecoration(
                        labelText: 'Tamaño unidad (p.ej. 100)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<UnitKind>(
                      initialValue: _perUnit,
                      decoration: const InputDecoration(labelText: 'Unidad base'),
                      items: const [
                        DropdownMenuItem(
                          value: UnitKind.g,
                          child: Text('por g (100g tip.)'),
                        ),
                        DropdownMenuItem(
                          value: UnitKind.ml,
                          child: Text('por ml (100ml tip.)'),
                        ),
                        DropdownMenuItem(
                          value: UnitKind.unit,
                          child: Text('por unidad'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _perUnit = v ?? UnitKind.g),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kcal,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Kcal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _p,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Proteína (g)'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Carbos (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _f,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Grasas (g)'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fib,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fibra (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _na,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sodio (mg)'),
                    ),
                  ),
                ],
              ),

              SwitchListTile(
                value: _isSupp,
                onChanged: (v) => setState(() => _isSupp = v),
                title: const Text('Es suplemento'),
                contentPadding: EdgeInsets.zero,
              ),

              TextField(
                controller: _colorHex,
                decoration: const InputDecoration(
                  labelText: 'Color hex (opcional, ej. 0xFF2196F3)',
                ),
              ),

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
                    onPressed: () async {
                      final name = _name.text.trim();
                      if (name.isEmpty) return;
                      final f = Food(
                        id: widget.initial?.id ?? '',
                        name: name,
                        perUnit: _perUnit,
                        unitSize: double.tryParse(_unitSize.text) ?? 100,
                        kcal: double.tryParse(_kcal.text) ?? 0,
                        protein: double.tryParse(_p.text) ?? 0,
                        carbs: double.tryParse(_c.text) ?? 0,
                        fat: double.tryParse(_f.text) ?? 0,
                        fiber: double.tryParse(_fib.text) ?? 0,
                        sodium: double.tryParse(_na.text) ?? 0,
                        isSupplement: _isSupp,
                        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
                        colorHex: _colorHex.text.trim().isEmpty ? null : _colorHex.text.trim(),
                      );
                      if (widget.initial == null) {
                        await widget.svc.createFood(f);
                      } else {
                        await widget.svc.updateFood(widget.initial!.id, f.toMap());
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    child: Text(isEdit ? 'Guardar' : 'Crear'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
