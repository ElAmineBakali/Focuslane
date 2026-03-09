import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/widgets/global_ui_components.dart';
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
import '../../design/ui/components/focus_module_header.dart';

/// ðŸ“š STUDY HOME SCREEN - Rediseñado
/// Dashboard principal del módulo de estudio con diseño moderno
class StudyHomeScreen extends StatefulWidget {
  final StudyFirestoreService svc;
  const StudyHomeScreen({super.key, required this.svc});

  @override
  State<StudyHomeScreen> createState() => _StudyHomeScreenState();
}

class _StudyHomeScreenState extends State<StudyHomeScreen> {
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

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _NotificationSettingsSheet(
            onSave: () async {
              final prefs = await SharedPreferences.getInstance();
              final notifyClasses = prefs.getBool(_kNotifyClasses) ?? true;
              final notifyTasks = prefs.getBool(_kNotifyTasks) ?? true;
              if (mounted) {
                final n = StudyNotifications(widget.svc);
                await n.scheduleAll(classes: notifyClasses, tasks: notifyTasks);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle),
                        const SizedBox(width: 8),
                        Text(
                          'Recordatorios actualizados',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar moderno con gradiente
          SliverAppBar.large(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.primaryContainer,
                leading: FocusModuleHeader.buildLeading(
                  context,
                  mode: FocusModuleLeadingMode.backToModuleDashboard,
                  backRouteName: AppRoutes.studyDashboard,
                ),
                leadingWidth: 96,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Estudio',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: 40,
                      child: Icon(
                        Icons.school,
                        size: 120,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Configurar notificaciones',
                onPressed: () => _showNotificationSettings(context),
              ),
            ],
          ),

          // Contenido principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  _buildQuickStats(),

                  const SizedBox(height: 24),

                  // Sección de acciones rápidas
                  Text(
                    'Acciones Rápidas',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildQuickActionsGrid(),

                  const SizedBox(height: 24),

                  // Acceso a funciones principales
                  Text(
                    'Gestión y Análisis',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildMainFeatures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<StudySession>>(
      stream: widget.svc.streamSessions(limit: 30),
      builder: (context, sessionsSnap) {
        return StreamBuilder<List<StudyTask>>(
          stream: widget.svc.streamTasks(),
          builder: (context, tasksSnap) {
            return StreamBuilder<List<Course>>(
              stream: widget.svc.streamCourses(),
              builder: (context, coursesSnap) {
                final sessions = sessionsSnap.data ?? [];
                final tasks = tasksSnap.data ?? [];

                // Calcular estadísticas
                final thisWeekSessions =
                    sessions.where((s) {
                      return s.date.isAfter(
                        DateTime.now().subtract(const Duration(days: 7)),
                      );
                    }).toList();

                final totalMinutes = thisWeekSessions.fold<int>(
                  0,
                  (sum, s) => sum + s.minutes,
                );

                final hours = totalMinutes ~/ 60;
                final pendingTasks =
                    tasks
                        .where(
                          (t) =>
                              t.status == TaskStatus.todo ||
                              t.status == TaskStatus.doing,
                        )
                        .length;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insights,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Esta Semana',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatPill(
                            label: 'Horas',
                            value: '$hours',
                            icon: Icons.timer,
                            color: colorScheme.primary,
                          ),
                          _StatPill(
                            label: 'Sesiones',
                            value: '${thisWeekSessions.length}',
                            icon: Icons.event_note,
                            color: colorScheme.tertiary,
                          ),
                          _StatPill(
                            label: 'Pendientes',
                            value: '$pendingTasks',
                            icon: Icons.task_alt,
                            color: colorScheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionsGrid() {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        FocusActionCard(
          title: 'Cursos',
          icon: Icons.school,
          color: colorScheme.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CoursesListScreen(svc: widget.svc),
              ),
            );
          },
          animationDelay: 100.ms,
        ),
        FocusActionCard(
          title: 'Tareas',
          icon: Icons.checklist,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudyTasksScreen(svc: widget.svc),
              ),
            );
          },
          animationDelay: 150.ms,
        ),
        FocusActionCard(
          title: 'Timer',
          icon: Icons.timer,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudyTimerScreen(svc: widget.svc),
              ),
            );
          },
          animationDelay: 200.ms,
        ),
        FocusActionCard(
          title: 'Horario',
          icon: Icons.schedule,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScheduleScreen(svc: widget.svc),
              ),
            );
          },
          animationDelay: 250.ms,
        ),
      ],
    );
  }

  Widget _buildMainFeatures() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _FeatureListTile(
          title: 'Analíticas',
          subtitle: 'Estadísticas de estudio y progreso',
          icon: Icons.analytics,
          color: colorScheme.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudyAnalyticsScreen(svc: widget.svc),
              ),
            );
          },
        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

        const SizedBox(height: 12),

        StreamBuilder<List<Course>>(
          stream: widget.svc.streamCourses(),
          builder: (context, coursesSnap) {
            final courses = coursesSnap.data ?? [];
            if (courses.isEmpty) return const SizedBox();

            return _FeatureListTile(
              title: 'Asistencia',
              subtitle: 'Control de asistencia a clases',
              icon: Icons.check_circle,
              color: colorScheme.tertiary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _AttendanceOverviewScreen(svc: widget.svc),
                  ),
                );
              },
            ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.2, end: 0);
          },
        ),
      ],
    );
  }
}

class _AttendanceOverviewScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  const _AttendanceOverviewScreen({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        leading: FocusModuleHeader.buildLeading(
          context,
          mode: FocusModuleLeadingMode.backToModuleDashboard,
          backRouteName: AppRoutes.studyDashboard,
        ),
        leadingWidth: 96,
      ),
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
                  builder: (_) => AttendanceScreen(svc: svc, course: course),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [courseColor.withOpacity(0.05), colorScheme.surface],
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
                            color:
                                meets
                                    ? colorScheme.primaryContainer
                                    : colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  meets
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
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
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
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliares del home
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _FeatureListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Bottom Sheet de configuración de notificaciones
class _NotificationSettingsSheet extends StatefulWidget {
  final VoidCallback onSave;
  const _NotificationSettingsSheet({required this.onSave});

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  static const _kNotifyClasses = 'study_notify_classes';
  static const _kNotifyTasks = 'study_notify_tasks';

  bool _notifyClasses = true;
  bool _notifyTasks = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyClasses = prefs.getBool(_kNotifyClasses) ?? true;
      _notifyTasks = prefs.getBool(_kNotifyTasks) ?? true;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifyClasses, _notifyClasses);
    await prefs.setBool(_kNotifyTasks, _notifyTasks);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notificaciones',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Configura tus recordatorios',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Opciones
                  _buildSwitchTile(
                    title: 'Recordar clases',
                    subtitle: 'Notificaciones antes de cada clase',
                    icon: Icons.schedule,
                    value: _notifyClasses,
                    onChanged: (v) => setState(() => _notifyClasses = v),
                  ),

                  const SizedBox(height: 12),

                  _buildSwitchTile(
                    title: 'Recordar tareas',
                    subtitle: 'Notificaciones de tareas y exámenes',
                    icon: Icons.task_alt,
                    value: _notifyTasks,
                    onChanged: (v) => setState(() => _notifyTasks = v),
                  ),

                  const SizedBox(height: 24),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await _savePrefs();
                        widget.onSave();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Guardar cambios',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              value
                  ? colorScheme.primary.withOpacity(0.3)
                  : colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(
              icon,
              color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

