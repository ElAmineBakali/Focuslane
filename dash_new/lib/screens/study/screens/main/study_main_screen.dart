import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/study/screens/courses/courses_list_screen.dart';
import 'package:focuslane/screens/study/screens/dashboard/study_dashboard_screen.dart';
import 'package:focuslane/screens/study/screens/diary/study_diary_screen.dart';
import 'package:focuslane/screens/study/screens/history/study_history_screen.dart';
import 'package:focuslane/screens/study/screens/schedule/schedule_screen.dart';
import 'package:focuslane/screens/study/screens/tasks/study_tasks_screen.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';

class StudyMainScreen extends StatefulWidget {
  const StudyMainScreen({super.key, required this.svc});

  final StudyFirestoreService svc;

  @override
  State<StudyMainScreen> createState() => _StudyMainScreenState();
}

class _StudyMainScreenState extends State<StudyMainScreen> {
  int _selectedIndex = 0;

  static const _items = <FocusSectionNavItem>[
    FocusSectionNavItem(icon: Icons.dashboard_rounded, label: 'Panel'),
    FocusSectionNavItem(icon: Icons.menu_book_rounded, label: 'Diario'),
    FocusSectionNavItem(icon: Icons.school_rounded, label: 'Cursos'),
    FocusSectionNavItem(
      icon: Icons.calendar_today_rounded,
      label: 'Planificador',
    ),
    FocusSectionNavItem(icon: Icons.checklist_rounded, label: 'Tareas'),
    FocusSectionNavItem(icon: Icons.history_rounded, label: 'Historial'),
  ];

  List<Widget> _screens() {
    return [
      StudyDashboardScreen(
        svc: widget.svc,
        embedded: true,
        onOpenSection: _selectIndex,
      ),
      StudyDiaryScreen(svc: widget.svc, embedded: true),
      CoursesListScreen(svc: widget.svc, embedded: true),
      ScheduleScreen(svc: widget.svc, embedded: true),
      StudyTasksScreen(svc: widget.svc, embedded: true),
      StudyHistoryScreen(svc: widget.svc, embedded: true),
    ];
  }

  void _selectIndex(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Estudio',
      subtitle: 'Cursos, sesiones, calificaciones e historial.',
      activeRoute: AppRoutes.studyDashboard,
      actions: [
        FocusIconButton(
          icon: Icons.timer_outlined,
          tooltip: 'Abrir temporizador',
          onPressed: () => Navigator.of(context).pushNamed('/study/timer'),
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
