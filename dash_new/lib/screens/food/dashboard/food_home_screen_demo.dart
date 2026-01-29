import 'package:flutter/material.dart';
import '../../../theme/food_theme.dart';
import 'widgets/food_components.dart';

/// FOOD MODULE DEMO - Pantalla de demostración con datos hardcoded
class FoodHomeDemoScreen extends StatelessWidget {
  const FoodHomeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[50],
      body: Column(
        children: [
          // TopBar
          Container(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
            padding: const EdgeInsets.all(FoodTheme.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Food Module',
                          style: FoodTypography.display(context).copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: FoodTheme.spacing4),
                        Text(
                          'Planificación, recetas y seguimiento nutricional',
                          style: FoodTypography.bodySmall(context),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva receta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FoodTheme.tealLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: FoodTheme.spacing12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Plan semanal'),
                    ),
                  ],
                ),
                const SizedBox(height: FoodTheme.spacing16),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar receta o ingrediente...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido principal
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(FoodTheme.spacing24),
              children: [
                // Métricas
                GridView.count(
                  crossAxisCount: isDesktop ? 4 : isTablet ? 2 : 1,
                  crossAxisSpacing: FoodTheme.spacing16,
                  mainAxisSpacing: FoodTheme.spacing16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.3,
                  children: [
                    FoodMetricCard(
                      icon: Icons.local_fire_department,
                      label: 'Calorías hoy',
                      value: '1,847',
                      subtitle: 'de 2,200 kcal',
                      accentColor: FoodTheme.tealSoft,
                    ),
                    FoodMetricCard(
                      icon: Icons.fitness_center,
                      label: 'Proteína',
                      value: '142g',
                      subtitle: 'objetivo 150g',
                      accentColor: FoodTheme.tealLight,
                    ),
                    FoodMetricCard(
                      icon: Icons.restaurant_menu,
                      label: 'Recetas guardadas',
                      value: '24',
                      subtitle: 'en tu biblioteca',
                      accentColor: FoodTheme.taupe,
                    ),
                    FoodMetricCard(
                      icon: Icons.shopping_cart,
                      label: 'Lista de compra',
                      value: '12 items',
                      subtitle: 'pendientes',
                      accentColor: FoodTheme.beigeSoft,
                    ),
                  ],
                ),
                const SizedBox(height: FoodTheme.spacing30),
                // Plan Semanal
                Container(
                  padding: const EdgeInsets.all(FoodTheme.spacing24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plan Semanal',
                                style: FoodTypography.heading3(context).copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Organiza tus comidas',
                                style: FoodTypography.caption(context),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.auto_awesome, size: 16),
                                label: const Text('Generar plan'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.shopping_cart, size: 16),
                                label: const Text('Exportar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: FoodTheme.spacing24),
                      // Días de la semana
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'Lunes',
                            'Martes',
                            'Miércoles',
                            'Jueves',
                            'Viernes',
                            'Sábado',
                            'Domingo',
                          ]
                              .map((day) => _buildDayPlan(context, day))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FoodTheme.spacing30),
                // Recetas y Shopping
                isDesktop || isTablet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildRecipesSection(context),
                          ),
                          const SizedBox(width: FoodTheme.spacing24),
                          Expanded(
                            flex: 1,
                            child: _buildShoppingSection(context),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildRecipesSection(context),
                          const SizedBox(height: FoodTheme.spacing24),
                          _buildShoppingSection(context),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPlan(BuildContext context, String day) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: FoodTheme.primaryGradient,
        borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildMeal('Desayuno', 'Avena con frutas'),
          const SizedBox(height: 8),
          _buildMeal('Comida', 'Pollo al horno'),
          const SizedBox(height: 8),
          _buildMeal('Cena', 'Ensalada César'),
        ],
      ),
    );
  }

  Widget _buildMeal(String mealType, String meal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mealType,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          meal,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRecipesSection(BuildContext context) {
    final recipes = [
      {'name': 'Pollo al Horno con Verduras', 'tags': ['Cena', 'Alto en proteína'], 'kcal': '420', 'protein': '45g'},
      {'name': 'Ensalada César con Pollo', 'tags': ['Almuerzo', 'Saludable'], 'kcal': '350', 'protein': '38g'},
      {'name': 'Pasta Carbonara Light', 'tags': ['Cena', 'Italiana'], 'kcal': '480', 'protein': '28g'},
      {'name': 'Salmón a la Plancha', 'tags': ['Cena', 'Omega-3'], 'kcal': '380', 'protein': '42g'},
      {'name': 'Smoothie Bowl Proteico', 'tags': ['Desayuno', 'Post-entreno'], 'kcal': '320', 'protein': '25g'},
      {'name': 'Tacos de Pescado', 'tags': ['Almuerzo', 'Mexicana'], 'kcal': '390', 'protein': '35g'},
    ];

    return Container(
      padding: const EdgeInsets.all(FoodTheme.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[300]!,
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
          Text(
            'Recetas Recientes',
            style: FoodTypography.heading3(context).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tus favoritas',
            style: FoodTypography.caption(context),
          ),
          const SizedBox(height: FoodTheme.spacing20),
          ...recipes.map((recipe) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRecipeCard(context, recipe),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Map<String, dynamic> recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: FoodTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['name'],
                  style: FoodTypography.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: (recipe['tags'] as List<String>)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: FoodTheme.tealLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${recipe['kcal']}',
                style: FoodTypography.bodySmall(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                recipe['protein'],
                style: FoodTypography.caption(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingSection(BuildContext context) {
    final items = [
      {'name': 'Pollo (1kg)', 'category': 'Proteínas', 'checked': false},
      {'name': 'Arroz integral', 'category': 'Granos', 'checked': false},
      {'name': 'Brócoli', 'category': 'Verduras', 'checked': true},
      {'name': 'Tomates', 'category': 'Verduras', 'checked': false},
      {'name': 'Aceite de oliva', 'category': 'Aceites', 'checked': false},
      {'name': 'Huevos (12u)', 'category': 'Proteínas', 'checked': true},
      {'name': 'Aguacate', 'category': 'Frutas', 'checked': false},
      {'name': 'Yogurt griego', 'category': 'Lácteos', 'checked': false},
    ];

    return Container(
      padding: const EdgeInsets.all(FoodTheme.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[300]!,
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
          Text(
            'Lista de Compra',
            style: FoodTypography.heading3(context).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${items.where((i) => !(i['checked'] as bool)).length} pendientes',
            style: FoodTypography.caption(context),
          ),
          const SizedBox(height: FoodTheme.spacing16),
          ...items.map((item) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: item['checked'] as bool,
                    onChanged: (val) {},
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: TextStyle(
                            decoration: (item['checked'] as bool)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          item['category'] as String,
                          style: FoodTypography.caption(context).copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
