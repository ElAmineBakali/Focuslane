import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/global_ui_components.dart';
import '../services/food_service_facade.dart';
import '../models/food_models.dart';

/// 📅 PLANNER DETAIL SCREEN
/// Vista y edición del planificador semanal
class PlannerDetailScreen extends StatefulWidget {
  final FoodServiceFacade svc;
  final String plannerId;

  const PlannerDetailScreen({
    super.key,
    required this.svc,
    required this.plannerId,
  });

  @override
  State<PlannerDetailScreen> createState() => _PlannerDetailScreenState();
}

class _PlannerDetailScreenState extends State<PlannerDetailScreen> {
  final _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificador Semanal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Generar lista de compras',
            onPressed: () => _generateShopping(context),
          ),
        ],
      ),
      body: StreamBuilder<WeekPlanner?>(
        stream: widget.svc.planner.streamPlanner(widget.plannerId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final planner = snap.data;
          if (planner == null) {
            return const FocusEmptyState(
              icon: Icons.error_outline,
              message: 'Planificador no encontrado',
            );
          }

          return Column(
            children: [
              // Selector de días
              _buildDaySelector(planner),

              // Contenido del día
              Expanded(
                child: _buildDayContent(context, planner, _selectedDayIndex),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDaySelector(WeekPlanner planner) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: FocusSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.md),
        itemCount: 7,
        itemBuilder: (_, i) {
          final isSelected = i == _selectedDayIndex;
          final dayMenus = planner.dayMap[i];
          final mealsCount = dayMenus == null
              ? 0
              : dayMenus.breakfast.length +
                  dayMenus.lunch.length +
                  dayMenus.dinner.length +
                  dayMenus.snack.length;

          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = i),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: FocusSpacing.sm),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [Colors.green, Colors.teal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : FocusColors.grey200,
                borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayNames[i],
                    style: FocusTypography.label(context).copyWith(
                      color: isSelected ? Colors.white : FocusColors.grey700,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: FocusSpacing.xs),
                  if (mealsCount > 0)
                    FocusBadge(
                      label: mealsCount.toString(),
                      color: isSelected ? Colors.white : Colors.green,
                      textColor:
                          isSelected ? Colors.green : Colors.white,
                    ),
                ],
              ),
            ),
          ).animate(target: isSelected ? 1 : 0).scale();
        },
      ),
    );
  }

  Widget _buildDayContent(
      BuildContext context, WeekPlanner planner, int dayIndex) {
    final dayMenus = planner.dayMap[dayIndex];

    if (dayMenus == null ||
        (dayMenus.breakfast.isEmpty &&
            dayMenus.lunch.isEmpty &&
            dayMenus.dinner.isEmpty &&
            dayMenus.snack.isEmpty)) {
      return FocusEmptyState(
        icon: Icons.add_circle_outline,
        message: 'Sin comidas planificadas',
        subtitle: 'Añade recetas a ${_dayNames[dayIndex]}',
        actionLabel: 'Añadir Comida',
        onAction: () => _showAddMealSheet(context, planner, dayIndex),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FocusSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Desayuno
          if (dayMenus.breakfast.isNotEmpty)
            _buildMealSection(
              context,
              planner,
              dayIndex,
              '🌅 Desayuno',
              MealTag.breakfast,
              dayMenus.breakfast,
              Colors.orange,
            ),

          // Comida
          if (dayMenus.lunch.isNotEmpty)
            _buildMealSection(
              context,
              planner,
              dayIndex,
              '🌞 Comida',
              MealTag.lunch,
              dayMenus.lunch,
              Colors.blue,
            ),

          // Cena
          if (dayMenus.dinner.isNotEmpty)
            _buildMealSection(
              context,
              planner,
              dayIndex,
              '🌙 Cena',
              MealTag.dinner,
              dayMenus.dinner,
              Colors.purple,
            ),

          // Snacks
          if (dayMenus.snack.isNotEmpty)
            _buildMealSection(
              context,
              planner,
              dayIndex,
              '🍎 Snacks',
              MealTag.snack,
              dayMenus.snack,
              Colors.green,
            ),

          // Botón de añadir más
          const SizedBox(height: FocusSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _showAddMealSheet(context, planner, dayIndex),
            icon: const Icon(Icons.add),
            label: const Text('Añadir Comida'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(
    BuildContext context,
    WeekPlanner planner,
    int dayIndex,
    String title,
    MealTag mealTag,
    List<PlannedMeal> meals,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: FocusSpacing.md),
            Text(title, style: FocusTypography.heading3(context)),
          ],
        ),
        const SizedBox(height: FocusSpacing.md),
        ...meals.map((meal) => _buildPlannedMealCard(
              context,
              planner,
              dayIndex,
              mealTag,
              meal,
              color,
            )),
        const SizedBox(height: FocusSpacing.lg),
      ],
    );
  }

  Widget _buildPlannedMealCard(
    BuildContext context,
    WeekPlanner planner,
    int dayIndex,
    MealTag mealTag,
    PlannedMeal meal,
    Color color,
  ) {
    return StreamBuilder<Recipe?>(
      stream: widget.svc.catalog.streamRecipeById(meal.recipeId),
      builder: (context, snap) {
        final recipe = snap.data;

        return Card(
          margin: const EdgeInsets.only(bottom: FocusSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(Icons.menu_book, color: color),
            ),
            title: Text(
              recipe?.name ?? 'Receta',
              style: FocusTypography.heading4(context),
            ),
            subtitle: meal.note != null
                ? Text(
                    meal.note!,
                    style: FocusTypography.caption(context),
                  )
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeMeal(planner, dayIndex, mealTag, meal),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddMealSheet(
    BuildContext context,
    WeekPlanner planner,
    int dayIndex,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddMealSheet(
        svc: widget.svc,
        planner: planner,
        dayIndex: dayIndex,
      ),
    );
  }

  Future<void> _removeMeal(
    WeekPlanner planner,
    int dayIndex,
    MealTag mealTag,
    PlannedMeal meal,
  ) async {
    final dayMenus = Map<int, DayMenu>.from(planner.dayMap);
    final currentDay = dayMenus[dayIndex]!;

    List<PlannedMeal> updatedMeals;
    switch (mealTag) {
      case MealTag.breakfast:
        updatedMeals =
            List.from(currentDay.breakfast)..removeWhere((m) => m == meal);
        dayMenus[dayIndex] = currentDay.copyWith(breakfast: updatedMeals);
        break;
      case MealTag.lunch:
        updatedMeals =
            List.from(currentDay.lunch)..removeWhere((m) => m == meal);
        dayMenus[dayIndex] = currentDay.copyWith(lunch: updatedMeals);
        break;
      case MealTag.dinner:
        updatedMeals =
            List.from(currentDay.dinner)..removeWhere((m) => m == meal);
        dayMenus[dayIndex] = currentDay.copyWith(dinner: updatedMeals);
        break;
      case MealTag.snack:
        updatedMeals =
            List.from(currentDay.snack)..removeWhere((m) => m == meal);
        dayMenus[dayIndex] = currentDay.copyWith(snack: updatedMeals);
        break;
    }

    final updated = planner.copyWith(dayMap: dayMenus);
    await widget.svc.planner.updatePlanner(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ Comida eliminada')),
    );
  }

  Future<void> _generateShopping(BuildContext context) async {
    final planner = await widget.svc.planner.getPlanner(widget.plannerId);
    if (planner == null) return;

    await widget.svc.planner.generateShoppingFromPlanner(
      plannerId: planner.id,
      multiplier: planner.customMultiplier,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Lista de compras generada')),
    );
  }
}

/// Sheet para añadir comidas al planificador
class _AddMealSheet extends StatefulWidget {
  final FoodServiceFacade svc;
  final WeekPlanner planner;
  final int dayIndex;

  const _AddMealSheet({
    required this.svc,
    required this.planner,
    required this.dayIndex,
  });

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  MealTag _selectedMeal = MealTag.lunch;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(FocusSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Añadir Comida',
              style: FocusTypography.heading2(context),
            ),
            const SizedBox(height: FocusSpacing.lg),

            // Selector de comida
            DropdownButtonFormField<MealTag>(
              value: _selectedMeal,
              decoration: InputDecoration(
                labelText: 'Tipo de comida',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                ),
              ),
              items: MealTag.values.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(_mealName(m)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedMeal = v!),
            ),

            const SizedBox(height: FocusSpacing.md),

            // Buscador
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar recetas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                ),
              ),
            ),

            const SizedBox(height: FocusSpacing.md),

            // Lista de recetas
            Expanded(
              child: StreamBuilder<List<Recipe>>(
                stream: widget.svc.catalog.streamRecipes(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allRecipes = snap.data ?? [];
                  final filteredRecipes = _searchQuery.isEmpty
                      ? allRecipes
                      : allRecipes
                          .where((r) =>
                              r.name.toLowerCase().contains(_searchQuery))
                          .toList();

                  if (filteredRecipes.isEmpty) {
                    return const FocusEmptyState(
                      icon: Icons.search_off,
                      message: 'Sin recetas',
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredRecipes.length,
                    itemBuilder: (_, i) {
                      final recipe = filteredRecipes[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.2),
                          child: const Icon(Icons.menu_book,
                              color: Colors.purple),
                        ),
                        title: Text(recipe.name),
                        subtitle: recipe.description != null
                            ? Text(
                                recipe.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () => _addRecipe(context, recipe.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addRecipe(BuildContext context, String recipeId) async {
    final dayMenus = Map<int, DayMenu>.from(widget.planner.dayMap);
    final currentDay = dayMenus[widget.dayIndex] ??
        DayMenu(
          breakfast: const [],
          lunch: const [],
          dinner: const [],
          snack: const [],
        );

    final newMeal = PlannedMeal(recipeId: recipeId, note: null);

    List<PlannedMeal> updatedMeals;
    switch (_selectedMeal) {
      case MealTag.breakfast:
        updatedMeals = [...currentDay.breakfast, newMeal];
        dayMenus[widget.dayIndex] = currentDay.copyWith(breakfast: updatedMeals);
        break;
      case MealTag.lunch:
        updatedMeals = [...currentDay.lunch, newMeal];
        dayMenus[widget.dayIndex] = currentDay.copyWith(lunch: updatedMeals);
        break;
      case MealTag.dinner:
        updatedMeals = [...currentDay.dinner, newMeal];
        dayMenus[widget.dayIndex] = currentDay.copyWith(dinner: updatedMeals);
        break;
      case MealTag.snack:
        updatedMeals = [...currentDay.snack, newMeal];
        dayMenus[widget.dayIndex] = currentDay.copyWith(snack: updatedMeals);
        break;
    }

    final updated = widget.planner.copyWith(dayMap: dayMenus);
    await widget.svc.planner.updatePlanner(updated);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Receta añadida al planificador')),
    );
  }

  String _mealName(MealTag m) {
    switch (m) {
      case MealTag.breakfast:
        return '🌅 Desayuno';
      case MealTag.lunch:
        return '🌞 Comida';
      case MealTag.dinner:
        return '🌙 Cena';
      case MealTag.snack:
        return '🍎 Snack';
    }
  }
}
