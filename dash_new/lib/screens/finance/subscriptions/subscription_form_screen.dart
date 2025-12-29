import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/subscription_model.dart';
import 'package:mi_dashboard_personal/services/finance/subscription_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SubscriptionFormScreen extends StatefulWidget {
  const SubscriptionFormScreen({super.key, this.subscription});
  static const route = '/finance/subscriptions/form';
  final Subscription? subscription;

  @override
  State<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends State<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late String _frequency;
  late DateTime _nextPaymentDate;
  bool _isActive = true;
  bool _reminderEnabled = true;
  int _reminderDays = 3;
  bool _autoMarkAsPaid = true;

  final _frequencies = {
    'daily': 'Diario',
    'weekly': 'Semanal',
    'monthly': 'Mensual',
    'yearly': 'Anual',
  };

  @override
  void initState() {
    super.initState();
    final s = widget.subscription;
    if (s != null) {
      _nameCtrl.text = s.name;
      _amountCtrl.text = s.amount.toStringAsFixed(2);
      _frequency = s.frequency;
      _nextPaymentDate = s.nextPaymentDate;
      _isActive = s.isActive;
      _reminderEnabled = s.reminderEnabled;
      _reminderDays = s.reminderDays;
      _autoMarkAsPaid = s.autoMarkAsPaid;
      _notesCtrl.text = s.notes ?? '';
    } else {
      _frequency = 'monthly';
      _nextPaymentDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          FinanceUI.sliverAppBar(
            context,
            title: widget.subscription == null ? 'Nueva Suscripción' : 'Editar Suscripción',
            backgroundIcon: Icons.repeat,
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    _buildFrequencyField(),
                    const SizedBox(height: 16),
                    _buildNextPaymentField(),
                    const SizedBox(height: 16),
                    _buildActiveSwitch(),
                    const SizedBox(height: 16),
                    _buildReminderSection(),
                    const SizedBox(height: 16),
                    _buildAutoMarkSwitch(),
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

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: InputDecoration(
        labelText: 'Nombre *',
        hintText: 'Ej: Netflix, Spotify',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountCtrl,
      decoration: InputDecoration(
        labelText: 'Importe *',
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

  Widget _buildFrequencyField() {
    return DropdownButtonFormField<String>(
      value: _frequency,
      decoration: InputDecoration(
        labelText: 'Frecuencia *',
        prefixIcon: const Icon(Icons.repeat),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _frequencies.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => setState(() => _frequency = v!),
    );
  }

  Widget _buildNextPaymentField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _nextPaymentDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _nextPaymentDate = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Próximo pago',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          DateFormat('EEEE, d MMM yyyy', 'es').format(_nextPaymentDate),
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  Widget _buildActiveSwitch() {
    return Card(
      child: SwitchListTile(
        title: Text('Suscripción activa', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(
          _isActive ? 'Generando pagos recurrentes' : 'No se generarán pagos',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        value: _isActive,
        onChanged: (v) => setState(() => _isActive = v),
      ),
    );
  }

  Widget _buildReminderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('Recordatorio', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _reminderEnabled ? 'Recibirás notificaciones' : 'Sin recordatorios',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              value: _reminderEnabled,
              onChanged: (v) => setState(() => _reminderEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 12),
              Text(
                'Días de anticipación',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _reminderDays.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: '$_reminderDays días',
                onChanged: (v) => setState(() => _reminderDays = v.toInt()),
              ),
              Center(
                child: Text(
                  '$_reminderDays días antes',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAutoMarkSwitch() {
    return Card(
      child: SwitchListTile(
        title: Text('Auto-marcar como pagado', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(
          _autoMarkAsPaid
              ? 'Creará transacción automáticamente en la fecha'
              : 'Deberás crear la transacción manualmente',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        value: _autoMarkAsPaid,
        onChanged: (v) => setState(() => _autoMarkAsPaid = v),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final sub = Subscription(
      id: widget.subscription?.id ?? '',
      userId: widget.subscription?.userId ?? '',
      name: _nameCtrl.text.trim(),
      title: _nameCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
      category: 'General',
      frequency: _frequency,
      nextPaymentDate: _nextPaymentDate,
      nextDue: _nextPaymentDate,
      reminderDays: _reminderDays,
      remindDaysBefore: _reminderDays,
      reminderEnabled: _reminderEnabled,
      autoMarkAsPaid: _autoMarkAsPaid,
      autoMark: _autoMarkAsPaid,
      isActive: _isActive,
      active: _isActive,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      if (widget.subscription == null) {
        await SubscriptionService.I.create(sub);
        if (_reminderEnabled) {
          await SubscriptionService.I.scheduleAllReminders();
        }
      } else {
        await SubscriptionService.I.update(sub);
        if (_reminderEnabled) {
          await SubscriptionService.I.scheduleAllReminders();
        }
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.subscription == null ? 'Suscripción creada' : 'Suscripción actualizada',
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
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
