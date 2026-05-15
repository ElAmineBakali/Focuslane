import 'package:flutter/material.dart';

import '../tokens/focuslane_tokens.dart';

class FocusSectionNavItem {
  const FocusSectionNavItem({
    required this.label,
    required this.icon,
    this.badge,
  });

  final String label;
  final IconData icon;
  final String? badge;
}

class FocusSectionNav extends StatelessWidget {
  const FocusSectionNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<FocusSectionNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        boxShadow: FocuslaneTokens.subtleShadow(context),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _SectionNavButton(
                item: items[index],
                selected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
              if (index != items.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionNavButton extends StatelessWidget {
  const _SectionNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FocusSectionNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = selected ? scheme.primary : scheme.onSurfaceVariant;
    final bg =
        selected
            ? scheme.primaryContainer.withValues(alpha: 0.34)
            : scheme.surfaceContainerLow;

    return Tooltip(
      message: item.label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
              border: Border.all(
                color:
                    selected
                        ? scheme.primary.withValues(alpha: 0.36)
                        : scheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: tone, size: 19),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: tone,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
                if (item.badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tone,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
