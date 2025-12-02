import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import 'food_edit_sheet.dart';

class FoodsListScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  const FoodsListScreen({super.key, required this.svc});

  @override
  State<FoodsListScreen> createState() => _FoodsListScreenState();
}

class _FoodsListScreenState extends State<FoodsListScreen> {
  String _q = '';
  bool _suppsOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alimentos & Suplementos'),
        actions: [
          IconButton(
            tooltip: 'Nuevo',
            icon: const Icon(Icons.add),
            onPressed:
                () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => FoodEditSheet(svc: widget.svc),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _q = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Sólo suplementos'),
                  selected: _suppsOnly,
                  onSelected: (v) => setState(() => _suppsOnly = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Food>>(
              stream: widget.svc.streamFoods(
                query: _q,
                supplementsOnly: _suppsOnly,
              ),
              builder: (context, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final list = snap.data!;
                if (list.isEmpty)
                  return const Center(child: Text('Sin alimentos aún'));
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final f = list[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.fastfood,
                          color:
                              f.color ?? Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(f.name),
                        subtitle: Text(
                          '${f.kcal.toStringAsFixed(0)} kcal por ${f.unitSize.toStringAsFixed(0)} ${f.perUnit.name}'
                          '${f.isSupplement ? ' • Suplemento' : ''}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder:
                                    (_) => FoodEditSheet(
                                      svc: widget.svc,
                                      initial: f,
                                    ),
                              );
                            }
                            if (v == 'del') {
                              final ok = await _confirm(
                                context,
                                'Eliminar',
                                '¿Eliminar "${f.name}"?',
                              );
                              if (ok) await widget.svc.deleteFood(f.id);
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
