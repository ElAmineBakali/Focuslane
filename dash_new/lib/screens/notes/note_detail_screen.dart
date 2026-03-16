import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'note_model.dart';
import 'note_firestore_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _lastEditedAt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _lastEditedAt = widget.note.lastEditedAt;
  }

  Future<void> _updateNote({bool popAfter = true}) async {
    final now = DateTime.now();
    final updatedNote = widget.note.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      updatedAt: now,
      lastEditedAt: now,
    );
    await NoteFirestoreService.update(updatedNote);
    if (mounted) {
      setState(() => _lastEditedAt = now);
    }
    if (popAfter && mounted) Navigator.pop(context);
  }

  Future<void> _deleteNote() async {
    await NoteFirestoreService.delete(widget.note.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar nota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteNote,
            tooltip: 'Eliminar',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _updateNote(),
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(
            'Edited: ${DateFormat('dd MMM yyyy · HH:mm').format(_lastEditedAt)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
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
                onPressed: () => _updateNote(),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
