import 'package:flutter/material.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import 'package:focuslane/screens/study/screens/dashboard/study_dashboard_screen.dart';
import 'package:focuslane/screens/study/screens/diary/study_diary_screen.dart';
import 'package:focuslane/screens/study/screens/courses/courses_list_screen.dart';
import 'package:focuslane/screens/study/screens/schedule/schedule_screen.dart';
import 'package:focuslane/screens/study/screens/tasks/study_tasks_screen.dart';
import 'package:focuslane/screens/study/screens/history/study_history_screen.dart';
import 'package:focuslane/design/ui/layouts/module_shell.dart';
import 'package:focuslane/design/ui/layouts/module_sidebar.dart';

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
      CoursesListScreen(svc: widget.svc),
      ScheduleScreen(svc: widget.svc),
      StudyTasksScreen(svc: widget.svc),
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




