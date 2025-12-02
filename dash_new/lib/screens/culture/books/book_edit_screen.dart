import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/culture_firestore_service.dart';
import '../../../models/culture_models.dart';
import '../../../widgets/ui_scaffold.dart';

class BookEditScreen extends StatefulWidget {
  const BookEditScreen({super.key});
  static const route = '/culture/book/edit';

  @override
  State<BookEditScreen> createState() => _BookEditScreenState();
}

class _BookEditScreenState extends State<BookEditScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _genre = TextEditingController();
  final _year = TextEditingController();
  final _pages = TextEditingController();
  final _cover = TextEditingController();
  final _pdfUrl = TextEditingController(); // ✅
  ItemStatus _status = ItemStatus.pending;
  double? _rating;

  bool _uploadingPdf = false;

  Book? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Book && editing == null) {
      editing = arg;
      _title.text = arg.title;
      _author.text = arg.author ?? '';
      _genre.text = arg.genre ?? '';
      _year.text = arg.year?.toString() ?? '';
      _pages.text = arg.pagesTotal?.toString() ?? '';
      _status = arg.status;
      _rating = arg.rating;
      _cover.text = arg.coverUrl ?? '';
      _pdfUrl.text = arg.pdfUrl ?? '';
    }
  }

  Future<void> _pickAndUploadPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // solicitamos bytes para web / path null
      );
      if (result == null || result.files.isEmpty) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para subir PDF')),
        );
        return;
      }
      setState(() => _uploadingPdf = true);

      final picked = result.files.single;
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final baseName =
          picked.name.toLowerCase().endsWith('.pdf')
              ? picked.name
              : '${picked.name}.pdf';
      final safeName = baseName.replaceAll(RegExp(r"[^a-zA-Z0-9_\.-]"), '_');
      final filePath =
          'users/$uid/books/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final storage = Supabase.instance.client.storage;

      if (kIsWeb || picked.path == null) {
        final bytes = picked.bytes;
        if (bytes == null) throw Exception('Bytes no disponibles para el PDF.');
        await storage
            .from('notes-media')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(contentType: 'application/pdf'),
            );
      } else {
        final file = File(picked.path!);
        final fileBytes = await file.readAsBytes();
        await storage
            .from('notes-media')
            .uploadBinary(
              filePath,
              fileBytes,
              fileOptions: FileOptions(contentType: 'application/pdf'),
            );
      }
      final url = storage.from('notes-media').getPublicUrl(filePath);

      setState(() {
        _pdfUrl.text = url;
        _uploadingPdf = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF subido correctamente')),
        );
      }
    } catch (e) {
      setState(() => _uploadingPdf = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Nuevo libro' : 'Editar libro'),
      ),
      body: TaskFormTheme(
        child: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _author,
                decoration: const InputDecoration(labelText: 'Autor'),
              ),
              TextFormField(
                controller: _genre,
                decoration: const InputDecoration(labelText: 'Género'),
              ),
              TextFormField(
                controller: _year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Año'),
              ),
              TextFormField(
                controller: _pages,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Páginas totales'),
              ),
              TextFormField(
                controller: _cover,
                decoration: const InputDecoration(
                  labelText: 'Cover URL (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pdfUrl,
                      decoration: const InputDecoration(
                        labelText: 'PDF URL (o selecciona archivo)',
                      ),
                      enabled: !_uploadingPdf,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _uploadingPdf
                      ? const CircularProgressIndicator()
                      : IconButton(
                        icon: const Icon(Icons.upload_file),
                        onPressed: _pickAndUploadPdf,
                        tooltip: 'Seleccionar PDF',
                      ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ItemStatus>(
                initialValue: _status,
                items:
                    ItemStatus.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.name)),
                        )
                        .toList(),
                onChanged:
                    (v) => setState(() => _status = v ?? ItemStatus.pending),
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Valoración (0..10)'),
                trailing: SizedBox(
                  width: 100,
                  child: TextField(
                    controller: TextEditingController(
                      text: _rating?.toStringAsFixed(1) ?? '',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => _rating = double.tryParse(v),
                    decoration: const InputDecoration(hintText: 'ej 8.5'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final b = Book(
                    id: editing?.id ?? '',
                    title: _title.text.trim(),
                    author:
                        _author.text.trim().isEmpty
                            ? null
                            : _author.text.trim(),
                    genre:
                        _genre.text.trim().isEmpty ? null : _genre.text.trim(),
                    year: int.tryParse(_year.text),
                    pagesTotal: int.tryParse(_pages.text),
                    status: _status,
                    rating: _rating,
                    coverUrl:
                        _cover.text.trim().isEmpty ? null : _cover.text.trim(),
                    pdfUrl:
                        _pdfUrl.text.trim().isEmpty
                            ? null
                            : _pdfUrl.text.trim(),
                  );
                  if (editing == null) {
                    await svc.addBook(b);
                  } else {
                    await svc.updateBook(b);
                  }
                  if (mounted) Navigator.pop(context, b);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
