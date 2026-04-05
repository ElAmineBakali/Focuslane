import 'package:flutter/material.dart';
import '../../../design/ui/components/focus_metric_card.dart';
import '../widgets/food_compact_widgets.dart';
import '../models/food_models.dart';
import '../../../design/ui/tokens/focuslane_tokens.dart';

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
    return FocusMetricCard(
      icon: icon,
      label: label,
      value: value,
      subtitle: subtitle,
      onTap: onTap,
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
        maxHeight: 160,
        padding: const EdgeInsets.all(10),
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
            const SizedBox(height: 10),
            FilledButton(
              onPressed: onGeneratePlan,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 32),
                backgroundColor: FocuslaneTokens.accent(context),
              ),
              child: const Text('Crear plan'),
            ),
          ],
        ),
      );
    }

    return FoodCompactCard(
      maxHeight: 300,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                Icon(
                  Icons.calendar_month,
                  color: FocuslaneTokens.accent(context),
                  size: 18,
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                    foregroundColor: FocuslaneTokens.accent(context),
                ),
                child: const Text('Generar'),
              ),
              OutlinedButton(
                onPressed: onExportList,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                    side: BorderSide(
                      color: FocuslaneTokens.borderColor(context),
                      width: FocuslaneTokens.borderW,
                    ),
                ),
                child: const Text('Lista'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weekPlan.entries.map((entry) {
                final label = _formatDayLabel(entry.key);
                final meals = entry.value;
                final visibleMeals = meals.entries.take(4).toList();
                final remaining = meals.length - visibleMeals.length;

                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: FocuslaneTokens.borderColor(context),
                      width: FocuslaneTokens.borderW,
                    ),
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
                      const SizedBox(height: 4),
                      ...visibleMeals.map((meal) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.key,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
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
                      }),
                      if (remaining > 0)
                        Text(
                          '+$remaining más',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewCalendar,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 28),
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
    final accent = FocuslaneTokens.accent(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 28),
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
    final accent = FocuslaneTokens.accent(context);

    return FoodCompactCard(
      maxHeight: 88,
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: FocuslaneTokens.accentSurface(context, opacity: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant, color: accent, size: 16),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 120,
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
                const SizedBox(height: 3),
                Wrap(
                  spacing: 4,
                  runSpacing: 3,
                  children: tags.take(2).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: FocuslaneTokens.accentSurface(
                          context,
                          opacity: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: FocuslaneTokens.borderColor(context),
                          width: FocuslaneTokens.borderW,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: FocuslaneTokens.accent(context),
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
        maxHeight: 160,
        padding: const EdgeInsets.all(10),
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
            const SizedBox(height: 10),
            if (widget.onNavigate != null)
              FilledButton(
                onPressed: widget.onNavigate,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 32)),
                child: const Text('Abrir listas'),
              ),
          ],
        ),
      );
    }

    return FoodCompactCard(
      maxHeight: 220,
      padding: const EdgeInsets.all(10),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                ),
                child: const Text('Marcar todo'),
              ),
              const SizedBox(width: 4),
              OutlinedButton(
                onPressed: widget.onClearCompleted,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                ),
                child: const Text('Limpiar completados'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pendingItems.take(6).toList().asMap().entries.map((entry) {
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
          }),
          if (pendingItems.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+ ${pendingItems.length - 6} productos más',
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
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 28),
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

