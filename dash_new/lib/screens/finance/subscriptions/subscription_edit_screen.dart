import 'package:flutter/material.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class SubscriptionEditScreen extends StatefulWidget {
  const SubscriptionEditScreen({super.key});
  static const route = '/finance/subscriptions/edit'; // EDITOR (RUTA DIFERENTE)

  @override
  State<SubscriptionEditScreen> createState() => _SubscriptionEditScreenState();
}

class _SubscriptionEditScreenState extends State<SubscriptionEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _currency = TextEditingController(text: 'EUR');
  final _category = TextEditingController(text: 'Other');
  String _billingCycle = 'monthly';
  int? _billingDay = 1;
  bool _isFixed = true;
  int _remindDaysBefore = 3;
  bool _autoMarkPaid = false;
  Subscription? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Subscription && editing == null) {
      editing = arg;
      _name.text = arg.name;
      _amount.text = arg.amount.toString();
      _currency.text = arg.currency;
      _category.text = arg.category;
      _billingCycle = arg.billingCycle;
      _billingDay = arg.billingDay;
      _isFixed = arg.isFixed;
      _remindDaysBefore = arg.remindDaysBefore;
      _autoMarkPaid = arg.autoMarkPaid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing == null ? 'Nueva suscripción' : 'Editar suscripción',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Importe'),
                validator:
                    (v) =>
                        (v == null || double.tryParse(v) == null)
                            ? 'Inválido'
                            : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currency,
                decoration: const InputDecoration(
                  labelText: 'Divisa (p.ej. EUR)',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _billingCycle,
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                  DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text('Personalizado'),
                  ),
                ],
                onChanged:
                    (v) => setState(() => _billingCycle = v ?? 'monthly'),
                decoration: const InputDecoration(labelText: 'Ciclo de cobro'),
              ),
              if (_billingCycle == 'monthly') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Día de cobro')),
                    DropdownButton<int>(
                      value: _billingDay,
                      onChanged: (v) => setState(() => _billingDay = v),
                      items:
                          List.generate(28, (i) => i + 1)
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text('$d'),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ],
              SwitchListTile(
                title: const Text('Marcar como gasto fijo (checklist)'),
                value: _isFixed,
                onChanged: (v) => setState(() => _isFixed = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recordar antes (días)'),
                trailing: DropdownButton<int>(
                  value: _remindDaysBefore,
                  onChanged: (v) => setState(() => _remindDaysBefore = v ?? 3),
                  items:
                      const [0, 1, 2, 3, 5, 7, 10]
                          .map(
                            (d) =>
                                DropdownMenuItem(value: d, child: Text('$d')),
                          )
                          .toList(),
                ),
              ),
              SwitchListTile(
                title: const Text('Auto-marcar como pagado'),
                value: _autoMarkPaid,
                onChanged: (v) => setState(() => _autoMarkPaid = v),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final obj = Subscription(
                    id: editing?.id ?? '',
                    name: _name.text.trim(),
                    amount: double.parse(_amount.text),
                    currency:
                        _currency.text.trim().isEmpty
                            ? 'EUR'
                            : _currency.text.trim(),
                    category:
                        _category.text.trim().isEmpty
                            ? 'Other'
                            : _category.text.trim(),
                    billingCycle: _billingCycle,
                    billingDay: _billingCycle == 'monthly' ? _billingDay : null,
                    isFixed: _isFixed,
                    remindDaysBefore: _remindDaysBefore,
                    autoMarkPaid: _autoMarkPaid,
                  );
                  if (editing == null) {
                    await svc.addSubscription(obj);
                  } else {
                    await svc.updateSubscription(obj);
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
                    await svc.deleteSubscription(editing!.id);
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
