import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:mi_dashboard_personal/design/blocks/toast/app_toast.dart';

import 'note_firestore_service.dart';
import 'note_model.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String? noteId;
  const NoteEditorScreen({super.key, this.note, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  static const Duration _autoSaveDelay = Duration(milliseconds: 900);
  static const List<Color> _textColorPalette = <Color>[
    Colors.black87,
    Colors.blue,
    Colors.deepPurple,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.brown,
  ];

  late final TextEditingController _titleCtrl;
  final QuillController _quillController = QuillController.basic();

  StreamSubscription? _docChangesSub;
  Timer? _autoSaveDebounce;

  Note? _current;
  bool _focusMode = false;
  bool _isPinned = false;
  bool _saving = false;
  bool _hydratingEditor = false;

  String _lastSavedSnapshot = '';
  DateTime? _lastSavedAt;
  Color _currentTextColor = Colors.black87;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _titleCtrl.addListener(_onDraftChanged);
    _quillController.addListener(_onQuillControllerChanged);

    _applyNoteToEditor(widget.note);

    if (widget.note == null && (widget.noteId ?? '').isNotEmpty) {
      _loadById(widget.noteId!);
    }
  }

  void _applyNoteToEditor(Note? note) {
    _hydratingEditor = true;
    _current = note;
    _titleCtrl.text = note?.title ?? '';

    try {
      if (note?.delta != null) {
        _quillController.document = Document.fromJson(note!.delta!);
      } else {
        _quillController.document = Document()..insert(0, note?.content ?? '');
      }
    } catch (_) {
      _quillController.document = Document()..insert(0, note?.content ?? '');
    }

    _isPinned = note?.isPinned ?? false;
    _lastSavedAt = note?.lastEditedAt ?? note?.updatedAt;
    _bindDocumentChangesListener();
    _currentTextColor = _readColorFromSelection() ?? _currentTextColor;
    _applyCurrentTextColorToFutureInput(notifyDraftChange: false);
    _lastSavedSnapshot = _buildSnapshot();
    _hydratingEditor = false;
  }

  void _bindDocumentChangesListener() {
    _docChangesSub?.cancel();
    _docChangesSub = _quillController.document.changes.listen((_) {
      _onDraftChanged();
    });
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
    if (_hydratingEditor) return;
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(_autoSaveDelay, () {
      _persist(popAfterSave: false, showError: false);
    });
  }

  void _onQuillControllerChanged() {
    if (_hydratingEditor) return;
    final color = _readColorFromSelection();
    if (color != null &&
        color.toARGB32() != _currentTextColor.toARGB32() &&
        mounted) {
      setState(() => _currentTextColor = color);
    }
  }

  Color? _readColorFromSelection() {
    final attr =
        _quillController.getSelectionStyle().attributes[Attribute.color.key];
    final value = attr?.value;
    if (value is! String || value.isEmpty) return null;

    final clean = value.replaceAll('#', '').trim();
    try {
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _toQuillHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _applyCurrentTextColorToFutureInput({bool notifyDraftChange = true}) {
    final colorAttr = ColorAttribute(_toQuillHex(_currentTextColor));
    final mergedStyle = _quillController.toggledStyle.put(colorAttr);
    _quillController.forceToggledStyle(mergedStyle);
    if (notifyDraftChange) {
      _onDraftChanged();
    }
  }

  void _onSelectTextColor(Color color) {
    _quillController.formatSelection(ColorAttribute(_toQuillHex(color)));
    setState(() => _currentTextColor = color);
    _applyCurrentTextColorToFutureInput(notifyDraftChange: false);
    _onDraftChanged();
  }

  String _buildSnapshot() {
    final payload = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'isPinned': _isPinned,
      'delta': _quillController.document.toDelta().toJson(),
    };
    return jsonEncode(payload);
  }

  DateTime? get _editedAt => _current?.lastEditedAt ?? _lastSavedAt;

  String _formatEditedAt(DateTime value) {
    return DateFormat('dd MMM yyyy · HH:mm').format(value);
  }

  Future<void> _persist({
    required bool popAfterSave,
    bool showError = true,
  }) async {
    final snapshot = _buildSnapshot();
    if (snapshot == _lastSavedSnapshot) {
      if (popAfterSave && mounted) {
        Navigator.pop(context);
      }
      return;
    }

    if (_saving) return;
    if (mounted) setState(() => _saving = true);

    final now = DateTime.now();
    final note = Note(
      id: _current?.id ?? '',
      title: _titleCtrl.text.trim(),
      content: _quillController.document.toPlainText().trimRight(),
      spans: _current?.spans ?? const [],
      delta: _quillController.document.toDelta().toJson(),
      tags: _current?.tags ?? const [],
      isPinned: _isPinned,
      colorHex: _current?.colorHex,
      coverUrl: _current?.coverUrl,
      style: _current?.style,
      attachments: _current?.attachments ?? const [],
      createdAt: _current?.createdAt ?? now,
      updatedAt: now,
      lastEditedAt: now,
      date: _current?.date,
      linkedTaskIds: _current?.linkedTaskIds ?? const [],
      order: _current?.order ?? 0,
    );

    try {
      Note saved = note;
      if (_current == null || (_current?.id.isEmpty ?? true)) {
        final newId = await NoteFirestoreService.add(note);
        if (newId == null) {
          throw StateError('Could not create note without authenticated user');
        }
        saved = note.copyWith(id: newId);
      } else {
        await NoteFirestoreService.update(note);
      }

      _lastSavedSnapshot = snapshot;
      _lastSavedAt = now;
      if (mounted) {
        setState(() {
          _current = saved;
        });
      } else {
        _current = saved;
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
    _docChangesSub?.cancel();
    _titleCtrl.removeListener(_onDraftChanged);
    _quillController.removeListener(_onQuillControllerChanged);
    _titleCtrl.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _autoSaveDebounce?.cancel();
        _persist(popAfterSave: false, showError: false);
      },
      child: Scaffold(
        appBar:
            _focusMode
                ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _focusMode = false),
                    tooltip: 'Salir de modo enfoque',
                  ),
                )
                : AppBar(
                  title: Text(
                    'Nota',
                    style: TextStyle(fontSize: isMobile ? 18 : 20),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: isMobile ? 22 : 24,
                      ),
                      onPressed: () {
                        setState(() => _isPinned = !_isPinned);
                        _onDraftChanged();
                      },
                      tooltip: 'Fijar',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.visibility_off_outlined,
                        size: isMobile ? 22 : 24,
                      ),
                      onPressed: () => setState(() => _focusMode = true),
                      tooltip: 'Modo enfoque',
                    ),
                    IconButton(
                      icon: Icon(Icons.check, size: isMobile ? 22 : 24),
                      onPressed:
                          () => _persist(
                            popAfterSave: true,
                            showError: true,
                          ),
                      tooltip: 'Guardar',
                    ),
                    if (_saving)
                      Padding(
                        padding: EdgeInsets.only(right: isMobile ? 8 : 12),
                        child: SizedBox(
                          width: isMobile ? 18 : 20,
                          height: isMobile ? 18 : 20,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
        body: Column(
          children: [
            if (!_focusMode)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 20,
                  isMobile ? 12 : 16,
                  isMobile ? 16 : 20,
                  0,
                ),
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 20,
                  0,
                  isMobile ? 16 : 20,
                  isMobile ? 6 : 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _editedAt == null
                            ? 'Edited: not saved yet'
                            : 'Edited: ${_formatEditedAt(_editedAt!)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      _saving ? 'Guardando...' : 'Autoguardado',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
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
                  showBackgroundColorButton: false,
                  showColorButton: false,
                ),
              ),
            if (!_focusMode)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 14 : 18,
                  6,
                  isMobile ? 14 : 18,
                  6,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Color',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    for (final swatch in _textColorPalette)
                      InkWell(
                        onTap: () => _onSelectTextColor(swatch),
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: isMobile ? 26 : 28,
                          height: isMobile ? 26 : 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: swatch,
                            border: Border.all(
                              color:
                                  _currentTextColor.toARGB32() ==
                                          swatch.toARGB32()
                                      ? color.primary
                                      : color.outlineVariant,
                              width:
                                  _currentTextColor.toARGB32() ==
                                          swatch.toARGB32()
                                      ? 2.2
                                      : 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
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
      ),
    );
  }
}

