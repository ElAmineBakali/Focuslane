import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/core/services/ai_backend_client.dart';
import 'package:focuslane/screens/finance/models/transaction_model.dart';
import 'package:focuslane/screens/finance/services/finance_category_labels.dart';
import 'package:focuslane/screens/finance/services/finance_ai_normalizer.dart';
import 'package:focuslane/screens/finance/services/finance_ai_preferences.dart';
import 'package:focuslane/screens/finance/services/finance_receipt_ai_service.dart';
import 'package:focuslane/screens/finance/services/transaction_service.dart';

import 'package:focuslane/screens/finance/widgets/finance_shell.dart';
import 'package:focuslane/design/ui/components/focus_card.dart';
import 'package:focuslane/design/ui/feedback/focus_feedback.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.transaction});
  static const route = '/finance/transactions/form';
  final FinanceTransaction? transaction;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  static const bool _aiDefaultAutoEnabled = false;
  static const bool _aiClassifyOnSave = true;
  static const bool _aiDebounceWhileTyping = false;
  static const int _aiDebounceMs = 900;
  static const Duration _aiRecentWindow = Duration(minutes: 10);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _ai = AiBackendClient();
  final _receiptAiService = FinanceReceiptAiService();

  late TxType _type;
  late DateTime _date;
  String? _category;
  String? _subCategory;
  String? _accountId;
  List<String> _tags = [];
  String _divisa = 'EUR';
  double _fxRate = 1.0;
  String _recurrence = 'once';
  String? _envelopeId;
  bool _isSaving = false;
  bool _autoClassifyEnabled = _aiDefaultAutoEnabled;
  bool _manualOverride = false;
  bool _isClassifying = false;
  FinanceAiMeta? _aiMeta;
  _AiSuggestion? _pendingSuggestion;
  _ReceiptScanDraft? _receiptDraft;
  bool _receiptDraftAppliedToForm = false;
  bool _isScanningReceipt = false;
  int? _activeReceiptScanSeq;
  int _receiptScanSeq = 0;
  bool _dateTouchedManually = false;
  Timer? _classifyDebounce;
  int _classifyRequestSeq = 0;
  bool _forceReclassifyOnSave = false;

  final _categories = {
    TxType.income: ['trabajo', 'freelance', 'inversiones', 'ahorro', 'otros'],
    TxType.expense: [
      'alimentacion',
      'transporte',
      'hogar',
      'suscripciones',
      'salud',
      'ocio',
      'educacion',
      'otros_gastos',
      'otros',
    ],
  };

  final _subCategories = {
    'alimentacion': ['supermercado', 'restaurantes', 'delivery', 'comestibles'],
    'transporte': [
      'gasolina',
      'transporte_publico',
      'taxi_uber',
      'mantenimiento',
    ],
    'hogar': [
      'alquiler',
      'hipoteca',
      'electricidad',
      'agua',
      'internet',
      'reparaciones',
    ],
    'ocio': ['cine', 'conciertos', 'viajes', 'hobbies', 'streaming'],
    'salud': ['medico', 'farmacia', 'gimnasio', 'seguros'],
    'educacion': ['cursos', 'libros', 'material'],
    'suscripciones': ['streaming', 'software', 'membresia', 'servicios'],
  };

  final _divisas = ['EUR', 'USD', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD'];
  final _recurrenceOptions = {
    'once': 'Una vez',
    'daily': 'Diario',
    'weekly': 'Semanal',
    'monthly': 'Mensual',
    'yearly': 'Anual',
  };

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _titleCtrl.text = t.title;
      _amountCtrl.text = t.amount.toStringAsFixed(2);
      _type = t.type;
      _date = t.date;
      _category = t.category;
      _subCategory = t.subCategory;
      _accountId = t.accountId;
      _tags = List.from(t.tags);
      _notesCtrl.text = t.notes ?? '';
      _divisa = t.originalCurrency ?? 'EUR';
      _fxRate = t.fxRate ?? 1.0;
      _recurrence = t.recurrence ?? 'once';
      _envelopeId = t.envelopeId;
      _aiMeta = t.aiMeta;
      _manualOverride = t.aiMeta?.manualOverride == true;
    } else {
      _type = TxType.expense;
      _date = DateTime.now();
    }
    _titleCtrl.addListener(_onInputChanged);
    _amountCtrl.addListener(_onInputChanged);
    _notesCtrl.addListener(_onInputChanged);
    unawaited(_loadAutoClassifyPreference());
  }

  Future<void> _loadAutoClassifyPreference() async {
    final enabled = await FinanceAiPreferences.getAutoClassifyEnabled(
      fallback: _aiDefaultAutoEnabled,
    );
    if (!mounted) return;
    setState(() {
      _autoClassifyEnabled = enabled;
    });
  }

  Future<void> _persistAutoClassifyPreference(bool enabled) {
    return FinanceAiPreferences.setAutoClassifyEnabled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    final subtitle =
        widget.transaction == null ? 'Nueva transacción' : 'Editar transacción';

    return FinanceShell(
      selectedIndex: 1,
      title: 'Finanzas',
      subtitle: subtitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        heroTag: null,
        icon:
            _isSaving
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.check),
        label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
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
                      _buildTypeSelector(),
                      const SizedBox(height: 16),
                      FocusCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleField(),
                            const SizedBox(height: 16),
                            _buildAmountField(),
                            const SizedBox(height: 12),
                            _buildReceiptScanPanel(),
                            const SizedBox(height: 12),
                            _buildAiAssistPanel(),
                            const SizedBox(height: 16),
                            _buildDateField(),
                            const SizedBox(height: 16),
                            _buildCategoryField(),
                            if (_category != null &&
                                _subCategories.containsKey(_category)) ...[
                              const SizedBox(height: 16),
                              _buildSubCategoryField(),
                            ],
                            const SizedBox(height: 16),
                            _buildAccountField(),
                            const SizedBox(height: 16),
                            _buildDivisaField(),
                            const SizedBox(height: 16),
                            _buildRecurrenceField(),
                            const SizedBox(height: 16),
                            _buildEnvelopeField(),
                            const SizedBox(height: 16),
                            _buildTagsField(),
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

  Widget _buildTypeSelector() {
    final cs = Theme.of(context).colorScheme;
    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de transacción',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 18,
                        color:
                            _type == TxType.income ? cs.onPrimary : cs.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('Ingreso'),
                    ],
                  ),
                  selected: _type == TxType.income,
                  onSelected:
                      (_) => setState(() {
                        _type = TxType.income;
                        _category = null;
                        _subCategory = null;
                      }),
                  selectedColor: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_down,
                        size: 18,
                        color: _type == TxType.expense ? cs.onError : cs.error,
                      ),
                      const SizedBox(width: 8),
                      const Text('Gasto'),
                    ],
                  ),
                  selected: _type == TxType.expense,
                  onSelected:
                      (_) => setState(() {
                        _type = TxType.expense;
                        _category = null;
                        _subCategory = null;
                      }),
                  selectedColor: cs.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleCtrl,
      decoration: InputDecoration(
        labelText: 'Titulo *',
        hintText: 'Ej: Compra supermercado',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
    );
  }

  Widget _buildAmountField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _amountCtrl,
            decoration: InputDecoration(
              labelText: 'Importe *',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.euro),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              final amount = double.tryParse(v);
              if (amount == null || amount <= 0) return 'Importe inválido';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _divisa,
            decoration: InputDecoration(
              labelText: 'Divisa',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items:
                _divisas
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
            onChanged: (v) => setState(() => _divisa = v ?? 'EUR'),
          ),
        ),
      ],
    );
  }

  Widget _buildDivisaField() {
    if (_divisa == 'EUR') return const SizedBox.shrink();
    return TextFormField(
      initialValue: _fxRate.toStringAsFixed(4),
      decoration: InputDecoration(
        labelText: 'Tipo de cambio a EUR',
        hintText: '1.0000',
        prefixIcon: const Icon(Icons.currency_exchange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: 'Ej: 1 $_divisa = ${_fxRate.toStringAsFixed(4)} EUR',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) {
        final rate = double.tryParse(v);
        if (rate != null) setState(() => _fxRate = rate);
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          if (!mounted) return;
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_date),
          );
          if (!mounted) return;
          setState(() {
            _date = DateTime(
              picked.year,
              picked.month,
              picked.day,
              time?.hour ?? _date.hour,
              time?.minute ?? _date.minute,
            );
            _dateTouchedManually = true;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha y hora',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(DateFormat('EEEE, d MMM yyyy HH:mm', 'es').format(_date)),
      ),
    );
  }

  Widget _buildCategoryField() {
    final options = [..._categories[_type]!];
    if (_category != null &&
        _category!.isNotEmpty &&
        !options.contains(_category)) {
      options.insert(0, _category!);
    }
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Categoría',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: const Text('Selecciona una categoria'),
      items:
          options
              .map(
                (cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(labelForCategory(cat)),
                ),
              )
              .toList(),
      onChanged:
          (v) => setState(() {
            _category = v;
            _subCategory = null;
            _setManualOverrideIfNeeded();
          }),
    );
  }

  Widget _buildSubCategoryField() {
    final subs = [...(_subCategories[_category] ?? <String>[])];
    if (_subCategory != null &&
        _subCategory!.isNotEmpty &&
        !subs.contains(_subCategory)) {
      subs.insert(0, _subCategory!);
    }
    if (subs.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<String>(
      initialValue: _subCategory,
      decoration: InputDecoration(
        labelText: 'Subcategoría',
        prefixIcon: const Icon(Icons.subdirectory_arrow_right),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: const Text('Opcional'),
      items:
          subs
              .map(
                (sub) => DropdownMenuItem(
                  value: sub,
                  child: Text(labelForSubCategory(sub)),
                ),
              )
              .toList(),
      onChanged:
          (v) => setState(() {
            _subCategory = v;
            _setManualOverrideIfNeeded();
          }),
    );
  }

  Widget _buildAccountField() {
    return TextFormField(
      initialValue: _accountId,
      decoration: InputDecoration(
        labelText: 'Cuenta/Metodo de pago',
        hintText: 'Ej: Tarjeta debito, Efectivo',
        prefixIcon: const Icon(Icons.account_balance_wallet),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (v) => _accountId = v.isEmpty ? null : v,
    );
  }

  Widget _buildRecurrenceField() {
    return DropdownButtonFormField<String>(
      initialValue: _recurrence,
      decoration: InputDecoration(
        labelText: 'Recurrencia',
        prefixIcon: const Icon(Icons.repeat),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          _recurrenceOptions.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
      onChanged: (v) => setState(() => _recurrence = v ?? 'once'),
    );
  }

  Widget _buildEnvelopeField() {
    return TextFormField(
      initialValue: _envelopeId,
      decoration: InputDecoration(
        labelText: 'Sobre',
        hintText: 'Ej: Vacaciones, Emergencias',
        prefixIcon: const Icon(Icons.folder_special),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: 'Asigna esta transacción a un sobre específico',
      ),
      onChanged: (v) => _envelopeId = v.isEmpty ? null : v,
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Etiquetas',
            hintText: 'Escribe y presiona Enter',
            prefixIcon: const Icon(Icons.label),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onFieldSubmitted: (v) {
            if (v.isNotEmpty && !_tags.contains(v)) {
              setState(() {
                _tags.add(v);
                _setManualOverrideIfNeeded();
              });
            }
          },
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted:
                            () => setState(() {
                              _tags.remove(tag);
                              _setManualOverrideIfNeeded();
                            }),
                      ),
                    )
                    .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildReceiptScanPanel() {
    final draft = _receiptDraft;
    final hasDraft = draft != null;
    final confidence = draft?.result.confidence;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed:
                  (_isScanningReceipt || _isSaving)
                      ? null
                      : _startReceiptScanFlow,
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Escanear ticket (IA)'),
            ),
            if (_isScanningReceipt) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              const Text('Analizando ticket…'),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _cancelReceiptScan,
                child: const Text('Cancelar'),
              ),
            ],
          ],
        ),
        if (hasDraft) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Ticket IA listo${confidence != null ? ' (${(confidence * 100).toStringAsFixed(0)}%)' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(draft.summary, style: Theme.of(context).textTheme.bodySmall),
              Text(
                _receiptDraftAppliedToForm
                    ? 'Aplicado al formulario'
                    : 'Pendiente de aplicar',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: _clearReceiptDraft,
                child: const Text('Quitar ticket'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAiAssistPanel() {
    final confidence = _pendingSuggestion?.confidence ?? _aiMeta?.confidence;
    final hasSuggestion = _pendingSuggestion != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _isClassifying ? null : _onAutoClassifyPressed,
                icon:
                    _isClassifying
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  _isClassifying ? 'Clasificando…' : 'Auto-clasificar',
                ),
              ),
              FilterChip(
                label: const Text('Auto'),
                selected: _autoClassifyEnabled,
                onSelected: (v) {
                  setState(() {
                    _autoClassifyEnabled = v;
                    if (!v) _cancelClassify();
                  });
                  unawaited(_persistAutoClassifyPreference(v));
                },
              ),
              if (_isClassifying)
                TextButton(
                  onPressed: _cancelClassify,
                  child: const Text('Cancelar'),
                ),
              if (hasSuggestion)
                Text(
                  'Sugerido por IA${confidence != null ? ' (${confidence.toStringAsFixed(2)})' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              if (hasSuggestion)
                FilledButton.tonal(
                  onPressed: _applyPendingSuggestion,
                  child: const Text('Aplicar'),
                ),
              if (_manualOverride)
                const Text(
                  'Manual override',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _clearReceiptDraft() {
    setState(() {
      _receiptDraft = null;
      _receiptDraftAppliedToForm = false;
      if (_aiMeta?.source == 'receipt_scan') {
        _aiMeta = null;
        _manualOverride = false;
      }
    });
  }

  void _cancelReceiptScan() {
    if (!_isScanningReceipt) return;
    setState(() {
      _activeReceiptScanSeq = null;
      _isScanningReceipt = false;
    });
    if (kDebugMode) {
      debugPrint('[FinanceReceiptAI] analysis cancelled by user');
    }
  }

  Future<void> _startReceiptScanFlow() async {
    final file = await _pickImageForReceipt();
    if (file == null || !mounted) return;

    final seq = ++_receiptScanSeq;

    try {
      setState(() {
        _isScanningReceipt = true;
        _activeReceiptScanSeq = seq;
      });

      final result = await _receiptAiService.scanFromImage(file);

      if (!mounted || _activeReceiptScanSeq != seq) return;
      setState(() {
        _isScanningReceipt = false;
        _activeReceiptScanSeq = null;
      });
      await _showReceiptAiPreview(result);
    } catch (error) {
      if (!mounted || _activeReceiptScanSeq != seq) return;
      setState(() {
        _isScanningReceipt = false;
        _activeReceiptScanSeq = null;
      });
      final message =
          error is FinanceReceiptAiException
              ? error.message
              : 'No se pudo analizar el ticket. Puedes continuar en modo manual.';
      if (kDebugMode) {
        debugPrint('[FinanceReceiptAI] scan error message=$message');
      }
      FocusFeedback.showError(context, message);
    }
  }

  Future<XFile?> _pickImageForReceipt() async {
    final picker = ImagePicker();
    try {
      if (kIsWeb) {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
          allowMultiple: false,
        );
        final files = picked?.files;
        if (files == null || files.isEmpty) return null;
        final file = files.first;
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          FocusFeedback.showError(
            context,
            'No se pudo leer la imagen seleccionada.',
          );
          return null;
        }
        return XFile.fromData(
          bytes,
          name: file.name,
          mimeType:
              file.extension != null
                  ? 'image/${file.extension!.toLowerCase()}'
                  : null,
        );
      }

      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Cámara'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galería'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return null;
      return picker.pickImage(source: source);
    } catch (_) {
      if (!mounted) return null;
      FocusFeedback.showError(
        context,
        'No se pudo abrir el selector de imágenes.',
      );
      return null;
    }
  }

  Future<void> _showReceiptAiPreview(FinanceReceiptAiResult result) async {
    if (!mounted) return;
    final hostContext = context;

    await showDialog<void>(
      context: hostContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        var applyToForm = true;
        var confirming = false;
        var showItems = false;

        return StatefulBuilder(
          builder: (_, setStateSheet) {
            Future<void> onConfirm() async {
              if (confirming) return;
              setStateSheet(() => confirming = true);

              final draft = _ReceiptScanDraft.fromResult(result);

              if (!mounted) return;
              setState(() {
                _receiptDraft = draft;
                _receiptDraftAppliedToForm = applyToForm;
                _aiMeta = draft.toMeta(manualOverride: false);
                _manualOverride = false;
                _pendingSuggestion = null;
                if (applyToForm) {
                  _applyReceiptDraftToForm(draft);
                }
              });

              if (kDebugMode) {
                debugPrint(
                  '[FinanceReceiptAI] preview confirmed applyToForm=$applyToForm merchant=${result.merchant ?? 'null'} total=${result.total?.toStringAsFixed(2) ?? 'null'}',
                );
              }

              if (dialogContext.mounted &&
                  Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }

              if (!mounted) return;
              FocusFeedback.showSuccess(
                hostContext,
                applyToForm
                    ? 'Datos del ticket aplicados al formulario.'
                    : 'Ticket analizado. Puedes seguir en modo manual.',
              );
            }

            final totalText =
                result.total == null
                    ? 'Sin total'
                    : '${result.total!.toStringAsFixed(2)} ${result.currency ?? _divisa}';
            final dateText = result.dateISO ?? 'No detectada';

            return AlertDialog(
              title: const Text('Escanear ticket (IA)'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.storefront_outlined),
                        title: const Text('Comercio'),
                        subtitle: Text(result.merchant ?? 'No detectado'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.payments_outlined),
                        title: const Text('Total'),
                        subtitle: Text(totalText),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Fecha'),
                        subtitle: Text(dateText),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.insights_outlined),
                        title: const Text('Modelo y confianza'),
                        subtitle: Text(
                          '${result.model} · ${(result.confidence * 100).toStringAsFixed(0)}%',
                        ),
                      ),
                      if (result.items.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text('Items (${result.items.length})'),
                          initiallyExpanded: showItems,
                          onExpansionChanged: (v) {
                            setStateSheet(() => showItems = v);
                          },
                          children:
                              result.items
                                  .map(
                                    (item) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(item.name),
                                      subtitle: Text(
                                        'Cantidad ${item.qty.toStringAsFixed(2)}',
                                      ),
                                      trailing: Text(
                                        '${item.price.toStringAsFixed(2)} ${result.currency ?? _divisa}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: applyToForm,
                        onChanged:
                            confirming
                                ? null
                                : (value) =>
                                    setStateSheet(() => applyToForm = value),
                        title: const Text('Aplicar a formulario'),
                        subtitle: const Text(
                          'Rellena importe/fecha/comercio y categoría sugerida, sin guardar automáticamente.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed:
                      confirming
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: confirming ? null : onConfirm,
                  child: Text(confirming ? 'Aplicando…' : 'Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyReceiptDraftToForm(_ReceiptScanDraft draft) {
    final result = draft.result;
    final merchant = result.merchant;
    final suggestedCategory = _suggestExpenseCategoryFromMerchant(merchant);

    _type = TxType.expense;

    if (result.total != null) {
      _amountCtrl.text = result.total!.toStringAsFixed(2);
    }

    if (merchant != null && merchant.isNotEmpty) {
      _titleCtrl.text = merchant;
      final notes = _notesCtrl.text.trim();
      final merchantNote = 'Comercio: $merchant';
      if (notes.isEmpty) {
        _notesCtrl.text = merchantNote;
      } else if (!notes.toLowerCase().contains(merchant.toLowerCase())) {
        _notesCtrl.text = '$notes · $merchantNote';
      }
    } else if (_titleCtrl.text.trim().isEmpty) {
      _titleCtrl.text = 'Ticket escaneado';
    }

    final parsedDate = result.parsedDate;
    if (parsedDate != null) {
      _date = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        12,
        0,
      );
      _dateTouchedManually = false;
    }

    _category = suggestedCategory;
    _subCategory =
        suggestedCategory == 'alimentacion' ? 'supermercado' : 'otros';

    if (result.currency != null && result.currency!.isNotEmpty) {
      _divisa = result.currency!;
      if (_divisa == 'EUR') {
        _fxRate = 1.0;
      }
    }
  }

  static const Set<String> _supermarketHints = {
    'mercadona',
    'carrefour',
    'lidl',
    'aldi',
    'dia',
    'eroski',
    'ahorramas',
  };

  String _suggestExpenseCategoryFromMerchant(String? merchant) {
    if (merchant == null || merchant.trim().isEmpty) return 'otros_gastos';
    final lower = merchant.toLowerCase();
    for (final hint in _supermarketHints) {
      if (lower.contains(hint)) return 'alimentacion';
    }
    return 'otros_gastos';
  }

  void _onInputChanged() {
    if (!_aiDebounceWhileTyping || !_autoClassifyEnabled) return;
    _classifyDebounce?.cancel();
    _classifyDebounce = Timer(const Duration(milliseconds: _aiDebounceMs), () {
      unawaited(_runClassification(manualRequest: false, forSave: false));
    });
  }

  void _cancelClassify() {
    _classifyDebounce?.cancel();
    _classifyRequestSeq += 1;
    if (mounted) {
      setState(() {
        _isClassifying = false;
      });
    }
  }

  void _onAutoClassifyPressed() {
    _forceReclassifyOnSave = true;
    unawaited(_runClassification(manualRequest: true, forSave: false));
  }

  void _setManualOverrideIfNeeded() {
    if (_aiMeta == null && _pendingSuggestion == null) return;
    _manualOverride = true;
    if (_aiMeta != null) {
      _aiMeta = _aiMeta!.copyWith(manualOverride: true);
    }
  }

  String _buildClassificationText() {
    final parts = <String>[
      _titleCtrl.text.trim(),
      if (_accountId != null && _accountId!.trim().isNotEmpty)
        _accountId!.trim(),
      if (_amountCtrl.text.trim().isNotEmpty) _amountCtrl.text.trim(),
      _divisa,
      if (_notesCtrl.text.trim().isNotEmpty) _notesCtrl.text.trim(),
    ];
    return parts.where((e) => e.isNotEmpty).join(' ').trim();
  }

  String _classificationInputHash(String value) {
    final normalized = value.trim().toLowerCase();
    final bytes = utf8.encode(normalized);
    var hash = 2166136261;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  bool _hasRecentSameHash(String inputHash) {
    final meta = _aiMeta;
    if (meta == null ||
        meta.inputHash != inputHash ||
        meta.classifiedAt == null) {
      return false;
    }
    return DateTime.now().difference(meta.classifiedAt!).abs() <=
        _aiRecentWindow;
  }

  bool _missingClassificationFields() {
    return (_category == null || _category!.trim().isEmpty) ||
        (_subCategory == null || _subCategory!.trim().isEmpty) ||
        _tags.isEmpty;
  }

  Future<void> _runClassification({
    required bool manualRequest,
    required bool forSave,
  }) async {
    final text = _buildClassificationText();
    if (text.isEmpty) {
      if (manualRequest && mounted) {
        FocusFeedback.showError(
          context,
          'Completa título/importe para clasificar',
        );
      }
      return;
    }

    final inputHash = _classificationInputHash(text);
    if (!manualRequest && _hasRecentSameHash(inputHash)) {
      return;
    }

    final seq = ++_classifyRequestSeq;
    if (mounted) {
      setState(() {
        _isClassifying = true;
      });
    }

    try {
      final result = await _ai.classifyFinance(text: text);
      if (!mounted || seq != _classifyRequestSeq) return;

      final suggestion = _AiSuggestion.fromResponse(result, inputHash);
      setState(() {
        _pendingSuggestion = suggestion;
        _isClassifying = false;
      });

      final shouldApplyNow =
          forSave &&
          (!_manualOverride &&
              (_missingClassificationFields() || manualRequest));
      if (shouldApplyNow) {
        _applyPendingSuggestion();
      }
    } catch (e) {
      if (!mounted || seq != _classifyRequestSeq) return;
      setState(() {
        _isClassifying = false;
      });
      if (manualRequest || forSave) {
        FocusFeedback.showError(context, 'No se pudo auto-clasificar');
      }
    }
  }

  void _applyPendingSuggestion() {
    final suggestion = _pendingSuggestion;
    if (suggestion == null) return;
    setState(() {
      _category = suggestion.category;
      _subCategory = suggestion.subCategory;
      _tags = suggestion.tags;
      _aiMeta = suggestion.toMeta(manualOverride: false);
      _pendingSuggestion = null;
      _manualOverride = false;
    });
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

    setState(() => _isSaving = true);

    try {
      final hasReceiptDraft =
          _receiptDraft != null || _aiMeta?.source == 'receipt_scan';
      final shouldRunAi =
          _autoClassifyEnabled &&
          (_forceReclassifyOnSave || _missingClassificationFields()) &&
          _aiClassifyOnSave &&
          !hasReceiptDraft;
      if (shouldRunAi) {
        await _runClassification(
          manualRequest: _forceReclassifyOnSave,
          forSave: true,
        );
      }

      final receiptResult = _receiptDraft?.result;
      final inferredCategory =
          (_type == TxType.expense)
              ? _suggestExpenseCategoryFromMerchant(receiptResult?.merchant)
              : null;
      final effectiveCategory =
          (_category == null || _category!.trim().isEmpty)
              ? inferredCategory
              : _category;
      final effectiveSubCategory =
          (_subCategory == null || _subCategory!.trim().isEmpty)
              ? (effectiveCategory == 'alimentacion' ? 'supermercado' : 'otros')
              : _subCategory;

      DateTime effectiveDate = _date;
      if (!_dateTouchedManually && receiptResult != null) {
        final parsed = receiptResult.parsedDate;
        effectiveDate =
            parsed == null
                ? DateTime.now()
                : DateTime(parsed.year, parsed.month, parsed.day, 12, 0);
      }

      String? effectiveNotes =
          _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim();
      final merchant = receiptResult?.merchant;
      if (merchant != null && merchant.isNotEmpty) {
        final merchantTag = 'Comercio: $merchant';
        if (effectiveNotes == null || effectiveNotes.isEmpty) {
          effectiveNotes = merchantTag;
        } else if (!effectiveNotes.toLowerCase().contains(
          merchant.toLowerCase(),
        )) {
          effectiveNotes = '$effectiveNotes · $merchantTag';
        }
      }

      final effectiveAiMeta =
          _manualOverride && _aiMeta != null
              ? _aiMeta!.copyWith(manualOverride: true)
              : _aiMeta;

      final tx = FinanceTransaction(
        id: widget.transaction?.id ?? '',
        userId: widget.transaction?.userId ?? '',
        date: effectiveDate,
        type: _type,
        title: _titleCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text),
        category: effectiveCategory,
        subCategory: effectiveSubCategory,
        accountId: _accountId,
        notes: effectiveNotes,
        tags: _tags,
        originalCurrency: _divisa != 'EUR' ? _divisa : null,
        fxRate: _divisa != 'EUR' ? _fxRate : null,
        recurrence: _recurrence != 'once' ? _recurrence : null,
        envelopeId: _envelopeId,
        relatedTxId: null,
        aiMeta: effectiveAiMeta,
      );

      String? createdDocId;
      if (widget.transaction == null) {
        createdDocId = await TransactionService.I.createAndReturnId(tx);
      } else {
        await TransactionService.I.update(tx);
        createdDocId = widget.transaction!.id;
      }

      if (kDebugMode) {
        debugPrint(
          '[FinanceReceiptAI] saved tx docId=${createdDocId ?? 'null'}',
        );
      }

      _forceReclassifyOnSave = false;
      if (mounted) {
        Navigator.pop(context, true);
        FocusFeedback.showSuccess(
          context,
          widget.transaction == null
              ? 'Transacción creada'
              : 'Transacción actualizada',
        );
      }
    } catch (e) {
      if (mounted) {
        FocusFeedback.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _classifyDebounce?.cancel();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}

class _ReceiptScanDraft {
  const _ReceiptScanDraft({required this.result, required this.classifiedAt});

  final FinanceReceiptAiResult result;
  final DateTime classifiedAt;

  String get summary {
    final merchant = result.merchant;
    final amount = result.total;
    if (merchant == null || merchant.isEmpty || amount == null) {
      return 'Revisa y guarda manualmente';
    }
    final currency = result.currency ?? 'EUR';
    return '$merchant · ${amount.toStringAsFixed(2)} $currency';
  }

  static _ReceiptScanDraft fromResult(FinanceReceiptAiResult result) {
    return _ReceiptScanDraft(result: result, classifiedAt: DateTime.now());
  }

  FinanceAiMeta toMeta({required bool manualOverride}) {
    final merchant = result.merchant ?? 'comercio_no_detectado';
    final amount = result.total?.toStringAsFixed(2) ?? 'total_no_detectado';
    final currency = result.currency ?? 'EUR';
    final baseShort = 'Ticket $merchant · $amount $currency'.trim();
    final short =
        baseShort.length <= 120 ? baseShort : baseShort.substring(0, 120);

    return FinanceAiMeta(
      source: 'receipt_scan',
      model: result.model,
      confidence: result.confidence,
      reasoningShort: short,
      classifiedAt: classifiedAt,
      inputHash: result.inputHash,
      manualOverride: manualOverride,
    );
  }
}

class _AiSuggestion {
  const _AiSuggestion({
    required this.category,
    required this.subCategory,
    required this.tags,
    required this.model,
    required this.confidence,
    required this.reasoningShort,
    required this.inputHash,
    required this.classifiedAt,
  });

  final String category;
  final String? subCategory;
  final List<String> tags;
  final String? model;
  final double? confidence;
  final String? reasoningShort;
  final String inputHash;
  final DateTime classifiedAt;

  static _AiSuggestion fromResponse(
    Map<String, dynamic> raw,
    String inputHash,
  ) {
    final normalized = FinanceAiNormalizer.normalize(raw);
    return _AiSuggestion(
      category: normalized.category,
      subCategory: normalized.subCategory,
      tags: normalized.tags,
      model: raw['model']?.toString(),
      confidence: (raw['confidence'] as num?)?.toDouble(),
      reasoningShort:
          raw['reasoning_short']?.toString() ??
          raw['reasoningShort']?.toString(),
      inputHash: inputHash,
      classifiedAt: DateTime.now(),
    );
  }

  FinanceAiMeta toMeta({required bool manualOverride}) {
    return FinanceAiMeta(
      source: 'openai',
      model: model,
      confidence: confidence,
      reasoningShort: reasoningShort,
      classifiedAt: classifiedAt,
      inputHash: inputHash,
      manualOverride: manualOverride,
    );
  }
}
