import 'package:flutter/material.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class BudgetEditScreen extends StatefulWidget {
  const BudgetEditScreen({super.key});
  static const route = '/finance/budgets/edit';

  @override
  State<BudgetEditScreen> createState() => _BudgetEditScreenState();
}

class _BudgetEditScreenState extends State<BudgetEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _limit = TextEditingController();
  String _period = 'monthly';
  int _startDay = 1;
  bool _active = true;
  Budget? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Budget && editing == null) {
      editing = arg;
      _name.text = arg.name;
      _category.text = arg.category ?? '';
      _limit.text = arg.limit.toString();
      _period = arg.period;
      _startDay = arg.startDayOfPeriod;
      _active = arg.active;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing == null ? 'Nuevo presupuesto' : 'Editar presupuesto',
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
                controller: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoría (vacío = global)',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _limit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Límite'),
                validator:
                    (v) =>
                        (v == null || double.tryParse(v) == null)
                            ? 'Inválido'
                            : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _period,
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                  DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text('Personalizado'),
                  ),
                ],
                onChanged: (v) => setState(() => _period = v ?? 'monthly'),
                decoration: const InputDecoration(labelText: 'Periodo'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Text('Inicio de periodo')),
                  DropdownButton<int>(
                    value: _startDay,
                    onChanged: (v) => setState(() => _startDay = v ?? 1),
                    items:
                        List.generate(28, (i) => i + 1)
                            .map(
                              (d) =>
                                  DropdownMenuItem(value: d, child: Text('$d')),
                            )
                            .toList(),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Activo'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final obj = Budget(
                    id: editing?.id ?? '',
                    name: _name.text.trim(),
                    category:
                        _category.text.trim().isEmpty
                            ? null
                            : _category.text.trim(),
                    limit: double.parse(_limit.text),
                    period: _period,
                    startDayOfPeriod: _startDay,
                    active: _active,
                  );
                  if (editing == null) {
                    await svc.addBudget(obj);
                  } else {
                    await svc.updateBudget(obj);
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
                    await svc.deleteBudget(editing!.id);
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
