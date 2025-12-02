// lib/screens/finance/debts/debt_entry_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class DebtEntryEditScreen extends StatefulWidget {
  const DebtEntryEditScreen({super.key});
  static const route = '/finance/people/debt/edit';

  @override
  State<DebtEntryEditScreen> createState() => _DebtEntryEditScreenState();
}

class _DebtEntryEditScreenState extends State<DebtEntryEditScreen> {
  final _form = GlobalKey<FormState>();
  final _concept = TextEditingController();
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();
  Person? person;
  DebtEntry? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Map) {
      person = arg['person'] as Person;
      if (arg['entry'] is DebtEntry && editing == null) {
        editing = arg['entry'] as DebtEntry;
        _concept.text = editing!.concept;
        _amount.text = editing!.amount.toString();
        _date = editing!.date;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: Text(editing == null ? 'Nuevo apunte' : 'Editar apunte')),
      body: TaskFormTheme(
        child: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
            children: [
              Text('Persona: ${person?.name ?? ''}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _concept,
                decoration: const InputDecoration(labelText: 'Concepto'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Importe (+ te debe / - tú debes)'),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text('Fecha: ${_date.toLocal().toString().split(' ').first}'),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed: () async {
                  if (person == null) return;
                  if (!_form.currentState!.validate()) return;
                  final obj = DebtEntry(
                    id: editing?.id ?? '',
                    amount: double.parse(_amount.text),
                    date: _date,
                    concept: _concept.text.trim(),
                  );
                  if (editing == null) {
                    await svc.addDebtEntry(person!.id, obj);
                  } else {
                    await svc.updateDebtEntry(person!.id, obj);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
              if (editing != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                  onPressed: () async {
                    await svc.deleteDebtEntry(person!.id, editing!.id);
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
