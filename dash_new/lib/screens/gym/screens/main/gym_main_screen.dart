import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/gym/screens/analytics/gym_analytics_screen.dart';
import 'package:focuslane/screens/gym/screens/dashboard/gym_dashboard_screen.dart';
import 'package:focuslane/screens/gym/screens/routines/preset_routines_screen.dart';
import 'package:focuslane/screens/gym/screens/routines/routines_list_screen.dart';
import 'package:focuslane/screens/gym/screens/session/session_history_screen.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';

class GymMainScreen extends StatefulWidget {
  final GymFirestoreService svc;

  const GymMainScreen({super.key, required this.svc});

  @override
  State<GymMainScreen> createState() => _GymMainScreenState();
}

class _GymMainScreenState extends State<GymMainScreen> {
  int _selectedIndex = 0;

  static const _items = <FocusSectionNavItem>[
    FocusSectionNavItem(icon: Icons.dashboard_rounded, label: 'Panel'),
    FocusSectionNavItem(icon: Icons.list_alt_rounded, label: 'Rutinas'),
    FocusSectionNavItem(icon: Icons.auto_awesome_rounded, label: 'Plantillas'),
    FocusSectionNavItem(icon: Icons.analytics_rounded, label: 'Progreso'),
    FocusSectionNavItem(icon: Icons.history_rounded, label: 'Historial'),
  ];

  List<Widget> _screens() {
    return [
      GymDashboardScreen(svc: widget.svc, embedded: true),
      RoutinesListScreen(svc: widget.svc, embedded: true),
      PresetRoutinesScreen(svc: widget.svc, embedded: true),
      GymAnalyticsScreen(svc: widget.svc, embedded: true),
      SessionHistoryScreen(svc: widget.svc, embedded: true),
    ];
  }

  void _selectIndex(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Gimnasio',
      subtitle: 'Rutinas, sesiones, descanso y progreso físico.',
      activeRoute: AppRoutes.gymDashboard,
      actions: [
        FocusIconButton(
          icon: Icons.list_alt_rounded,
          tooltip: 'Abrir rutinas',
          onPressed: () => _selectIndex(1),
        ),
        const SizedBox(width: 10),
        FocusIconButton(
          icon: Icons.history_rounded,
          tooltip: 'Abrir historial',
          onPressed: () => _selectIndex(4),
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
}
