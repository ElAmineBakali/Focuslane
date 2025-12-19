import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

 class FoodEditSheet extends StatefulWidget {
  final FoodFirestoreService svc;
  final Food? initial;
  
  const FoodEditSheet({super.key, required this.svc, this.initial});

  @override
  State<FoodEditSheet> createState() => _FoodEditSheetState();
}

class _FoodEditSheetState extends State<FoodEditSheet> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _unitSizeController = TextEditingController(text: '100');
  final _kcalController = TextEditingController(text: '0');
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  final _fiberController = TextEditingController(text: '0');
  final _sodiumController = TextEditingController(text: '0');
  
  UnitKind _perUnit = UnitKind.g;
  bool _isSupplement = false;
  bool _isSaving = false;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    final f = widget.initial;
    if (f != null) {
      _nameController.text = f.name;
      _brandController.text = f.brand ?? '';
      _unitSizeController.text = f.unitSize.toString();
      _kcalController.text = f.kcal.toString();
      _proteinController.text = f.protein.toString();
      _carbsController.text = f.carbs.toString();
      _fatController.text = f.fat.toString();
      _fiberController.text = f.fiber.toString();
      _sodiumController.text = f.sodium.toString();
      _perUnit = f.perUnit;
      _isSupplement = f.isSupplement;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.onSurface.withOpacity(0.3) : AppColors.grey300,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        _isSupplement ? Icons.medication : Icons.restaurant,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        isEdit ? 'Editar Alimento' : 'Nuevo Alimento',
                        style: AppTypography.heading2(context),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(begin: -0.2, duration: 300.ms),

              const SizedBox(height: AppSpacing.lg),

              TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: isDark ? colorScheme.onSurface.withOpacity(0.6) : AppColors.grey600,
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.info), text: 'Información'),
                  Tab(icon: Icon(Icons.analytics), text: 'Nutrición'),
                ],
              ),

              SizedBox(
                height: 500,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(colorScheme, isDark),
                    _buildNutritionTab(),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerHighest : AppColors.grey100,
                  border: Border(
                    top: BorderSide(color: isDark ? colorScheme.outline : AppColors.grey300),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ModernPrimaryButton(
                        label: isEdit ? 'Guardar Cambios' : 'Crear Alimento',
                        icon: Icons.check,
                        fullWidth: true,
                        isLoading: _isSaving,
                        onPressed: _saveFood,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoTab(ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernTextField(
            label: 'Nombre del alimento*',
            hint: 'Ej: Pechuga de pollo',
            controller: _nameController,
            prefixIcon: Icons.restaurant,
            validator: (v) => v == null || v.isEmpty ? 'Nombre requerido' : null,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          ModernTextField(
            label: 'Marca',
            hint: 'Opcional',
            controller: _brandController,
            prefixIcon: Icons.business,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          Text('Tamaño de porción', style: AppTypography.label(context)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ModernTextField(
                  label: 'Cantidad',
                  hint: '100',
                  controller: _unitSizeController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.numbers,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: isDark ? colorScheme.outline : AppColors.grey300),
                  ),
                  child: DropdownButton<UnitKind>(
                    value: _perUnit,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: UnitKind.g, child: Text('g')),
                      DropdownMenuItem(value: UnitKind.ml, child: Text('ml')),
                      DropdownMenuItem(value: UnitKind.unit, child: Text('unidad')),
                    ],
                    onChanged: (v) => setState(() => _perUnit = v ?? UnitKind.g),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.gym.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.gym.withOpacity(0.3)),
            ),
            child: SwitchListTile(
              value: _isSupplement,
              onChanged: (v) => setState(() => _isSupplement = v),
              title: Text('Es un suplemento', style: AppTypography.heading4(context)),
              subtitle: Text('Vitaminas, proteínas, etc.', style: AppTypography.caption(context)),
              secondary: Icon(Icons.medication, color: AppColors.gym),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNutritionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información nutricional',
            style: AppTypography.heading3(context),
          ),
          Text(
            'Por ${_unitSizeController.text.isEmpty ? "100" : _unitSizeController.text}${_perUnit.name}',
            style: AppTypography.caption(context),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
                     Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.foodGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Calorías',
                      style: AppTypography.heading4(context, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ModernTextField(
                  label: '',
                  hint: '250',
                  controller: _kcalController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.numbers,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),

          Text('Macronutrientes (gramos)', style: AppTypography.label(context)),
          const SizedBox(height: AppSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: _MacroField(
                  label: 'Proteínas',
                  controller: _proteinController,
                  color: AppColors.error,
                  icon: Icons.fitness_center,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MacroField(
                  label: 'Carbos',
                  controller: _carbsController,
                  color: AppColors.warning,
                  icon: Icons.bakery_dining,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          Row(
            children: [
              Expanded(
                child: _MacroField(
                  label: 'Grasas',
                  controller: _fatController,
                  color: AppColors.info,
                  icon: Icons.water_drop,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MacroField(
                  label: 'Fibra',
                  controller: _fiberController,
                  color: AppColors.success,
                  icon: Icons.eco,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          ModernTextField(
            label: 'Sodio (mg)',
            hint: '0',
            controller: _sodiumController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.grain,
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
        id: widget.initial?.id ?? '',
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        perUnit: _perUnit,
        unitSize: double.tryParse(_unitSizeController.text) ?? 100,
        kcal: double.tryParse(_kcalController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        fiber: double.tryParse(_fiberController.text) ?? 0,
        sodium: double.tryParse(_sodiumController.text) ?? 0,
        isSupplement: _isSupplement,
      );
      
      if (widget.initial == null) {
        await widget.svc.createFood(food);
      } else {
        await widget.svc.updateFood(widget.initial!.id, food.toMap());
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.initial == null 
                        ? 'Alimento creado correctamente'
                        : 'Alimento actualizado correctamente',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Error al guardar: $e',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MacroField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final IconData icon;
  
  const _MacroField({
    required this.label,
    required this.controller,
    required this.color,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption(context, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: color),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: color, width: 2),
            ),
            filled: true,
            fillColor: color.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }
}
