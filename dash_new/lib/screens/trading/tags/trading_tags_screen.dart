import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';

class TradingTagsScreen extends StatefulWidget {
  const TradingTagsScreen({super.key});
  static const route = '/trading/tags';

  @override
  State<TradingTagsScreen> createState() => _TradingTagsScreenState();
}

class _TradingTagsScreenState extends State<TradingTagsScreen> {
  final _name = TextEditingController();
  final _color = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: const Text('Tags de trading')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<TradingTag>>(
              stream: svc.watchTags(),
              builder: (_, s) {
                final data = s.data ?? [];
                if (s.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (data.isEmpty) return const Center(child: Text('Sin tags'));
                return ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = data[i];
                    return ListTile(
                      leading: const Icon(Icons.tag),
                      title: Text(t.name),
                      subtitle:
                          t.color != null ? Text('Color: ${t.color}') : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => svc.deleteTag(t.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _color,
                    decoration: const InputDecoration(
                      labelText: 'Color (opcional)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    if (_name.text.trim().isEmpty) return;
                    await svc.addTag(
                      TradingTag(
                        id: '',
                        name: _name.text.trim(),
                        color:
                            _color.text.trim().isEmpty
                                ? null
                                : _color.text.trim(),
                      ),
                    );
                    _name.clear();
                    _color.clear();
                  },
                  child: const Text('Añadir'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
