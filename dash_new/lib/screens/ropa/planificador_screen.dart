import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/ropa/services/plan_outfit_firestore_service.dart';
import '../../screens/ropa/services/outfit_firestore_service.dart';
import 'models/outfit_model.dart';
import 'models/plan_outfit_model.dart';

class PlanificadorScreen extends StatelessWidget {
  const PlanificadorScreen({super.key});

  // --- helpers ---
  String? _imgUrl(Outfit? o) {
    final p = o?.portada;
    if (p == null) return null;
    // soporta distintas claves sin romper compat
    return p['mediumUrl'] ??
        p['thumbUrl'] ??
        p['url'] ??
        p['image'] ??
        p['img'];
  }

  String _estadoLabel(EstadoPlan e) => switch (e) {
    EstadoPlan.planificado => 'Planificado',
    EstadoPlan.usado => 'Usado',
    EstadoPlan.saltado => 'Saltado',
  };

  Color _estadoColor(BuildContext context, EstadoPlan e) => switch (e) {
    EstadoPlan.planificado => Theme.of(context).colorScheme.primaryContainer,
    EstadoPlan.usado => Colors.green.withOpacity(.18),
    EstadoPlan.saltado => Colors.redAccent.withOpacity(.18),
  };

  // --- crear plan ---
  Future<void> _crearPlan(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final plans = PlanOutfitFirestoreService();
    final outfitsSvc = OutfitFirestoreService();

    DateTime fecha = DateTime.now();
    String? parte;
    String? outfitId;
    String nota = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Nuevo plan', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(
                      'Fecha: ${fecha.toLocal().toString().split(' ').first}',
                    ),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: fecha,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => fecha = d);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: parte,
                    decoration: const InputDecoration(
                      labelText: 'Parte del día (opcional)',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'mañana', child: Text('Mañana')),
                      DropdownMenuItem(value: 'tarde', child: Text('Tarde')),
                      DropdownMenuItem(value: 'noche', child: Text('Noche')),
                    ],
                    onChanged: (v) => setState(() => parte = v),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Outfit>>(
                    stream: outfitsSvc.outfitsStream(uid),
                    builder: (_, s) {
                      final data = s.data ?? const <Outfit>[];
                      if (data.isEmpty) {
                        return const ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('No tienes outfits aún'),
                          subtitle: Text('Crea uno para poder planificarlo'),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: outfitId,
                        decoration: const InputDecoration(labelText: 'Outfit'),
                        items:
                            data.map((o) {
                              final u = _imgUrl(o);
                              return DropdownMenuItem(
                                value: o.id,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child:
                                            u != null
                                                ? Image.network(
                                                  u,
                                                  fit: BoxFit.cover,
                                                )
                                                : Container(
                                                  color:
                                                      Theme.of(ctx)
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                  child: const Icon(
                                                    Icons.checkroom,
                                                    size: 18,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        o.nombre.isEmpty
                                            ? '(Sin nombre)'
                                            : o.nombre,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (v) => setState(() => outfitId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                    ),
                    onChanged: (v) => nota = v,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          if (outfitId == null) return;
                          final plan = PlanOutfit(
                            id: '',
                            fecha: fecha,
                            parteDelDia: parte,
                            outfitId: outfitId!,
                            estado: EstadoPlan.planificado,
                            nota: nota,
                          );
                          await plans.addPlan(uid, plan);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // --- editar plan (estado/nota) ---
  Future<void> _editarPlanSheet(
    BuildContext context, {
    required PlanOutfit plan,
    required Outfit? outfit,
    required Future<void> Function(PlanOutfit updated) onSave,
  }) async {
    EstadoPlan estado = plan.estado;
    String nota = plan.nota;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Plan • ${outfit?.nombre ?? 'Outfit'}',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<EstadoPlan>(
                  initialValue: estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items:
                      EstadoPlan.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(_estadoLabel(e)),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => estado = v ?? estado,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: nota),
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Nota'),
                  onChanged: (v) => nota = v,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final updated = PlanOutfit(
                          id: plan.id,
                          fecha: plan.fecha,
                          parteDelDia: plan.parteDelDia,
                          outfitId: plan.outfitId,
                          estado: estado,
                          nota: nota,
                        );
                        await onSave(updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final planSvc = PlanOutfitFirestoreService();
    final outfitsSvc = OutfitFirestoreService();

    final inicio = DateTime.now().subtract(const Duration(days: 7));
    final fin = DateTime.now().add(const Duration(days: 30));

    return Scaffold(
      appBar: AppBar(title: const Text("Planificador de Outfits")),
      body: StreamBuilder<List<Outfit>>(
        stream: outfitsSvc.outfitsStream(uid),
        builder: (context, outfitsSnap) {
          final outfits = outfitsSnap.data ?? const <Outfit>[];
          // mapa para resolver outfit de cada plan
          final byId = {for (final o in outfits) o.id: o};

          return StreamBuilder<List<PlanOutfit>>(
            stream: planSvc.planesPorRango(uid, inicio, fin),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final planes = snapshot.data!;
              if (planes.isEmpty) {
                return const Center(child: Text("No hay outfits planificados"));
              }

              planes.sort((a, b) => a.fecha.compareTo(b.fecha));

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: planes.length,
                itemBuilder: (context, i) {
                  final plan = planes[i];
                  final outfit = byId[plan.outfitId];
                  final img = _imgUrl(outfit);

                  return Card(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child:
                              img != null
                                  ? Image.network(img, fit: BoxFit.cover)
                                  : Container(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.checkroom),
                                  ),
                        ),
                      ),
                      title: Text(
                        outfit?.nombre.isNotEmpty == true
                            ? outfit!.nombre
                            : (outfit == null
                                ? '(Outfit eliminado)'
                                : '(Sin nombre)'),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${plan.fecha.toLocal()}".split(' ')[0] +
                                (plan.parteDelDia != null
                                    ? ' • ${plan.parteDelDia}'
                                    : ''),
                          ),
                          if (plan.nota.isNotEmpty)
                            Text(
                              plan.nota,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _estadoColor(context, plan.estado),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _estadoLabel(plan.estado),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 6),
                          PopupMenuButton<String>(
                            tooltip: 'Acciones',
                            onSelected: (v) async {
                              if (v == 'edit') {
                                await _editarPlanSheet(
                                  context,
                                  plan: plan,
                                  outfit: outfit,
                                  onSave:
                                      (upd) async =>
                                          planSvc.updatePlan(uid, upd),
                                );
                              } else if (v == 'del') {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (_) => AlertDialog(
                                        title: const Text('Eliminar plan'),
                                        content: Text(
                                          '¿Eliminar el plan del ${plan.fecha.toLocal().toString().split(' ').first}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                );
                                if (ok == true) {
                                  await planSvc.deletePlan(uid, plan.id);
                                }
                              }
                            },
                            itemBuilder:
                                (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'del',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                          ),
                        ],
                      ),
                      onTap:
                          () => _editarPlanSheet(
                            context,
                            plan: plan,
                            outfit: outfit,
                            onSave: (upd) async => planSvc.updatePlan(uid, upd),
                          ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _crearPlan(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}



