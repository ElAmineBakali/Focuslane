import 'package:flutter/material.dart';
import 'courses/courses_list_screen.dart';
import 'tasks/study_tasks_screen.dart';
import 'timer/study_timer_screen.dart';
import 'analytics/study_analytics_screen.dart';
import 'calendar/integrated_calendar_screen.dart';
import 'schedule/schedule_screen.dart';
import 'services/study_firestore_service.dart';
import 'services/study_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyHomeScreen extends StatefulWidget {
  final StudyFirestoreService svc;
  const StudyHomeScreen({super.key, required this.svc});

  @override
  State<StudyHomeScreen> createState() => _StudyHomeScreenState();
}

class _StudyHomeScreenState extends State<StudyHomeScreen> {
  int _index = 0;

  static const _kNotifyClasses = 'study_notify_classes';
  static const _kNotifyTasks = 'study_notify_tasks';

  @override
  void initState() {
    super.initState();
    _maybeScheduleOnStart();
  }

  Future<void> _maybeScheduleOnStart() async {
    final prefs = await SharedPreferences.getInstance();
    final notifyClasses = prefs.getBool(_kNotifyClasses) ?? true;
    final notifyTasks = prefs.getBool(_kNotifyTasks) ?? true;
    if (!mounted) return;
    if (notifyClasses || notifyTasks) {
      final n = StudyNotifications(widget.svc);
      await n.scheduleAll(classes: notifyClasses, tasks: notifyTasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _TabSpec('Cursos', Icons.school_rounded),
      const _TabSpec('Tareas', Icons.checklist_rounded),
      const _TabSpec('Estudio', Icons.timer_rounded),
      const _TabSpec('Analíticas', Icons.bar_chart_rounded),
      const _TabSpec('Calendario', Icons.calendar_month_rounded),
      const _TabSpec('Horario', Icons.schedule_rounded),
    ];

    Widget body;
    switch (_index) {
      case 0: body = CoursesListScreen(svc: widget.svc); break;
      case 1: body = StudyTasksScreen(svc: widget.svc); break;
      case 2: body = StudyTimerScreen(svc: widget.svc); break;
      case 3: body = StudyAnalyticsScreen(svc: widget.svc); break;
      case 4: body = IntegratedCalendarScreen(svc: widget.svc); break;
      case 5: body = ScheduleScreen(svc: widget.svc); break;
      default: body = CoursesListScreen(svc: widget.svc); break;
    }

    return Scaffold(
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i)=>setState(()=>_index=i),
        destinations: tabs.map((t)=>NavigationDestination(icon: Icon(t.icon), label: t.title)).toList(),
      ),
    );
  }
}

class _TabSpec {
  final String title;
  final IconData icon;
  const _TabSpec(this.title, this.icon);
}
