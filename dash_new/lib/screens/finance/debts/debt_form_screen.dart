import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/loan_model.dart';
import 'package:mi_dashboard_personal/services/finance/debt_service_loans.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          FinanceUI.sliverAppBar(
            context,
            title: widget.debt == null ? 'Nueva Deuda' : 'Editar Deuda',
            backgroundIcon: Icons.account_balance_wallet,
            actions: widget.debt != null
                ? [
                    IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: _showLedger,
                      tooltip: 'Ver pagos',
                    ),
                  ]
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Form(
                key: _formKey,
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: Text('Guardar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: InputDecoration(
        labelText: 'Nombre *',
        hintText: 'Ej: Préstamo personal',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildCreditorField() {
    return TextFormField(
      controller: _creditorCtrl,
      decoration: InputDecoration(
        labelText: 'Acreedor *',
        hintText: 'Ej: Banco Santander, Juan Pérez',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildOriginalAmountField() {
    return TextFormField(
      controller: _originalAmountCtrl,
      decoration: InputDecoration(
        labelText: 'Importe original *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.euro),
        suffixText: '€',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final amount = double.tryParse(v);
        if (amount == null || amount <= 0) return 'Importe inválido';
        return null;
      },
      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildInterestRateField() {
    return TextFormField(
      controller: _interestRateCtrl,
      decoration: InputDecoration(
        labelText: 'Tasa de interés',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.percent),
        suffixText: '%',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: 'Opcional - Tasa anual',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
      style: GoogleFonts.poppins(),
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
        child: Text(
          DateFormat('d MMMM yyyy', 'es').format(_startDate),
          style: GoogleFonts.poppins(),
        ),
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
              : 'Sin fecha límite',
          style: GoogleFonts.poppins(),
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
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildPaymentSection() {
    final debt = widget.debt!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance actual',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '${debt.balance.toStringAsFixed(2)}€',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: FinanceUI.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addPayment,
                icon: const Icon(Icons.add),
                label: const Text('Registrar pago'),
              ),
            ),
          ],
        ),
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
          title: Text('Registrar pago', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Importe',
                  suffixText: '€',
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pago registrado', style: GoogleFonts.poppins())),
          );
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
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Historial de pagos',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: debt.ledger.isEmpty
                    ? Center(
                        child: Text(
                          'No hay pagos registrados',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: debt.ledger.length,
                        itemBuilder: (_, i) {
                          final payment = debt.ledger[debt.ledger.length - 1 - i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: FinanceUI.income.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.payment, color: FinanceUI.income),
                              ),
                              title: Text(
                                '${payment.amount.toStringAsFixed(2)}€',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DateFormat('d MMM yyyy').format(payment.date)),
                                  if (payment.notes != null)
                                    Text(
                                      payment.notes!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
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
      interestRate: _interestRateCtrl.text.isEmpty ? null : double.parse(_interestRateCtrl.text),
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.debt == null ? 'Deuda creada' : 'Deuda actualizada',
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
    _creditorCtrl.dispose();
    _originalAmountCtrl.dispose();
    _interestRateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
