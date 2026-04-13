import 'package:flutter/material.dart';
import '../../study/services/study_firestore_service.dart';
import '../../study/dashboard/study_dashboard_screen.dart';
import '../../study/diary/study_diary_screen.dart';
import '../../study/catalog/study_catalog_screen.dart';
import '../../study/planner/study_planner_screen.dart';
import '../../study/lists/study_lists_screen.dart';
import '../../study/history/study_history_screen.dart';
import '../../../design/ui/layouts/module_shell.dart';
import '../../../design/ui/layouts/module_sidebar.dart';

class StudyMainScreen extends StatefulWidget {
  final StudyFirestoreService svc;

  const StudyMainScreen({super.key, required this.svc});

  @override
  State<StudyMainScreen> createState() => _StudyMainScreenState();
}

class _StudyMainScreenState extends State<StudyMainScreen> {
  int _selectedIndex = 0;

  List<Widget> _screens() {
    return [
      StudyDashboardScreen(svc: widget.svc),
      StudyDiaryScreen(svc: widget.svc),
      StudyCatalogScreen(svc: widget.svc),
      StudyPlannerScreen(svc: widget.svc),
      StudyListsScreen(svc: widget.svc),
      StudyHistoryScreen(svc: widget.svc),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      const ModuleSidebarItem(icon: Icons.dashboard, label: 'Panel'),
      const ModuleSidebarItem(icon: Icons.menu_book, label: 'Diario'),
      const ModuleSidebarItem(icon: Icons.school, label: 'Cursos'),
      const ModuleSidebarItem(icon: Icons.calendar_today, label: 'Planificador'),
      const ModuleSidebarItem(icon: Icons.checklist, label: 'Tareas'),
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
      moduleTitle: 'Módulo Study',
      moduleIcon: Icons.school,
    );
  }
}

