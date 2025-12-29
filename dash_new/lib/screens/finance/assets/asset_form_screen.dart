import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/asset_model.dart';
import 'package:mi_dashboard_personal/services/finance/asset_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          FinanceUI.sliverAppBar(
            context,
            title: widget.asset == null ? 'Nuevo Activo' : 'Editar Activo',
            backgroundIcon: Icons.account_balance,
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoSection(),
                    const SizedBox(height: 16),
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: Text('Guardar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foto del activo', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
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
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
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
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Icon(Icons.broken_image, size: 50)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _photoUrl = null),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
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
                    border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Añadir foto',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
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
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildTypeField() {
    return DropdownButtonFormField<String>(
      value: _type,
      decoration: InputDecoration(
        labelText: 'Tipo *',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _types.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => setState(() => _type = v!),
    );
  }

  Widget _buildPurchaseValueField() {
    return TextFormField(
      controller: _purchaseValueCtrl,
      decoration: InputDecoration(
        labelText: 'Valor de compra *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.shopping_cart),
        suffixText: '€',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final amount = double.tryParse(v);
        if (amount == null || amount < 0) return 'Valor inválido';
        return null;
      },
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildCurrentValueField() {
    return TextFormField(
      controller: _currentValueCtrl,
      decoration: InputDecoration(
        labelText: 'Valor actual *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.euro),
        suffixText: '€',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: 'Valor estimado actual del activo',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final amount = double.tryParse(v);
        if (amount == null || amount < 0) return 'Valor inválido';
        return null;
      },
      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
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
        if (picked != null) {
          setState(() => _purchaseDate = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de compra',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          DateFormat('d MMMM yyyy', 'es').format(_purchaseDate),
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationCtrl,
      decoration: InputDecoration(
        labelText: 'Ubicación',
        hintText: 'Ej: Madrid, España',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: GoogleFonts.poppins(),
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
      style: GoogleFonts.poppins(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? photoUrl = _photoUrl;
    if (_photoFile != null) {
      // Upload photo to Firebase Storage
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.asset == null ? 'Activo creado' : 'Activo actualizado',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins())),
        );
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
