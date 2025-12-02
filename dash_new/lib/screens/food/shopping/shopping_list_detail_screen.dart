import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  final String listId;
  const ShoppingListDetailScreen({super.key, required this.svc, required this.listId});

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista'),
        actions: [
          IconButton(
            tooltip: 'Añadir item',
            icon: const Icon(Icons.add),
            onPressed: _addItemDialog,
          ),
        ],
      ),
      body: TaskFormTheme(
        child: StreamBuilder<List<ShoppingList>>(
        stream: widget.svc.streamShoppingLists(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!.firstWhere(
            (l) => l.id == widget.listId,
            orElse: () => ShoppingList(
              id: widget.listId,
              name: 'Lista',
              scope: ShoppingScope.custom,
              isDefault: false,
              items: const [],
              createdAt: DateTime.now(),
            ),
          );
          final total = list.items.fold<double>(0, (a, it) => a + (it.total ?? 0));
          return ListView(
            padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
            children: [
              ListTile(
                title: Text(list.name, style: Theme.of(context).textTheme.titleLarge),
                subtitle: Text('${list.scope.name} • ${list.items.length} items'),
                trailing: Text(total > 0 ? 'Total: ${total.toStringAsFixed(2)}' : ''),
              ),
              const SizedBox(height: 8),
              if (list.items.isEmpty) const Center(child: Text('Añade productos con +')),
              ...list.items.asMap().entries.map((e) {
                final i = e.value;
                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: i.checked,
                      onChanged: (v) => widget.svc.toggleChecked(list.id, e.key, v ?? false),
                    ),
                    title: Text(i.name),
                    subtitle: Text(
                      '${i.qty.toStringAsFixed(0)} ${i.unit.name}'
                      '${i.pricePerUnit != null ? ' • ${i.pricePerUnit} €/u' : ''}'
                      '${i.total != null ? ' • total ${i.total}' : ''}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') await _editItemDialog(e.key, i);
                        if (v == 'del') await widget.svc.removeShoppingItem(list.id, e.key);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'del', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
     )
    );
  }

  Future<void> _addItemDialog() async {
    final name = TextEditingController();
    final qty = TextEditingController(text: '1');
    final ppu = TextEditingController();
    UnitKind unit = UnitKind.unit;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Añadir producto'),
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
            TextField(controller: ppu, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio por unidad (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Añadir')),
        ],
      ),
    );
    if (ok == true) {
      final q = double.tryParse(qty.text) ?? 1;
      final price = double.tryParse(ppu.text);
      final item = ShoppingListItem(
        id: '',
        name: name.text.trim().isEmpty ? 'Producto' : name.text.trim(),
        qty: q,
        unit: unit,
        checked: false,
        pricePerUnit: price,
        total: (price != null) ? price * q : null,
      );
      await widget.svc.upsertShoppingItem(widget.listId, item: item);
    }
  }

  Future<void> _editItemDialog(int index, ShoppingListItem i) async {
    final name = TextEditingController(text: i.name);
    final qty = TextEditingController(text: i.qty.toString());
    final ppu = TextEditingController(text: i.pricePerUnit?.toString() ?? '');
    UnitKind unit = i.unit;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar producto'),
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
            TextField(controller: ppu, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio por unidad (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok == true) {
      final q = double.tryParse(qty.text) ?? i.qty;
      final price = double.tryParse(ppu.text);
      final updated = ShoppingListItem(
        id: '',
        foodId: i.foodId,
        name: name.text.trim().isEmpty ? i.name : name.text.trim(),
        qty: q,
        unit: unit,
        checked: i.checked,
        pricePerUnit: price,
        total: (price != null) ? price * q : null,
        tags: i.tags,
        notes: i.notes,
      );
      await widget.svc.upsertShoppingItem(widget.listId, itemId: index.toString(), item: updated);
    }
  }

  // ignore: unused_element
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
