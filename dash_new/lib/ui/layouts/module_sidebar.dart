import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class ModuleSidebarItem {
  final IconData icon;
  final String label;

  const ModuleSidebarItem({
    required this.icon,
    required this.label,
  });
}

class ModuleSidebar extends StatelessWidget {
  final List<ModuleSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String title;
  final IconData headerIcon;

  const ModuleSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.title,
    required this.headerIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: FocuslaneTokens.borderColor(context),
            width: FocuslaneTokens.borderW,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: FocuslaneTokens.primaryGradient(context),
              border: Border(
                bottom: BorderSide(
                  color: FocuslaneTokens.borderColor(context),
                  width: FocuslaneTokens.borderW,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(headerIcon, color: colorScheme.onPrimary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == selectedIndex;
                final bg = selected
                    ? FocuslaneTokens.accentSurface(context, opacity: 0.16)
                    : Colors.transparent;
                final fg = selected
                    ? FocuslaneTokens.accent(context)
                    : colorScheme.onSurfaceVariant;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Material(
                    color: bg,
                    borderRadius: BorderRadius.circular(
                      FocuslaneTokens.radius12,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        FocuslaneTokens.radius12,
                      ),
                      onTap: () => onItemSelected(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, color: fg, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: fg,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
