import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'note_model.dart';
import 'note_firestore_service.dart';
import 'package:mi_dashboard_personal/blocks/toast/app_toast.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String? noteId;
  const NoteEditorScreen({super.key, this.note, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleCtrl;
  final _quillController = QuillController.basic();
  Note? _current;
  bool _focusMode = false;
  bool _isPinned = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _current = widget.note;
    _titleCtrl = TextEditingController(text: _current?.title ?? '');
    if (_current?.delta != null) {
      try {
        _quillController.document = Document.fromJson(_current!.delta!);
      } catch (_) {
        _quillController.document = Document()..insert(0, _current?.content ?? '');
      }
    } else {
      _quillController.document = Document()..insert(0, _current?.content ?? '');
    }
    _isPinned = _current?.isPinned ?? false;
    if (_current == null && (widget.noteId ?? '').isNotEmpty) {
      _loadById(widget.noteId!);
    }
  }

  Future<void> _loadById(String id) async {
    final n = await NoteFirestoreService.getById(id);
    if (n != null && mounted) {
      setState(() {
        _current = n;
        _titleCtrl.text = n.title;
        try {
          if (n.delta != null) {
            _quillController.document = Document.fromJson(n.delta!);
          } else {
            _quillController.document = Document()..insert(0, n.content);
          }
        } catch (_) {
          _quillController.document = Document()..insert(0, n.content);
        }
        _isPinned = n.isPinned;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final deltaJson = _quillController.document.toDelta().toJson();
    final plain = _quillController.document.toPlainText();
    final note = Note(
      id: _current?.id ?? '',
      title: _titleCtrl.text.trim(),
      content: plain,
      spans: _current?.spans ?? const [],
      delta: deltaJson,
      tags: _current?.tags ?? const [],
      isPinned: _isPinned,
      colorHex: _current?.colorHex,
      coverUrl: null,
      style: _current?.style,
      attachments: _current?.attachments ?? const [],
      createdAt: _current?.createdAt ?? now,
      updatedAt: now,
      date: _current?.date,
      linkedTaskIds: _current?.linkedTaskIds ?? const [],
      order: _current?.order ?? 0,
    );

    try {
      if (_current == null || (_current?.id.isEmpty ?? true)) {
        final newId = await NoteFirestoreService.add(note);
        if (newId != null) {
          setState(() => _current = note.copyWith(id: newId));
        }
      } else {
        await NoteFirestoreService.update(note);
        setState(() => _current = note);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error guardando la nota');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: _focusMode ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _focusMode = false),
          tooltip: 'Salir de modo enfoque',
        ),
      ) : AppBar(
        title: Text('Nota', style: TextStyle(fontSize: isMobile ? 18 : 20)),
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: isMobile ? 22 : 24),
            onPressed: () => setState(() => _isPinned = !_isPinned),
            tooltip: 'Fijar',
          ),
          IconButton(
            icon: Icon(Icons.visibility_off_outlined, size: isMobile ? 22 : 24),
            onPressed: () => setState(() => _focusMode = true),
            tooltip: 'Modo enfoque',
          ),
          IconButton(
            icon: Icon(Icons.check, size: isMobile ? 22 : 24),
            onPressed: _save,
            tooltip: 'Guardar',
          ),
          if (_saving)
            Padding(
              padding: EdgeInsets.only(right: isMobile ? 8 : 12),
              child: SizedBox(width: isMobile ? 18 : 20, height: isMobile ? 18 : 20, child: const CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_focusMode)
            Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, isMobile ? 12 : 16, isMobile ? 16 : 20, 0),
              child: TextField(
                controller: _titleCtrl,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 20 : 24,
                ),
                decoration: InputDecoration(
                  hintText: 'Título',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: color.onSurfaceVariant),
                ),
              ),
            ),
          if (!_focusMode)
            QuillSimpleToolbar(
              controller: _quillController,
              config: QuillSimpleToolbarConfig(
                buttonOptions: QuillSimpleToolbarButtonOptions(
                  base: QuillToolbarBaseButtonOptions(
                    iconSize: isMobile ? 18 : 20,
                  ),
                ),
                showSubscript: false,
                showSuperscript: false,
                showFontFamily: false,
                showCodeBlock: false,
                showInlineCode: false,
                showLink: false,
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              child: QuillEditor.basic(
                controller: _quillController,
                config: QuillEditorConfig(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
