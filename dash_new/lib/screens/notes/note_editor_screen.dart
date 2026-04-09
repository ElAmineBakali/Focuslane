import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:focuslane/design/blocks/toast/app_toast.dart';

import 'note_firestore_service.dart';
import 'note_model.dart';

class _NoteEditorContentState {
  Note? note;
  bool isPinned = false;
  bool hydrating = false;
  String lastSavedSnapshot = '';
  DateTime? lastSavedAt;

  DateTime? get editedAt => note?.lastEditedAt ?? lastSavedAt;

  void applyLoadedNote(Note? value) {
    note = value;
    isPinned = value?.isPinned ?? false;
    lastSavedAt = value?.lastEditedAt ?? value?.updatedAt;
  }

  void markSaved({required Note savedNote, required String snapshot, required DateTime savedAt}) {
    note = savedNote;
    lastSavedSnapshot = snapshot;
    lastSavedAt = savedAt;
  }
}

class _NoteEditorEngine {
  _NoteEditorEngine();

  final QuillController quillController = QuillController.basic();
  final FocusNode focusNode = FocusNode();

  StreamSubscription? _docChangesSub;
  VoidCallback? _onContentMutated;

  void attach({required VoidCallback onContentMutated}) {
    _onContentMutated = onContentMutated;
    _bindDocumentChangesListener();
  }

  void loadDocument(Document document) {
    quillController.document = document;
    _bindDocumentChangesListener();
  }

  void dispose() {
    _docChangesSub?.cancel();
    quillController.dispose();
    focusNode.dispose();
  }

  void _bindDocumentChangesListener() {
    _docChangesSub?.cancel();
    _docChangesSub = quillController.document.changes.listen((_) {
      _onContentMutated?.call();
    });
  }
}

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String? noteId;

  const NoteEditorScreen({super.key, this.note, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  static const Duration _autoSaveDelay = Duration(milliseconds: 900);

  late final TextEditingController _titleCtrl;
  late final _NoteEditorEngine _editor;
  final _NoteEditorContentState _contentState = _NoteEditorContentState();

  Timer? _autoSaveDebounce;

  bool _focusMode = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _editor = _NoteEditorEngine();
    _editor.attach(onContentMutated: _onDraftChanged);

    _titleCtrl.addListener(_onDraftChanged);

    _applyNoteToEditor(widget.note);

    if (widget.note == null && (widget.noteId ?? '').isNotEmpty) {
      _loadById(widget.noteId!);
    }
  }

  void _applyNoteToEditor(Note? note) {
    _contentState.hydrating = true;
    _contentState.applyLoadedNote(note);
    _titleCtrl.text = note?.title ?? '';

    try {
      if (note?.delta != null) {
        _editor.loadDocument(Document.fromJson(note!.delta!));
      } else {
        _editor.loadDocument(Document()..insert(0, note?.content ?? ''));
      }
    } catch (_) {
      _editor.loadDocument(Document()..insert(0, note?.content ?? ''));
    }

    _contentState.lastSavedSnapshot = _buildSnapshot();
    _contentState.hydrating = false;
  }

  Future<void> _loadById(String id) async {
    final note = await NoteFirestoreService.getById(id);
    if (note != null && mounted) {
      setState(() {
        _applyNoteToEditor(note);
      });
    }
  }

  void _onDraftChanged() {
    if (_contentState.hydrating) return;
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(_autoSaveDelay, () {
      _persist(popAfterSave: false, showError: false);
    });
  }

  Future<void> _confirmDeleteNote() async {
    final noteId = _contentState.note?.id ?? '';
    if (noteId.isEmpty) {
      if (mounted) {
        AppToast.error(context, 'Primero guarda la nota para poder borrarla');
      }
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar nota'),
          content: const Text('Esta accion no se puede deshacer. Â¿Eliminar esta nota?'),
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
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await NoteFirestoreService.delete(noteId);
      if (!mounted) return;
      AppToast.success(context, 'Nota eliminada');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Error eliminando la nota');
      }
    }
  }

  String _buildSnapshot() {
    final payload = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'isPinned': _contentState.isPinned,
      'delta': _editor.quillController.document.toDelta().toJson(),
    };
    return jsonEncode(payload);
  }

  DateTime? get _editedAt => _contentState.editedAt;

  String _formatEditedAt(DateTime value) {
    return DateFormat('dd MMM yyyy â€¢ HH:mm').format(value);
  }

  Future<void> _persist({
    required bool popAfterSave,
    bool showError = true,
  }) async {
    final snapshot = _buildSnapshot();
    if (snapshot == _contentState.lastSavedSnapshot) {
      if (popAfterSave && mounted) {
        Navigator.pop(context);
      }
      return;
    }

    if (_saving) return;
    if (mounted) setState(() => _saving = true);

    final now = DateTime.now();
    final note = Note(
      id: _contentState.note?.id ?? '',
      title: _titleCtrl.text.trim(),
      content: _editor.quillController.document.toPlainText().trimRight(),
      spans: _contentState.note?.spans ?? const [],
      delta: _editor.quillController.document.toDelta().toJson(),
      tags: _contentState.note?.tags ?? const [],
      isPinned: _contentState.isPinned,
      colorHex: _contentState.note?.colorHex,
      coverUrl: _contentState.note?.coverUrl,
      style: _contentState.note?.style,
      attachments: _contentState.note?.attachments ?? const [],
      createdAt: _contentState.note?.createdAt ?? now,
      updatedAt: now,
      lastEditedAt: now,
      date: _contentState.note?.date,
      linkedTaskIds: _contentState.note?.linkedTaskIds ?? const [],
      order: _contentState.note?.order ?? 0,
    );

    try {
      Note saved = note;
      if (_contentState.note == null || (_contentState.note?.id.isEmpty ?? true)) {
        final newId = await NoteFirestoreService.add(note);
        if (newId == null) {
          throw StateError('Could not create note without authenticated user');
        }
        saved = note.copyWith(id: newId);
      } else {
        await NoteFirestoreService.update(note);
      }

      _contentState.markSaved(savedNote: saved, snapshot: snapshot, savedAt: now);
      if (mounted) {
        setState(() {});
      }

      if (popAfterSave && mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted && showError) {
        AppToast.error(context, 'Error guardando la nota');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    _titleCtrl.removeListener(_onDraftChanged);
    _titleCtrl.dispose();
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _autoSaveDebounce?.cancel();
        _persist(popAfterSave: false, showError: false);
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: scheme.surfaceContainerLowest,
          title: const Text('Editar nota'),
          actions: [
            IconButton(
              icon: Icon(
                _contentState.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              onPressed: () {
                setState(() => _contentState.isPinned = !_contentState.isPinned);
                _onDraftChanged();
              },
              tooltip: 'Fijar',
            ),
            IconButton(
              icon: Icon(_focusMode ? Icons.visibility : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _focusMode = !_focusMode),
              tooltip: 'Modo enfoque',
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _persist(popAfterSave: true, showError: true),
              tooltip: 'Guardar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDeleteNote,
              tooltip: 'Eliminar nota',
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (!_focusMode)
                Container(
                  margin: EdgeInsets.fromLTRB(isMobile ? 12 : 18, 4, isMobile ? 12 : 18, 10),
                  padding: EdgeInsets.fromLTRB(isMobile ? 12 : 16, isMobile ? 10 : 14, isMobile ? 12 : 16, 12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outlineVariant.withOpacity(0.55)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleCtrl,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 20 : 24,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Titulo',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _editedAt == null
                                  ? 'Sin guardar'
                                  : 'Editado: ${_formatEditedAt(_editedAt!)}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            _saving ? 'Guardando...' : 'Autoguardado',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (!_focusMode)
                Container(
                  margin: EdgeInsets.fromLTRB(isMobile ? 12 : 18, 0, isMobile ? 12 : 18, 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      QuillSimpleToolbar(
                        controller: _editor.quillController,
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
                          showBackgroundColorButton: false,
                          showColorButton: false,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(isMobile ? 12 : 18, 0, isMobile ? 12 : 18, isMobile ? 10 : 12),
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: scheme.outlineVariant.withOpacity(0.55)),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: QuillEditor.basic(
                    controller: _editor.quillController,
                    focusNode: _editor.focusNode,
                    config: QuillEditorConfig(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 8,
                        vertical: isMobile ? 10 : 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

