import 'package:flutter/material.dart';
import '../../../theme/focuslane_ui.dart';

class FoodSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const FoodSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final items = [
      _SidebarItem(
        icon: Icons.dashboard,
        label: 'Panel',
        index: 0,
      ),
      _SidebarItem(
        icon: Icons.restaurant_menu,
        label: 'Diario',
        index: 1,
      ),
      _SidebarItem(
        icon: Icons.restaurant,
        label: 'Alimentos',
        index: 2,
      ),
      _SidebarItem(
        icon: Icons.menu_book,
        label: 'Recetas',
        index: 3,
      ),
      _SidebarItem(
        icon: Icons.calendar_today,
        label: 'Planificador',
        index: 4,
      ),
      _SidebarItem(
        icon: Icons.shopping_cart,
        label: 'Compras',
        index: 5,
      ),
      _SidebarItem(
        icon: Icons.kitchen,
        label: 'Despensa',
        index: 6,
      ),
      _SidebarItem(
        icon: Icons.analytics,
        label: 'Historial',
        index: 7,
      ),
      _SidebarItem(
        icon: Icons.notifications,
        label: 'Notificaciones',
        index: 8,
      ),
    ];

    return Container(
      width: isDesktop ? 260 : double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: isDesktop
            ? Border(
                right: BorderSide(
                  color: FocuslaneUI.borderColor(context),
                  width: FocuslaneUI.borderW,
                ),
              )
            : null,
      ),
      child: Column(
        children: [
          if (isDesktop)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: FocuslaneUI.primaryGradient(context),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    color: colorScheme.onPrimary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Módulo Food',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (!isDesktop)
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: FocuslaneUI.primaryGradient(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, color: colorScheme.onPrimary, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Módulo Food',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == item.index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FocuslaneUI.accentSurface(context, opacity: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(FocuslaneUI.radius),
                      border: Border.all(
                        color: isSelected
                            ? FocuslaneUI.accent(context)
                            : FocuslaneUI.borderColor(context),
                        width: FocuslaneUI.borderW,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => onItemSelected(item.index),
                      borderRadius: BorderRadius.circular(FocuslaneUI.radius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected
                                  ? FocuslaneUI.accent(context)
                                  : colorScheme.onSurface.withOpacity(0.7),
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected
                                    ? FocuslaneUI.accent(context)
                                    : colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 16,
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

class _SidebarItem {
  final IconData icon;
  final String label;
  final int index;

  _SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
