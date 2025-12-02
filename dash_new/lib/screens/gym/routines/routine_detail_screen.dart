// lib/screens/gym/routine_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/gym_firestore_service.dart';
import '../models/gym_models.dart';
import '../session/live_session_screen.dart';
import '../analytics/gym_analytics_screen.dart';

SnackBar _niceBar(String text, {IconData? icon}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    content: Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Expanded(child: Text(text)),
      ],
    ),
    duration: const Duration(seconds: 3),
  );
}

class RoutineDetailScreen extends StatelessWidget {
  final GymFirestoreService svc;
  final Routine routine;
  const RoutineDetailScreen({
    super.key,
    required this.svc,
    required this.routine,
  });

  Future<void> _createDaySheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    int? restDefault;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom:
                  16 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nuevo día en "${routine.name}"',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del día (p. ej. Pecho/Espalda)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Descanso por defecto (segundos, opcional)',
                  ),
                  onChanged: (s) => restDefault = int.tryParse(s),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Crear'),
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

      // Calcula siguiente 'order'
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
      // Feedback
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        _niceBar(
          'Día "$name" creado correctamente 🎉',
          icon: Icons.check_circle_rounded,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          // Estado de rutina predeterminada en vivo
          StreamBuilder<Routine?>(
            stream: svc.streamDefaultRoutine(),
            builder: (context, snap) {
              return IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Estadísticas',
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GymAnalyticsScreen(svc: svc),
                      ),
                    ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDaySheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Añadir día'),
      ),
      body: StreamBuilder<List<RoutineDay>>(
        stream: svc.streamDays(routine.id),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final days = snap.data!;
          if (days.isEmpty) {
            return const Center(
              child: Text('Crea tu primer día con el botón ➕'),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              MediaQuery.of(context).viewPadding.bottom + 100,
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: days.length,
            itemBuilder: (c, i) {
              final d = days[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(d.name),
                  subtitle: _LastDoneSubtitle(
                    svc: svc,
                    routineId: routine.id,
                    dayId: d.id,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'dup') {
                        await svc.duplicateDay(routine.id, d.id);
                        if (c.mounted) {
                          ScaffoldMessenger.of(c).showSnackBar(
                            _niceBar(
                              'Día duplicado ✨',
                              icon: Icons.copy_all_rounded,
                            ),
                          );
                        }
                      }
                      if (v == 'del') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text('Eliminar día'),
                                content: Text(
                                  '¿Eliminar "${d.name}" y sus ejercicios?',
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
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                        );
                        if (ok == true) {
                          await svc.deleteDayCascade(routine.id, d.id);
                          if (c.mounted) {
                            ScaffoldMessenger.of(c).showSnackBar(
                              _niceBar(
                                'Día eliminado 🗑️',
                                icon: Icons.delete_outline,
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
                            child: Text('Duplicar día'),
                          ),
                          PopupMenuItem(
                            value: 'del',
                            child: Text('Eliminar día'),
                          ),
                        ],
                  ),
                  onTap:
                      () => Navigator.push(
                        c,
                        MaterialPageRoute(
                          builder:
                              (_) => LiveSessionScreen(
                                svc: svc,
                                routine: routine,
                                day: d,
                              ),
                        ),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
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
    final dayRef = svc.root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId);

    return StreamBuilder<DocumentSnapshot>(
      stream: dayRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists)
          return const Text('Sin sesiones aún');
        final data = snap.data!.data() as Map<String, dynamic>;
        final dt =
            _readAsDate(data['lastDone']) ?? _readAsDate(data['lastDoneLocal']);
        if (dt == null) return const Text('Sin sesiones aún');

        final lastLocal = dt.toLocal();
        final now = DateTime.now();
        final sameDay =
            lastLocal.year == now.year &&
            lastLocal.month == now.month &&
            lastLocal.day == now.day;

        return Text(sameDay ? 'Hecho hoy ✓' : 'Última vez: $lastLocal');
      },
    );
  }
}
