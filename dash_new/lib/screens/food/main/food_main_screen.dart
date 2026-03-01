import 'package:flutter/material.dart';
import '../services/food_firestore_service.dart';
import '../screens/food_dashboard_screen.dart';
import '../screens/food_diary_screen.dart';
import '../screens/foods_list_screen.dart';
import '../screens/recipes_list_screen.dart';
import '../screens/food_planner_screen.dart';
import '../screens/shopping_lists_screen.dart';
import '../screens/pantry_screen.dart';
import '../screens/food_history_screen.dart';
import '../screens/food_settings_notifications_screen.dart';
import '../../../design/ui/layouts/module_shell.dart';
import '../../../design/ui/layouts/module_sidebar.dart';

class FoodMainScreen extends StatefulWidget {
  final FoodFirestoreService svc;

  const FoodMainScreen({super.key, required this.svc});

  @override
  State<FoodMainScreen> createState() => _FoodMainScreenState();
}

class _FoodMainScreenState extends State<FoodMainScreen> {
  int _selectedIndex = 0;

  List<Widget> _getScreens() {
    return [
      FoodDashboardScreen(svc: widget.svc),
      FoodDiaryScreen(svc: widget.svc),
      FoodsListScreen(svc: widget.svc),
      RecipesListScreen(svc: widget.svc),
      FoodPlannerScreen(svc: widget.svc),
      ShoppingListsScreen(svc: widget.svc),
      PantryScreen(svc: widget.svc),
      FoodHistoryScreen(svc: widget.svc),
      FoodSettingsNotificationsScreen(
        svc: widget.svc,
        initialSection: FoodSettingsSection.notificaciones,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      const ModuleSidebarItem(icon: Icons.dashboard, label: 'Panel'),
      const ModuleSidebarItem(icon: Icons.restaurant_menu, label: 'Diario'),
      const ModuleSidebarItem(icon: Icons.restaurant, label: 'Alimentos'),
      const ModuleSidebarItem(icon: Icons.menu_book, label: 'Recetas'),
      const ModuleSidebarItem(icon: Icons.calendar_today, label: 'Planificador'),
      const ModuleSidebarItem(icon: Icons.list_alt, label: 'Listas de Compra'),
      const ModuleSidebarItem(icon: Icons.kitchen, label: 'Despensa'),
      const ModuleSidebarItem(icon: Icons.history, label: 'Historial'),
      const ModuleSidebarItem(
        icon: Icons.notifications,
        label: 'Notificaciones y recordatorios',
      ),
    ];

    return ModuleShell(
      items: items,
      selectedIndex: _selectedIndex,
      onItemSelected: (index) => setState(() => _selectedIndex = index),
      body: IndexedStack(
        index: _selectedIndex,
        children: _getScreens(),
      ),
      moduleTitle: 'MÃ³dulo Food',
      moduleIcon: Icons.restaurant,
    );
  }
}

