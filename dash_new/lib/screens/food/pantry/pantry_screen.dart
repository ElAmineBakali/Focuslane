import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

class PantryScreen extends StatelessWidget {
  final FoodFirestoreService svc;
  const PantryScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despensa'),
        actions: [
          IconButton(
            tooltip: 'Añadir',
            icon: const Icon(Icons.add),
            onPressed: () => _editItem(context, svc),
          ),
        ],
      ),
      body: StreamBuilder<List<PantryItem>>(
        stream: svc.streamPantry(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('Vacío. Añade productos con +'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final p = list[i];
              final low = (p.minQty != null && p.qty <= (p.minQty ?? 0));
              return Card(
                child: ListTile(
                  leading: Icon(low ? Icons.warning_amber : Icons.kitchen,
                      color: low ? Colors.amber : Theme.of(context).colorScheme.primary),
                  title: Text(p.name),
                  subtitle: Text('${p.qty.toStringAsFixed(0)} ${p.unit.name}${p.minQty != null ? ' • mínimo ${p.minQty}' : ''}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'consume') {
                        final q = await _promptNumber(context, 'Consumir cantidad');
                        if (q != null) await svc.consumePantry(p.id, q);
                      }
                      if (v == 'edit') {
                        await _editItem(context, svc, initial: p, id: p.id);
                      }
                      if (v == 'del') {
                        final ok = await _confirm(context, 'Eliminar', '¿Eliminar "${p.name}"?');
                        if (ok) await svc.deletePantry(p.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'consume', child: Text('Consumir…')),
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'del', child: Text('Eliminar')),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: list.length,
          );
        },
      ),
    );
  }

  Future<void> _editItem(BuildContext context, FoodFirestoreService svc, {PantryItem? initial, String? id}) async {
    final name = TextEditingController(text: initial?.name ?? '');
    final qty = TextEditingController(text: (initial?.qty ?? 1).toString());
    final minQty = TextEditingController(text: (initial?.minQty ?? '').toString());
    UnitKind unit = initial?.unit ?? UnitKind.unit;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(initial == null ? 'Añadir a despensa' : 'Editar despensa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad')),
            DropdownButton<UnitKind>(
              value: unit,
              items: const [
                DropdownMenuItem(value: UnitKind.unit, child: Text('unidad')),
                DropdownMenuItem(value: UnitKind.g, child: Text('g')),
                DropdownMenuItem(value: UnitKind.ml, child: Text('ml')),
              ],
              onChanged: (v) => unit = v ?? UnitKind.unit,
            ),
            TextField(controller: minQty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mínimo (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok == true) {
      final item = PantryItem(
        id: id ?? '',
        name: name.text.trim().isEmpty ? 'Producto' : name.text.trim(),
        qty: double.tryParse(qty.text) ?? 1,
        unit: unit,
        minQty: double.tryParse(minQty.text),
      );
      await svc.upsertPantry(item, id: id);
    }
  }

  Future<double?> _promptNumber(BuildContext context, String label) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: TextField(controller: c, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok == true) return double.tryParse(c.text);
    return null;
  }

  Future<bool> _confirm(BuildContext context, String title, String msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    return ok == true;
  }
}
