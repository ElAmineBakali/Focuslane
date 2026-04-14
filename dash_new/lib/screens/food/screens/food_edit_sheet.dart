import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/tokens/focuslane_tokens.dart';
import 'package:flutter/services.dart';
import 'package:focuslane/screens/food/models/food_models.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'package:focuslane/screens/food/widgets/food_compact_widgets.dart';

class FoodEditSheet extends StatefulWidget {
  final FoodFirestoreService svc;
  final Food? food;

  const FoodEditSheet({
    super.key,
    required this.svc,
    this.food,
  });

  @override
  State<FoodEditSheet> createState() => _FoodEditSheetState();
}

class _FoodEditSheetState extends State<FoodEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _kcalController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;
  late TextEditingController _servingSizeController;
  late TextEditingController _servingUnitController;

  bool _isSupp = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.food;

    _nameController = TextEditingController(text: f?.name ?? '');
    _brandController = TextEditingController(text: f?.brand ?? '');
    _kcalController = TextEditingController(text: f?.kcal.toString() ?? '');
    _proteinController = TextEditingController(
      text: f?.protein.toString() ?? '',
    );
    _carbsController = TextEditingController(text: f?.carbs.toString() ?? '');
    _fatController = TextEditingController(text: f?.fat.toString() ?? '');
    _fiberController = TextEditingController(text: f?.fiber.toString() ?? '');
    _servingSizeController = TextEditingController(
      text: f?.servingSize.toString() ?? '100',
    );
    _servingUnitController = TextEditingController(text: f?.servingUnit ?? 'g');
    _isSupp = f?.isSupp ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _servingSizeController.dispose();
    _servingUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.food != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                  color: FocuslaneUI.dividerColor(context),
                  width: FocuslaneUI.dividerW,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.add_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    isEditing ? 'Editar Alimento' : 'Nuevo Alimento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  FoodCompactTextField(
                    label: 'Nombre del alimento',
                    controller: _nameController,
                    prefixIcon: Icons.restaurant,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FoodCompactTextField(
                    label: 'Marca (opcional)',
                    controller: _brandController,
                    prefixIcon: Icons.business,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FoodCompactTextField(
                          label: 'Tamaño porción',
                          controller: _servingSizeController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.scale,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FoodCompactTextField(
                          label: 'Unidad',
                          controller: _servingUnitController,
                          prefixIcon: Icons.label,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Información Nutricional',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FoodCompactTextField(
                          label: 'Calorías',
                          controller: _kcalController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.local_fire_department,
                          suffix: 'kcal',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FoodCompactTextField(
                          label: 'Proteína',
                          controller: _proteinController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.fitness_center,
                          suffix: 'g',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FoodCompactTextField(
                          label: 'Carbohidratos',
                          controller: _carbsController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.grain,
                          suffix: 'g',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FoodCompactTextField(
                          label: 'Grasas',
                          controller: _fatController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.water_drop,
                          suffix: 'g',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FoodCompactTextField(
                    label: 'Fibra (opcional)',
                    controller: _fiberController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.eco,
                    suffix: 'g',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    value: _isSupp,
                    onChanged: (value) => setState(() => _isSupp = value),
                    title: const Text('Es suplemento'),
                    subtitle: const Text(
                      'Marca si es proteína en polvo, creatina, etc.',
                    ),
                    activeThumbColor: colorScheme.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: FocuslaneUI.dividerColor(context),
                  width: FocuslaneUI.dividerW,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveFood,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Guardar' : 'Crear'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final food = Food(
        id: widget.food?.id ?? '',
        name: _nameController.text.trim(),
        brand:
            _brandController.text.trim().isEmpty
                ? null
                : _brandController.text.trim(),
        perUnit: UnitKind.g,
        unitSize: double.tryParse(_servingSizeController.text) ?? 100,
        kcal: double.tryParse(_kcalController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        fiber: double.tryParse(_fiberController.text) ?? 0,
        sodium: 0,
        isSupplement: _isSupp,
      );

      if (widget.food == null) {
        await widget.svc.createFood(food);
      } else {
        await widget.svc.updateFood(food.id, food.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
        FoodFeedback.showSuccess(
          context,
          widget.food == null ? 'Alimento creado' : 'Alimento actualizado',
        );
      }
    } catch (e) {
      if (mounted) {
        FoodFeedback.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}


