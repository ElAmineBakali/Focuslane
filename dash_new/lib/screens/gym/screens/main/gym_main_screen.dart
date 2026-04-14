import 'package:flutter/material.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/gym/screens/dashboard/gym_dashboard_screen.dart';
import 'package:focuslane/screens/gym/screens/catalog/gym_catalog_screen.dart';
import 'package:focuslane/screens/gym/screens/planner/gym_planner_screen.dart';
import 'package:focuslane/screens/gym/screens/lists/gym_lists_screen.dart';
import 'package:focuslane/screens/gym/screens/history/gym_history_screen.dart';
import 'package:focuslane/design/ui/layouts/module_shell.dart';
import 'package:focuslane/design/ui/layouts/module_sidebar.dart';

class GymMainScreen extends StatefulWidget {
  final GymFirestoreService svc;

  const GymMainScreen({super.key, required this.svc});

  @override
  State<GymMainScreen> createState() => _GymMainScreenState();
}

class _GymMainScreenState extends State<GymMainScreen> {
  int _selectedIndex = 0;

  List<Widget> _screens() {
    return [
      GymDashboardScreen(svc: widget.svc),
      GymCatalogScreen(svc: widget.svc),
      GymPlannerScreen(svc: widget.svc),
      GymListsScreen(svc: widget.svc),
      GymHistoryScreen(svc: widget.svc),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      const ModuleSidebarItem(icon: Icons.dashboard, label: 'Panel'),
      const ModuleSidebarItem(icon: Icons.list_alt, label: 'Rutinas'),
      const ModuleSidebarItem(icon: Icons.calendar_today, label: 'Planificador'),
      const ModuleSidebarItem(icon: Icons.bar_chart, label: 'Analíticas'),
      const ModuleSidebarItem(icon: Icons.history, label: 'Historial'),
    ];

    return ModuleShell(
      items: items,
      selectedIndex: _selectedIndex,
      onItemSelected: (index) => setState(() => _selectedIndex = index),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens(),
      ),
      moduleTitle: 'Módulo Gym',
      moduleIcon: Icons.fitness_center,
    );
  }
}



