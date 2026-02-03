import 'package:flutter/material.dart';
import '../widgets/food_compact_widgets.dart';
import '../models/food_models.dart';

class FoodTopBar extends StatelessWidget {
  final VoidCallback onNewRecipe;
  final VoidCallback onWeeklyPlan;
  final VoidCallback onFilter;
  final ValueChanged<String> onSearchChanged;

  const FoodTopBar({
    super.key,
    required this.onNewRecipe,
    required this.onWeeklyPlan,
    required this.onFilter,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Food',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Resumen diario y planificación semanal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: onFilter,
              tooltip: 'Filtros',
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: onWeeklyPlan,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Plan semanal'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 36),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onNewRecipe,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva receta'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 36),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FoodCompactTextField(
          label: 'Buscar',
          hint: 'Busca alimentos, recetas o planes',
          prefixIcon: Icons.search,
          onChanged: onSearchChanged,
        ),
      ],
    );
  }
}

class FoodMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  const FoodMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 110),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: colorScheme.primary, size: 16),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoodWeeklyPlanCard extends StatelessWidget {
  final Map<String, Map<String, String>> weekPlan;
  final VoidCallback onGeneratePlan;
  final VoidCallback onExportList;
  final VoidCallback onViewCalendar;

  const FoodWeeklyPlanCard({
    super.key,
    required this.weekPlan,
    required this.onGeneratePlan,
    required this.onExportList,
    required this.onViewCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (weekPlan.isEmpty) {
      return FoodCompactCard(
        maxHeight: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Plan Semanal',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no tienes un plan semanal activo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onGeneratePlan,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
              child: const Text('Crear plan'),
            ),
          ],
        ),
      );
    }

    return FoodCompactCard(
      maxHeight: 260,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Plan Semanal',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onGeneratePlan,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Generar'),
              ),
              OutlinedButton(
                onPressed: onExportList,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Lista'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weekPlan.entries.map((entry) {
                final label = _formatDayLabel(entry.key);
                final meals = entry.value;

                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...meals.entries.map((meal) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.key,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                meal.value,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewCalendar,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Ver calendario completo'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDayLabel(String key) {
    final parsed = DateTime.tryParse(key);
    if (parsed != null) {
      final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return '${weekdays[parsed.weekday - 1]} ${parsed.day}';
    }
    switch (key) {
      case 'Mon':
        return 'Lun';
      case 'Tue':
        return 'Mar';
      case 'Wed':
        return 'Mié';
      case 'Thu':
        return 'Jue';
      case 'Fri':
        return 'Vie';
      case 'Sat':
        return 'Sáb';
      case 'Sun':
        return 'Dom';
      default:
        return key;
    }
  }
}

class FoodSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const FoodSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        TextButton(
          onPressed: onActionPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class FoodRecipeCard extends StatelessWidget {
  final String name;
  final List<String> tags;
  final double kcal;
  final double protein;
  final VoidCallback onTap;

  const FoodRecipeCard({
    super.key,
    required this.name,
    required this.tags,
    required this.kcal,
    required this.protein,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FoodCompactCard(
      maxHeight: 96,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tags.take(2).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${kcal.toStringAsFixed(0)} kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${protein.toStringAsFixed(0)}g proteína',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FoodShoppingListCard extends StatefulWidget {
  final String? listId;
  final List<ShoppingListItem> items;
  final void Function(int index, bool checked)? onToggleItem;
  final VoidCallback? onMarkAll;
  final VoidCallback? onClearCompleted;
  final VoidCallback? onNavigate;

  const FoodShoppingListCard({
    super.key,
    required this.listId,
    required this.items,
    this.onToggleItem,
    this.onMarkAll,
    this.onClearCompleted,
    this.onNavigate,
  });

  @override
  State<FoodShoppingListCard> createState() => _FoodShoppingListCardState();
}

class _FoodShoppingListCardState extends State<FoodShoppingListCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pendingItems = widget.items.where((item) => !item.checked).toList();
    final completedCount = widget.items.where((item) => item.checked).length;

    if (widget.items.isEmpty) {
      return FoodCompactCard(
        maxHeight: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Lista de Compra',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'No hay una lista activa con productos.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.onNavigate != null)
              FilledButton(
                onPressed: widget.onNavigate,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                child: const Text('Abrir listas'),
              ),
          ],
        ),
      );
    }

    return FoodCompactCard(
      maxHeight: 260,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Lista de Compra',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$completedCount/${widget.items.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton(
                onPressed: widget.onMarkAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Marcar todo'),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: widget.onClearCompleted,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Limpiar completados'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pendingItems.take(6).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final qtyText =
                '${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1)} ${item.unit.name}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: item.checked,
                    onChanged: (value) {
                      if (value == null) return;
                      widget.onToggleItem?.call(
                        widget.items.indexOf(item),
                        value,
                      );
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: colorScheme.primary,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration:
                                item.checked
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                        Text(
                          item.total != null
                              ? '$qtyText • €${item.total!.toStringAsFixed(2)}'
                              : qtyText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (pendingItems.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+ ${pendingItems.length - 6} items más',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (widget.onNavigate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onNavigate,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Ver lista completa'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
