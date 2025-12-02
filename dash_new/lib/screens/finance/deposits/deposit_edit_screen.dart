// lib/screens/finance/deposits/deposit_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';
import 'package:mi_dashboard_personal/screens/finance/deposits/deposit_movement_edit_screen.dart';

class DepositEditScreen extends StatefulWidget {
  const DepositEditScreen({super.key});
  static const route = '/finance/deposits/edit';

  @override
  State<DepositEditScreen> createState() => _DepositEditScreenState();
}

class _DepositEditScreenState extends State<DepositEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _where = TextEditingController();
  final _amount = TextEditingController();
  final _currency = TextEditingController(text: 'EUR');
  bool _isMine = true;
  final _category = TextEditingController();
  final _ownerNote = TextEditingController();
  Deposit? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Deposit && editing == null) {
      editing = arg;
      _name.text = arg.name;
      _where.text = arg.where;
      _amount.text = arg.amount.toString();
      _currency.text = arg.currency;
      _isMine = arg.isMine;
      _category.text = arg.category ?? '';
      _ownerNote.text = arg.ownerNote ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: Text(editing == null ? 'Nuevo depósito' : 'Editar depósito')),
      body: TaskFormTheme(
        child: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(12, 12, 12, screenPad(context)),
            children: [
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => (v==null||v.trim().isEmpty)?'Requerido':null),
              const SizedBox(height: 8),
              TextFormField(controller: _where, decoration: const InputDecoration(labelText: 'Dónde está'), validator: (v) => (v==null||v.trim().isEmpty)?'Requerido':null),
              const SizedBox(height: 8),
              TextFormField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cantidad'),
                validator: (v)=> (v==null||double.tryParse(v)==null)?'Inválido':null),
              const SizedBox(height: 8),
              TextFormField(controller: _currency, decoration: const InputDecoration(labelText: 'Divisa')),
              const SizedBox(height: 8),
              SwitchListTile(title: const Text('Es mío'), value: _isMine, onChanged: (v)=>setState(()=>_isMine=v)),
              const SizedBox(height: 8),
              TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Categoría (cash/bank/third-party/escrow)')),
              const SizedBox(height: 8),
              TextFormField(controller: _ownerNote, decoration: const InputDecoration(labelText: 'Nota')),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final obj = Deposit(
                    id: editing?.id ?? '',
                    name: _name.text.trim(),
                    where: _where.text.trim(),
                    amount: double.parse(_amount.text),
                    currency: _currency.text.trim().isEmpty?'EUR':_currency.text.trim(),
                    isMine: _isMine,
                    category: _category.text.trim().isEmpty?null:_category.text.trim(),
                    ownerNote: _ownerNote.text.trim().isEmpty?null:_ownerNote.text.trim(),
                  );
                  if (editing == null) {
                    await svc.addDeposit(obj);
                  } else {
                    await svc.updateDeposit(obj);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
              if (editing != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Movimiento (+/-)'),
                  onPressed: () => Navigator.pushNamed(context, DepositMovementEditScreen.route, arguments: editing),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
