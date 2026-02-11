import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/core_routes.dart';
import '../models/core_daily_stats.dart';
import '../models/core_recommendation.dart';
import '../services/core_aggregation_service.dart';
import '../services/core_recommendation_service.dart';
import '../utils/date_utils.dart';

class CoreDebugScreen extends StatefulWidget {
  const CoreDebugScreen({super.key});

  @override
  State<CoreDebugScreen> createState() => _CoreDebugScreenState();
}

class _CoreDebugScreenState extends State<CoreDebugScreen> {
  int _offset = 0;
  double? _targetKcal;
  double? _targetProtein;
  double? _targetWater;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('food')
        .doc('root')
        .collection('config')
        .doc('targets')
        .get();
    final data = snap.data() ?? const {};
    setState(() {
      _targetKcal = (data['kcal'] as num?)?.toDouble();
      _targetProtein = (data['protein'] as num?)?.toDouble();
      _targetWater = (data['water'] as num?)?.toDouble();
    });
  }

  DateTime get _selectedDate => DateTime.now().subtract(Duration(days: _offset));

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final dayId = dayIdFromDateTime(_selectedDate);
    final stream = CoreAggregationService.I.watchDay(uid, dayId);

    return Scaffold(
      appBar: AppBar(title: const Text('Core Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                _chip('Hoy', 0),
                _chip('Ayer', 1),
                _chip('-7', 7),
                _chip('-30', 30),
              ],
            ),
            const SizedBox(height: 12),
            Text('Día: $dayId'),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<CoreDailyStats>(
                stream: stream,
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? CoreDailyStats(dayId: dayId);
                  final hasError = snapshot.hasError;
                  final recs = <CoreRecommendation>[];
                  recs.addAll(
                    CoreRecommendationService.I.build(
                      stats,
                      targetKcal: _targetKcal,
                      targetProtein: _targetProtein,
                      targetWater: _targetWater,
                    ),
                  );
                  if (hasError) {
                    recs.add(
                      const CoreRecommendation(
                        id: 'sync-error',
                        dayId: '',
                        title: 'Error de sincronización',
                        message: 'No se pudieron leer algunos datos.',
                        severity: CoreRecommendationSeverity.low,
                        actionRoute: null,
                        actionLabel: null,
                      ),
                    );
                  }
                  return ListView(
                    children: [
                      _section('Stats', [
                        'Kcal: ${stats.kcal.toStringAsFixed(0)}',
                        'Proteína: ${stats.protein.toStringAsFixed(0)}',
                        'Entrenos: ${stats.workoutsCount} (${stats.workoutMinutes} min)',
                        'Estudio: ${stats.studyMinutes} min (${stats.studySessionsCount} sesiones)',
                        'Tareas: ${stats.tasksDone}/${stats.tasksTotal}',
                        'Finanzas gasto: ${stats.financeSpentTotal.toStringAsFixed(2)}',
                      ]),
                      _section('Recomendaciones', recs.isEmpty ? ['Sin recomendaciones'] : []),
                      ...recs.map(_recTile),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int offset) {
    final selected = _offset == offset;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _offset = offset),
    );
  }

  Widget _section(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...lines.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(l),
            )),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _recTile(CoreRecommendation r) {
    Color color;
    switch (r.severity) {
      case CoreRecommendationSeverity.low:
        color = Colors.blueGrey;
        break;
      case CoreRecommendationSeverity.med:
        color = Colors.orange;
        break;
      case CoreRecommendationSeverity.high:
        color = Colors.red;
        break;
    }
    return Card(
      child: ListTile(
        title: Text(r.title),
        subtitle: Text(r.message),
        trailing: r.actionRoute == null
            ? null
            : TextButton(
                onPressed: () => _openRoute(r.actionRoute!),
                child: Text(r.actionLabel ?? 'Abrir'),
              ),
        leading: CircleAvatar(backgroundColor: color, radius: 6),
      ),
    );
  }

  void _openRoute(String route) async {
    try {
      await Navigator.of(context).pushNamed(route);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta no disponible')),
      );
    }
  }
}