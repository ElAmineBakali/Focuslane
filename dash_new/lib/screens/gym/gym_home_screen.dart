import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mi_dashboard_personal/screens/gym/models/gym_models.dart';
import 'package:mi_dashboard_personal/screens/gym/services/gym_firestore_service.dart';
import 'routines/routines_list_screen.dart';
import 'routines/routine_detail_screen.dart';
import 'routines/preset_routines_screen.dart';
import 'analytics/gym_analytics_screen_v2.dart';
import 'widgets/export_data_screen.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';
import 'package:intl/intl.dart';

/// 🏋️ GymHomeScreen rediseñado - Estética profesional estilo Strong/Hevy
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
      whenLocal: at,
      useExact: false,
    );
  }

  @override
  void initState() {
    super.initState();
    _scheduleGymReminders();
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
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Gimnasio',
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
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: 40,
                      child: Icon(
                        Icons.fitness_center,
                        size: 120,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Reprogramar recordatorios',
                onPressed: () {
                  _scheduleGymReminders();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Recordatorios actualizados',
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                  // Rutina predeterminada (si existe)
                  StreamBuilder<Routine?>(
                    stream: widget.svc.streamDefaultRoutine(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final defaultRoutine = snap.data;
                      
                      if (defaultRoutine != null) {
                        return _buildDefaultRoutineCard(defaultRoutine)
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.2, end: 0);
                      }
                      return const SizedBox();
                    },
                  ),
                  
                  if (true) const SizedBox(height: 20),
                  
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

  Widget _buildDefaultRoutineCard(Routine routine) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoutineDetailScreen(svc: widget.svc, routine: routine),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.push_pin,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rutina Activa',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routine.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<List<SessionDoc>>(
      stream: widget.svc.streamSessions(limit: 7),
      builder: (context, snap) {
        final sessions = snap.data ?? [];
        final lastWeekSessions = sessions.where((s) {
          return s.date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
        }).toList();
        
        final totalVolume = lastWeekSessions.fold<double>(
          0,
          (sum, s) => sum + s.volumeKg,
        );
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Sesiones',
                '${lastWeekSessions.length}',
                'Esta semana',
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Volumen',
                '${(totalVolume / 1000).toStringAsFixed(1)} ton',
                '7 días',
                Icons.fitness_center,
                Colors.orange,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
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
            // Última sesión (si existe)
            if (sessions.isNotEmpty) ...[
              _buildLastSessionCard(sessions.first)
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
            ],
            
            // Historial completo
            _buildFeatureCard(
              'Historial Completo',
              'Ver todas tus sesiones de entrenamiento',
              Icons.history,
              Colors.indigo,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GymAnalyticsScreenV2(svc: widget.svc),
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
