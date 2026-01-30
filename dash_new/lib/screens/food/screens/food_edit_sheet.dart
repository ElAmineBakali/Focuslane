import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

/// FoodEditSheet - Modal para añadir/editar alimentos
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
    _kcalController = TextEditingController(text: f?.kcal?.toString() ?? '');
    _proteinController = TextEditingController(text: f?.protein?.toString() ?? '');
    _carbsController = TextEditingController(text: f?.carbs?.toString() ?? '');
    _fatController = TextEditingController(text: f?.fat?.toString() ?? '');
    _fiberController = TextEditingController(text: f?.fiber?.toString() ?? '');
    _servingSizeController = TextEditingController(text: f?.servingSize?.toString() ?? '100');
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
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.add_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    isEditing ? 'Editar Alimento' : 'Nuevo Alimento',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
          
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  ModernTextField(
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
                  const SizedBox(height: AppSpacing.lg),
                  
                  ModernTextField(
                    label: 'Marca (opcional)',
                    controller: _brandController,
                    prefixIcon: Icons.business,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ModernTextField(
                          label: 'Tamaño porción',
                          controller: _servingSizeController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.scale,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ModernTextField(
                          label: 'Unidad',
                          controller: _servingUnitController,
                          prefixIcon: Icons.label,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  Text(
                    'Información Nutricional',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ModernTextField(
                          label: 'Calorías',
                          controller: _kcalController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.local_fire_department,
                          suffix: 'kcal',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ModernTextField(
                          label: 'Proteína',
                          controller: _proteinController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.fitness_center,
                          suffix: 'g',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ModernTextField(
                          label: 'Carbohidratos',
                          controller: _carbsController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.grain,
                          suffix: 'g',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ModernTextField(
                          label: 'Grasas',
                          controller: _fatController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.water_drop,
                          suffix: 'g',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  ModernTextField(
                    label: 'Fibra (opcional)',
                    controller: _fiberController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.eco,
                    suffix: 'g',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  SwitchListTile(
                    value: _isSupp,
                    onChanged: (value) => setState(() => _isSupp = value),
                    title: const Text('Es suplemento'),
                    subtitle: const Text('Marca si es proteína en polvo, creatina, etc.'),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveFood,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
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
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.food == null ? 'Alimento creado' : 'Alimento actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
