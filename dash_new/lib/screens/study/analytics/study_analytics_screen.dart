import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';

class StudyAnalyticsScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  final String? courseId;
  const StudyAnalyticsScreen({super.key, required this.svc, this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analíticas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TotalHoursPerCourseCard(svc: svc),
          _StreakCard(svc: svc, courseId: courseId),
          const SizedBox(height: 12),
          _MinutesBarCard(svc: svc, courseId: courseId, days: 30),
          const SizedBox(height: 12),
          _MethodDistributionCard(svc: svc, courseId: courseId),
          const SizedBox(height: 12),
          _ActiveDaysByCourseCard(svc: svc),
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
        final sessions = snap.data!;
        final totals = <String, int>{};
        for (final s in sessions) {
          totals[s.courseId] = (totals[s.courseId] ?? 0) + s.minutes;
        }
        final items =
            totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.timeline),
                title: Text('Horas totales por curso'),
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
                    trailing: Text('${(e.value / 60).toStringAsFixed(1)} h'),
                  ),
                ),
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
        final map = <String, Set<DateTime>>{}; // courseId -> unique days
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
        final map = <int, int>{}; // dayOffset -> minutes
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
