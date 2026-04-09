import 'package:flutter/material.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/gym_firestore_service.dart';
import '../session/live_session_screen.dart';
import '../analytics/gym_analytics_screen.dart';
import '../../../design/ui/components/focus_module_header.dart';

class RoutineDetailScreen extends StatelessWidget {
  final GymFirestoreService svc;
  final Routine routine;

  const RoutineDetailScreen({
    super.key,
    required this.svc,
    required this.routine,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: false,
            pinned: true,
            expandedHeight: 200,
            leading: FocusModuleHeader.buildLeading(
              context,
              mode: FocusModuleLeadingMode.backToModuleDashboard,
              backRouteName: AppRoutes.gymDashboard,
            ),
            leadingWidth: 96,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                routine.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [routine.color, routine.color.withOpacity(0.6)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 200,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Estadísticas',
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GymAnalyticsScreen(svc: svc),
                      ),
                    ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<List<RoutineDay>>(
              stream: svc.streamDays(routine.id),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final days = snap.data!;

                if (days.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: s.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: s.outlineVariant.withOpacity(0.5),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 64,
                          color: s.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin días aún',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: s.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primer día con el botón inferior',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: s.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: days.length,
                  itemBuilder: (c, i) {
                    final d = days[i];
                    return _buildDayCard(context, d, i, s)
                        .animate()
                        .fadeIn(delay: (50 * i).ms, duration: 400.ms)
                        .slideX(begin: 0.2, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDaySheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Añadir Día'),
        backgroundColor: routine.color,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    RoutineDay d,
    int index,
    ColorScheme s,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [s.surfaceContainerHighest, s.surfaceContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: routine.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          LiveSessionScreen(svc: svc, routine: routine, day: d),
                ),
              ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            routine.color,
                            routine.color.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: routine.color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'D${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: s.onSurface,
                            ),
                          ),
                          _LastDoneSubtitle(
                            svc: svc,
                            routineId: routine.id,
                            dayId: d.id,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: s.onSurfaceVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (v) async {
                        if (v == 'dup') {
                          await svc.duplicateDay(routine.id, d.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              _buildSnackBar(
                                'Día duplicado âœ¨',
                                Icons.copy_all_rounded,
                                s,
                              ),
                            );
                          }
                        }
                        if (v == 'del') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: Text(
                                    'Eliminar día',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  content: Text(
                                    '¿Eliminar "${d.name}" y sus ejercicios?',
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: s.error,
                                      ),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                          );
                          if (ok == true) {
                            await svc.deleteDayCascade(routine.id, d.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                _buildSnackBar(
                                  'Día eliminado ðŸ—‘ï¸',
                                  Icons.delete_outline,
                                  s,
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder:
                          (_) => const [
                            PopupMenuItem(
                              value: 'dup',
                              child: Row(
                                children: [
                                  Icon(Icons.content_copy_rounded, size: 20),
                                  SizedBox(width: 12),
                                  Text('Duplicar día'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'del',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded, size: 20),
                                  SizedBox(width: 12),
                                  Text('Eliminar día'),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SnackBar _buildSnackBar(String text, IconData icon, ColorScheme s) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: s.inverseSurface,
      content: Row(
        children: [
          Icon(icon, size: 20, color: s.onInverseSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: s.onInverseSurface)),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _createDaySheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    int? restDefault;
    final s = Theme.of(context).colorScheme;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (ctx) => Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 0,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Nuevo día',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: s.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'en "${routine.name}"',
                  style: TextStyle(fontSize: 14, color: s.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Nombre del día',
                    hintText: 'Ej: Pecho/Espalda, Push, Pierna...',
                    prefixIcon: const Icon(Icons.label_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: s.surfaceContainerHighest.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Descanso por defecto (opcional)',
                    hintText: '90',
                    suffixText: 'segundos',
                    prefixIcon: const Icon(Icons.timer_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: s.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  onChanged: (s) => restDefault = int.tryParse(s),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: routine.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Crear día',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );

    if (ok == true) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) return;

      final col = svc.root
          .collection('routines')
          .doc(routine.id)
          .collection('days');

      final snap = await col.get();
      final nextOrder =
          (snap.docs
              .map((d) {
                final m = d.data();
                return (m['order'] as num?)?.toInt() ?? 0;
              })
              .fold<int>(0, (a, b) => b > a ? b : a)) +
          1;

      await col.add({
        'name': name,
        'order': nextOrder,
        if (restDefault != null) 'restSecDefault': restDefault,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          'Día "$name" creado correctamente ðŸŽ‰',
          Icons.check_circle_rounded,
          Theme.of(context).colorScheme,
        ),
      );
    }
  }
}

class _LastDoneSubtitle extends StatelessWidget {
  final GymFirestoreService svc;
  final String routineId;
  final String dayId;

  const _LastDoneSubtitle({
    required this.svc,
    required this.routineId,
    required this.dayId,
  });

  DateTime? _readAsDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final dayRef = svc.root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId);

    return StreamBuilder<DocumentSnapshot>(
      stream: dayRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return Text(
            'Sin sesiones aún',
            style: TextStyle(fontSize: 12, color: s.onSurfaceVariant),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final dt =
            _readAsDate(data['lastDone']) ?? _readAsDate(data['lastDoneLocal']);

        if (dt == null) {
          return Text(
            'Sin sesiones aún',
            style: TextStyle(fontSize: 12, color: s.onSurfaceVariant),
          );
        }

        final lastLocal = dt.toLocal();
        final now = DateTime.now();
        final sameDay =
            lastLocal.year == now.year &&
            lastLocal.month == now.month &&
            lastLocal.day == now.day;

        return Row(
          children: [
            Icon(
              sameDay ? Icons.check_circle_rounded : Icons.history_rounded,
              size: 14,
              color: sameDay ? Colors.green : s.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              sameDay ? 'Hecho hoy' : 'Hace ${_formatTimeDiff(lastLocal, now)}',
              style: TextStyle(
                fontSize: 12,
                color: sameDay ? Colors.green : s.onSurfaceVariant,
                fontWeight: sameDay ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimeDiff(DateTime past, DateTime now) {
    final diff = now.difference(past);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'ahora';
  }
}


