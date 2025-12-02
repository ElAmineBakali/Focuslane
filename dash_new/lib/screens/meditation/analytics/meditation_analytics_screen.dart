// lib/screens/meditation/analytics/meditation_analytics_screen.dart
import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';

class MeditationAnalyticsScreen extends StatefulWidget {
  const MeditationAnalyticsScreen({super.key});
  static const route = '/meditation/analytics';

  @override
  State<MeditationAnalyticsScreen> createState() =>
      _MeditationAnalyticsScreenState();
}

class _MeditationAnalyticsScreenState extends State<MeditationAnalyticsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final svc = MeditationFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analíticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _month,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null)
                setState(() => _month = DateTime(d.year, d.month, 1));
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: svc.monthStats(_month),
        builder: (context, s) {
          final minutes = (s.data?['minutes'] ?? 0) as int;
          final count = (s.data?['count'] ?? 0) as int;
          final byType = (s.data?['byType'] as Map<String, int>?) ?? {};

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _sectionCard(
                icon: Icons.query_stats,
                title: 'KPIs del mes',
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _kpi('Minutos', minutes.toDouble(), Icons.timelapse),
                    _kpi(
                      'Sesiones',
                      count.toDouble(),
                      Icons.library_music_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                icon: Icons.bar_chart,
                title: 'Minutos por tipo',
                child:
                    (byType.isEmpty)
                        ? const ListTile(title: Text('Sin datos'))
                        : Column(
                          children:
                              byType.entries.map((e) {
                                final total = minutes == 0 ? 1 : minutes;
                                final pct = (e.value / total).clamp(0.0, 1.0);
                                return ListTile(
                                  leading: const Icon(Icons.label_outline),
                                  title: Text(e.key),
                                  subtitle: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 8,
                                    ),
                                  ),
                                  trailing: Text('${e.value}m'),
                                );
                              }).toList(),
                        ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                icon: Icons.calendar_today,
                title: 'Heatmap (minutos por día)',
                child: FutureBuilder<Map<DateTime, int>>(
                  future: svc.heatmapMonth(_month),
                  builder: (context, h) {
                    final map = h.data ?? {};
                    return _heatmapGrid(map);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kpi(String title, double v, IconData icon) {
    return SizedBox(
      width: 230,
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Center(child: Text(title)),
          subtitle: Center(child: Text(v.toStringAsFixed(0))),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _heatmapGrid(Map<DateTime, int> byDay) {
    final last = DateTime(_month.year, _month.month + 1, 0);
    final days = last.day;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(days, (i) {
          final d = DateTime(_month.year, _month.month, i + 1);
          final v = byDay[DateTime(d.year, d.month, d.day)] ?? 0;
          final intensity = (v / 30).clamp(0.0, 1.0); // 30 min = full
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(intensity * 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 10,
                color: intensity > 0.55 ? Colors.white : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
