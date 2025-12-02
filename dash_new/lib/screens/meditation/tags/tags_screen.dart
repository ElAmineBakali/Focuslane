// lib/screens/meditation/tags/tags_screen.dart
import 'package:flutter/material.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});
  static const route = '/meditation/tags';

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final _name = TextEditingController();
  final _color = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SimpleTag>>(
              stream: MeditationFirestoreService.I.watchTags(),
              builder: (context, s) {
                final data = s.data ?? [];
                if (s.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (data.isEmpty) return const Center(child: Text('Sin tags'));
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    0,
                    0,
                    MediaQuery.of(context).viewPadding.bottom + 96,
                  ),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = data[i];
                    return ListTile(
                      leading: const Icon(Icons.tag_outlined),
                      title: Text(t.name),
                      subtitle:
                          t.color != null ? Text('Color: ${t.color}') : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed:
                            () => MeditationFirestoreService.I.deleteTag(t.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12 + MediaQuery.of(context).viewPadding.bottom,
            ),
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
                    await MeditationFirestoreService.I.addTag(
                      SimpleTag(
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
