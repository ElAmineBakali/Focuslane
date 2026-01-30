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
import '../screens/food_settings_screen.dart';
import 'food_sidebar.dart';

class FoodMainScreen extends StatefulWidget {
  final FoodFirestoreService svc;

  const FoodMainScreen({super.key, required this.svc});

  @override
  State<FoodMainScreen> createState() => _FoodMainScreenState();
}

class _FoodMainScreenState extends State<FoodMainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      FoodSettingsScreen(svc: widget.svc),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop
          ? Drawer(
              child: FoodSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      appBar: !isDesktop
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(_getTitle()),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            FoodSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _getScreens(),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    final titles = [
      'Dashboard',
      'Diario',
      'Alimentos',
      'Recetas',
      'Planificador',
      'Listas de Compra',
      'Despensa',
      'Historial',
      'Configuración',
    ];
    return titles[_selectedIndex];
  }
}
