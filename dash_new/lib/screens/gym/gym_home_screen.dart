import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mi_dashboard_personal/screens/gym/models/gym_models.dart';
import 'package:mi_dashboard_personal/screens/gym/services/gym_firestore_service.dart';
import 'routines/routines_list_screen.dart';
import 'routines/routine_detail_screen.dart';
import 'routines/preset_routines_screen.dart';
import 'analytics/gym_analytics_screen_v2.dart';
import 'session/session_history_screen.dart';
import 'widgets/export_data_screen.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/module_shell.dart';
import '../../widgets/global_ui_components.dart';

 class GymHomeScreen extends StatefulWidget {
  final GymFirestoreService svc;
  const GymHomeScreen({super.key, required this.svc});

  @override
  State<GymHomeScreen> createState() => _GymHomeScreenState();
}

class _GymHomeScreenState extends State<GymHomeScreen> {
  static const int _weeklyWeightId = 22010;
  static const int _weeklyMeasureId = 22011;
  static const int _inactivityId = 22001;

  Future<void> _scheduleGymReminders() async {
    DateTime nextWeekday(int weekday, {int hour = 9, int minute = 0}) {
      final now = DateTime.now();
      int add = (weekday - now.weekday) % 7;
      if (add == 0) add = 7;
      final d = now.add(Duration(days: add));
      return DateTime(d.year, d.month, d.day, hour, minute);
    }

    await NotificationService.I.cancel(_weeklyWeightId);
    await NotificationService.I.cancel(_weeklyMeasureId);

    final nextMon = nextWeekday(DateTime.monday, hour: 9);
    await NotificationService.I.scheduleOnce(
      id: _weeklyWeightId,
      title: 'Control semanal',
      body: 'Pésate y registra tu peso 📉',
      whenLocal: nextMon,
      useExact: false,
    );

    final nextMon2 = nextWeekday(DateTime.monday, hour: 9, minute: 5);
    await NotificationService.I.scheduleOnce(
      id: _weeklyMeasureId,
      title: 'Medidas corporales',
      body: 'Toca medir perímetros (pecho, brazo, cintura…) 📏',
      whenLocal: nextMon2,
      useExact: false,
    );

    const xDays = 3;
    await NotificationService.I.cancel(_inactivityId);
    final last = await widget.svc.lastSessionDate();
    DateTime base;
    if (last == null) {
      base = DateTime.now().add(Duration(days: xDays));
    } else {
      base = last.add(Duration(days: xDays));
      if (base.isBefore(DateTime.now())) {
        base = DateTime.now().add(const Duration(minutes: 5));
      }
    }
    final at = DateTime(base.year, base.month, base.day, 10, 0);
    await NotificationService.I.scheduleOnce(
      id: _inactivityId,
      title: 'Vuelve al gym',
      body: 'Llevas $xDays días sin entrenar. ¡Toca sesión! 💪',
          return Row(
            children: [
              Expanded(
                child: FocusStatCard(
                  label: 'Sesiones',
                  value: '${lastWeekSessions.length}',
                  subtitle: 'Esta semana',
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FocusStatCard(
                  label: 'Volumen',
                  value: '${(totalVolume / 1000).toStringAsFixed(1)} ton',
                  subtitle: '7 días',
                  icon: Icons.fitness_center,
                  color: Colors.orange,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
                      style: GoogleFonts.poppins(),
                    ),
                  ],
          if (true) const SizedBox(height: 20),
          
      return FocusActionsGrid(
        items: [
          FocusActionItem(
            title: 'Mis Rutinas',
            icon: Icons.list_alt,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoutinesListScreen(svc: widget.svc),
                ),
              );
            },
            animationDelay: 100.ms,
          ),
          FocusActionItem(
            title: 'Rutinas Destacadas',
            icon: Icons.auto_awesome,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PresetRoutinesScreen(svc: widget.svc),
                ),
              );
            },
            animationDelay: 200.ms,
          ),
          FocusActionItem(
            title: 'Analíticas',
            icon: Icons.bar_chart,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GymAnalyticsScreenV2(svc: widget.svc),
                ),
              );
            },
            animationDelay: 300.ms,
          ),
          FocusActionItem(
            title: 'Exportar Datos',
            icon: Icons.download,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExportDataScreen(svc: widget.svc),
                ),
              );
            },
            animationDelay: 400.ms,
          ),
        ],
      );
            );
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routine.splitType,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onPrimaryContainer.withOpacity(0.5),
                ),
                           FocusFeatureCard(
                title: 'Historial Completo',
                subtitle: 'Ver todas tus sesiones de entrenamiento',
                icon: Icons.history,
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionHistoryScreen(svc: widget.svc),
                    ),
                  );
                },
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0),
          return s.date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
        }).toList();
        
        final totalVolume = lastWeekSessions.fold<double>(
          0,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(
          'Mis Rutinas',
          Icons.list_alt,
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoutinesListScreen(svc: widget.svc),
              ),
            );
          },
        ).animate(delay: 100.ms).fadeIn(duration: 400.ms).scale(),
        
        _buildActionCard(
          'Rutinas Destacadas',
          Icons.auto_awesome,
          Colors.purple,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PresetRoutinesScreen(svc: widget.svc),
              ),
            );
          },
        ).animate(delay: 200.ms).fadeIn(duration: 400.ms).scale(),
        
        _buildActionCard(
          'Analíticas',
          Icons.bar_chart,
          Colors.green,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GymAnalyticsScreenV2(svc: widget.svc),
              ),
            );
          },
        ).animate(delay: 300.ms).fadeIn(duration: 400.ms).scale(),
        
        _buildActionCard(
          'Exportar Datos',
          Icons.download,
          Colors.orange,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExportDataScreen(svc: widget.svc),
              ),
            );
          },
        ).animate(delay: 400.ms).fadeIn(duration: 400.ms).scale(),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainFeatures() {
    return StreamBuilder<List<SessionDoc>>(
      stream: widget.svc.streamSessions(limit: 5),
      builder: (context, snap) {
        final sessions = snap.data ?? [];
        
        return Column(
          children: [
                         if (sessions.isNotEmpty) ...[
              _buildLastSessionCard(sessions.first)
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
            ],
            
                         _buildFeatureCard(
              'Historial Completo',
              'Ver todas tus sesiones de entrenamiento',
              Icons.history,
              Colors.indigo,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionHistoryScreen(svc: widget.svc),
                  ),
                );
              },
            ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0),
          ],
        );
      },
    );
  }

  Widget _buildLastSessionCard(SessionDoc session) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Última Sesión',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('d MMM', 'es').format(session.date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.dayName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              session.routineName,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSessionStat(
                  Icons.fitness_center,
                  '${session.volumeKg.toStringAsFixed(0)} kg',
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                if (session.durationMin != null)
                  _buildSessionStat(
                    Icons.timer,
                    '${session.durationMin} min',
                    Colors.blue,
                  ),
                if (session.prList.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  _buildSessionStat(
                    Icons.emoji_events,
                    '${session.prList.length} PR',
                    Colors.amber,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  color: color.withOpacity(0.2),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

 class _NotificationSettingsSheet extends StatefulWidget {
  final VoidCallback onSave;
  const _NotificationSettingsSheet({required this.onSave});

  @override
  State<_NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<_NotificationSettingsSheet> {
  bool _enableWeightReminder = true;
  bool _enableMeasurementsReminder = true;
  bool _enableInactivityReminder = true;
  int _inactivityDays = 3;
  int _weightReminderDay = DateTime.monday;
  TimeOfDay _weightReminderTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _measurementsReminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                         Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

                         Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configurar Notificaciones',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Personaliza tus recordatorios',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey[300]),

                         Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                children: [
                                     _buildSection(
                    icon: Icons.monitor_weight_outlined,
                    title: 'Control de Peso Semanal',
                    subtitle: 'Recordatorio para registrar tu peso',
                    value: _enableWeightReminder,
                    onChanged: (v) => setState(() => _enableWeightReminder = v),
                    colorScheme: colorScheme,
                    child: _enableWeightReminder
                        ? Column(
                            children: [
                              const SizedBox(height: 12),
                              ListTile(
                                dense: true,
                                leading: Icon(Icons.calendar_today, size: 20, color: colorScheme.primary),
                                title: Text('Día de la semana', style: GoogleFonts.poppins(fontSize: 14)),
                                trailing: DropdownButton<int>(
                                  value: _weightReminderDay,
                                  onChanged: (v) => setState(() => _weightReminderDay = v!),
                                  items: const [
                                    DropdownMenuItem(value: DateTime.monday, child: Text('Lunes')),
                                    DropdownMenuItem(value: DateTime.tuesday, child: Text('Martes')),
                                    DropdownMenuItem(value: DateTime.wednesday, child: Text('Miércoles')),
                                    DropdownMenuItem(value: DateTime.thursday, child: Text('Jueves')),
                                    DropdownMenuItem(value: DateTime.friday, child: Text('Viernes')),
                                    DropdownMenuItem(value: DateTime.saturday, child: Text('Sábado')),
                                    DropdownMenuItem(value: DateTime.sunday, child: Text('Domingo')),
                                  ],
                                ),
                              ),
                              ListTile(
                                dense: true,
                                leading: Icon(Icons.access_time, size: 20, color: colorScheme.primary),
                                title: Text('Hora', style: GoogleFonts.poppins(fontSize: 14)),
                                trailing: TextButton(
                                  onPressed: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: _weightReminderTime,
                                    );
                                    if (time != null) {
                                      setState(() => _weightReminderTime = time);
                                    }
                                  },
                                  child: Text(
                                    '${_weightReminderTime.hour.toString().padLeft(2, '0')}:${_weightReminderTime.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                                     _buildSection(
                    icon: Icons.straighten,
                    title: 'Medidas Físicas Semanales',
                    subtitle: 'Recordatorio para medidas corporales',
                    value: _enableMeasurementsReminder,
                    onChanged: (v) => setState(() => _enableMeasurementsReminder = v),
                    colorScheme: colorScheme,
                    child: _enableMeasurementsReminder
                        ? Column(
                            children: [
                              const SizedBox(height: 12),
                              ListTile(
                                dense: true,
                                leading: Icon(Icons.access_time, size: 20, color: colorScheme.primary),
                                title: Text('Hora (Lunes)', style: GoogleFonts.poppins(fontSize: 14)),
                                trailing: TextButton(
                                  onPressed: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: _measurementsReminderTime,
                                    );
                                    if (time != null) {
                                      setState(() => _measurementsReminderTime = time);
                                    }
                                  },
                                  child: Text(
                                    '${_measurementsReminderTime.hour.toString().padLeft(2, '0')}:${_measurementsReminderTime.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                                     _buildSection(
                    icon: Icons.notifications_active,
                    title: 'Alerta de Inactividad',
                    subtitle: 'Aviso cuando llevas días sin entrenar',
                    value: _enableInactivityReminder,
                    onChanged: (v) => setState(() => _enableInactivityReminder = v),
                    colorScheme: colorScheme,
                    child: _enableInactivityReminder
                        ? Column(
                            children: [
                              const SizedBox(height: 12),
                              ListTile(
                                dense: true,
                                leading: Icon(Icons.timer_outlined, size: 20, color: colorScheme.primary),
                                title: Text('Días de inactividad', style: GoogleFonts.poppins(fontSize: 14)),
                                subtitle: Slider(
                                  value: _inactivityDays.toDouble(),
                                  min: 1,
                                  max: 7,
                                  divisions: 6,
                                  label: '$_inactivityDays días',
                                  onChanged: (v) => setState(() => _inactivityDays = v.round()),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_inactivityDays días',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ],
              ),
            ),

                         Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancelar', style: GoogleFonts.poppins()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        widget.onSave();
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Guardar y Activar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: value,
            onChanged: onChanged,
          ),
          if (child != null) ...[
            Divider(height: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}
