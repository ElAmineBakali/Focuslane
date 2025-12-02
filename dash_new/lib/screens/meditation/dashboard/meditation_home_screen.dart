import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';

class MeditationHomeScreen extends StatefulWidget {
  const MeditationHomeScreen({super.key});
  static const route = '/meditation';

  @override
  State<MeditationHomeScreen> createState() => _MeditationHomeScreenState();
}

class _MeditationHomeScreenState extends State<MeditationHomeScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final svc = MeditationFirestoreService.I;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditación'),
        actions: [
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/meditation/sessions'),
          ),
          IconButton(
            tooltip: 'Analíticas',
            icon: const Icon(Icons.insights),
            onPressed: () => Navigator.pushNamed(context, '/meditation/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Cambiar mes',
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _month,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) {
                setState(() => _month = DateTime(d.year, d.month, 1));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        child: Column(
          children: [
            // KPIs de racha (en vivo)
            StreamBuilder<Map<String, dynamic>>(
              stream: svc.watchMeta(),
              builder: (context, snap) {
                final meta = snap.data ?? const {};
                final streak = (meta['streak'] as num?)?.toInt() ?? 0;
                final best = (meta['bestStreak'] as num?)?.toInt() ?? 0;
                final items = [
                  _kpiSmall(context, 'Racha actual', '${streak}d', Icons.local_fire_department_outlined),
                  _kpiSmall(context, 'Mejor racha', '${best}d', Icons.emoji_events_outlined),
                ];
                return _kpiResponsive(items);
              },
            ),
            const SizedBox(height: 8),

            FutureBuilder<Map<String, dynamic>>(
              future: svc.monthStats(_month),
              builder: (context, snap) {
                final minutes = (snap.data?['minutes'] ?? 0) as int;
                final count = (snap.data?['count'] ?? 0) as int;
                final items = [
                  _kpiSmall(context, 'Minutos (mes)', minutes.toString(), Icons.timelapse),
                  _kpiSmall(context, 'Sesiones (mes)', count.toString(), Icons.library_music_outlined),
                ];
                return _kpiResponsive(items);
              },
            ),
            const SizedBox(height: 16),

            _navCard(
              icon: Icons.timer_outlined,
              title: 'Temporizador (silenciosa)',
              onTap: () => Navigator.pushNamed(context, '/meditation/timer'),
            ),
            _navCard(
              icon: Icons.blur_circular_outlined,
              title: 'Respiración guiada',
              subtitle: 'Presets y sonidos ambiente dentro',
              onTap: () => Navigator.pushNamed(context, '/meditation/breath'),
            ),
            _navCard(
              icon: Icons.notifications_active_outlined,
              title: 'Recordatorios',
              onTap: () => Navigator.pushNamed(context, '/meditation/reminders'),
            ),
            _navCard(
              icon: Icons.tag_outlined,
              title: 'Tags',
              onTap: () => Navigator.pushNamed(context, '/meditation/tags'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiSmall(BuildContext context, String title, String value, IconData icon) {
    final w = MediaQuery.of(context).size.width;
    final cardW = w < 480 ? (w - 16 - 8) / 2 : 220.0;
    return SizedBox(
      width: cardW,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _kpiResponsive(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isNarrow = w < 520;
        if (!isNarrow) {
          return Wrap(spacing: 8, runSpacing: 8, children: items);
        }
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += 2) {
          if (i + 1 < items.length) {
            rows.add(Row(children: [Expanded(child: items[i]), const SizedBox(width: 8), Expanded(child: items[i + 1])]));
          } else {
            rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: (w / 2) - 4), Expanded(child: items[i])]));
          }
          rows.add(const SizedBox(height: 8));
        }
        return Column(children: rows);
      },
    );
  }

  Widget _navCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
