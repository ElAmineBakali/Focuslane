import 'package:flutter/material.dart';
import '../../../../theme/food_theme.dart';
import 'food_components.dart';

/// Top bar del módulo Food con búsqueda y acciones
class FoodTopBar extends StatelessWidget {
  final VoidCallback? onNewRecipe;
  final VoidCallback? onWeeklyPlan;
  final VoidCallback? onFilter;

  const FoodTopBar({
    super.key,
    this.onNewRecipe,
    this.onWeeklyPlan,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive: en mobile, botones más pequeños y disposición vertical
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(
        isSmallScreen ? FoodTheme.spacing16 : FoodTheme.spacing24,
      ),
      decoration: BoxDecoration(
        color: FoodTheme.getCardBackground(context),
        boxShadow: FoodTheme.cardShadow(context),
      ),
      child: isSmallScreen ? _buildMobileLayout(context) : _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Título y subtítulo
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
                  style: FoodTypography.bodySmall(context).copyWith(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Botones de acción
            ElevatedButton.icon(
              onPressed: onNewRecipe,
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
              onPressed: onWeeklyPlan,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Plan semanal'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: FoodTheme.spacing16),
        // Buscador
        SizedBox(
          width: double.infinity,
          child: _buildSearchBar(context),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          'Food Module',
          style: FoodTypography.heading1(context).copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: FoodTheme.spacing4),
        Text(
          'Planificación nutricional',
          style: FoodTypography.caption(context).copyWith(
            fontSize: 13,
          ),
        ),
        const SizedBox(height: FoodTheme.spacing16),
        // Buscador
        _buildSearchBar(context),
        const SizedBox(height: FoodTheme.spacing12),
        // Botones en fila
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onNewRecipe,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FoodTheme.tealLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: FoodTheme.spacing8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onWeeklyPlan,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Plan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar receta o ingrediente...',
          hintStyle: FoodTypography.bodySmall(context).copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: FoodTheme.getTextTertiary(context),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: FoodTheme.spacing16,
            vertical: FoodTheme.spacing12,
          ),
        ),
        onChanged: (value) {
          // TODO: Implementar búsqueda
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    bool isPrimary = false,
    bool isCompact = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isCompact ? 18 : 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? FoodTheme.getPrimaryAccent(context)
            : FoodTheme.getSurfaceBackground(context),
        foregroundColor: isPrimary
            ? Colors.white
            : FoodTheme.getTextPrimary(context),
        elevation: isPrimary ? 2 : 0,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? FoodTheme.spacing12 : FoodTheme.spacing20,
          vertical: isCompact ? FoodTheme.spacing12 : FoodTheme.spacing16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
          side: !isPrimary
              ? BorderSide(color: FoodTheme.getBorderColor(context))
              : BorderSide.none,
        ),
      ),
    );
  }
}

/// Card del plan semanal
class FoodWeeklyPlanCard extends StatefulWidget {
  final Map<String, Map<String, String?>> weekPlan; // {dayId: {meal: recipeName}}
  final VoidCallback? onGeneratePlan;
  final VoidCallback? onExportList;
  final VoidCallback? onViewCalendar;

  const FoodWeeklyPlanCard({
    super.key,
    this.weekPlan = const {},
    this.onGeneratePlan,
    this.onExportList,
    this.onViewCalendar,
  });

  @override
  State<FoodWeeklyPlanCard> createState() => _FoodWeeklyPlanCardState();
}

class _FoodWeeklyPlanCardState extends State<FoodWeeklyPlanCard> {
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Container(
      padding: const EdgeInsets.all(FoodTheme.spacing24),
      decoration: BoxDecoration(
        color: FoodTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
        border: Border.all(color: FoodTheme.getBorderColor(context)),
        boxShadow: FoodTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FoodSectionHeader(
                title: 'Plan Semanal',
                subtitle: 'Organiza tus comidas',
                icon: Icons.calendar_view_week,
              ),
              Row(
                children: [
                  _buildHeaderButton(
                    context,
                    'Generar plan',
                    Icons.auto_awesome,
                    widget.onGeneratePlan,
                  ),
                  const SizedBox(width: FoodTheme.spacing8),
                  _buildHeaderButton(
                    context,
                    'Exportar lista',
                    Icons.shopping_cart,
                    widget.onExportList,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: FoodTheme.spacing24),
          // Contenido
          isSmallScreen
              ? _buildMobilePlan(context)
              : _buildDesktopPlan(context),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: FoodTheme.getPrimaryAccent(context),
        side: BorderSide(color: FoodTheme.getBorderColor(context)),
        padding: const EdgeInsets.symmetric(
          horizontal: FoodTheme.spacing16,
          vertical: FoodTheme.spacing12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
        ),
      ),
    );
  }

  Widget _buildDesktopPlan(BuildContext context) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final meals = ['Desayuno', 'Comida', 'Cena'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: days.asMap().entries.map((entry) {
          final dayIndex = entry.key;
          final dayLabel = entry.value;

          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: FoodTheme.spacing12),
            child: Column(
              children: [
                // Día header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: FoodTheme.spacing12,
                  ),
                  decoration: BoxDecoration(
                    gradient: FoodTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
                  ),
                  child: Center(
                    child: Text(
                      dayLabel,
                      style: FoodTypography.labelLarge(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: FoodTheme.spacing12),
                // Comidas
                ...meals.map((meal) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: FoodTheme.spacing8),
                    child: FoodMealSlot(
                      recipeName: _getRecipeForDay(dayIndex, meal),
                      kcal: _getRecipeForDay(dayIndex, meal) != null ? 450 : null,
                      isEmpty: _getRecipeForDay(dayIndex, meal) == null,
                      onTap: () {
                        // TODO: Abrir selector de receta
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobilePlan(BuildContext context) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final meals = ['Desayuno', 'Comida', 'Cena'];

    return Column(
      children: [
        // Selector de día
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: days.asMap().entries.map((entry) {
              final dayIndex = entry.key;
              final dayLabel = entry.value;
              final isSelected = _selectedDayIndex == dayIndex;

              return Padding(
                padding: const EdgeInsets.only(right: FoodTheme.spacing8),
                child: ChoiceChip(
                  label: Text(dayLabel),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedDayIndex = dayIndex);
                  },
                  backgroundColor: FoodTheme.getSurfaceBackground(context),
                  selectedColor: FoodTheme.getPrimaryAccent(context),
                  labelStyle: FoodTypography.labelSmall(context).copyWith(
                    color: isSelected
                        ? Colors.white
                        : FoodTheme.getTextSecondary(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : FoodTheme.getBorderColor(context),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: FoodTheme.spacing16),
        // Lista de comidas para el día seleccionado
        ...meals.map((meal) {
          return Padding(
            padding: const EdgeInsets.only(bottom: FoodTheme.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal,
                  style: FoodTypography.labelSmall(context),
                ),
                const SizedBox(height: FoodTheme.spacing8),
                FoodMealSlot(
                  recipeName: _getRecipeForDay(_selectedDayIndex, meal),
                  kcal: _getRecipeForDay(_selectedDayIndex, meal) != null
                      ? 450
                      : null,
                  isEmpty: _getRecipeForDay(_selectedDayIndex, meal) == null,
                  onTap: () {
                    // TODO: Abrir selector de receta
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String? _getRecipeForDay(int dayIndex, String meal) {
    // TODO: Implementar lógica real con widget.weekPlan
    // Placeholder: algunas comidas tienen recetas
    if (dayIndex == 0 && meal == 'Desayuno') return 'Avena con frutos';
    if (dayIndex == 1 && meal == 'Comida') return 'Pollo con arroz';
    if (dayIndex == 2 && meal == 'Cena') return 'Salmón al horno';
    return null;
  }
}

/// Card de lista de compra
class FoodShoppingListCard extends StatelessWidget {
  final List<ShoppingItem> items;
  final VoidCallback? onAddItem;
  final VoidCallback? onMarkAll;
  final VoidCallback? onClear;

  const FoodShoppingListCard({
    super.key,
    this.items = const [],
    this.onAddItem,
    this.onMarkAll,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final categories = _groupByCategory(items);

    return Container(
      padding: const EdgeInsets.all(FoodTheme.spacing20),
      decoration: BoxDecoration(
        color: FoodTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
        border: Border.all(color: FoodTheme.getBorderColor(context)),
        boxShadow: FoodTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FoodSectionHeader(
                title: 'Lista de Compra',
                subtitle: '${items.length} items',
                icon: Icons.shopping_bag,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    onPressed: onMarkAll,
                    tooltip: 'Marcar todo',
                    color: FoodTheme.getTextSecondary(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onClear,
                    tooltip: 'Limpiar',
                    color: FoodTheme.getTextSecondary(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: FoodTheme.spacing16),
          // Campo añadir
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FoodTheme.spacing12,
              vertical: FoodTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: FoodTheme.getSurfaceBackground(context),
              borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
              border: Border.all(color: FoodTheme.getBorderColor(context)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add,
                  color: FoodTheme.getTextTertiary(context),
                  size: 20,
                ),
                const SizedBox(width: FoodTheme.spacing8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Añadir item...',
                      hintStyle: FoodTypography.bodySmall(context),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      // TODO: Añadir item
                      onAddItem?.call();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FoodTheme.spacing16),
          // Items por categoría
          if (items.isEmpty)
            const FoodEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Sin items',
              subtitle: 'Añade productos a tu lista de compra',
            )
          else
            ...categories.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: FoodTheme.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: FoodTypography.labelSmall(context),
                    ),
                    const SizedBox(height: FoodTheme.spacing8),
                    ...entry.value.map((item) {
                      return CheckboxListTile(
                        value: item.checked,
                        onChanged: (value) {
                          // TODO: Toggle check
                        },
                        title: Text(
                          item.name,
                          style: FoodTypography.body(context).copyWith(
                            decoration: item.checked
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.checked
                                ? FoodTheme.getTextTertiary(context)
                                : FoodTheme.getTextPrimary(context),
                          ),
                        ),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: FoodTheme.getPrimaryAccent(context),
                      );
                    }),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Map<String, List<ShoppingItem>> _groupByCategory(List<ShoppingItem> items) {
    final Map<String, List<ShoppingItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }
}

/// Modelo para item de compra (placeholder)
class ShoppingItem {
  final String name;
  final String category;
  final bool checked;

  const ShoppingItem({
    required this.name,
    required this.category,
    this.checked = false,
  });
}
