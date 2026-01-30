import 'package:flutter/material.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';
import 'food_dashboard_widgets.dart';
import 'food_diary_screen.dart';
import 'recipes_list_screen.dart';
import 'recipe_detail_screen.dart';
import 'food_planner_screen.dart';
import 'shopping_lists_screen.dart';

/// FOOD HOME SCREEN - Rediseñado con estilo premium SaaS
/// Dashboard principal del módulo Food con diseño moderno y profesional
/// Paleta pastel: #D7CDC2, #B5A89B, #80AAA6, #A0BFBD, #D2E2E0, #E5EDEF
class FoodDashboardScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  
  const FoodDashboardScreen({super.key, required this.svc});

  @override
  State<FoodDashboardScreen> createState() => _FoodDashboardScreenState();
}

class _FoodDashboardScreenState extends State<FoodDashboardScreen> {
  String _dayId(DateTime d) => d.toIso8601String().substring(0, 10);
  
  String _getWeekId(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return _dayId(monday);
  }

  @override
  Widget build(BuildContext context) {
    final todayId = _dayId(DateTime.now());
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Container(
            color: colorScheme.surfaceContainerHighest,
            padding: EdgeInsets.all(
              isDesktop ? 24.0 : 16.0,
            ),
            child: FoodTopBar(
              onNewRecipe: () => _navigateToRecipes(context),
              onWeeklyPlan: () => _navigateToPlanner(context),
              onFilter: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filtros próximamente')),
                );
              },
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(
                isDesktop ? 40.0 : 16.0,
              ),
              children: [
                _buildMetricsSection(context, todayId, isDesktop),
                const SizedBox(height: 12.0),
                
                _buildWeeklyPlanSection(context),
                const SizedBox(height: 20.0),
                
                isDesktop || isTablet
                    ? _buildBottomSectionDesktop(context)
                    : _buildBottomSectionMobile(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de métricas (4 tarjetas)
  Widget _buildMetricsSection(
    BuildContext context,
    String todayId,
    bool isDesktop,
  ) {
    return StreamBuilder<DailyIntakeDoc>(
      stream: widget.svc.streamDay(todayId),
      builder: (context, daySnap) {
        // Si hay error, usar valores por defecto sin mostrar snackbar durante build
        final day = daySnap.data ??
            DailyIntakeDoc(
              id: todayId,
              entries: const [],
              waterMl: 0,
              totals: const {
                'kcal': 0.0,
                'protein': 0.0,
                'carbs': 0.0,
                'fat': 0.0,
              },
              targets: const {},
            );

        final kcal = day.totals['kcal'] ?? 0.0;
        final protein = day.totals['protein'] ?? 0.0;
        
        return StreamBuilder<List<Recipe>>(
          stream: widget.svc.streamRecipes(),
          builder: (context, recipesSnap) {
            // Si hay error, usar valor por defecto
            final recipesCount = recipesSnap.data?.length ?? 0;

            return StreamBuilder<List<ShoppingList>>(
              stream: widget.svc.streamShoppingLists(),
              builder: (context, shoppingSnap) {
                // Si hay error, usar valor por defecto
                final shoppingItems =
                    shoppingSnap.data?.expand((list) => list.items).length ?? 0;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive: 4 columnas en desktop, 2 en tablet, 1 en mobile
                    final crossAxisCount = constraints.maxWidth >= 1200
                        ? 4
                        : constraints.maxWidth >= 600
                            ? 2
                            : 1;
                    
                    final cards = [
                      FoodMetricCard(
                        icon: Icons.local_fire_department,
                        label: 'Calorías hoy',
                        value: '${kcal.toStringAsFixed(0)} kcal',
                        subtitle: 'de 2,000 objetivo',
                        onTap: () => _navigateToDiary(context),
                      ),
                      FoodMetricCard(
                        icon: Icons.fitness_center,
                        label: 'Proteína hoy',
                        value: '${protein.toStringAsFixed(0)} g',
                        subtitle: 'de 150g objetivo',
                        onTap: () => _navigateToDiary(context),
                      ),
                      FoodMetricCard(
                        icon: Icons.restaurant_menu,
                        label: 'Recetas guardadas',
                        value: '$recipesCount',
                        subtitle: 'en tu biblioteca',
                        onTap: () => _navigateToRecipes(context),
                      ),
                      FoodMetricCard(
                        icon: Icons.shopping_cart,
                        label: 'Lista de compra',
                        value: '$shoppingItems productos',
                        subtitle: 'pendientes',
                        onTap: () => _navigateToShopping(context),
                      ),
                    ];

                    if (crossAxisCount == 1) {
                      // Mobile: columna simple
                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 16.0,
                                ),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
                    } else {
                      // Desktop/Tablet: Grid
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.3,
                        children: cards,
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// Sección del plan semanal
  Widget _buildWeeklyPlanSection(BuildContext context) {
    final weekId = _getWeekId(DateTime.now());
    
    return StreamBuilder<WeekPlanner>(
      stream: widget.svc.streamWeek(weekId),
      builder: (context, snapshot) {
        final weekPlan = snapshot.data;
        final weekDays = weekPlan?.days ?? {};
        
        final Map<String, Map<String, String>> displayPlan = {};
        
        for (var entry in weekDays.entries) {
          final dayId = entry.key;
          final dayEntries = entry.value;
          
          final meals = <String, String>{};
          for (var mealEntry in dayEntries) {
            final slotName = _getMealSlotName(mealEntry.slot);
            meals[slotName] = mealEntry.refId;
          }
          
          if (meals.isNotEmpty) {
            displayPlan[dayId] = meals;
          }
        }
        
        if (displayPlan.isEmpty) {
          displayPlan['${DateTime.now().toIso8601String().substring(0, 10)}'] = {
            'Info': 'No hay plan semanal configurado',
          };
        }
        
        return FoodWeeklyPlanCard(
          weekPlan: displayPlan,
          onGeneratePlan: () => _navigateToPlanner(context),
          onExportList: () => _navigateToShopping(context),
          onViewCalendar: () => _navigateToPlanner(context),
        );
      },
    );
  }
  
  String _getMealSlotName(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return 'Desayuno';
      case MealSlot.snack:
        return 'Snack';
      case MealSlot.lunch:
        return 'Comida';
      case MealSlot.merienda:
        return 'Merienda';
      case MealSlot.dinner:
        return 'Cena';
    }
  }

  /// Sección inferior para desktop (2 columnas)
  Widget _buildBottomSectionDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda: Recetas recientes
        Expanded(
          flex: 2,
          child: _buildRecipesSection(context),
        ),
        const SizedBox(width: 24.0),
        // Columna derecha: Lista de compra
        Expanded(
          flex: 1,
          child: _buildShoppingSection(context),
        ),
      ],
    );
  }

  /// Sección inferior para mobile (columnas apiladas)
  Widget _buildBottomSectionMobile(BuildContext context) {
    return Column(
      children: [
        _buildRecipesSection(context),
        const SizedBox(height: 24.0),
        _buildShoppingSection(context),
      ],
    );
  }

  /// Sección de recetas recientes/recomendadas
  Widget _buildRecipesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return StreamBuilder<List<Recipe>>(
      stream: widget.svc.streamRecipes(),
      builder: (context, snapshot) {
        final recipes = snapshot.data ?? [];
        final recentRecipes = recipes.take(6).toList();

        return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FoodSectionHeader(
            title: 'Recetas Recientes',
            subtitle: 'Tus favoritas',
            icon: Icons.restaurant,
            actionLabel: 'Ver todas',
            onActionPressed: () => _navigateToRecipes(context),
          ),
          const SizedBox(height: 20.0),
          if (recentRecipes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.restaurant, size: 64, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16.0),
                    Text(
                      'No hay recetas guardadas',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextButton(
                      onPressed: () => _navigateToRecipes(context),
                      child: const Text('Añadir primera receta'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentRecipes.map((recipe) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: FoodRecipeCard(
                  name: recipe.name,
                  tags: _getRecipeTags(recipe),
                  kcal: _calculateRecipeKcal(recipe) ?? 0,
                  protein: _calculateRecipeProtein(recipe) ?? 0,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(
                        recipe: recipe,
                        svc: widget.svc,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
      },
    );
  }

  /// Sección de lista de compra
  Widget _buildShoppingSection(BuildContext context) {
    return StreamBuilder<List<ShoppingList>>(
      stream: widget.svc.streamShoppingLists(),
      builder: (context, snapshot) {
        final lists = snapshot.data ?? [];
        final activeList = lists.where((l) => l.completedAt == null).firstOrNull;
        
        final items = activeList?.items.map((item) {
          return ShoppingItem(
            name: item.name,
            category: _getCategoryLabel(item.unit.name),
            checked: item.checked,
          );
        }).toList() ?? [];

        return FoodShoppingListCard(
          items: items.isEmpty ? _getPlaceholderShoppingItems() : items,
          onNavigate: () => _navigateToShopping(context),
        );
      },
    );
  }

  /// Helpers para obtener datos de recetas (placeholders por ahora)
  List<String> _getRecipeTags(Recipe recipe) {
    // TODO: Implementar lógica real de tags
    final tags = <String>[];
    
    if (recipe.name.toLowerCase().contains('pollo') ||
        recipe.name.toLowerCase().contains('pavo')) {
      tags.add('High protein');
    }
    if (recipe.name.toLowerCase().contains('ensalada') ||
        recipe.name.toLowerCase().contains('vegetal')) {
      tags.add('Low carb');
    }
    if (recipe.name.toLowerCase().contains('vegano') ||
        recipe.name.toLowerCase().contains('vegan')) {
      tags.add('Vegan');
    }
    
    // Tags por defecto si no hay coincidencias
    if (tags.isEmpty) {
      tags.add('Casera');
    }
    
    return tags;
  }

  double? _calculateRecipeKcal(Recipe recipe) {
    // TODO: Calcular calorías reales desde ingredientes
    // Por ahora retornar un valor placeholder
    return 450.0;
  }

  double? _calculateRecipeProtein(Recipe recipe) {
    // TODO: Calcular proteína real desde ingredientes
    return 32.0;
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return 'Fruta';
      case 'protein':
        return 'Proteína';
      case 'dairy':
        return 'Lácteos';
      case 'vegetable':
        return 'Verduras';
      case 'grain':
        return 'Granos';
      default:
        return 'Otros';
    }
  }

  List<ShoppingItem> _getPlaceholderShoppingItems() {
    // Placeholder para demo cuando no hay lista activa
    return const [
      ShoppingItem(name: 'Plátanos', category: 'Fruta', checked: false),
      ShoppingItem(name: 'Pechuga de pollo', category: 'Proteína', checked: false),
      ShoppingItem(name: 'Leche', category: 'Lácteos', checked: false),
      ShoppingItem(name: 'Brócoli', category: 'Verduras', checked: true),
      ShoppingItem(name: 'Avena', category: 'Granos', checked: false),
      ShoppingItem(name: 'Huevos', category: 'Proteína', checked: false),
      ShoppingItem(name: 'Manzanas', category: 'Fruta', checked: false),
      ShoppingItem(name: 'Yogur griego', category: 'Lácteos', checked: false),
      ShoppingItem(name: 'Espinacas', category: 'Verduras', checked: false),
      ShoppingItem(name: 'Arroz integral', category: 'Granos', checked: true),
      ShoppingItem(name: 'Salmón', category: 'Proteína', checked: false),
      ShoppingItem(name: 'Aceite de oliva', category: 'Otros', checked: false),
    ];
  }

  // Navegación
  void _navigateToDiary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDiaryScreen(svc: widget.svc),
      ),
    );
  }

  void _navigateToRecipes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipesListScreen(svc: widget.svc),
      ),
    );
  }

  void _navigateToPlanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodPlannerScreen(svc: widget.svc),
      ),
    );
  }

  void _navigateToShopping(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListsScreen(svc: widget.svc),
      ),
    );
  }
}
