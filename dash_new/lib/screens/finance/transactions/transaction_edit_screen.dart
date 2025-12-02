import 'package:flutter/material.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class TransactionEditScreen extends StatefulWidget {
  const TransactionEditScreen({super.key});
  static const route = '/finance/transactions/edit';

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _category = TextEditingController(text: 'Other');
  DateTime _date = DateTime.now();
  TxType _type = TxType.expense;

  FinanceTransaction? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is FinanceTransaction && editing == null) {
      editing = arg;
      _title.text = editing!.title;
      _amount.text = editing!.amount.toString();
      _category.text = editing!.category;
      _date = editing!.date;
      _type = editing!.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: Text(editing == null ? 'Nueva transacción' : 'Editar transacción')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cantidad'),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Cantidad inválida' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TxType>(
                initialValue: _type,
                items: const [
                  DropdownMenuItem(value: TxType.expense, child: Text('Gasto')),
                  DropdownMenuItem(value: TxType.income, child: Text('Ingreso')),
                  DropdownMenuItem(value: TxType.transfer, child: Text('Transferencia')),
                ],
                onChanged: (v) => setState(() => _type = v ?? TxType.expense),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Categoría'),
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
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final obj = FinanceTransaction(
                    id: editing?.id ?? '',
                    title: _title.text.trim(),
                    amount: double.parse(_amount.text),
                    type: _type,
                    category: _category.text.trim().isEmpty ? 'Other' : _category.text.trim(),
                    date: _date,
                  );
                  if (editing == null) {
                    await svc.addTransaction(obj);
                  } else {
                    await svc.updateTransaction(obj);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
              if (editing != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                  onPressed: () async {
                    await svc.deleteTransaction(editing!.id);
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
