import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/study_firestore_service.dart';
import '../services/study_notifications.dart';
import '../models/study_models.dart';

class StudySettingsSheet extends StatefulWidget {
  final StudyFirestoreService svc;
  const StudySettingsSheet({super.key, required this.svc});

  @override
  State<StudySettingsSheet> createState() => _StudySettingsSheetState();
}

class _StudySettingsSheetState extends State<StudySettingsSheet> {
  static const _kNotifyClasses = 'study_notify_classes';
  static const _kNotifyTasks = 'study_notify_tasks';
  static const _kClassesAdvanceMinutes = 'study_classes_advance_minutes';
  static const _kTasksAdvanceHours = 'study_tasks_advance_hours';

  bool _notifyClasses = true;
  bool _notifyTasks = true;
  int _classesAdvanceMinutes = 15;
  int _tasksAdvanceHours = 24;
  bool _loading = true;
  Map<String, bool> _courseNotifications = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cargar configuración global
    final notifyClasses = prefs.getBool(_kNotifyClasses) ?? true;
    final notifyTasks = prefs.getBool(_kNotifyTasks) ?? true;
    final classesAdvance = prefs.getInt(_kClassesAdvanceMinutes) ?? 15;
    final tasksAdvance = prefs.getInt(_kTasksAdvanceHours) ?? 24;
    
    // Cargar configuración por curso
    final courses = await widget.svc.streamCourses().first;
    final courseNotifs = <String, bool>{};
    for (final course in courses) {
      courseNotifs[course.id] = prefs.getBool('study_notify_course_${course.id}') ?? true;
    }
    
    setState(() {
      _notifyClasses = notifyClasses;
      _notifyTasks = notifyTasks;
      _classesAdvanceMinutes = classesAdvance;
      _tasksAdvanceHours = tasksAdvance;
      _courseNotifications = courseNotifs;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifyClasses, _notifyClasses);
    await prefs.setBool(_kNotifyTasks, _notifyTasks);
    await prefs.setInt(_kClassesAdvanceMinutes, _classesAdvanceMinutes);
    await prefs.setInt(_kTasksAdvanceHours, _tasksAdvanceHours);
    
    // Guardar configuración por curso
    for (final entry in _courseNotifications.entries) {
      await prefs.setBool('study_notify_course_${entry.key}', entry.value);
    }
  }

  Future<void> _reschedule() async {
    final notif = StudyNotifications(widget.svc);
    await notif.scheduleAll(classes: _notifyClasses, tasks: _notifyTasks);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recordatorios reprogramados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: _loading
            ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: Theme.of(context).colorScheme.primary,
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Configura recordatorios personalizados',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Contenido scrollable
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECCIÓN 1: Notificaciones globales
                          _SectionTitle(
                            icon: Icons.toggle_on_rounded,
                            title: 'Configuración General',
                            subtitle: 'Activa o desactiva tipos de notificaciones',
                          ),
                          const SizedBox(height: 16),
                          
                          _NotificationTile(
                            icon: Icons.schedule_rounded,
                            title: 'Recordatorios de clases',
                            subtitle: 'Notificación antes de cada clase programada',
                            value: _notifyClasses,
                            onChanged: (v) => setState(() => _notifyClasses = v),
                            color: Colors.blue,
                          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
                          
                          const SizedBox(height: 12),
                          
                          if (_notifyClasses)
                            _TimeSelector(
                              label: 'Con cuánta anticipación',
                              value: _classesAdvanceMinutes,
                              options: const [5, 10, 15, 30, 60],
                              unit: 'min antes',
                              onChanged: (v) => setState(() => _classesAdvanceMinutes = v),
                            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
                          
                          const SizedBox(height: 12),
                          
                          _NotificationTile(
                            icon: Icons.assignment_rounded,
                            title: 'Recordatorios de tareas y exámenes',
                            subtitle: 'Alertas antes de las fechas límite',
                            value: _notifyTasks,
                            onChanged: (v) => setState(() => _notifyTasks = v),
                            color: Colors.purple,
                          ).animate().fadeIn(duration: 300.ms, delay: 50.ms).slideX(begin: -0.1, end: 0),
                          
                          const SizedBox(height: 12),
                          
                          if (_notifyTasks)
                            _TimeSelector(
                              label: 'Con cuánta anticipación',
                              value: _tasksAdvanceHours,
                              options: const [1, 6, 12, 24, 48],
                              unit: 'horas antes',
                              onChanged: (v) => setState(() => _tasksAdvanceHours = v),
                            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
                          
                          const SizedBox(height: 32),
                          
                          // SECCIÓN 2: Notificaciones por curso
                          _SectionTitle(
                            icon: Icons.book_rounded,
                            title: 'Notificaciones por Curso',
                            subtitle: 'Personaliza qué cursos te notifican',
                          ),
                          const SizedBox(height: 16),
                          
                          StreamBuilder<List<Course>>(
                            stream: widget.svc.streamCourses(),
                            builder: (context, snapshot) {
                              final courses = snapshot.data ?? [];
                              if (courses.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No hay cursos creados',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              return Column(
                                children: courses.map((course) {
                                  final isEnabled = _courseNotifications[course.id] ?? true;
                                  return _CourseTile(
                                    course: course,
                                    value: isEnabled,
                                    onChanged: (v) {
                                      setState(() {
                                        _courseNotifications[course.id] = v;
                                      });
                                    },
                                  ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
                                }).toList(),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Botones de acción
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await _save();
                                    await _reschedule();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: Text(
                                    'Reprogramar',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    await _save();
                                    if (mounted) Navigator.pop(context);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Ajustes guardados correctamente',
                                            style: GoogleFonts.plusJakartaSans(),
                                          ),
                                          backgroundColor: Colors.green.shade600,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.save_rounded),
                                  label: Text(
                                    'Guardar',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Widget para títulos de sección
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Widget para cada opción de notificación
class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(value ? 0.1 : 0.05),
            color.withOpacity(value ? 0.05 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(value ? 0.3 : 0.1),
          width: value ? 2 : 1,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// Widget para seleccionar tiempo de anticipación
class _TimeSelector extends StatelessWidget {
  final String label;
  final int value;
  final List<int> options;
  final String unit;
  final ValueChanged<int> onChanged;

  const _TimeSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = value == option;
              return GestureDetector(
                onTap: () => onChanged(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                            ],
                          )
                        : null,
                    color: !isSelected
                        ? Theme.of(context).colorScheme.surface
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                  ),
                  child: Text(
                    '$option $unit',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Widget para cada curso
class _CourseTile extends StatelessWidget {
  final Course course;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CourseTile({
    required this.course,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (course.color ?? Colors.grey).withOpacity(value ? 0.1 : 0.05),
            (course.color ?? Colors.grey).withOpacity(value ? 0.05 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (course.color ?? Colors.grey).withOpacity(value ? 0.3 : 0.1),
          width: value ? 2 : 1,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: course.color ?? Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          course.name,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: course.teacher != null
            ? Text(
                'Prof: ${course.teacher}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
      ),
    );
  }
}
