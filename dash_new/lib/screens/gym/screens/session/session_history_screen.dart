import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';

import 'session_summary_screen.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({
    super.key,
    required this.svc,
    this.embedded = false,
  });

  final GymFirestoreService svc;
  final bool embedded;

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _HistoryContent(
      svc: widget.svc,
      query: _query,
      searchController: _searchController,
      onSearchChanged: (value) => setState(() => _query = value.toLowerCase()),
      onClearSearch: () {
        _searchController.clear();
        setState(() => _query = '');
      },
    );

    if (widget.embedded) return content;

    return AppShell(
      title: 'Historial',
      subtitle: 'Sesiones, volumen y marcas personales.',
      activeRoute: AppRoutes.gymDashboard,
      child: content,
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.svc,
    required this.query,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final GymFirestoreService svc;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SessionDoc>>(
      stream: svc.streamSessions(limit: 200),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PageContainer(
            child: FocusEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudo cargar el historial',
              subtitle: '${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var sessions = snapshot.data ?? const <SessionDoc>[];
        if (query.trim().isNotEmpty) {
          sessions =
              sessions.where((session) {
                return session.routineName.toLowerCase().contains(query) ||
                    session.dayName.toLowerCase().contains(query);
              }).toList();
        }

        final grouped = <String, List<SessionDoc>>{};
        for (final session in sessions) {
          final key = DateFormat('MMMM yyyy', 'es_ES').format(session.date);
          grouped.putIfAbsent(key, () => []).add(session);
        }

        return SingleChildScrollView(
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FocusSectionHeader(
                  icon: Icons.history_rounded,
                  title: 'Historial',
                  subtitle: '${sessions.length} sesiones registradas',
                ),
                const SizedBox(height: 14),
                FocusCard(
                  padding: const EdgeInsets.all(14),
                  child: FocusTextField(
                    label: 'Buscar sesiones',
                    hint: 'Rutina o día',
                    controller: searchController,
                    prefixIcon: Icons.search_rounded,
                    suffixIcon:
                        query.isEmpty
                            ? null
                            : IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: onClearSearch,
                            ),
                    onChanged: onSearchChanged,
                  ),
                ),
                const SizedBox(height: 16),
                if (sessions.isEmpty)
                  FocusCard(
                    child: FocusEmptyState(
                      icon: Icons.inbox_rounded,
                      message:
                          query.isEmpty
                              ? 'No hay sesiones registradas'
                              : 'Sin resultados',
                      subtitle:
                          query.isEmpty
                              ? 'Completa una sesión para crear historial.'
                              : 'Prueba con otra rutina o día.',
                    ),
                  )
                else
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _capitalize(entry.key),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    ResponsiveGrid(
                      minItemWidth: 320,
                      spacing: 12,
                      children: [
                        for (final session in entry.value)
                          _SessionHistoryCard(
                            session: session,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SessionSummaryScreen(
                                          session: session,
                                          svc: svc,
                                        ),
                                  ),
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({required this.session, required this.onTap});

  final SessionDoc session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPr = session.prList.isNotEmpty;

    return FocusCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.dayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      session.routineName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPr)
                FocusBadge(
                  label: '${session.prList.length} PR',
                  color: scheme.tertiary,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FocusBadge(
                label: DateFormat('d MMM yyyy', 'es_ES').format(session.date),
                color: scheme.primary,
              ),
              FocusBadge(
                label: '${session.durationMin ?? 0} min',
                color: scheme.secondary,
              ),
              FocusBadge(
                label: _volumeLabel(session.volumeKg),
                color: scheme.tertiary,
              ),
            ],
          ),
          if (session.feelingEnergy != null ||
              session.feelingFatigue != null ||
              session.feelingMotivation != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                [
                  if (session.feelingEnergy != null)
                    'Energía ${session.feelingEnergy}/5',
                  if (session.feelingFatigue != null)
                    'Fatiga ${session.feelingFatigue}/5',
                  if (session.feelingMotivation != null)
                    'Motivación ${session.feelingMotivation}/5',
                ].join(' - '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value.substring(0, 1).toUpperCase() + value.substring(1);
}

String _volumeLabel(double value) {
  if (value <= 0) return '0 kg';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} ton';
  return '${value.toStringAsFixed(0)} kg';
}
