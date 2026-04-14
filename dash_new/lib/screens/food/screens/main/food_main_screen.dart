import 'package:flutter/material.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'package:focuslane/screens/food/screens/food_dashboard_screen.dart';
import 'package:focuslane/screens/food/screens/food_diary_screen.dart';
import 'package:focuslane/screens/food/screens/foods_list_screen.dart';
import 'package:focuslane/screens/food/screens/recipes_list_screen.dart';
import 'package:focuslane/screens/food/screens/food_planner_screen.dart';
import 'package:focuslane/screens/food/screens/shopping_lists_screen.dart';
import 'package:focuslane/screens/food/screens/pantry_screen.dart';
import 'package:focuslane/design/ui/layouts/module_shell.dart';
import 'package:focuslane/design/ui/layouts/module_sidebar.dart';

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
    ];

    return ModuleShell(
      items: items,
      selectedIndex: _selectedIndex,
      onItemSelected: (index) => setState(() => _selectedIndex = index),
      body: IndexedStack(
        index: _selectedIndex,
        children: _getScreens(),
      ),
      moduleTitle: 'Módulo de nutrición',
      moduleIcon: Icons.restaurant,
    );
  }
}


