import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:focuslane/screens/finance/models/asset_model.dart';
import 'package:focuslane/screens/finance/services/asset_service.dart';

import 'package:focuslane/screens/finance/widgets/finance_shell.dart';
import 'package:focuslane/design/ui/components/focus_card.dart';
import 'package:focuslane/design/ui/feedback/focus_feedback.dart';

class AssetFormScreen extends StatefulWidget {
  const AssetFormScreen({super.key, this.asset});
  static const route = '/finance/assets/form';
  final Asset? asset;

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _currentValueCtrl = TextEditingController();
  final _purchaseValueCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late String _type;
  late DateTime _purchaseDate;
  String? _photoUrl;
  File? _photoFile;

  final _types = {
    'property': 'Propiedad',
    'vehicle': 'Vehículo',
    'investment': 'Inversión',
    'savings': 'Ahorros',
    'crypto': 'Criptomoneda',
    'other': 'Otro',
  };

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    if (a != null) {
      _nameCtrl.text = a.name;
      _currentValueCtrl.text = a.currentValue.toStringAsFixed(2);
      _purchaseValueCtrl.text = a.purchaseValue.toStringAsFixed(2);
      _type = a.type;
      _purchaseDate = a.purchaseDate;
      _photoUrl = a.photoUrl;
      _locationCtrl.text = a.location ?? '';
      _notesCtrl.text = a.notes ?? '';
    } else {
      _type = 'other';
      _purchaseDate = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.asset == null ? 'Nuevo activo' : 'Editar activo';

    return FinanceShell(
      selectedIndex: 3,
      title: 'Finanzas',
      subtitle: subtitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        heroTag: null,
        icon: const Icon(Icons.check),
        label: const Text('Guardar'),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 1024 ? 16.0 : 12.0;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPhotoSection(),
                      const SizedBox(height: 16),
                      FocusCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNameField(),
                            const SizedBox(height: 16),
                            _buildTypeField(),
                            const SizedBox(height: 16),
                            _buildPurchaseValueField(),
                            const SizedBox(height: 16),
                            _buildCurrentValueField(),
                            const SizedBox(height: 16),
                            _buildPurchaseDateField(),
                            const SizedBox(height: 16),
                            _buildLocationField(),
                            const SizedBox(height: 16),
                            _buildNotesField(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoSection() {
    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Foto del activo',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_photoFile != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _photoFile!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _photoFile = null),
                  ),
                ),
              ],
            )
          else if (_photoUrl != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _photoUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _photoUrl = null),
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
    );
    if (image != null) {
      setState(() => _photoFile = File(image.path));
    }
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: InputDecoration(
        labelText: 'Nombre *',
        hintText: 'Ej: Casa familiar, Tesla Model 3',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
    );
  }

  Widget _buildTypeField() {
    return DropdownButtonFormField<String>(
      initialValue: _type,
      decoration: InputDecoration(
        labelText: 'Tipo *',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          _types.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
      onChanged: (v) => setState(() => _type = v ?? 'other'),
    );
  }

  Widget _buildPurchaseValueField() {
    return TextFormField(
      controller: _purchaseValueCtrl,
      decoration: InputDecoration(
        labelText: 'Valor de compra *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.shopping_cart),
        suffixText: 'EUR',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final amount = double.tryParse(v);
        if (amount == null || amount < 0) return 'Valor inválido';
        return null;
      },
    );
  }

  Widget _buildCurrentValueField() {
    return TextFormField(
      controller: _currentValueCtrl,
      decoration: InputDecoration(
        labelText: 'Valor actual *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.euro),
        suffixText: 'EUR',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final amount = double.tryParse(v);
        if (amount == null || amount < 0) return 'Valor inválido';
        return null;
      },
    );
  }

  Widget _buildPurchaseDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _purchaseDate,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _purchaseDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de compra',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(DateFormat('d MMMM yyyy', 'es').format(_purchaseDate)),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationCtrl,
      decoration: InputDecoration(
        labelText: 'Ubicacion',
        hintText: 'Ej: Madrid, Espana',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesCtrl,
      decoration: InputDecoration(
        labelText: 'Notas',
        hintText: 'Detalles adicionales...',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 3,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? photoUrl = _photoUrl;
    if (_photoFile != null) {
      photoUrl = await AssetService.I.uploadPhoto(_photoFile!);
    }

    final asset = Asset(
      id: widget.asset?.id ?? '',
      userId: widget.asset?.userId ?? '',
      name: _nameCtrl.text.trim(),
      type: _type,
      currentValue: double.parse(_currentValueCtrl.text),
      purchaseValue: double.parse(_purchaseValueCtrl.text),
      purchaseDate: _purchaseDate,
      photoUrl: photoUrl,
      location: _locationCtrl.text.isEmpty ? null : _locationCtrl.text.trim(),
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
      valueHistory: widget.asset?.valueHistory ?? [],
    );

    try {
      if (widget.asset == null) {
        await AssetService.I.create(asset);
      } else {
        await AssetService.I.update(asset);
      }
      if (mounted) {
        Navigator.pop(context, true);
        FocusFeedback.showSuccess(
          context,
          widget.asset == null ? 'Activo creado' : 'Activo actualizado',
        );
      }
    } catch (e) {
      if (mounted) {
        FocusFeedback.showError(context, 'Error: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentValueCtrl.dispose();
    _purchaseValueCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
