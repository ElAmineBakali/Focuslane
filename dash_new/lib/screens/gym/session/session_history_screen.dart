import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/gym_firestore_service.dart';
import '../models/gym_models.dart';
import '../session/session_summary_screen.dart';

/// 📜 Pantalla de historial completo de sesiones con búsqueda y filtros
class SessionHistoryScreen extends StatefulWidget {
  final GymFirestoreService svc;

  const SessionHistoryScreen({super.key, required this.svc});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  String _searchQuery = '';
  String? _selectedRoutineFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar moderno
          SliverAppBar.large(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: colorScheme.primaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Historial',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
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
                child: Center(
                  child: Icon(
                    Icons.history_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),

          // Barra de búsqueda y filtros
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Búsqueda
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre de rutina o día...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Lista de sesiones
          StreamBuilder<List<SessionDoc>>(
            stream: widget.svc.streamSessions(
              limit: 200,
              routineId: _selectedRoutineFilter,
            ),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              var sessions = snap.data!;

              // Aplicar filtro de búsqueda
              if (_searchQuery.isNotEmpty) {
                sessions = sessions.where((s) {
                  return s.routineName.toLowerCase().contains(_searchQuery) ||
                      s.dayName.toLowerCase().contains(_searchQuery);
                }).toList();
              }

              if (sessions.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay sesiones registradas',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Agrupar por mes
              final byMonth = <String, List<SessionDoc>>{};
              for (final s in sessions) {
                final key = DateFormat('MMMM yyyy', 'es').format(s.date);
                byMonth.putIfAbsent(key, () => []).add(s);
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entries = byMonth.entries.toList();
                    final monthKey = entries[index].key;
                    final monthSessions = entries[index].value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header de mes
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            monthKey.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Sesiones del mes
                        ...monthSessions.map((s) {
                          return _buildSessionCard(s, colorScheme);
                        }),

                        const SizedBox(height: 8),
                      ],
                    ).animate().fadeIn(delay: (50 * index).ms);
                  },
                  childCount: byMonth.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(SessionDoc session, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionSummaryScreen(
                session: session,
                svc: widget.svc,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Rutina + Día
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.routineName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          session.dayName,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (session.prList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${session.prList.length} PR',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _buildStatChip(
                    Icons.calendar_today_rounded,
                    DateFormat('d MMM yyyy', 'es').format(session.date),
                    colorScheme,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.timer_rounded,
                    '${session.durationMin ?? 0} min',
                    colorScheme,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.scale_rounded,
                    '${session.volumeKg.toStringAsFixed(0)} kg',
                    colorScheme,
                  ),
                ],
              ),

              // Sensaciones (si existen)
              if (session.feelingEnergy != null ||
                  session.feelingFatigue != null ||
                  session.feelingMotivation != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      if (session.feelingEnergy != null)
                        Text(
                          '⚡ ${session.feelingEnergy}',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                      if (session.feelingFatigue != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '💪 ${session.feelingFatigue}',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                      ],
                      if (session.feelingMotivation != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '❤️ ${session.feelingMotivation}',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
