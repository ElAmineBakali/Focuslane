import 'package:flutter/material.dart';
import '../../../../theme/food_theme.dart';

/// Card de métrica estilo SaaS para el dashboard Food
class FoodMetricCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? accentColor;
  final VoidCallback? onTap;

  const FoodMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.accentColor,
    this.onTap,
  });

  @override
  State<FoodMetricCard> createState() => _FoodMetricCardState();
}

class _FoodMetricCardState extends State<FoodMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? FoodTheme.getPrimaryAccent(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(FoodTheme.spacing24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
            border: Border.all(
              color: _isHovered
                  ? accentColor
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              width: _isHovered ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono con fondo
              Container(
                padding: const EdgeInsets.all(FoodTheme.spacing12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
                ),
                child: Icon(
                  widget.icon,
                  color: accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: FoodTheme.spacing20),
              // Label
              Text(
                widget.label,
                style: FoodTypography.bodySmall(context).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: FoodTheme.spacing8),
              // Valor principal
              Text(
                widget.value,
                style: FoodTypography.heading2(context).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: FoodTheme.spacing4),
                Text(
                  widget.subtitle!,
                  style: FoodTypography.caption(context).copyWith(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Header de sección con botón de acción opcional
class FoodSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const FoodSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: FoodTheme.getPrimaryAccent(context),
            size: 24,
          ),
          const SizedBox(width: FoodTheme.spacing12),
        ],
        // Use Flexible to avoid strict flex in potentially unbounded widths
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: FoodTypography.heading3(context),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: FoodTheme.spacing4),
                Text(
                  subtitle!,
                  style: FoodTypography.caption(context),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onActionPressed != null)
          TextButton.icon(
            onPressed: onActionPressed,
            icon: const Icon(Icons.add, size: 18),
            label: Text(actionLabel!),
            style: TextButton.styleFrom(
              foregroundColor: FoodTheme.getPrimaryAccent(context),
            ),
          ),
      ],
    );
  }
}

/// Card de receta profesional
class FoodRecipeCard extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final List<String> tags;
  final double? kcal;
  final double? protein;
  final VoidCallback? onTap;

  const FoodRecipeCard({
    super.key,
    required this.name,
    this.imageUrl,
    this.tags = const [],
    this.kcal,
    this.protein,
    this.onTap,
  });

  @override
  State<FoodRecipeCard> createState() => _FoodRecipeCardState();
}

class _FoodRecipeCardState extends State<FoodRecipeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: FoodTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(FoodTheme.radiusLarge),
            border: Border.all(
              color: FoodTheme.getBorderColor(context),
            ),
            boxShadow: _isHovered
                ? FoodTheme.cardShadowHover(context)
                : FoodTheme.cardShadow(context),
          ),
          child: Row(
            children: [
              // Imagen o placeholder
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: FoodTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(FoodTheme.radiusLarge),
                    bottomLeft: Radius.circular(FoodTheme.radiusLarge),
                  ),
                ),
                child: widget.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(FoodTheme.radiusLarge),
                          bottomLeft: Radius.circular(FoodTheme.radiusLarge),
                        ),
                        child: Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(FoodTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      Text(
                        widget.name,
                        style: FoodTypography.heading4(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: FoodTheme.spacing8),
                      // Tags
                      if (widget.tags.isNotEmpty)
                        Wrap(
                          spacing: FoodTheme.spacing8,
                          runSpacing: FoodTheme.spacing4,
                          children: widget.tags.take(2).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: FoodTheme.spacing8,
                                vertical: FoodTheme.spacing4,
                              ),
                              decoration: BoxDecoration(
                                color: FoodTheme.tealLight.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(FoodTheme.radiusSmall),
                              ),
                              child: Text(
                                tag,
                                style: FoodTypography.caption(context).copyWith(
                                  color: FoodTheme.tealSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: FoodTheme.spacing8),
                      // Macros
                      Row(
                        children: [
                          if (widget.kcal != null) ...[
                            Icon(
                              Icons.local_fire_department,
                              size: 16,
                              color: FoodTheme.getTextTertiary(context),
                            ),
                            const SizedBox(width: FoodTheme.spacing4),
                            Text(
                              '${widget.kcal!.toStringAsFixed(0)} kcal',
                              style: FoodTypography.caption(context),
                            ),
                          ],
                          if (widget.kcal != null && widget.protein != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: FoodTheme.spacing8,
                              ),
                              child: Text(
                                '•',
                                style: FoodTypography.caption(context),
                              ),
                            ),
                          if (widget.protein != null) ...[
                            Text(
                              '${widget.protein!.toStringAsFixed(0)}g proteína',
                              style: FoodTypography.caption(context),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Botón acción
              Padding(
                padding: const EdgeInsets.only(right: FoodTheme.spacing16),
                child: Icon(
                  Icons.chevron_right,
                  color: FoodTheme.getTextTertiary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slot de comida en el plan semanal
class FoodMealSlot extends StatelessWidget {
  final String? recipeName;
  final double? kcal;
  final VoidCallback? onTap;
  final bool isEmpty;

  const FoodMealSlot({
    super.key,
    this.recipeName,
    this.kcal,
    this.onTap,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty || recipeName == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(FoodTheme.spacing12),
          decoration: BoxDecoration(
            color: FoodTheme.getSurfaceBackground(context),
            borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
            border: Border.all(
              color: FoodTheme.getBorderColor(context),
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: FoodTheme.getTextTertiary(context),
                ),
                const SizedBox(width: FoodTheme.spacing4),
                Text(
                  'Añadir',
                  style: FoodTypography.caption(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(FoodTheme.spacing12),
        decoration: BoxDecoration(
          gradient: FoodTheme.primaryGradient,
          borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: FoodTheme.tealSoft.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipeName!,
                    style: FoodTypography.labelSmall(context).copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.edit,
                  size: 14,
                  color: Colors.white70,
                ),
              ],
            ),
            if (kcal != null) ...[
              const SizedBox(height: FoodTheme.spacing4),
              Text(
                '${kcal!.toStringAsFixed(0)} kcal',
                style: FoodTypography.caption(context).copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vacío elegante
class FoodEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const FoodEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FoodTheme.spacing40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(FoodTheme.spacing30),
              decoration: BoxDecoration(
                gradient: FoodTheme.subtleGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: FoodTheme.getPrimaryAccent(context),
              ),
            ),
            const SizedBox(height: FoodTheme.spacing24),
            Text(
              title,
              style: FoodTypography.heading3(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FoodTheme.spacing8),
            Text(
              subtitle,
              style: FoodTypography.bodySmall(context),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: FoodTheme.spacing24),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FoodTheme.getPrimaryAccent(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: FoodTheme.spacing24,
                    vertical: FoodTheme.spacing16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FoodTheme.radiusMedium),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
