import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_dashboard_personal/navigation/app_route_observer.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';
import 'food_dashboard_widgets.dart';
import '../../../shared/ui/app_card.dart';
import 'food_diary_screen.dart';
import 'recipes_list_screen.dart';
import 'recipe_detail_screen.dart';
import 'food_planner_screen.dart';
import 'shopping_lists_screen.dart';
import '../widgets/food_compact_widgets.dart';
import '../../../theme/focuslane_ui.dart';
import '../../../ui/components/focus_module_header.dart';
import '../../../core/constants/core_routes.dart';

class FoodDashboardScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  
  const FoodDashboardScreen({super.key, required this.svc});

  @override
  State<FoodDashboardScreen> createState() => _FoodDashboardScreenState();
}

class _FoodDashboardScreenState extends State<FoodDashboardScreen>
    with RouteAware {
  String _dayId(DateTime d) => d.toIso8601String().substring(0, 10);
  
  String _getWeekId(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return _dayId(monday);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
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
      appBar: FoodCompactAppBar(
        title: 'Food',
        subtitle: 'Planificación, recetas y seguimiento',
        leadingMode: FocusModuleLeadingMode.exitModule,
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined, size: 18),
            tooltip: 'Abrir Hub',
            onPressed: () => Navigator.pushNamed(context, CoreRoutes.coreHub),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 18),
            tooltip: 'Plan semanal',
            onPressed: () => _navigateToPlanner(context),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Nueva receta',
            onPressed: () => _navigateToRecipes(context),
          ),
        ],
      ),
      body: ListView(
        padding: isDesktop
            ? const EdgeInsets.all(40)
            : FocuslaneUI.pagePaddingCompact,
        children: [
          _buildMetricsSection(context, todayId, isDesktop),
          const SizedBox(height: 8.0),
          _buildWeeklyPlanSection(context),
          const SizedBox(height: 10.0),
          isDesktop || isTablet
              ? _buildBottomSectionDesktop(context)
              : _buildBottomSectionMobile(context),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(
    BuildContext context,
    String todayId,
    bool isDesktop,
  ) {
    return StreamBuilder<DailyIntakeDoc>(
      stream: widget.svc.streamDay(todayId),
      builder: (context, daySnap) {
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
            final recipesCount = recipesSnap.data?.length ?? 0;

            return StreamBuilder<List<ShoppingList>>(
              stream: widget.svc.streamShoppingLists(),
              builder: (context, shoppingSnap) {
                final shoppingItems =
                    shoppingSnap.data?.expand((list) => list.items).length ?? 0;

                return LayoutBuilder(
                  builder: (context, constraints) {
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
                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 10.0,
                                ),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
                    } else {
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.8,
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

  Widget _buildWeeklyPlanSection(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.svc.streamWeekPlannersRaw(),
      builder: (context, snapshot) {
        final plannersRaw = snapshot.data ?? [];
        final selected = _pickActivePlanner(plannersRaw);
        if (selected == null) {
          return FoodWeeklyPlanCard(
            weekPlan: const {},
            onGeneratePlan: () => _navigateToPlanner(context),
            onExportList: () => _navigateToShopping(context),
            onViewCalendar: () => _navigateToPlanner(context),
          );
        }

        final planner = WeekPlanner.fromMap(
          selected['id'] as String,
          Map<String, dynamic>.from(selected),
        );

        return StreamBuilder<List<Food>>(
          stream: widget.svc.streamFoods(),
          builder: (context, foodsSnap) {
            final foods = foodsSnap.data ?? [];
            final foodsMap = {for (final f in foods) f.id: f.name};

            return StreamBuilder<List<Recipe>>(
              stream: widget.svc.streamRecipes(),
              builder: (context, recipesSnap) {
                final recipes = recipesSnap.data ?? [];
                final recipesMap = {
                  for (final r in recipes) r.id: r.name,
                };

                final displayPlan = _buildDisplayPlan(
                  planner,
                  foodsMap: foodsMap,
                  recipesMap: recipesMap,
                );

                return FoodWeeklyPlanCard(
                  weekPlan: displayPlan,
                  onGeneratePlan: () => _navigateToPlanner(context),
                  onExportList: () => _navigateToShopping(context),
                  onViewCalendar: () => _navigateToPlanner(context),
                );
              },
            );
          },
        );
      },
    );
  }
  
  String _getMealSlotName(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return 'Desayuno';
      case MealSlot.snack:
        return 'Aperitivo';
      case MealSlot.lunch:
        return 'Comida';
      case MealSlot.merienda:
        return 'Merienda';
      case MealSlot.dinner:
        return 'Cena';
    }
  }

  Widget _buildBottomSectionDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildRecipesSection(context),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          flex: 1,
          child: _buildShoppingSection(context),
        ),
      ],
    );
  }

  Widget _buildBottomSectionMobile(BuildContext context) {
    return Column(
      children: [
        _buildRecipesSection(context),
        const SizedBox(height: 10.0),
        _buildShoppingSection(context),
      ],
    );
  }

  Widget _buildRecipesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return StreamBuilder<List<Recipe>>(
      stream: widget.svc.streamRecipes(),
      builder: (context, snapshot) {
        final recipes = snapshot.data ?? [];
        final recentRecipes = recipes.take(6).toList();

        return AppSurface(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FoodSectionHeader(
                title: 'Recetas recientes',
                subtitle: 'Favoritas y últimas',
                icon: Icons.restaurant,
                actionLabel: 'Ver todas',
                onActionPressed: () => _navigateToRecipes(context),
              ),
              const SizedBox(height: 6.0),
              if (recentRecipes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 28,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'No hay recetas guardadas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
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
                    padding: const EdgeInsets.only(bottom: 6.0),
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
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShoppingSection(BuildContext context) {
    return StreamBuilder<List<ShoppingList>>(
      stream: widget.svc.streamShoppingLists(),
      builder: (context, snapshot) {
        final lists = snapshot.data ?? [];
        final activeLists = lists.where((l) => l.completedAt == null).toList();
        ShoppingList? activeList;

        if (activeLists.isNotEmpty) {
          activeList =
              activeLists.firstWhere(
                (l) => l.isDefault,
                orElse: () => activeLists.first,
              );
        }

        return FoodShoppingListCard(
          listId: activeList?.id,
          items: activeList?.items ?? const [],
          onToggleItem: (index, checked) {
            if (activeList == null) return;
            widget.svc.toggleCheckedByIndex(activeList.id, index, checked);
          },
          onMarkAll: () {
            if (activeList == null) return;
            widget.svc.setAllChecked(activeList.id, true);
          },
          onClearCompleted: () {
            if (activeList == null) return;
            widget.svc.clearCompleted(activeList.id);
          },
          onNavigate: () => _navigateToShopping(context),
        );
      },
    );
  }

  List<String> _getRecipeTags(Recipe recipe) {
    final tags = <String>[];
    
    if (recipe.name.toLowerCase().contains('pollo') ||
        recipe.name.toLowerCase().contains('pavo')) {
      tags.add('Alto en proteína');
    }
    if (recipe.name.toLowerCase().contains('ensalada') ||
        recipe.name.toLowerCase().contains('vegetal')) {
      tags.add('Bajo en carbohidratos');
    }
    if (recipe.name.toLowerCase().contains('vegano') ||
        recipe.name.toLowerCase().contains('vegan')) {
      tags.add('Vegano');
    }
    
    if (tags.isEmpty) {
      tags.add('Casera');
    }
    
    return tags;
  }

  double? _calculateRecipeKcal(Recipe recipe) {
    return 450.0;
  }

  double? _calculateRecipeProtein(Recipe recipe) {
    return 32.0;
  }

  Map<String, Map<String, String>> _buildDisplayPlan(
    WeekPlanner planner, {
    required Map<String, String> foodsMap,
    required Map<String, String> recipesMap,
  }) {
    final displayPlan = <String, Map<String, String>>{};

    for (final entry in planner.days.entries) {
      final dayId = entry.key;
      final dayEntries = entry.value;

      final meals = <String, String>{};
      for (final mealEntry in dayEntries) {
        final slotName = _getMealSlotName(mealEntry.slot);
        final name = mealEntry.type == FavoriteType.food
            ? foodsMap[mealEntry.refId]
            : recipesMap[mealEntry.refId];
        meals[slotName] = name ?? mealEntry.refId;
      }

      if (meals.isNotEmpty) {
        displayPlan[dayId] = meals;
      }
    }

    return displayPlan;
  }

  Map<String, dynamic>? _pickActivePlanner(List<Map<String, dynamic>> raw) {
    if (raw.isEmpty) return null;

    final flagged = raw.where((p) {
      return p['isActive'] == true || p['isDefault'] == true;
    }).toList();

    if (flagged.isNotEmpty) {
      return flagged.first;
    }

    raw.sort((a, b) {
      final ad = _toDate(a['updatedAt']) ?? _toDate(a['createdAt']);
      final bd = _toDate(b['updatedAt']) ?? _toDate(b['createdAt']);
      return (bd ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(ad ?? DateTime.fromMillisecondsSinceEpoch(0));
    });

    return raw.first;
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

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
    ).then((_) => setState(() {}));
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
