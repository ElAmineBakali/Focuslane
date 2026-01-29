import 'package:flutter/material.dart';
import '../../../theme/food_theme.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';
import 'widgets/food_components.dart';
import 'widgets/food_sections.dart';
import '../diary/food_diary_screen_v2.dart';
import '../recipes/recipes_list_screen_v2.dart';
import '../planner/food_planner_screen_v2.dart';
import '../shopping/shopping_lists_screen_v2.dart';

/// FOOD HOME SCREEN - Rediseñado con estilo premium SaaS
/// Dashboard principal del módulo Food con diseño moderno y profesional
/// Paleta pastel: #D7CDC2, #B5A89B, #80AAA6, #A0BFBD, #D2E2E0, #E5EDEF
class FoodHomeScreenV2 extends StatefulWidget {
  final FoodFirestoreService svc;
  
  const FoodHomeScreenV2({super.key, required this.svc});

  @override
  State<FoodHomeScreenV2> createState() => _FoodHomeScreenV2State();
}

class _FoodHomeScreenV2State extends State<FoodHomeScreenV2> {
  String _dayId(DateTime d) => d.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final todayId = _dayId(DateTime.now());
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      backgroundColor: FoodTheme.getScaffoldBackground(context),
      body: Column(
        children: [
          // Top Bar con padding
          Container(
            color: FoodTheme.getCardBackground(context),
            padding: EdgeInsets.all(
              isDesktop ? FoodTheme.spacing24 : FoodTheme.spacing16,
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
          
          // Contenido principal con scroll
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(
                isDesktop ? FoodTheme.spacing40 : FoodTheme.spacing16,
              ),
              children: [
                // Sección de métricas
                _buildMetricsSection(context, todayId, isDesktop),
                const SizedBox(height: FoodTheme.spacing30),
                
                // Plan semanal
                FoodWeeklyPlanCard(
                  weekPlan: {
                    '2026-01-27': {
                      'Desayuno': 'Avena con Frutas',
                      'Comida': 'Pollo al Horno',
                      'Cena': 'Ensalada César',
                    },
                    '2026-01-28': {
                      'Desayuno': 'Smoothie Proteico',
                      'Comida': 'Pasta Carbonara',
                      'Cena': 'Salmón a la Plancha',
                    },
                    '2026-01-29': {
                      'Desayuno': 'Tostadas con Aguacate',
                      'Comida': 'Arroz con Pollo',
                      'Cena': 'Tacos de Pescado',
                    },
                    '2026-01-30': {
                      'Desayuno': 'Yogurt con Granola',
                      'Comida': 'Hamburguesa Fit',
                      'Cena': 'Wrap de Pollo',
                    },
                    '2026-01-31': {
                      'Desayuno': 'Pancakes Proteicos',
                      'Comida': 'Sushi Bowl',
                      'Cena': 'Pizza Casera',
                    },
                    '2026-02-01': {
                      'Desayuno': 'Huevos Revueltos',
                      'Comida': 'Pasta con Verduras',
                      'Cena': 'Filete con Ensalada',
                    },
                    '2026-02-02': {
                      'Desayuno': 'Batido Verde',
                      'Comida': 'Burritos',
                      'Cena': 'Sopa de Verduras',
                    },
                  },
                  onGeneratePlan: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generación automática próximamente'),
                      ),
                    );
                  },
                  onExportList: () => _navigateToShopping(context),
                  onViewCalendar: () => _navigateToPlanner(context),
                ),
                const SizedBox(height: FoodTheme.spacing30),
                
                // Sección inferior: Recetas y Lista de compra
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
                        accentColor: FoodTheme.tealSoft,
                        onTap: () => _navigateToDiary(context),
                      ),
                      FoodMetricCard(
                        icon: Icons.fitness_center,
                        label: 'Proteína hoy',
                        value: '${protein.toStringAsFixed(0)} g',
                        subtitle: 'de 150g objetivo',
                        accentColor: FoodTheme.tealLight,
                        onTap: () => _navigateToDiary(context),
                      ),
                      FoodMetricCard(
                        icon: Icons.restaurant_menu,
                        label: 'Recetas guardadas',
                        value: '$recipesCount',
                        subtitle: 'en tu biblioteca',
                        accentColor: FoodTheme.taupe,
                        onTap: () => _navigateToRecipes(context),
                      ),
                      FoodMetricCard(
                        icon: Icons.shopping_cart,
                        label: 'Lista de compra',
                        value: '$shoppingItems items',
                        subtitle: 'pendientes',
                        accentColor: FoodTheme.beigeSoft,
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
                                  bottom: FoodTheme.spacing16,
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
                        crossAxisSpacing: FoodTheme.spacing16,
                        mainAxisSpacing: FoodTheme.spacing16,
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
        const SizedBox(width: FoodTheme.spacing24),
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
        const SizedBox(height: FoodTheme.spacing24),
        _buildShoppingSection(context),
      ],
    );
  }

  /// Sección de recetas recientes/recomendadas
  Widget _buildRecipesSection(BuildContext context) {
    // DATOS DE EJEMPLO para visualizar el diseño
    final exampleRecipes = [
      {'name': 'Pollo al Horno con Verduras', 'tags': ['Cena', 'Alto en proteína'], 'kcal': 420.0, 'protein': 45.0},
      {'name': 'Ensalada César con Pollo', 'tags': ['Almuerzo', 'Saludable'], 'kcal': 350.0, 'protein': 38.0},
      {'name': 'Pasta Carbonara Light', 'tags': ['Cena', 'Italiana'], 'kcal': 480.0, 'protein': 28.0},
      {'name': 'Salmón a la Plancha', 'tags': ['Cena', 'Omega-3'], 'kcal': 380.0, 'protein': 42.0},
      {'name': 'Smoothie Bowl Proteico', 'tags': ['Desayuno', 'Post-entreno'], 'kcal': 320.0, 'protein': 25.0},
      {'name': 'Tacos de Pescado', 'tags': ['Almuerzo', 'Mexicana'], 'kcal': 390.0, 'protein': 35.0},
    ];

    return Container(
      padding: const EdgeInsets.all(FoodTheme.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
          const SizedBox(height: FoodTheme.spacing20),
          ...exampleRecipes.map((recipe) {
            return Padding(
              padding: const EdgeInsets.only(bottom: FoodTheme.spacing12),
              child: FoodRecipeCard(
                name: recipe['name'] as String,
                tags: recipe['tags'] as List<String>,
                kcal: recipe['kcal'] as double,
                protein: recipe['protein'] as double,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Abriendo: ${recipe['name']}')),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Sección de lista de compra
  Widget _buildShoppingSection(BuildContext context) {
    // DATOS DE EJEMPLO
    final exampleItems = [
      ShoppingItem(name: 'Pollo (1kg)', category: 'Proteínas', checked: false),
      ShoppingItem(name: 'Arroz integral', category: 'Granos', checked: false),
      ShoppingItem(name: 'Brócoli', category: 'Verduras', checked: true),
      ShoppingItem(name: 'Tomates', category: 'Verduras', checked: false),
      ShoppingItem(name: 'Aceite de oliva', category: 'Aceites', checked: false),
      ShoppingItem(name: 'Huevos (12u)', category: 'Proteínas', checked: true),
      ShoppingItem(name: 'Aguacate', category: 'Frutas', checked: false),
      ShoppingItem(name: 'Yogurt griego', category: 'Lácteos', checked: false),
    ];

    return FoodShoppingListCard(
      items: exampleItems,
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
        builder: (_) => FoodDiaryScreenV2(svc: widget.svc),
      ),
    );
  }

  void _navigateToRecipes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipesListScreenV2(svc: widget.svc),
      ),
    );
  }

  void _navigateToPlanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodPlannerScreenV2(svc: widget.svc),
      ),
    );
  }

  void _navigateToShopping(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListsScreenV2(svc: widget.svc),
      ),
    );
  }
}
