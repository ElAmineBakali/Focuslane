import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/food/screens/food_dashboard_screen.dart';
import 'package:focuslane/screens/food/screens/food_diary_screen.dart';
import 'package:focuslane/screens/food/screens/food_planner_screen.dart';
import 'package:focuslane/screens/food/screens/foods_list_screen.dart';
import 'package:focuslane/screens/food/screens/pantry_screen.dart';
import 'package:focuslane/screens/food/screens/recipes_list_screen.dart';
import 'package:focuslane/screens/food/screens/shopping_lists_screen.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';

class FoodMainScreen extends StatefulWidget {
  const FoodMainScreen({super.key, required this.svc});

  final FoodFirestoreService svc;

  @override
  State<FoodMainScreen> createState() => _FoodMainScreenState();
}

class _FoodMainScreenState extends State<FoodMainScreen> {
  int _selectedIndex = 0;

  static const _items = <FocusSectionNavItem>[
    FocusSectionNavItem(icon: Icons.dashboard_rounded, label: 'Panel'),
    FocusSectionNavItem(icon: Icons.restaurant_menu_rounded, label: 'Diario'),
    FocusSectionNavItem(icon: Icons.restaurant_rounded, label: 'Alimentos'),
    FocusSectionNavItem(icon: Icons.menu_book_rounded, label: 'Recetas'),
    FocusSectionNavItem(icon: Icons.calendar_month_rounded, label: 'Plan'),
    FocusSectionNavItem(icon: Icons.shopping_cart_rounded, label: 'Compra'),
    FocusSectionNavItem(icon: Icons.kitchen_rounded, label: 'Despensa'),
  ];

  List<Widget> _screens() {
    return [
      FoodDashboardScreen(
        svc: widget.svc,
        embedded: true,
        onOpenSection: _selectIndex,
      ),
      FoodDiaryScreen(svc: widget.svc, embedded: true),
      FoodsListScreen(svc: widget.svc, embedded: true),
      RecipesListScreen(svc: widget.svc, embedded: true),
      FoodPlannerScreen(svc: widget.svc, embedded: true),
      ShoppingListsScreen(svc: widget.svc, embedded: true),
      PantryScreen(svc: widget.svc, embedded: true),
    ];
  }

  void _selectIndex(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Alimentación',
      subtitle: _subtitleFor(_selectedIndex),
      activeRoute: AppRoutes.foodDashboard,
      actions: [
        if (_selectedIndex == 1)
          FocusIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Registrar comida',
            onPressed: () => _selectIndex(1),
          ),
        const SizedBox(width: 10),
      ],
      child: Column(
        children: [
          FocusSectionNav(
            items: _items,
            selectedIndex: _selectedIndex,
            onSelected: _selectIndex,
          ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens()),
          ),
        ],
      ),
    );
  }

  String _subtitleFor(int index) {
    switch (index) {
      case 1:
        return 'Registro diario, macros e hidratación.';
      case 2:
        return 'Catálogo de alimentos y suplementos.';
      case 3:
        return 'Recetas guardadas y raciones.';
      case 4:
        return 'Planificador de comidas y lista automática.';
      case 5:
        return 'Listas de compra activas.';
      case 6:
        return 'Inventario y stock bajo.';
      default:
        return 'Calorías, macros, hidratación y análisis con IA.';
    }
  }
}
