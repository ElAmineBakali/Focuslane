import 'package:flutter/material.dart';
import '../../../../theme/food_theme.dart';
import 'food_components.dart';
import 'food_sections.dart';

/// EJEMPLO DE USO DE COMPONENTES FOOD
/// Este archivo demuestra cómo usar todos los componentes del módulo Food
/// NO es parte del código de producción, solo documentación visual

class FoodComponentsShowcase extends StatelessWidget {
  const FoodComponentsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FoodTheme.getScaffoldBackground(context),
      appBar: AppBar(
        title: const Text('Food Components Showcase'),
        backgroundColor: FoodTheme.getPrimaryAccent(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FoodTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCIÓN 1: Metric Cards
            Text(
              '1. Metric Cards',
              style: FoodTypography.heading1(context),
            ),
            const SizedBox(height: FoodTheme.spacing16),
            Text(
              'Cards de métricas con hover effect y navegación',
              style: FoodTypography.bodySmall(context),
            ),
            const SizedBox(height: FoodTheme.spacing24),
            
            Row(
              children: [
                Expanded(
                  child: FoodMetricCard(
                    icon: Icons.local_fire_department,
                    label: 'Calorías hoy',
                    value: '1,850 kcal',
                    subtitle: 'de 2,000 objetivo',
                    accentColor: FoodTheme.tealSoft,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: FoodTheme.spacing16),
                Expanded(
                  child: FoodMetricCard(
                    icon: Icons.fitness_center,
                    label: 'Proteína hoy',
                    value: '132 g',
                    subtitle: 'de 150g objetivo',
                    accentColor: FoodTheme.tealLight,
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: FoodTheme.spacing40),
            const Divider(),
            const SizedBox(height: FoodTheme.spacing40),

            // SECCIÓN 2: Section Headers
            Text(
              '2. Section Headers',
              style: FoodTypography.heading1(context),
            ),
            const SizedBox(height: FoodTheme.spacing24),
            
            FoodSectionHeader(
              title: 'Recetas Recientes',
              subtitle: 'Tus favoritas del mes',
              icon: Icons.restaurant,
              actionLabel: 'Ver todas',
              onActionPressed: () {},
            ),
            
            const SizedBox(height: FoodTheme.spacing24),
            
            FoodSectionHeader(
              title: 'Lista de Compra',
              icon: Icons.shopping_cart,
            ),

            const SizedBox(height: FoodTheme.spacing40),
            const Divider(),
            const SizedBox(height: FoodTheme.spacing40),

            // SECCIÓN 3: Recipe Cards
            Text(
              '3. Recipe Cards',
              style: FoodTypography.heading1(context),
            ),
            const SizedBox(height: FoodTheme.spacing24),
            
            FoodRecipeCard(
              name: 'Pollo al Horno con Verduras',
              tags: const ['High protein', 'Low carb', 'Healthy'],
              kcal: 450,
              protein: 42,
              onTap: () {},
            ),
            
            const SizedBox(height: FoodTheme.spacing16),
            
            FoodRecipeCard(
              name: 'Ensalada César con Salmón',
              tags: const ['High protein', 'Omega-3'],
              kcal: 380,
              protein: 35,
              onTap: () {},
            ),

            const SizedBox(height: FoodTheme.spacing40),
            const Divider(),
            const SizedBox(height: FoodTheme.spacing40),

            // SECCIÓN 4: Meal Slots
            Text(
              '4. Meal Slots',
              style: FoodTypography.heading1(context),
            ),
            const SizedBox(height: FoodTheme.spacing16),
            Text(
              'Para el plan semanal',
              style: FoodTypography.bodySmall(context),
            ),
            const SizedBox(height: FoodTheme.spacing24),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Slot vacío',
                        style: FoodTypography.labelSmall(context),
                      ),
                      const SizedBox(height: FoodTheme.spacing8),
                      const FoodMealSlot(
                        isEmpty: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FoodTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Slot con receta',
                        style: FoodTypography.labelSmall(context),
                      ),
                      const SizedBox(height: FoodTheme.spacing8),
                      const FoodMealSlot(
                        recipeName: 'Avena con frutos rojos',
                        kcal: 320,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: FoodTheme.spacing40),
            const Divider(),
            const SizedBox(height: FoodTheme.spacing40),

            // SECCIÓN 5: Empty State
            Text(
              '5. Empty State',
              style: FoodTypography.heading1(context),
            ),
            const SizedBox(height: FoodTheme.spacing24),
            
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: FoodTheme.getCardBackground(context),
                borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
                border: Border.all(color: FoodTheme.getBorderColor(context)),
              ),
              child: const FoodEmptyState(
                icon: Icons.restaurant_menu,
                title: 'Sin recetas',
                subtitle: 'Crea tu primera receta para comenzar',
                buttonLabel: 'Nueva receta',
              ),
            ),

            const SizedBox(height: FoodTheme.spacing40),
            const Divider(),
            const SizedBox(height: FoodTheme.spacing40),

            // SECCIÓN 6: Shopping List Card
            Text(
              '6. Shopping List Card',
              style: FoodTypography.heading1(context),
            ),
            const SizedBox(height: FoodTheme.spacing24),
            
            FoodShoppingListCard(
              items: const [
                ShoppingItem(name: 'Plátanos', category: 'Fruta'),
                ShoppingItem(name: 'Pollo', category: 'Proteína'),
                ShoppingItem(name: 'Leche', category: 'Lácteos', checked: true),
                ShoppingItem(name: 'Brócoli', category: 'Verduras'),
              ],
              onAddItem: () {},
              onMarkAll: () {},
              onClear: () {},
            ),

            const SizedBox(height: FoodTheme.spacing40),
            const Divider(),
            const SizedBox(height: FoodTheme.spacing40),

            // SECCIÓN 7: Weekly Plan Card
            Text(
              '7. Weekly Plan Card',
              style: FoodTypography.heading1(context),
            ),
            const SizedBox(height: FoodTheme.spacing24),
            
            FoodWeeklyPlanCard(
              onGeneratePlan: () {},
              onExportList: () {},
              onViewCalendar: () {},
            ),

            const SizedBox(height: FoodTheme.spacing40),
            const Divider(),
            const SizedBox(height: FoodTheme.spacing40),

            // SECCIÓN 8: Top Bar
            Text(
              '8. Top Bar',
              style: FoodTypography.heading1(context),
            ),
            const SizedBox(height: FoodTheme.spacing16),
            Text(
              'Nota: normalmente va fijo arriba, aquí se muestra como ejemplo',
              style: FoodTypography.caption(context),
            ),
            const SizedBox(height: FoodTheme.spacing24),
            
            FoodTopBar(
              onNewRecipe: () {},
              onWeeklyPlan: () {},
              onFilter: () {},
            ),

            const SizedBox(height: FoodTheme.spacing40),
            const Divider(),
            const SizedBox(height: FoodTheme.spacing40),

            // SECCIÓN 9: Paleta de colores
            Text(
              '9. Paleta de Colores',
              style: FoodTypography.heading1(context),
            ),
            const SizedBox(height: FoodTheme.spacing24),
            
            Wrap(
              spacing: FoodTheme.spacing16,
              runSpacing: FoodTheme.spacing16,
              children: [
                _buildColorSwatch('Teal Soft', FoodTheme.tealSoft),
                _buildColorSwatch('Teal Light', FoodTheme.tealLight),
                _buildColorSwatch('Beige Soft', FoodTheme.beigeSoft),
                _buildColorSwatch('Taupe', FoodTheme.taupe),
                _buildColorSwatch('Background Light', FoodTheme.backgroundLight),
                _buildColorSwatch('Background Very Light', FoodTheme.backgroundVeryLight),
              ],
            ),

            const SizedBox(height: FoodTheme.spacing40),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: FoodTheme.spacing8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
