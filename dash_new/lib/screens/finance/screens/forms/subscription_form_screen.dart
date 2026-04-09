import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/screens/finance/models/subscription_model.dart';
import 'package:focuslane/screens/finance/services/subscription_service.dart';

import '../../widgets/finance_shell.dart';
import '../../../../design/ui/components/focus_card.dart';
import '../../../../design/ui/feedback/focus_feedback.dart';

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
    final subtitle = widget.subscription == null
      ? 'Nueva suscripción'
      : 'Editar suscripción';

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
                  child: FocusCard(
                    padding: const EdgeInsets.all(16),
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
        hintText: 'Ej: Netflix, Spotify',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountCtrl,
      decoration: InputDecoration(
        labelText: 'Importe *',
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

  Widget _buildFrequencyField() {
    return DropdownButtonFormField<String>(
      initialValue: _frequency,
      decoration: InputDecoration(
        labelText: 'Frecuencia *',
        prefixIcon: const Icon(Icons.repeat),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _frequencies.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => setState(() => _frequency = v ?? 'monthly'),
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
        if (picked != null) setState(() => _nextPaymentDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Proximo pago',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(DateFormat('EEEE, d MMM yyyy', 'es').format(_nextPaymentDate)),
      ),
    );
  }

  Widget _buildActiveSwitch() {
    return FocusCard(
      padding: const EdgeInsets.all(8),
      child: SwitchListTile(
        title: const Text('Suscripcion activa'),
        subtitle: Text(
          _isActive ? 'Generando pagos recurrentes' : 'No se generaran pagos',
        ),
        value: _isActive,
        onChanged: (v) => setState(() => _isActive = v),
      ),
    );
  }

  Widget _buildReminderSection() {
    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Recordatorio'),
            subtitle: Text(
              _reminderEnabled ? 'Recibiras notificaciones' : 'Sin recordatorios',
            ),
            value: _reminderEnabled,
            onChanged: (v) => setState(() => _reminderEnabled = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_reminderEnabled) ...[
            const SizedBox(height: 12),
            const Text('Dias de anticipacion'),
            const SizedBox(height: 8),
            Slider(
              value: _reminderDays.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$_reminderDays dias',
              onChanged: (v) => setState(() => _reminderDays = v.toInt()),
            ),
            Center(child: Text('$_reminderDays dias antes')),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoMarkSwitch() {
    return FocusCard(
      padding: const EdgeInsets.all(8),
      child: SwitchListTile(
        title: const Text('Auto-marcar como pagado'),
        subtitle: Text(
          _autoMarkAsPaid
              ? 'Creara transaccion automaticamente en la fecha'
              : 'Deberas crear la transaccion manualmente',
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
        Navigator.pop(context, true);
        FocusFeedback.showSuccess(
          context,
          widget.subscription == null
              ? 'Suscripcion creada'
              : 'Suscripcion actualizada',
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
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}


