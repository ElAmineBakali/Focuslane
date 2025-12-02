import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

class RecipeEditScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  final Recipe? initial;
  const RecipeEditScreen({super.key, required this.svc, this.initial});

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _steps = TextEditingController();
  final List<RecipeIngredient> _ings = [];
  int _servings = 1;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    if (r != null) {
      _name.text = r.name;
      _desc.text = r.description ?? '';
      _steps.text = r.steps;
      _servings = r.servings;
      _ings.addAll(r.ingredients);
    }
  }

  Future<void> _save() async {
    final r = Recipe(
      id: widget.initial?.id ?? '',
      name: _name.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      servings: _servings,
      ingredients: _ings,
      steps: _steps.text.trim(),
    );
    if (widget.initial == null) {
      await widget.svc.createRecipe(r);
    } else {
      await widget.svc.updateRecipe(r.id, r.toMap());
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar receta' : 'Nueva receta'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addIngredientDialog,
        child: const Icon(Icons.add),
      ),
      body: TaskFormTheme(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, screenPad(context)),
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Descripción'),
                minLines: 3,
                maxLines: 6,
              ),

              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _servings,
                decoration: const InputDecoration(labelText: 'Raciones'),
                items: List.generate(
                  10,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                ),
                onChanged: (v) => setState(() => _servings = v ?? _servings),
              ),

              const SizedBox(height: 12),
              Text(
                'Ingredientes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),

              if (_ings.isEmpty)
                const Text('Añade ingredientes con el botón +'),
              ..._ings.asMap().entries.map((e) {
                final i = e.value;
                return Card(
                  child: ListTile(
                    title: Text(
                      i.foodId != null
                          ? 'Food: ${i.foodId}'
                          : (i.freeName ?? 'Ingrediente'),
                    ),
                    subtitle: Text(
                      '${i.qty.toStringAsFixed(0)} ${i.unit.name}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => setState(() => _ings.removeAt(e.key)),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              TextField(
                controller: _steps,
                decoration: const InputDecoration(labelText: 'Pasos'),
                minLines: 6,
                maxLines: null,
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'Guardar' : 'Crear'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addIngredientDialog() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '100');
    UnitKind unit = UnitKind.g;

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Ingrediente (rápido)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre libre (o FoodId)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UnitKind>(
                    initialValue: unit,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: const [
                      DropdownMenuItem(value: UnitKind.g, child: Text('g')),
                      DropdownMenuItem(value: UnitKind.ml, child: Text('ml')),
                      DropdownMenuItem(
                        value: UnitKind.unit,
                        child: Text('unidad'),
                      ),
                    ],
                    onChanged: (v) => unit = v ?? UnitKind.g,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Añadir'),
              ),
            ],
          ),
    );

    if (ok == true) {
      setState(() {
        _ings.add(
          RecipeIngredient(
            foodId: null,
            freeName:
                nameCtrl.text.trim().isEmpty
                    ? 'Ingrediente'
                    : nameCtrl.text.trim(),
            qty: double.tryParse(qtyCtrl.text) ?? 0,
            unit: unit,
          ),
        );
      });
    }
  }
}
