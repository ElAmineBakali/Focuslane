import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/screens/finance/models/loan_model.dart';
import 'package:focuslane/screens/finance/services/debt_service_loans.dart';

import '../../widgets/finance_shell.dart';
import '../../../../design/ui/components/focus_card.dart';
import '../../../../design/ui/feedback/focus_feedback.dart';

class DebtFormScreen extends StatefulWidget {
  const DebtFormScreen({super.key, this.debt});
  static const route = '/finance/debts/form';
  final Debt? debt;

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _creditorCtrl = TextEditingController();
  final _originalAmountCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late DateTime _startDate;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    if (d != null) {
      _nameCtrl.text = d.name;
      _creditorCtrl.text = d.creditor;
      _originalAmountCtrl.text = d.originalAmount.toStringAsFixed(2);
      _interestRateCtrl.text = d.interestRate?.toStringAsFixed(2) ?? '';
      _startDate = d.startDate;
      _dueDate = d.dueDate;
      _notesCtrl.text = d.notes ?? '';
    } else {
      _startDate = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.debt == null ? 'Nueva deuda' : 'Editar deuda';

    return FinanceShell(
      selectedIndex: 5,
      title: 'Finanzas',
      subtitle: subtitle,
      actions: widget.debt != null
          ? [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: _showLedger,
                tooltip: 'Ver pagos',
              ),
            ]
          : null,
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
                  child: FocusCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildCreditorField(),
                        const SizedBox(height: 16),
                        _buildOriginalAmountField(),
                        const SizedBox(height: 16),
                        _buildInterestRateField(),
                        const SizedBox(height: 16),
                        _buildStartDateField(),
                        const SizedBox(height: 16),
                        _buildDueDateField(),
                        const SizedBox(height: 16),
                        _buildNotesField(),
                        if (widget.debt != null) ...[
                          const SizedBox(height: 24),
                          _buildPaymentSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: InputDecoration(
        labelText: 'Nombre *',
        hintText: 'Ej: Prestamo personal',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
    );
  }

  Widget _buildCreditorField() {
    return TextFormField(
      controller: _creditorCtrl,
      decoration: InputDecoration(
        labelText: 'Acreedor *',
        hintText: 'Ej: Banco Santander',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
    );
  }

  Widget _buildOriginalAmountField() {
    return TextFormField(
      controller: _originalAmountCtrl,
      decoration: InputDecoration(
        labelText: 'Importe original *',
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
        if (amount == null || amount <= 0) return 'Importe invalido';
        return null;
      },
    );
  }

  Widget _buildInterestRateField() {
    return TextFormField(
      controller: _interestRateCtrl,
      decoration: InputDecoration(
        labelText: 'Tasa de interes',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.percent),
        suffixText: '%',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: 'Opcional - Tasa anual',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
    );
  }

  Widget _buildStartDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _startDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de inicio',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(DateFormat('d MMMM yyyy', 'es').format(_startDate)),
      ),
    );
  }

  Widget _buildDueDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 365)),
          firstDate: _startDate,
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => _dueDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de vencimiento',
          prefixIcon: const Icon(Icons.event),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          helperText: 'Opcional',
        ),
        child: Text(
          _dueDate != null
              ? DateFormat('d MMMM yyyy', 'es').format(_dueDate!)
              : 'Sin fecha limite',
        ),
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

  Widget _buildPaymentSection() {
    final debt = widget.debt!;
    final cs = Theme.of(context).colorScheme;
    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Balance actual'),
              Text(
                '${debt.balance.toStringAsFixed(2)} EUR',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addPayment,
              icon: const Icon(Icons.add),
              label: const Text('Registrar pago'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPayment() async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime date = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Importe',
                  suffixText: 'EUR',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: widget.debt!.startDate,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(DateFormat('d MMM yyyy').format(date)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notas',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result == true && amountCtrl.text.isNotEmpty) {
      final amount = double.tryParse(amountCtrl.text);
      if (amount != null && amount > 0) {
        final payment = DebtPayment(
          date: date,
          amount: amount,
          notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
        );
        await DebtService.I.addPayment(widget.debt!.id, payment);
        if (mounted) {
          FocusFeedback.showSuccess(context, 'Pago registrado');
          Navigator.pop(context);
        }
      }
    }
  }

  void _showLedger() {
    final debt = widget.debt!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => FocusCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text('Historial de pagos', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Expanded(
                child: debt.ledger.isEmpty
                    ? const Center(child: Text('Sin pagos registrados'))
                    : ListView.builder(
                        controller: controller,
                        itemCount: debt.ledger.length,
                        itemBuilder: (context, i) {
                          final p = debt.ledger[i];
                          return ListTile(
                            leading: const Icon(Icons.payment),
                            title: Text('${p.amount.toStringAsFixed(2)} EUR'),
                            subtitle: Text(DateFormat('d MMM yyyy').format(p.date)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final debt = Debt(
      id: widget.debt?.id ?? '',
      userId: widget.debt?.userId ?? '',
      name: _nameCtrl.text.trim(),
      creditor: _creditorCtrl.text.trim(),
      originalAmount: double.parse(_originalAmountCtrl.text),
      balance: widget.debt?.balance ?? double.parse(_originalAmountCtrl.text),
      interestRate: _interestRateCtrl.text.isEmpty
          ? null
          : double.tryParse(_interestRateCtrl.text),
      startDate: _startDate,
      dueDate: _dueDate,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
      ledger: widget.debt?.ledger ?? [],
    );

    try {
      if (widget.debt == null) {
        await DebtService.I.create(debt);
      } else {
        await DebtService.I.update(debt);
      }
      if (mounted) {
        Navigator.pop(context, true);
        FocusFeedback.showSuccess(
          context,
          widget.debt == null ? 'Deuda creada' : 'Deuda actualizada',
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
    _creditorCtrl.dispose();
    _originalAmountCtrl.dispose();
    _interestRateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}


