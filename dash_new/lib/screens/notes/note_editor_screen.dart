import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:mi_dashboard_personal/design/blocks/toast/app_toast.dart';

import 'note_firestore_service.dart';
import 'note_model.dart';

class _NoteEditorFormatController extends ChangeNotifier {
  _NoteEditorFormatController({
    required this.quillController,
    required this.editorFocusNode,
    required Color initialColor,
  }) : _activeTextColor = initialColor;

  final QuillController quillController;
  final FocusNode editorFocusNode;

  Color _activeTextColor;
  TextSelection? _lastKnownSelection;

  Color get activeTextColor => _activeTextColor;

  void captureSelection() {
    final selection = quillController.selection;
    if (_isValidSelection(selection)) {
      _lastKnownSelection = selection;
    }
  }

  void onEditorChanged() {
    final selection = quillController.selection;
    if (_isValidSelection(selection)) {
      _lastKnownSelection = selection;
    }

    final selectedColor = _readSelectionColor();
    if (selectedColor != null &&
        selectedColor.toARGB32() != _activeTextColor.toARGB32()) {
      _activeTextColor = selectedColor;
      notifyListeners();
    }
  }

  void applyColor(Color color) {
    _activeTextColor = color;
    final safeSelection = _resolveSelection();

    if (!editorFocusNode.hasFocus) {
      editorFocusNode.requestFocus();
    }

    if (safeSelection != null) {
      quillController.updateSelection(safeSelection, ChangeSource.local);
    }

    final colorAttr = ColorAttribute(_toQuillHex(color));
    quillController.formatSelection(colorAttr);

    if (safeSelection != null) {
      quillController.updateSelection(safeSelection, ChangeSource.local);
    }

    onEditorChanged();
    notifyListeners();
  }

  Color? _readSelectionColor() {
    final attr =
        quillController.getSelectionStyle().attributes[Attribute.color.key];
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

  TextSelection? _resolveSelection() {
    final current = quillController.selection;
    if (_isValidSelection(current)) return current;
    if (_lastKnownSelection != null && _isValidSelection(_lastKnownSelection!)) {
      return _lastKnownSelection;
    }

    final length = quillController.document.length;
    if (length <= 0) return null;
    final collapsed = TextSelection.collapsed(offset: length - 1);
    return _isValidSelection(collapsed) ? collapsed : null;
  }

  bool _isValidSelection(TextSelection selection) {
    return selection.start >= 0 && selection.end >= 0;
  }

  static String _toQuillHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class _ColorPaletteBar extends StatelessWidget {
  const _ColorPaletteBar({
    required this.palette,
    required this.activeColor,
    required this.onColorTapDown,
    required this.onColorTap,
    required this.isMobile,
  });

  final List<Color> palette;
  final Color activeColor;
  final VoidCallback onColorTapDown;
  final ValueChanged<Color> onColorTap;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 10 : 12, 10, isMobile ? 10 : 12, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, size: 16),
              const SizedBox(width: 6),
              Text(
                'Color activo',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(width: 8),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final swatch in palette)
                Focus(
                  canRequestFocus: false,
                  child: GestureDetector(
                    onTapDown: (_) => onColorTapDown(),
                    onTap: () => onColorTap(swatch),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: isMobile ? 28 : 30,
                      height: isMobile ? 28 : 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: swatch,
                        border: Border.all(
                          color: activeColor.toARGB32() == swatch.toARGB32()
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width:
                              activeColor.toARGB32() == swatch.toARGB32() ? 2.5 : 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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

  static const List<Color> _textColorPalette = <Color>[
    Colors.black87,
    Colors.grey,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.deepPurple,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.redAccent,
    Colors.brown,
  ];

  late final TextEditingController _titleCtrl;
  late final FocusNode _editorFocusNode;
  late final _NoteEditorFormatController _formatController;
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

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _editorFocusNode = FocusNode();
    _formatController = _NoteEditorFormatController(
      quillController: _quillController,
      editorFocusNode: _editorFocusNode,
      initialColor: Colors.black87,
    );

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
    _formatController.onEditorChanged();

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
    _formatController.onEditorChanged();
  }

  void _onColorSelected(Color color) {
    _formatController.applyColor(color);
    _onDraftChanged();
  }

  void _captureSelectionBeforeColorTap() {
    _formatController.captureSelection();
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
    return DateFormat('dd MMM yyyy • HH:mm').format(value);
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
    _editorFocusNode.dispose();
    _formatController.dispose();
    _quillController.dispose();
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
              icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () {
                setState(() => _isPinned = !_isPinned);
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
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _formatController,
                        builder: (context, _) {
                          return _ColorPaletteBar(
                            palette: _textColorPalette,
                            activeColor: _formatController.activeTextColor,
                            onColorTapDown: _captureSelectionBeforeColorTap,
                            onColorTap: _onColorSelected,
                            isMobile: isMobile,
                          );
                        },
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
                    controller: _quillController,
                    focusNode: _editorFocusNode,
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
