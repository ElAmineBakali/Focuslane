import 'package:flutter/material.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/gym_firestore_service.dart';
import '../models/gym_models.dart';
import '../session/live_session_screen.dart';
import '../../../design/ui/components/focus_module_header.dart';

class RoutineDayPickerScreen extends StatefulWidget {
  final GymFirestoreService svc;
  final Routine routine;
  const RoutineDayPickerScreen({
    super.key,
    required this.svc,
    required this.routine,
  });

  @override
  State<RoutineDayPickerScreen> createState() => _RoutineDayPickerScreenState();
}

class _RoutineDayPickerScreenState extends State<RoutineDayPickerScreen> {
  final _dayCtrl = TextEditingController();

  @override
  void dispose() {
    _dayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
        leading: FocusModuleHeader.buildLeading(
          context,
          mode: FocusModuleLeadingMode.backToModuleDashboard,
          backRouteName: AppRoutes.gymDashboard,
        ),
        leadingWidth: 96,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text('Nuevo día'),
                  content: TextField(
                    controller: _dayCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del día (ej. Push / Pull / Legs)',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Crear'),
                    ),
                  ],
                ),
          );
          if (ok == true) {
            final name = _dayCtrl.text.trim();
            if (name.isNotEmpty) {
              await svc.addDay(
                widget.routine.id,
                name,
                order: DateTime.now().millisecondsSinceEpoch,
              );
              _dayCtrl.clear();
            }
          }
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<RoutineDay>>(
        stream: svc.streamDays(widget.routine.id),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final days = snap.data!;
          if (days.isEmpty) {
            return const Center(child: Text('Añade tus días con el botón +'));
          }
          return ReorderableListView.builder(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              MediaQuery.of(context).viewPadding.bottom + 100,
            ),
            itemCount: days.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              final ordered = [...days];
              final item = ordered.removeAt(oldIndex);
              ordered.insert(newIndex, item);
              await svc.reorderDays(
                widget.routine.id,
                ordered.map((d) => d.id).toList(),
              );
            },
            itemBuilder: (_, i) {
              final d = days[i];
              return Card(
                key: ValueKey(d.id),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle_rounded),
                  title: Text(d.name),
                  subtitle: _LastDoneMini(
                    svc: svc,
                    routineId: widget.routine.id,
                    dayId: d.id,
                  ),
                  trailing: IconButton(
                    tooltip: 'Eliminar día',
                    icon: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.redAccent,
                    ),
                    onPressed: () async {
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
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                      );
                      if (ok == true) {
                        await svc.deleteDayCascade(widget.routine.id, d.id);
                      }
                    },
                  ),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => LiveSessionScreen(
                                svc: widget.svc,
                                routine: widget.routine,
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

class _LastDoneMini extends StatelessWidget {
  final GymFirestoreService svc;
  final String routineId;
  final String dayId;
  const _LastDoneMini({
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
    final ref = svc.root
        .collection('routines')
        .doc(routineId)
        .collection('days')
        .doc(dayId);

    return StreamBuilder<DocumentSnapshot>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Text('Sin sesiones aún');
        }
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

        return Text(sameDay ? 'Hecho hoy' : 'Ultima vez: $lastLocal');
      },
    );
  }
}


