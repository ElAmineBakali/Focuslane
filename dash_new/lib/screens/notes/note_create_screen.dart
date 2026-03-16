import 'package:flutter/material.dart';
import 'note_model.dart';
import 'note_firestore_service.dart';

class NoteCreateScreen extends StatefulWidget {
  const NoteCreateScreen({super.key});

  @override
  State<NoteCreateScreen> createState() => _NoteCreateScreenState();
}

class _NoteCreateScreenState extends State<NoteCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote({bool popAfter = true}) async {
    final now = DateTime.now();
    final note = Note(
      id: '',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: now,
      updatedAt: now,
      lastEditedAt: now,
      order: 0,
    );
    await NoteFirestoreService.add(note);
    if (popAfter && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva nota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveNote(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            style: theme.textTheme.bodyLarge,
            minLines: 8,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: 'Contenido',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _saveNote(),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
