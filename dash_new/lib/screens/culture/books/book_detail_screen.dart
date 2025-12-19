import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_dashboard_personal/blocks/toast/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/culture_firestore_service.dart';
import '../../../models/culture_models.dart';
import 'book_edit_screen.dart';
import '../../../widgets/ui_scaffold.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key});
  static const route = '/culture/book';

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? book;

  final _quickPage = TextEditingController();
  final _sumShort = TextEditingController();
  final _sumDeep = TextEditingController();

  final _sessPages = TextEditingController();
  final _sessMin = TextEditingController();
  final _sessNotes = TextEditingController();

  final _quoteText = TextEditingController();
  final _quotePage = TextEditingController();
  final _quoteNote = TextEditingController();

  bool _uploading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Book && book == null) {
      book = arg;
      _quickPage.text = arg.currentPage.toString();
      _sumShort.text = arg.shortSummary ?? '';
      _sumDeep.text = arg.deepSummary ?? '';
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pickAndUploadPdf(Book b) async {
    try {
      setState(() => _uploading = true);

      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, 
      );
      if (res == null || res.files.isEmpty) return;

      final file = res.files.first;
      final Uint8List? bytes = file.bytes;
    
      const maxPdfBytes = 5 * 1024 * 1024;
      if (bytes == null) {
        AppToast.error(context, 'No se pudo leer el archivo');
        return;
      }
      if (bytes.length > maxPdfBytes) {
        AppToast.error(context, 'El PDF supera el límite de 5MB');
        return;
      }

      final path = 'books/${b.id}/book.pdf';

      await Supabase.instance.client.storage
          .from('notes-media')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'application/pdf'),
          );
      final url = Supabase.instance.client.storage
          .from('notes-media')
          .getPublicUrl(path);

      final updated = _copyBookWith(b, pdfUrl: url);
      await CultureFirestoreService.I.updateBook(updated);
      setState(() => book = updated);

      if (mounted) {
        AppToast.success(context, 'PDF subido correctamente');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error al subir PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePdf(Book b) async {
    try {
      try {
        final client = Supabase.instance.client.storage;
        final url = b.pdfUrl ?? '';
        String path = 'books/${b.id}/book.pdf';
        final marker = '/object/public/notes-media/';
        final i = url.indexOf(marker);
        if (i != -1) {
          final derived = url.substring(i + marker.length);
          if (derived.isNotEmpty) {
            path = derived;
          }
        }
        await client.from('notes-media').remove([path]);
      } catch (_) {}

      final updated = _copyBookWith(b, pdfUrl: null);
      await CultureFirestoreService.I.updateBook(updated);
      setState(() => book = updated);
      if (mounted) {
        AppToast.info(context, 'PDF eliminado');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error al eliminar PDF: $e');
      }
    }
  }

  Book _copyBookWith(
    Book b, {
    int? currentPage,
    String? shortSummary,
    String? deepSummary,
    String? pdfUrl,
  }) {
    return Book(
      id: b.id,
      title: b.title,
      author: b.author,
      year: b.year,
      genre: b.genre,
      pagesTotal: b.pagesTotal,
      currentPage: currentPage ?? b.currentPage,
      shortSummary: shortSummary ?? b.shortSummary,
      deepSummary: deepSummary ?? b.deepSummary,
      rating: b.rating,
      status: b.status,
      tags: b.tags,
      coverUrl: b.coverUrl,
      pdfUrl: pdfUrl ?? b.pdfUrl,
      startedAt: b.startedAt,
      finishedAt: b.finishedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    if (book == null)
      return const Scaffold(body: Center(child: Text('Sin libro')));
    final b = book!;

    return Scaffold(
      appBar: AppBar(
        title: Text(b.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                BookEditScreen.route,
                arguments: b,
              );
              if (result is Book && mounted) {
                setState(() => book = result);
                _quickPage.text = result.currentPage.toString();
                _sumShort.text = result.shortSummary ?? '';
                _sumDeep.text = result.deepSummary ?? '';
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await svc.deleteBook(b.id);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: PaddedListView(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text('${b.author ?? "—"} • ${b.genre ?? ""}'),
              subtitle: Text(
                'Estado: ${b.status.name} • Rating: ${b.rating?.toStringAsFixed(1) ?? "-"}',
              ),
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archivo PDF',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  if (b.pdfUrl != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.picture_as_pdf),
                      title: const Text('PDF adjunto'),
                      subtitle: Text(b.pdfUrl!),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openPdf(b.pdfUrl!),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Ver PDF'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                _uploading ? null : () => _pickAndUploadPdf(b),
                            icon: const Icon(Icons.upload_file),
                            label: Text(
                              _uploading ? 'Subiendo...' : 'Actualizar PDF',
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar PDF',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removePdf(b),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'No hay PDF adjunto',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed:
                              _uploading ? null : () => _pickAndUploadPdf(b),
                          icon: const Icon(Icons.upload_file),
                          label: Text(_uploading ? 'Subiendo...' : 'Subir PDF'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progreso',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quickPage,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Página actual',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final p =
                              int.tryParse(_quickPage.text) ?? b.currentPage;
                          await svc.setBookCurrentPage(b.id, p);
                          setState(
                            () => book = _copyBookWith(b, currentPage: p),
                          );
                        },
                        child: const Text('Actualizar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value:
                        (b.pagesTotal == null || b.pagesTotal == 0)
                            ? null
                            : (b.currentPage / b.pagesTotal!)
                                .clamp(0, 1)
                                .toDouble(),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resúmenes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _sumShort,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Resumen corto',
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _sumDeep,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Resumen profundo',
                    ),
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                    onPressed: () async {
                      await CultureFirestoreService.I.updateBook(
                        _copyBookWith(
                          b,
                          currentPage:
                              int.tryParse(_quickPage.text) ?? b.currentPage,
                          shortSummary:
                              _sumShort.text.trim().isEmpty
                                  ? null
                                  : _sumShort.text.trim(),
                          deepSummary:
                              _sumDeep.text.trim().isEmpty
                                  ? null
                                  : _sumDeep.text.trim(),
                        ),
                      );
                      if (mounted) {
                        AppToast.success(context, 'Resúmenes guardados');
                      }
                    },
                    child: const Text('Guardar resúmenes'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesiones de lectura',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sessPages,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Páginas',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _sessMin,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minutos',
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _sessNotes,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                    onPressed: () async {
                      final s = BookSession(
                        id: '',
                        date: DateTime.now(),
                        pages: int.tryParse(_sessPages.text) ?? 0,
                        minutes: int.tryParse(_sessMin.text) ?? 0,
                        notes:
                            _sessNotes.text.trim().isEmpty
                                ? null
                                : _sessNotes.text.trim(),
                      );
                      await CultureFirestoreService.I.addBookSession(b.id, s);
                      _sessPages.clear();
                      _sessMin.clear();
                      _sessNotes.clear();
                    },
                    child: const Text('Añadir sesión'),
                  ),
                  const Divider(),
                  StreamBuilder<List<BookSession>>(
                    stream: CultureFirestoreService.I.watchBookSessions(b.id),
                    builder: (_, s) {
                      final data = s.data ?? [];
                      if (data.isEmpty)
                        return const Text('Sin sesiones todavía');
                      return Column(
                        children:
                            data
                                .map(
                                  (x) => ListTile(
                                    leading: const Icon(Icons.timer),
                                    title: Text(
                                      '${x.pages} págs • ${x.minutes} min',
                                    ),
                                    subtitle: Text(
                                      x.date
                                              .toLocal()
                                              .toString()
                                              .split('.')
                                              .first +
                                          (x.notes != null
                                              ? ' • ${x.notes}'
                                              : ''),
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Citas', style: Theme.of(context).textTheme.titleMedium),
                  TextField(
                    controller: _quoteText,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Texto'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quotePage,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Página',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _quoteNote,
                          decoration: const InputDecoration(
                            labelText: 'Nota (opcional)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                    onPressed: () async {
                      if (_quoteText.text.trim().isEmpty) return;
                      await CultureFirestoreService.I.addBookQuote(
                        b.id,
                        BookQuote(
                          id: '',
                          text: _quoteText.text.trim(),
                          page: int.tryParse(_quotePage.text),
                          note:
                              _quoteNote.text.trim().isEmpty
                                  ? null
                                  : _quoteNote.text.trim(),
                        ),
                      );
                      _quoteText.clear();
                      _quotePage.clear();
                      _quoteNote.clear();
                    },
                    child: const Text('Guardar cita'),
                  ),
                  const Divider(),
                  StreamBuilder<List<BookQuote>>(
                    stream: CultureFirestoreService.I.watchBookQuotes(b.id),
                    builder: (_, s) {
                      final data = s.data ?? [];
                      if (data.isEmpty)
                        return const Text('Sin citas guardadas');
                      return Column(
                        children:
                            data
                                .map(
                                  (q) => ListTile(
                                    leading: const Icon(Icons.format_quote),
                                    title: Text(q.text),
                                    subtitle: Text(
                                      'Pág. ${q.page ?? "-"} ${q.note != null ? "• ${q.note}" : ""}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed:
                                          () => CultureFirestoreService.I
                                              .deleteBookQuote(b.id, q.id),
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
