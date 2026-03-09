import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design/theme/global_ui_theme.dart';
import '../widgets/food_compact_widgets.dart';
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
      appBar: FoodCompactAppBar(
        title: recipe.name,
        subtitle: 'Detalle de receta',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Editar receta',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeEditScreen(svc: svc, initial: recipe),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((recipe.description ?? '').trim().isNotEmpty) ...[
              FoodCompactCard(
                maxHeight: 140,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notes,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Descripción',
                          style: AppTypography.heading4(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      recipe.description!.trim(),
                      style: AppTypography.body(context),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (recipe.tags.isNotEmpty) ...[
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: recipe.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (hasNutrition) ...[
              FoodCompactCard(
                maxHeight: 180,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Información Nutricional',
                          style: AppTypography.heading4(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Totales (${recipe.servings} raciones)',
                      style: AppTypography.caption(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _NutrientRow(
                      label: 'Calorías',
                      value: '${recipe.kcal!.toStringAsFixed(0)} kcal',
                      icon: Icons.local_fire_department,
                      color: colorScheme.primary,
                    ),
                    _NutrientRow(
                      label: 'Proteínas',
                      value: '${recipe.protein!.toStringAsFixed(1)} g',
                      icon: Icons.fitness_center,
                      color: colorScheme.secondary,
                    ),
                    _NutrientRow(
                      label: 'Carbohidratos',
                      value: '${recipe.carbs!.toStringAsFixed(1)} g',
                      icon: Icons.bakery_dining,
                      color: colorScheme.tertiary,
                    ),
                    _NutrientRow(
                      label: 'Grasas',
                      value: '${recipe.fat!.toStringAsFixed(1)} g',
                      icon: Icons.water_drop,
                      color: colorScheme.primary,
                    ),
                    if (recipe.fiber != null)
                      _NutrientRow(
                        label: 'Fibra',
                        value: '${recipe.fiber!.toStringAsFixed(1)} g',
                        icon: Icons.eco,
                        color: colorScheme.secondary,
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
              const SizedBox(height: AppSpacing.sm),
            ],
            FoodCompactCard(
              maxHeight: 180,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Ingredientes',
                        style: AppTypography.heading4(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...recipe.ingredients.asMap().entries.map((entry) {
                    final ingredient = entry.value;
                    final displayName =
                        ingredient.freeName ?? ingredient.foodId ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            if (recipe.steps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              FoodCompactCard(
                maxHeight: 220,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Preparación',
                          style: AppTypography.heading4(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      recipe.steps,
                      style: AppTypography.body(context),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
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
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTypography.body(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.body(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

