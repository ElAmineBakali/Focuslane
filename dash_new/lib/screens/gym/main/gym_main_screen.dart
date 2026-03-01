import 'package:flutter/material.dart';
import '../../gym/services/gym_firestore_service.dart';
import '../../gym/dashboard/gym_dashboard_screen.dart';
import '../../gym/diary/gym_diary_screen.dart';
import '../../gym/catalog/gym_catalog_screen.dart';
import '../../gym/planner/gym_planner_screen.dart';
import '../../gym/lists/gym_lists_screen.dart';
import '../../gym/pantry/gym_pantry_screen.dart';
import '../../gym/history/gym_history_screen.dart';
import '../../gym/settings/gym_settings_screen.dart';
import '../../../design/ui/layouts/module_shell.dart';
import '../../../design/ui/layouts/module_sidebar.dart';

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
      GymDiaryScreen(svc: widget.svc),
      GymCatalogScreen(svc: widget.svc),
      GymPlannerScreen(svc: widget.svc),
      GymListsScreen(svc: widget.svc),
      GymPantryScreen(svc: widget.svc),
      GymHistoryScreen(svc: widget.svc),
      GymSettingsScreen(svc: widget.svc),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      const ModuleSidebarItem(icon: Icons.dashboard, label: 'Panel'),
      const ModuleSidebarItem(icon: Icons.receipt_long, label: 'Diario'),
      const ModuleSidebarItem(icon: Icons.list_alt, label: 'Rutinas'),
      const ModuleSidebarItem(icon: Icons.calendar_today, label: 'Planificador'),
      const ModuleSidebarItem(icon: Icons.bar_chart, label: 'AnalÃ­ticas'),
      const ModuleSidebarItem(icon: Icons.monitor_weight, label: 'Cuerpo'),
      const ModuleSidebarItem(icon: Icons.history, label: 'Historial'),
      const ModuleSidebarItem(icon: Icons.tune, label: 'Objetivos'),
    ];

    return ModuleShell(
      items: items,
      selectedIndex: _selectedIndex,
      onItemSelected: (index) => setState(() => _selectedIndex = index),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens(),
      ),
      moduleTitle: 'MÃ³dulo Gym',
      moduleIcon: Icons.fitness_center,
    );
  }
}

