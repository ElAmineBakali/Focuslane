// lib/screens/finance/deposits/deposit_movement_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class DepositMovementEditScreen extends StatefulWidget {
  const DepositMovementEditScreen({super.key});
  static const route = '/finance/deposits/movement';

  @override
  State<DepositMovementEditScreen> createState() => _DepositMovementEditScreenState();
}

class _DepositMovementEditScreenState extends State<DepositMovementEditScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  DateTime _date = DateTime.now();
  Deposit? deposit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Deposit) deposit = arg;
  }

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: const Text('Movimiento de depósito')),
      body: TaskFormTheme(
        child: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
            children: [
              Text('Depósito: ${deposit?.name ?? ""}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Cantidad (+ entrada / - salida)'),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _reason, decoration: const InputDecoration(labelText: 'Motivo (opcional)')),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text('Fecha: ${_date.toLocal().toString().split(' ').first}'),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed: () async {
                  if (deposit == null) return;
                  if (!_form.currentState!.validate()) return;
                  await svc.addDepositMovement(deposit!.id, amount: double.parse(_amount.text), date: _date, reason: _reason.text.trim().isEmpty?null:_reason.text.trim());
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
