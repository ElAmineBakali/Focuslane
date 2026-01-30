import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import 'recipe_edit_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  final FoodFirestoreService svc;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    final hasNutrition = recipe.kcal != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: ModernGradientAppBar(
        title: recipe.name,
        icon: Icons.menu_book,
        useThemeColors: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeEditScreen(
                    svc: svc,
                    initial: recipe,
                  ),
                ),
              );
            },
            tooltip: 'Editar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.description != null) ...[
              Card(
                elevation: AppSpacing.elevationSm,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    recipe.description!,
                    style: AppTypography.body(context),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            if (recipe.tags.isNotEmpty) ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: recipe.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            if (hasNutrition) ...[
              Card(
                elevation: AppSpacing.elevationMd,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Información Nutricional',
                            style: AppTypography.heading3(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Totales (${recipe.servings} raciones)',
                        style: AppTypography.caption(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _NutrientRow(
                        label: 'Calorías',
                        value: '${recipe.kcal!.toStringAsFixed(0)} kcal',
                        icon: Icons.local_fire_department,
                        color: AppColors.food,
                      ),
                      _NutrientRow(
                        label: 'Proteínas',
                        value: '${recipe.protein!.toStringAsFixed(1)} g',
                        icon: Icons.fitness_center,
                        color: AppColors.error,
                      ),
                      _NutrientRow(
                        label: 'Carbohidratos',
                        value: '${recipe.carbs!.toStringAsFixed(1)} g',
                        icon: Icons.bakery_dining,
                        color: AppColors.warning,
                      ),
                      _NutrientRow(
                        label: 'Grasas',
                        value: '${recipe.fat!.toStringAsFixed(1)} g',
                        icon: Icons.water_drop,
                        color: AppColors.info,
                      ),
                      if (recipe.fiber != null)
                        _NutrientRow(
                          label: 'Fibra',
                          value: '${recipe.fiber!.toStringAsFixed(1)} g',
                          icon: Icons.eco,
                          color: AppColors.success,
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            Card(
              elevation: AppSpacing.elevationSm,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_basket,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Ingredientes',
                          style: AppTypography.heading3(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...recipe.ingredients.asMap().entries.map((entry) {
                      final ingredient = entry.value;
                      final displayName = ingredient.freeName ?? ingredient.foodId ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '$displayName - ${ingredient.qty.toStringAsFixed(0)} ${ingredient.unit.name}',
                                style: AppTypography.body(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            
            if (recipe.steps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Card(
                elevation: AppSpacing.elevationSm,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_list_numbered,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Preparación',
                            style: AppTypography.heading3(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        recipe.steps,
                        style: AppTypography.body(context),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
            ],
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _NutrientRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(context),
            ),
          ),
          Text(
            value,
            style: AppTypography.body(context).copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
