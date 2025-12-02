import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import 'shopping_list_detail_screen.dart';

class ShoppingListsScreen extends StatelessWidget {
  final FoodFirestoreService svc;
  const ShoppingListsScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas de compra'),
        actions: [
          IconButton(
            tooltip: 'Nueva lista',
            icon: const Icon(Icons.add),
            onPressed: () async {
              final nameCtrl = TextEditingController();
              bool makeDefault = false;
              ShoppingScope scope = ShoppingScope.custom;
              final ok = await showDialog<bool>(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('Nueva lista'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                            ),
                          ),
                          DropdownButton<ShoppingScope>(
                            value: scope,
                            items: const [
                              DropdownMenuItem(
                                value: ShoppingScope.custom,
                                child: Text('Custom'),
                              ),
                              DropdownMenuItem(
                                value: ShoppingScope.weekly,
                                child: Text('Semanal'),
                              ),
                              DropdownMenuItem(
                                value: ShoppingScope.biweekly,
                                child: Text('Quincenal'),
                              ),
                              DropdownMenuItem(
                                value: ShoppingScope.monthly,
                                child: Text('Mensual'),
                              ),
                            ],
                            onChanged: (v) => scope = v ?? ShoppingScope.custom,
                          ),
                          StatefulBuilder(
                            builder: (ctx, setState) {
                              return CheckboxListTile(
                                value: makeDefault,
                                onChanged:
                                    (v) => setState(
                                      () => makeDefault = v ?? false,
                                    ),
                                title: const Text('Marcar como predeterminada'),
                              );
                            },
                          ),
                        ],
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
                final id = await svc.createShoppingList(
                  nameCtrl.text.trim().isEmpty ? 'Lista' : nameCtrl.text.trim(),
                  scope: scope,
                  isDefault: makeDefault,
                );
                // ignore: use_build_context_synchronously
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ShoppingListDetailScreen(svc: svc, listId: id),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ShoppingList>>(
        stream: svc.streamShoppingLists(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final lists = snap.data!;
          if (lists.isEmpty)
            return const Center(child: Text('Crea tu primera lista con +'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final l = lists[i];
              final total = l.items.fold<double>(
                0,
                (a, it) => a + (it.total ?? 0),
              );
              return Card(
                child: ListTile(
                  leading: Icon(l.isDefault ? Icons.star : Icons.list),
                  title: Text(l.name),
                  subtitle: Text(
                    '${l.scope.name} • ${l.items.length} items'
                    '${total > 0 ? ' • Estimado: ${total.toStringAsFixed(2)}' : ''}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'default') await svc.setDefaultList(l.id);
                      if (v == 'delete') {
                        final ok = await _confirm(
                          context,
                          'Eliminar',
                          '¿Eliminar "${l.name}"?',
                        );
                        if (ok) await svc.deleteShoppingList(l.id);
                      }
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(
                            value: 'default',
                            child: Text('Marcar como predeterminada'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                  ),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ShoppingListDetailScreen(
                                svc: svc,
                                listId: l.id,
                              ),
                        ),
                      ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: lists.length,
          );
        },
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    return ok == true;
  }
}
