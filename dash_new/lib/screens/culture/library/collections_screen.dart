import 'package:flutter/material.dart';
import '../../../screens/culture/services/culture_firestore_service.dart';
import '../models/culture_models.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});
  static const route = '/culture/collections';

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colecciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await svc.addCollection(
                CultureCollection(id: '', name: 'Nueva colección'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CultureCollection>>(
        stream: svc.watchCollections(),
        builder: (_, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) {
            return const Center(child: Text('Crea tu primera colección'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = data[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.collections_bookmark),
                  title: Text(c.name),
                  subtitle: Text(
                    '${c.items.length} elementos'
                    '${c.targetDate != null ? " • objetivo ${c.targetDate!.toLocal().toString().split(" ").first}" : ""}',
                  ),
                  onTap: () => _editCollection(context, svc, c),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _editCollection(
    BuildContext context,
    CultureFirestoreService svc,
    CultureCollection c,
  ) {
    final name = TextEditingController(text: c.name);
    final desc = TextEditingController(text: c.description ?? '');
    DateTime? target = c.targetDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: StatefulBuilder(
                builder:
                    (ctx, setStateSB) => SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Editar colección',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),

                          TextField(
                            controller: name,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                            ),
                          ),
                          TextField(
                            controller: desc,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                            ),
                          ),
                          const SizedBox(height: 8),

                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event),
                            title: Text(
                              'Fecha objetivo: ${target != null ? target!.toLocal().toString().split(" ").first : "–"}',
                            ),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: target ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) setStateSB(() => target = d);
                            },
                          ),

                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () async {
                                  await svc.updateCollection(
                                    CultureCollection(
                                      id: c.id,
                                      name:
                                          name.text.trim().isEmpty
                                              ? c.name
                                              : name.text.trim(),
                                      description:
                                          desc.text.trim().isEmpty
                                              ? null
                                              : desc.text.trim(),
                                      targetDate: target,
                                      items: c.items,
                                    ),
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                },
                                child: const Text('Guardar'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar'),
                            onPressed: () async {
                              await svc.deleteCollection(c.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
    );
  }
}



