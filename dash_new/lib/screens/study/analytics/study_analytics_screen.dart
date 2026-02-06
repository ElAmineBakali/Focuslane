import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import '../../../ui/components/focus_module_header.dart';

class StudyAnalyticsScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  final String? courseId;
  const StudyAnalyticsScreen({super.key, required this.svc, this.courseId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analíticas',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: FocusModuleHeader.buildLeading(
          context,
          mode: FocusModuleLeadingMode.backToModuleDashboard,
          backRouteName: AppRoutes.studyDashboard,
        ),
        leadingWidth: 96,
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TotalHoursPerCourseCard(
            svc: svc,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          _StreakCard(svc: svc, courseId: courseId)
              .animate()
              .fadeIn(delay: 100.ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          _MinutesBarCard(svc: svc, courseId: courseId, days: 30)
              .animate()
              .fadeIn(delay: 200.ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          _MethodDistributionCard(svc: svc, courseId: courseId)
              .animate()
              .fadeIn(delay: 300.ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          _ActiveDaysByCourseCard(svc: svc)
              .animate()
              .fadeIn(delay: 400.ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _TotalHoursPerCourseCard extends StatelessWidget {
  final StudyFirestoreService svc;
  const _TotalHoursPerCourseCard({required this.svc});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<StudySession>>(
      stream: svc.streamSessions(limit: 1000),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final sessions = snap.data!;
        final totals = <String, int>{};
        for (final s in sessions) {
          totals[s.courseId] = (totals[s.courseId] ?? 0) + s.minutes;
        }
        final items =
            totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.timeline,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Horas totales por curso',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sin sesiones registradas',
                        style: GoogleFonts.poppins(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...items.map(
                  (e) => Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${(e.value / 60).toStringAsFixed(1)} h',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveDaysByCourseCard extends StatelessWidget {
  final StudyFirestoreService svc;
  const _ActiveDaysByCourseCard({required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudySession>>(
      stream: svc.streamSessions(limit: 1000),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Card(
            child: SizedBox(
              height: 130,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        final map = <String, Set<DateTime>>{};
        for (final s in snap.data!) {
          final d = DateTime(s.date.year, s.date.month, s.date.day);
          map.putIfAbsent(s.courseId, () => <DateTime>{}).add(d);
        }
        final items =
            map.entries.map((e) => MapEntry(e.key, e.value.length)).toList()
              ..sort((a, b) => b.value.compareTo(a.value));
        return Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Días activos por curso'),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Sin sesiones'),
                )
              else
                ...items.map(
                  (e) => ListTile(
                    title: Text(e.key),
                    trailing: Text('${e.value} días'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StreakCard extends StatelessWidget {
  final StudyFirestoreService svc;
  final String? courseId;
  const _StreakCard({required this.svc, this.courseId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudySession>>(
      stream: svc.streamSessions(courseId: courseId, limit: 365),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Card(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        final list = snap.data!;
        final days =
            list
                .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
                .toSet()
                .toList()
              ..sort();
        int streak = 0;
        DateTime d = DateTime.now();
        while (days.contains(DateTime(d.year, d.month, d.day))) {
          streak++;
          d = d.subtract(const Duration(days: 1));
        }
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
            ),
            title: const Text('Racha de estudio'),
            subtitle: Text('$streak días seguidos'),
          ),
        );
      },
    );
  }
}

class _MinutesBarCard extends StatelessWidget {
  final StudyFirestoreService svc;
  final String? courseId;
  final int days;
  const _MinutesBarCard({required this.svc, this.courseId, required this.days});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudySession>>(
      stream: svc.streamSessions(courseId: courseId, limit: 500),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Card(
            child: SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        final list = snap.data!;
        final now = DateTime.now();
        final map = <int, int>{};
        for (int i = 0; i < days; i++) {
          map[i] = 0;
        }
        for (final s in list) {
          final diff = now.difference(s.date).inDays;
          if (diff >= 0 && diff < days) {
            map[diff] = (map[diff] ?? 0) + s.minutes;
          }
        }
        final bars = <BarChartGroupData>[];
        for (int i = days - 1; i >= 0; i--) {
          bars.add(
            BarChartGroupData(
              x: days - 1 - i,
              barRods: [BarChartRodData(toY: (map[i] ?? 0).toDouble())],
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Minutos últimos 30 días'),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: bars,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MethodDistributionCard extends StatelessWidget {
  final StudyFirestoreService svc;
  final String? courseId;
  const _MethodDistributionCard({required this.svc, this.courseId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudySession>>(
      stream: svc.streamSessions(courseId: courseId, limit: 500),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Card(
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        final list = snap.data!;
        final totals = <StudyMethod, int>{};
        for (final s in list) {
          totals[s.method] = (totals[s.method] ?? 0) + s.minutes;
        }
        final items =
            totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.pie_chart),
                title: Text('Distribución por método'),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Sin sesiones todavía'),
                )
              else
                ...items.map(
                  (e) => ListTile(
                    title: Text(e.key.name),
                    trailing: Text('${e.value} min'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
