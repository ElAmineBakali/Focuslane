import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:focuslane/design/blocks/toast/app_toast.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';

import '../models/note_model.dart';
import '../services/note_firestore_service.dart';

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

  void markSaved({
    required Note savedNote,
    required String snapshot,
    required DateTime savedAt,
  }) {
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
  bool _loadingExisting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _editor = _NoteEditorEngine();
    _editor.attach(onContentMutated: _onDraftChanged);

    _titleCtrl.addListener(_onDraftChanged);

    _applyNoteToEditor(widget.note);

    if (widget.note == null && (widget.noteId ?? '').isNotEmpty) {
      _loadingExisting = true;
      _loadById(widget.noteId!);
    }
  }

  void _applyNoteToEditor(Note? note) {
    _contentState.hydrating = true;
    _contentState.applyLoadedNote(note);
    _titleCtrl.text = note?.title ?? '';

    try {
      if (note?.delta != null) {
        _editor.loadDocument(
          Document.fromJson(_normalizeDeltaForReadability(note!.delta!)),
        );
      } else {
        _editor.loadDocument(Document()..insert(0, note?.content ?? ''));
      }
    } catch (_) {
      _editor.loadDocument(Document()..insert(0, note?.content ?? ''));
    }

    _contentState.lastSavedSnapshot = _buildSnapshot();
    _contentState.hydrating = false;
  }

  List<dynamic> _normalizeDeltaForReadability(List<dynamic> delta) {
    return delta
        .map((op) {
          if (op is! Map) return op;
          final opMap = Map<String, dynamic>.from(op);
          final attrs = opMap['attributes'];
          if (attrs is! Map) return op;
          final sanitized = Map<String, dynamic>.from(attrs);
          sanitized.remove('color');
          sanitized.remove('background');
          if (sanitized.isEmpty) {
            final next = Map<String, dynamic>.from(opMap);
            next.remove('attributes');
            return next;
          }
          final next = Map<String, dynamic>.from(opMap);
          next['attributes'] = sanitized;
          return next;
        })
        .toList(growable: false);
  }

  Future<void> _loadById(String id) async {
    final note = await NoteFirestoreService.getById(id);
    if (!mounted) return;
    if (note != null) {
      setState(() {
        _applyNoteToEditor(note);
        _loadingExisting = false;
      });
      return;
    }
    setState(() => _loadingExisting = false);
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
          content: const Text(
            'Esta acción no se puede deshacer. ¿Eliminar esta nota?',
          ),
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
    return DateFormat('dd MMM yyyy · HH:mm', 'es_ES').format(value);
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
      if (_contentState.note == null ||
          (_contentState.note?.id.isEmpty ?? true)) {
        final newId = await NoteFirestoreService.add(note);
        if (newId == null) {
          throw StateError('Could not create note without authenticated user');
        }
        saved = note.copyWith(id: newId);
      } else {
        await NoteFirestoreService.update(note);
      }

      _contentState.markSaved(
        savedNote: saved,
        snapshot: snapshot,
        savedAt: now,
      );
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
          title: const Text('Nota'),
          actions: [
            IconButton(
              icon: Icon(
                _contentState.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
              ),
              onPressed: () {
                setState(
                  () => _contentState.isPinned = !_contentState.isPinned,
                );
                _onDraftChanged();
              },
              tooltip: 'Fijar',
            ),
            IconButton(
              icon: Icon(
                _focusMode ? Icons.visibility : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _focusMode = !_focusMode),
              tooltip: 'Modo enfoque',
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
          bottom: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = isMobile ? 12.0 : 20.0;

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 8),
                    child: Column(
                      children: [
                        if (!_focusMode)
                          _NoteEditorHeader(
                            titleController: _titleCtrl,
                            editedAtLabel:
                                _editedAt == null
                                    ? 'Sin guardar'
                                    : 'Editado: ${_formatEditedAt(_editedAt!)}',
                            savingLabel:
                                _saving
                                    ? 'Guardando...'
                                    : 'Autoguardado activo',
                            isSaving: _saving,
                            onSave:
                                () => _persist(
                                  popAfterSave: true,
                                  showError: true,
                                ),
                            onDelete: _confirmDeleteNote,
                          ),
                        if (!_focusMode) const SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isMobile ? 10 : 14),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.58,
                                ),
                              ),
                              boxShadow: FocuslaneTokens.cardShadow(context),
                            ),
                            child:
                                _loadingExisting
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : DefaultTextStyle.merge(
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: 16,
                                      ),
                                      child: QuillEditor.basic(
                                        controller: _editor.quillController,
                                        focusNode: _editor.focusNode,
                                        config: QuillEditorConfig(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 8 : 12,
                                            vertical: isMobile ? 10 : 14,
                                          ),
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                        if (!_focusMode && !_loadingExisting) ...[
                          const SizedBox(height: 8),
                          _NoteToolbarCard(controller: _editor.quillController),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NoteEditorHeader extends StatelessWidget {
  const _NoteEditorHeader({
    required this.titleController,
    required this.editedAtLabel,
    required this.savingLabel,
    required this.isSaving,
    required this.onSave,
    required this.onDelete,
  });

  final TextEditingController titleController;
  final String editedAtLabel;
  final String savingLabel;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FocusCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      backgroundColor: scheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 20 : 24,
                ),
                decoration: const InputDecoration(
                  hintText: 'Titulo',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(label: editedAtLabel, color: scheme.secondary),
                  FocusBadge(
                    label: savingLabel,
                    color: isSaving ? scheme.primary : scheme.tertiary,
                  ),
                ],
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FocusSecondaryButton(
                label: 'Eliminar',
                icon: Icons.delete_outline_rounded,
                onPressed: onDelete,
              ),
              FocusPrimaryButton(
                label: 'Guardar',
                icon: Icons.save_rounded,
                isLoading: isSaving,
                onPressed: onSave,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleBlock, const SizedBox(height: 14), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _NoteToolbarCard extends StatelessWidget {
  const _NoteToolbarCard({required this.controller});

  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.56),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _MobileNoteToolbar(controller: controller),
      ),
    );
  }
}

class _MobileNoteToolbar extends StatelessWidget {
  const _MobileNoteToolbar({required this.controller});

  final QuillController controller;

  bool _hasAttr(String key) {
    return controller.getSelectionStyle().attributes.containsKey(key);
  }

  void _toggle(Attribute attribute) {
    final key = attribute.key;
    if (_hasAttr(key)) {
      controller.formatSelection(Attribute.clone(attribute, null));
      return;
    }
    controller.formatSelection(attribute);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Negrita',
          onPressed: () => _toggle(Attribute.bold),
          icon: const Icon(Icons.format_bold),
        ),
        IconButton(
          tooltip: 'Cursiva',
          onPressed: () => _toggle(Attribute.italic),
          icon: const Icon(Icons.format_italic),
        ),
        IconButton(
          tooltip: 'Subrayado',
          onPressed: () => _toggle(Attribute.underline),
          icon: const Icon(Icons.format_underlined),
        ),
        IconButton(
          tooltip: 'Tachado',
          onPressed: () => _toggle(Attribute.strikeThrough),
          icon: const Icon(Icons.format_strikethrough),
        ),
        IconButton(
          tooltip: 'Lista',
          onPressed: () => _toggle(Attribute.ul),
          icon: const Icon(Icons.format_list_bulleted),
        ),
        IconButton(
          tooltip: 'Lista numerada',
          onPressed: () => _toggle(Attribute.ol),
          icon: const Icon(Icons.format_list_numbered),
        ),
        IconButton(
          tooltip: 'Cita',
          onPressed: () => _toggle(Attribute.blockQuote),
          icon: const Icon(Icons.format_quote),
        ),
        IconButton(
          tooltip: 'Limpiar formato',
          onPressed: () {
            controller.formatSelection(Attribute.clone(Attribute.bold, null));
            controller.formatSelection(Attribute.clone(Attribute.italic, null));
            controller.formatSelection(
              Attribute.clone(Attribute.underline, null),
            );
            controller.formatSelection(
              Attribute.clone(Attribute.strikeThrough, null),
            );
            controller.formatSelection(Attribute.clone(Attribute.ul, null));
            controller.formatSelection(Attribute.clone(Attribute.ol, null));
            controller.formatSelection(
              Attribute.clone(Attribute.blockQuote, null),
            );
          },
          icon: const Icon(Icons.format_clear),
        ),
      ],
    );
  }
}
