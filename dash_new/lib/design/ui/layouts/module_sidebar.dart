import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class ModuleSidebarItem {
  final IconData icon;
  final String label;

  const ModuleSidebarItem({required this.icon, required this.label});
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
      width: FocuslaneTokens.sidebarWidth,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant,
            width: FocuslaneTokens.borderW,
          ),
        ),
        boxShadow: FocuslaneTokens.subtleShadow(context),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: FocuslaneTokens.subtleShadow(context),
                  ),
                  child: Icon(
                    headerIcon,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FocusLane',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        title,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == selectedIndex;
                final bg =
                    selected
                        ? colorScheme.secondaryContainer.withValues(alpha: 0.42)
                        : Colors.transparent;
                final fg =
                    selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant;

                return Material(
                  color: bg,
                  borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      FocuslaneTokens.radius8,
                    ),
                    onTap: () => onItemSelected(index),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color:
                                selected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
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
                                  fontWeight:
                                      selected
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
