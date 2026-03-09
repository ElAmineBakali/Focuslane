import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/prenda_model.dart';
import '../../screens/ropa/services/prenda_firestore_service.dart';
import 'package:mi_dashboard_personal/design/widgets/ui_scaffold.dart';

class PrendaFormScreen extends StatefulWidget {
  final Prenda? initial;
  const PrendaFormScreen({super.key, this.initial});

  @override
  State<PrendaFormScreen> createState() => _PrendaFormScreenState();
}

class _PrendaFormScreenState extends State<PrendaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  EstadoPrenda _estado = EstadoPrenda.lavada;
  String _categoriaSeleccionada = 'top';

  final ImagePicker _picker = ImagePicker();

  Uint8List? _previewBytes;
  XFile? _pickedFile;
  bool _saving = false;
  Map<String, String> _imagenes = const {};

  final Map<String, String> _categorias = const {
    'head': 'Cabeza / Gorros',
    'top': 'Parte superior',
    'outer': 'Capa exterior',
    'bottom': 'Parte inferior',
    'shoes': 'Calzado',
    'accessories': 'Accesorios',
  };

  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    if (x != null) {
      _nombreCtrl.text = x.nombre;
      _descripcionCtrl.text = x.descripcion;
      _estado = x.estado;
      _categoriaSeleccionada = x.categoriaId;
      _imagenes = x.imagenes;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _pickedFile = img;
        _previewBytes = bytes;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _pickedFile = img;
        _previewBytes = bytes;
      });
    }
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay usuario autenticado')),
        );
        setState(() => _saving = false);
        return;
      }

      final svc = PrendaFirestoreService();
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wardrobe_items');

      final id = widget.initial?.id ?? col.doc().id;

      Map<String, String> imagenes = Map<String, String>.from(
        widget.initial?.imagenes ?? {},
      );
      if (_pickedFile != null) {
        imagenes = await svc.uploadImagenPrenda(
          uid: uid,
          prendaId: id,
          file: _pickedFile!,
        );
      }

      final prenda = Prenda(
        id: id,
        nombre: _nombreCtrl.text.trim(),
        categoriaId: _categoriaSeleccionada,
        descripcion: _descripcionCtrl.text.trim(),
        estado: _estado,
        colores: widget.initial?.colores ?? const [],
        temporadas: widget.initial?.temporadas ?? const [],
        ocasiones: widget.initial?.ocasiones ?? const [],
        marca: widget.initial?.marca,
        precio: widget.initial?.precio,
        imagenes: imagenes,
        vecesUsada: widget.initial?.vecesUsada ?? 0,
        ultimaVezUsada: widget.initial?.ultimaVezUsada,
        archivada: widget.initial?.archivada ?? false,
        favorita: widget.initial?.favorita ?? false,
        etiquetas: widget.initial?.etiquetas ?? const [],
      );

      if (widget.initial == null) {
        await svc.addPrenda(uid, prenda);
      } else {
        await svc.updatePrenda(uid, prenda);
      }

      if (mounted) Navigator.pop(context, prenda);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumb =
        _imagenes['thumb'] ?? _imagenes['medium'] ?? _imagenes['full'];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Añadir prenda' : 'Editar prenda'),
      ),
      body: TaskFormTheme(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, screenPad(context)),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Campo obligatorio'
                                    : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _descripcionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _categoriaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                        ),
                        items:
                            _categorias.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) =>
                                setState(() => _categoriaSeleccionada = val!),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<EstadoPrenda>(
                        initialValue: _estado,
                        decoration: const InputDecoration(labelText: 'Estado'),
                        items:
                            EstadoPrenda.values
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _estado = val!),
                      ),
                      const SizedBox(height: 16),
                      if (_previewBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _previewBytes!,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        )
                      else if (thumb != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            thumb,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Text('Ninguna imagen seleccionada'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saving ? null : _pickFromGallery,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Galería / Archivos'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saving ? null : _pickFromCamera,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Cámara'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon:
                      _saving
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save),
                  label: Text(
                    _saving
                        ? 'Guardandoâ€¦'
                        : (widget.initial == null ? 'Guardar' : 'Actualizar'),
                  ),
                  onPressed: _saving ? null : _guardar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



