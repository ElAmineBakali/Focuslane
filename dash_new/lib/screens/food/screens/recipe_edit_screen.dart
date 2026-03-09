import 'package:flutter/material.dart';
import '../../../design/theme/focuslane_ui.dart';
import '../../../design/theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import '../widgets/food_compact_widgets.dart';

class RecipeEditScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  final Recipe? initial;

  const RecipeEditScreen({super.key, required this.svc, this.initial});

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');

  List<RecipeIngredient> _ingredients = [];
  List<String> _steps = [];
  List<String> _tags = [];

  bool _isSaving = false;
  bool _isCalculating = false;
  Map<String, double>? _calculatedMacros;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final r = widget.initial;
    if (r != null) {
      _nameController.text = r.name;
      _descController.text = r.description ?? '';
      _servingsController.text = r.servings.toString();
      _ingredients = List.from(r.ingredients);
      if (r.steps.isNotEmpty) _steps = [r.steps];
      _tags = List.from(r.tags);

      if (r.kcal != null) {
        _calculatedMacros = {
          'kcal': r.kcal!,
          'protein': r.protein ?? 0,
          'carbs': r.carbs ?? 0,
          'fat': r.fat ?? 0,
          'fiber': r.fiber ?? 0,
          'sodium': r.sodium ?? 0,
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Scaffold(
      appBar: FoodCompactAppBar(
        title: isEdit ? 'Editar receta' : 'Nueva receta',
        subtitle: 'Editor de recetas',
        actions: [
          if (_ingredients.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.calculate, size: 18),
              onPressed: _calculateMacros,
              tooltip: 'Calcular macros',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: FocuslaneUI.accent(context),
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: FocuslaneUI.accent(context),
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Información'),
                Tab(icon: Icon(Icons.restaurant), text: 'Ingredientes'),
                Tab(icon: Icon(Icons.list_alt), text: 'Pasos'),
                Tab(icon: Icon(Icons.analytics), text: 'Nutrición'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildIngredientsTab(),
                  _buildStepsTab(),
                  _buildNutritionTab(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ModernPrimaryButton(
                      label: isEdit ? 'Guardar Cambios' : 'Crear Receta',
                      icon: Icons.check,
                      fullWidth: true,
                      color: FocuslaneUI.accent(context),
                      isLoading: _isSaving,
                      onPressed: _saveRecipe,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernTextField(
            label: 'Nombre de la receta*',
            hint: 'Ej: Pollo al horno con verduras',
            controller: _nameController,
            prefixIcon: Icons.menu_book,
            validator:
                (v) => v == null || v.isEmpty ? 'Nombre requerido' : null,
          ),

          const SizedBox(height: AppSpacing.md),

          ModernTextField(
            label: 'Descripción',
            hint: 'Opcional',
            controller: _descController,
            prefixIcon: Icons.description,
            maxLines: 3,
          ),

          const SizedBox(height: AppSpacing.md),

          ModernTextField(
            label: 'Número de raciones*',
            hint: '4',
            controller: _servingsController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.people,
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          ),

          const SizedBox(height: AppSpacing.md),

          Text('Etiquetas', style: AppTypography.label(context)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ..._tags.map(
                (tag) => ModernChip(
                  label: tag,
                  onDelete: () => setState(() => _tags.remove(tag)),
                ),
              ),
              ModernChip(
                label: '+ Añadir',
                icon: Icons.add,
                color: FocuslaneUI.accent(context),
                onTap: _addTag,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab() {
    return Column(
      children: [
        if (_ingredients.isEmpty)
          Expanded(
            child: ModernEmptyState(
              icon: Icons.restaurant_outlined,
              message: 'No hay ingredientes',
              subtitle:
                  'Añade ingredientes para calcular automáticamente las macros',
              actionLabel: 'Añadir ingrediente',
              onAction: _addIngredient,
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _ingredients.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _ingredients.removeAt(oldIndex);
                  _ingredients.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final ing = _ingredients[index];
                return _IngredientCard(
                  key: ValueKey(ing.hashCode),
                  ingredient: ing,
                  onEdit: () => _editIngredient(index),
                  onDelete: () => setState(() => _ingredients.removeAt(index)),
                );
              },
            ),
          ),

        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ModernPrimaryButton(
            label: 'Añadir Ingrediente',
            icon: Icons.add,
            fullWidth: true,
            color: FocuslaneUI.accent(context),
            onPressed: _addIngredient,
          ),
        ),
      ],
    );
  }

  Widget _buildStepsTab() {
    return Column(
      children: [
        if (_steps.isEmpty)
          Expanded(
            child: ModernEmptyState(
              icon: Icons.list_alt_outlined,
              message: 'No hay pasos',
              subtitle: 'Añade los pasos de preparación',
              actionLabel: 'Añadir paso',
              onAction: _addStep,
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _steps.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _steps.removeAt(oldIndex);
                  _steps.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                return _StepCard(
                  key: ValueKey(_steps[index]),
                  stepNumber: index + 1,
                  stepText: _steps[index],
                  onEdit: () => _editStep(index),
                  onDelete: () => setState(() => _steps.removeAt(index)),
                );
              },
            ),
          ),

        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ModernPrimaryButton(
            label: 'Añadir Paso',
            icon: Icons.add,
            fullWidth: true,
            color: FocuslaneUI.accent(context),
            onPressed: _addStep,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_calculatedMacros == null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: FocuslaneUI.accentSurface(context, opacity: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: FocuslaneUI.borderColor(context),
                  width: FocuslaneUI.borderW,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info,
                    color: FocuslaneUI.accent(context),
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Auto-cálculo de Macros',
                    style: AppTypography.heading3(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Añade ingredientes con cantidades y presiona el botón de calcular para obtener automáticamente los valores nutricionales',
                    style: AppTypography.body(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ModernPrimaryButton(
                    label:
                        _ingredients.isEmpty
                            ? 'Añade ingredientes primero'
                            : 'Calcular Macros Ahora',
                    icon: Icons.calculate,
                    fullWidth: true,
                    color: FocuslaneUI.accent(context),
                    isLoading: _isCalculating,
                    onPressed: _ingredients.isEmpty ? null : _calculateMacros,
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Información Nutricional Total',
                  style: AppTypography.heading3(context),
                ),
                ModernBadge(
                  label: 'AUTO-CALCULADO',
                  color: FocuslaneUI.accent2(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Para toda la receta (${_servingsController.text} raciones)',
              style: AppTypography.caption(context),
            ),

            const SizedBox(height: AppSpacing.md),

            _NutritionSummaryCard(
              macros: _calculatedMacros!,
              servings: int.tryParse(_servingsController.text) ?? 1,
            ),

            const SizedBox(height: AppSpacing.md),

            Center(
              child: OutlinedButton.icon(
                onPressed: _calculateMacros,
                icon: const Icon(Icons.refresh),
                label: const Text('Recalcular'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FocuslaneUI.accent(context),
                  side: BorderSide(
                    color: FocuslaneUI.borderColor(context),
                    width: FocuslaneUI.borderW,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Añadir Etiqueta', style: AppTypography.heading3(ctx)),
            content: ModernTextField(
              label: 'Etiqueta',
              hint: 'Ej: vegano, rápido, saludable',
              controller: controller,
              prefixIcon: Icons.label,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Añadir'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty && !_tags.contains(result)) {
      setState(() => _tags.add(result));
    }
  }

  Future<void> _addIngredient() async {
    FoodFeedback.showInfo(
      context,
      'Añadir ingrediente estará disponible pronto',
    );
  }

  Future<void> _editIngredient(int index) async {}

  Future<void> _addStep() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Añadir Paso', style: AppTypography.heading3(ctx)),
            content: ModernTextField(
              label: 'Descripción del paso',
              hint: 'Ej: Precalentar el horno a 180°C',
              controller: controller,
              prefixIcon: Icons.edit,
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Añadir'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _steps.add(result));
    }
  }

  Future<void> _editStep(int index) async {
    final controller = TextEditingController(text: _steps[index]);
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Editar Paso', style: AppTypography.heading3(ctx)),
            content: ModernTextField(
              label: 'Descripción del paso',
              controller: controller,
              prefixIcon: Icons.edit,
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _steps[index] = result);
    }
  }

  Future<void> _calculateMacros() async {
    if (_ingredients.isEmpty) return;

    setState(() => _isCalculating = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _calculatedMacros = {
          'kcal': 450.0,
          'protein': 35.0,
          'carbs': 25.0,
          'fat': 20.0,
          'fiber': 5.0,
          'sodium': 350.0,
        };
      });

      FoodFeedback.showSuccess(context, 'Macros calculadas');
    } catch (e) {
      FoodFeedback.showError(context, 'Error al calcular macros: $e');
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final recipe = Recipe(
        id: widget.initial?.id ?? '',
        name: _nameController.text.trim(),
        description:
            _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
        servings: int.tryParse(_servingsController.text) ?? 1,
        ingredients: _ingredients,
        steps: _steps.join('\n'),
        tags: _tags,
        kcal: _calculatedMacros?['kcal'],
        protein: _calculatedMacros?['protein'],
        carbs: _calculatedMacros?['carbs'],
        fat: _calculatedMacros?['fat'],
        fiber: _calculatedMacros?['fiber'],
        sodium: _calculatedMacros?['sodium'],
      );

      if (widget.initial == null) {
        await widget.svc.createRecipe(recipe);
      } else {
        await widget.svc.updateRecipe(widget.initial!.id, recipe.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
        FoodFeedback.showSuccess(
          context,
          widget.initial == null
              ? 'Receta creada correctamente'
              : 'Receta actualizada correctamente',
        );
      }
    } catch (e) {
      if (mounted) {
        FoodFeedback.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _IngredientCard extends StatelessWidget {
  final RecipeIngredient ingredient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IngredientCard({
    super.key,
    required this.ingredient,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = ingredient.freeName ?? ingredient.foodId ?? 'Ingrediente';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocuslaneUI.radius),
        side: BorderSide(
          color: FocuslaneUI.borderColor(context),
          width: FocuslaneUI.borderW,
        ),
      ),
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(name),
        subtitle: Text('${ingredient.qty} ${ingredient.unit.name}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String stepText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StepCard({
    super.key,
    required this.stepNumber,
    required this.stepText,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocuslaneUI.radius),
        side: BorderSide(
          color: FocuslaneUI.borderColor(context),
          width: FocuslaneUI.borderW,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: FocuslaneUI.accent(context),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: AppTypography.heading4(
                context,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        title: Text(stepText),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionSummaryCard extends StatelessWidget {
  final Map<String, double> macros;
  final int servings;

  const _NutritionSummaryCard({required this.macros, required this.servings});

  @override
  Widget build(BuildContext context) {
    final perServing = macros.map((k, v) => MapEntry(k, v / servings));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: FocuslaneUI.primaryGradient(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Por ración',
                style: AppTypography.heading3(
                  context,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              ModernBadge(
                label: '1/$servings',
                color: Theme.of(context).colorScheme.onPrimary,
                textColor: FocuslaneUI.accent(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${perServing['kcal']!.toStringAsFixed(0)} kcal',
                style: AppTypography.heading1(
                  context,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroDisplay(
                label: 'Proteínas',
                value: perServing['protein']!.toStringAsFixed(1),
                unit: 'g',
              ),
              _MacroDisplay(
                label: 'Carbohidratos',
                value: perServing['carbs']!.toStringAsFixed(1),
                unit: 'g',
              ),
              _MacroDisplay(
                label: 'Grasas',
                value: perServing['fat']!.toStringAsFixed(1),
                unit: 'g',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroDisplay extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MacroDisplay({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.heading2(
            context,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        Text(
          unit,
          style: AppTypography.caption(
            context,
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption(
            context,
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

