import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:mi_dashboard_personal/screens/finance/models/transaction_model.dart';
import 'package:mi_dashboard_personal/screens/finance/services/transaction_service.dart';

import '../../widgets/finance_shell.dart';
import '../../../../ui/components/focus_card.dart';
import '../../../../ui/feedback/focus_feedback.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.transaction});
  static const route = '/finance/transactions/form';
  final FinanceTransaction? transaction;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

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

  final _categories = {
    TxType.income: ['Salario', 'Freelance', 'Inversiones', 'Otros Ingresos'],
    TxType.expense: [
      'Alimentacion',
      'Transporte',
      'Vivienda',
      'Ocio',
      'Salud',
      'Educacion',
      'Compras',
      'Otros Gastos',
    ],
  };

  final _subCategories = {
    'Alimentacion': ['Supermercado', 'Restaurantes', 'Delivery'],
    'Transporte': [
      'Gasolina',
      'Transporte Publico',
      'Taxi/Uber',
      'Mantenimiento',
    ],
    'Vivienda': [
      'Alquiler',
      'Hipoteca',
      'Electricidad',
      'Agua',
      'Internet',
      'Reparaciones',
    ],
    'Ocio': ['Cine', 'Conciertos', 'Viajes', 'Hobbies', 'Streaming'],
    'Salud': ['Medico', 'Farmacia', 'Gimnasio', 'Seguros'],
    'Educacion': ['Cursos', 'Libros', 'Material'],
    'Compras': ['Ropa', 'Tecnologia', 'Hogar'],
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
    } else {
      _type = TxType.expense;
      _date = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.transaction == null
      ? 'Nueva transacción'
      : 'Editar transacción';

    return FinanceShell(
      selectedIndex: 1,
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
            'Tipo de transaccion',
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
                        color: _type == TxType.income
                            ? cs.onPrimary
                            : cs.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('Ingreso'),
                    ],
                  ),
                  selected: _type == TxType.income,
                  onSelected: (_) => setState(() {
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
                        color: _type == TxType.expense
                            ? cs.onError
                            : cs.error,
                      ),
                      const SizedBox(width: 8),
                      const Text('Gasto'),
                    ],
                  ),
                  selected: _type == TxType.expense,
                  onSelected: (_) => setState(() {
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              final amount = double.tryParse(v);
              if (amount == null || amount <= 0) return 'Importe invalido';
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _divisas
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
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_date),
          );
          setState(() {
            _date = DateTime(
              picked.year,
              picked.month,
              picked.day,
              time?.hour ?? _date.hour,
              time?.minute ?? _date.minute,
            );
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
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Categoria *',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: const Text('Selecciona una categoria'),
      items: _categories[_type]!
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (v) => setState(() {
        _category = v;
        _subCategory = null;
      }),
      validator: (v) => v == null ? 'Requerido' : null,
    );
  }

  Widget _buildSubCategoryField() {
    final subs = _subCategories[_category] ?? [];
    if (subs.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<String>(
      initialValue: _subCategory,
      decoration: InputDecoration(
        labelText: 'Subcategoria',
        prefixIcon: const Icon(Icons.subdirectory_arrow_right),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: const Text('Opcional'),
      items: subs
          .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
          .toList(),
      onChanged: (v) => setState(() => _subCategory = v),
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
      items: _recurrenceOptions.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => setState(() => _recurrence = v ?? 'once'),
    );
  }

  Widget _buildEnvelopeField() {
    return TextFormField(
      initialValue: _envelopeId,
      decoration: InputDecoration(
        labelText: 'Sobre (Envelope Budgeting)',
        hintText: 'Ej: Vacaciones, Emergencias',
        prefixIcon: const Icon(Icons.folder_special),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: 'Asigna esta transaccion a un sobre especifico',
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
              setState(() => _tags.add(v));
            }
          },
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map((tag) => Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    ))
                .toList(),
          ),
        ],
      ],
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

    final tx = FinanceTransaction(
      id: widget.transaction?.id ?? '',
      userId: widget.transaction?.userId ?? '',
      date: _date,
      type: _type,
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
      category: _category,
      subCategory: _subCategory,
      accountId: _accountId,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
      tags: _tags,
      originalCurrency: _divisa != 'EUR' ? _divisa : null,
      fxRate: _divisa != 'EUR' ? _fxRate : null,
      recurrence: _recurrence != 'once' ? _recurrence : null,
      envelopeId: _envelopeId,
      relatedTxId: null,
    );

    try {
      if (widget.transaction == null) {
        await TransactionService.I.create(tx);
      } else {
        await TransactionService.I.update(tx);
      }
      if (mounted) {
        Navigator.pop(context, true);
        FocusFeedback.showSuccess(
          context,
          widget.transaction == null
              ? 'Transaccion creada'
              : 'Transaccion actualizada',
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
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
