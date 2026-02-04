import 'package:flutter/material.dart';
import '../../../ui/layouts/module_sidebar.dart';

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
    return ModuleSidebar(
      items: const [
        ModuleSidebarItem(icon: Icons.dashboard, label: 'Panel'),
        ModuleSidebarItem(icon: Icons.restaurant_menu, label: 'Diario'),
        ModuleSidebarItem(icon: Icons.restaurant, label: 'Alimentos'),
        ModuleSidebarItem(icon: Icons.menu_book, label: 'Recetas'),
        ModuleSidebarItem(icon: Icons.calendar_today, label: 'Planificador'),
        ModuleSidebarItem(icon: Icons.list_alt, label: 'Listas de Compra'),
        ModuleSidebarItem(icon: Icons.kitchen, label: 'Despensa'),
        ModuleSidebarItem(icon: Icons.history, label: 'Historial'),
        ModuleSidebarItem(
          icon: Icons.notifications,
          label: 'Notificaciones y recordatorios',
        ),
      ],
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      title: 'Módulo Food',
      headerIcon: Icons.restaurant,
    );
  }
}
