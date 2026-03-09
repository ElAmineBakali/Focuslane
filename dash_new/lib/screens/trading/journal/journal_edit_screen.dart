import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_dashboard_personal/design/widgets/ui_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum Outcome { win, loss, breakeven }

class TradingJournalEditScreen extends StatefulWidget {
  const TradingJournalEditScreen({super.key});
  static const route = '/trading/journal/edit';

  @override
  State<TradingJournalEditScreen> createState() =>
      _TradingJournalEditScreenState();
}

class _TradingJournalEditScreenState extends State<TradingJournalEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Campos
  DateTime? _openTime;
  DateTime? _closeTime;
  final _typeCtrl = TextEditingController(text: 'market'); // market/limit/stop
  final _sizeCtrl = TextEditingController();
  final _itemCtrl = TextEditingController(text: 'USTEC');
  final _entryCtrl = TextEditingController();
  final _slCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();
  final _closePriceCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController(text: '0');
  final _profitCtrl = TextEditingController();
  Outcome _outcome = Outcome.win;
  bool _strategyOk = true;
  final _commentsCtrl = TextEditingController();

  // Imagen
  final _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _previewBytes;

  Future<void> _pickImage() async {
    final f = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 3000,
      maxHeight: 3000,
    );
    if (f != null) {
      final bytes = await f.readAsBytes();
      setState(() {
        _picked = f;
        _previewBytes = bytes;
      });
    }
  }

  Future<void> _pickDateTime({required bool open}) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (t == null) return;
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() {
      if (open) {
        _openTime = dt;
      } else {
        _closeTime = dt;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;
    final storage = Supabase.instance.client.storage;

    final col = firestore
        .collection('users')
        .doc(uid)
        .collection('trading_journal');
    final doc = col.doc(); // id nuevo

    Map<String, String>? imageUrls;
    if (_picked != null) {
      // Subimos 2 versiones por simplicidad (full y thumb = misma imagen)
      final ext = _picked!.name.split('.').last;
      final fullPath = 'users/$uid/trading_journal/${doc.id}/full.$ext';
      final thumbPath = 'users/$uid/trading_journal/${doc.id}/thumb.$ext';

      final bytes = await _picked!.readAsBytes();

      await storage
          .from('notes-media')
          .uploadBinary(
            fullPath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
            ),
          );
      await storage
          .from('notes-media')
          .uploadBinary(
            thumbPath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
            ),
          );

      imageUrls = {
        'full': storage.from('notes-media').getPublicUrl(fullPath),
        'thumb': storage.from('notes-media').getPublicUrl(thumbPath),
      };
    }

    // Construimos el registro
    final data = {
      'openTime': _openTime,
      'type': _typeCtrl.text.trim(),
      'size': double.tryParse(_sizeCtrl.text.trim()) ?? 0.0,
      'item': _itemCtrl.text.trim(),
      'entryPrice': double.tryParse(_entryCtrl.text.trim()) ?? 0.0,
      'sl': double.tryParse(_slCtrl.text.trim()) ?? 0.0,
      'tp': double.tryParse(_tpCtrl.text.trim()) ?? 0.0,
      'closeTime': _closeTime,
      'closePrice': double.tryParse(_closePriceCtrl.text.trim()) ?? 0.0,
      'commission': double.tryParse(_commissionCtrl.text.trim()) ?? 0.0,
      'profit': double.tryParse(_profitCtrl.text.trim()) ?? 0.0,
      'outcome': _outcome.name, // win/loss/breakeven
      'strategyOk': _strategyOk,
      'comments': _commentsCtrl.text.trim(),
      'imageUrls': imageUrls,
      'createdAt': DateTime.now(),
    };

    await doc.set(data);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    InputDecoration deco(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo registro de diario')),
      body: TaskFormTheme(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, screenPad(context)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fechas
                Text('Apertura', style: tt.titleMedium),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _openTime == null
                            ? 'Sin fecha'
                            : _openTime!.toLocal().toString(),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _pickDateTime(open: true),
                      icon: const Icon(Icons.access_time),
                      label: const Text('Elegir'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Cierre', style: tt.titleMedium),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _closeTime == null
                            ? 'Sin fecha'
                            : _closeTime!.toLocal().toString(),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _pickDateTime(open: false),
                      icon: const Icon(Icons.access_time),
                      label: const Text('Elegir'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campos
                Text('Tipo', style: tt.titleMedium), const SizedBox(height: 5),
                TextFormField(
                  controller: _typeCtrl,
                  decoration: deco('market / limit / stop'),
                ),
                const SizedBox(height: 12),
                Text('Tamaño (Size)', style: tt.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _sizeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: deco('Ej: 1.0'),
                ),
                const SizedBox(height: 12),
                Text('Activo', style: tt.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _itemCtrl,
                  decoration: deco('Ej: USTEC'),
                ),
                const SizedBox(height: 12),
                Text('Precio de entrada', style: tt.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _entryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: deco('Entry'),
                ),
                const SizedBox(height: 12),
                Text('Stop Loss', style: tt.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _slCtrl,
                  keyboardType: TextInputType.number,
                  decoration: deco('SL'),
                ),
                const SizedBox(height: 12),
                Text('Take Profit', style: tt.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _tpCtrl,
                  keyboardType: TextInputType.number,
                  decoration: deco('TP'),
                ),
                const SizedBox(height: 12),
                Text('Precio de cierre', style: tt.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _closePriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: deco('Close price'),
                ),
                const SizedBox(height: 12),
                Text('Comisión', style: tt.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _commissionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: deco('Ej: 0'),
                ),
                const SizedBox(height: 12),
                Text('Beneficio (Profit)', style: tt.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _profitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: deco('Ej: 25.50'),
                ),
                const SizedBox(height: 16),

                // Outcome + Strategy
                Text('Resultado', style: tt.titleMedium),
                const SizedBox(height: 5),
                SegmentedButton<Outcome>(
                  segments: const [
                    ButtonSegment(
                      value: Outcome.win,
                      label: Text('Win'),
                      icon: Icon(Icons.trending_up),
                    ),
                    ButtonSegment(
                      value: Outcome.loss,
                      label: Text('Loss'),
                      icon: Icon(Icons.trending_down),
                    ),
                    ButtonSegment(
                      value: Outcome.breakeven,
                      label: Text('BE'),
                      icon: Icon(Icons.horizontal_rule),
                    ),
                  ],
                  selected: {_outcome},
                  onSelectionChanged: (s) => setState(() => _outcome = s.first),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('¿Cumplí la estrategia?'),
                  value: _strategyOk,
                  onChanged: (v) => setState(() => _strategyOk = v),
                ),
                const SizedBox(height: 12),

                // Comentarios
                Text('Comentarios', style: tt.titleMedium),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _commentsCtrl,
                  maxLines: 4,
                  decoration: deco('Ideas, psicología, gestiónâ€¦'),
                ),
                const SizedBox(height: 16),

                // Imagen
                Text('Imagen (opcional)', style: tt.titleMedium),
                const SizedBox(height: 5),
                if (_previewBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _previewBytes!,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Text('Ninguna imagen seleccionada'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Galería / Archivos'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

