import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'courses/courses_list_screen.dart';
import 'tasks/study_tasks_screen.dart';
import 'timer/study_timer_screen.dart';
import 'analytics/study_analytics_screen.dart';
import 'schedule/schedule_screen.dart';
import 'attendance/attendance_screen.dart';
import 'services/study_firestore_service.dart';
import 'services/study_notifications.dart';
import 'models/study_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

        class StudyHomeScreen extends StatefulWidget {
  final StudyFirestoreService svc;
  const StudyHomeScreen({super.key, required this.svc});

  @override
  State<StudyHomeScreen> createState() => _StudyHomeScreenState();
}

class _StudyHomeScreenState extends State<StudyHomeScreen> {
  int _selectedIndex = 0;

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
    final pages = [
      CoursesListScreen(svc: widget.svc),
      StudyTasksScreen(svc: widget.svc),
      StudyTimerScreen(svc: widget.svc),
      StudyAnalyticsScreen(svc: widget.svc),
      _AttendanceOverviewScreen(svc: widget.svc),
      ScheduleScreen(svc: widget.svc),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      animationDuration: const Duration(milliseconds: 400),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school_rounded),
          label: 'Cursos',
          tooltip: 'Mis cursos',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist_rounded),
          label: 'Tareas',
          tooltip: 'Tareas y exámenes',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer_rounded),
          label: 'Estudio',
          tooltip: 'Temporizador',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Analíticas',
          tooltip: 'Estadísticas',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: 'Asistencia',
          tooltip: 'Asistencia',
        ),
        NavigationDestination(
          icon: Icon(Icons.schedule_outlined),
          selectedIcon: Icon(Icons.schedule_rounded),
          label: 'Horario',
          tooltip: 'Horario semanal',
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

 class _AttendanceOverviewScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  const _AttendanceOverviewScreen({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia')),
      body: StreamBuilder<List<Course>>(
        stream: svc.streamCourses(),
        builder: (context, courseSnap) {
          if (!courseSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = courseSnap.data!;
          if (courses.isEmpty) {
            return const Center(child: Text('No hay cursos registrados'));
          }

          final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
          return ListView.builder(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12 + bottomPadding,
            ),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _AttendanceCard(svc: svc, course: course);
            },
          );
        },
      ),
    );
  }
}

 class _AttendanceCard extends StatelessWidget {
  final StudyFirestoreService svc;
  final Course course;
  const _AttendanceCard({required this.svc, required this.course});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, String>>(
      stream: svc.streamAttendanceMap(course.id),
      builder: (context, snap) {
        final map = snap.data ?? const <String, String>{};
        final attended = map.values.where((v) => v == 'A').length;
        final absent = map.values.where((v) => v == 'X').length;
        final total = attended + absent;
        final percent = total == 0 ? 0.0 : (attended * 100.0 / total);
        final target = course.attendanceRequired ?? 0.0;
        final meets = percent >= target;
        final colorScheme = Theme.of(context).colorScheme;
        final courseColor = course.color ?? colorScheme.primary;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceScreen(
                    svc: svc,
                    course: course,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    courseColor.withOpacity(0.05),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            course.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: meets
                                ? colorScheme.primaryContainer
                                : colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: meets 
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: percent / 100),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              meets ? courseColor : colorScheme.error,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          label: 'Asistencias',
                          value: '$attended',
                          icon: Icons.check_circle_outline_rounded,
                          color: colorScheme.primary,
                        ),
                        _StatItem(
                          label: 'Faltas',
                          value: '$absent',
                          icon: Icons.cancel_outlined,
                          color: colorScheme.error,
                        ),
                        if (target > 0)
                          _StatItem(
                            label: 'Requerido',
                            value: '${target.toInt()}%',
                            icon: Icons.flag_outlined,
                            color: colorScheme.tertiary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
