import 'package:flutter/material.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class VariableExpensesScreen extends StatefulWidget {
  const VariableExpensesScreen({super.key});
  static const route = '/finance/checklist/variable';

  @override
  State<VariableExpensesScreen> createState() => _VariableExpensesScreenState();
}

class _VariableExpensesScreenState extends State<VariableExpensesScreen> {
  String periodKey = yyyymm(DateTime.now());
  final _name = TextEditingController();
  final _category = TextEditingController(text: 'Other');
  final _amount = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos variables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final now = DateTime.now();
              final d = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => periodKey = yyyymm(d));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<VariableExpenseItem>>(
              stream: svc.watchVariableExpenses(periodKey),
              builder: (context, s) {
                final data = s.data ?? [];
                if (s.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    0,
                    0,
                    MediaQuery.of(context).viewPadding.bottom + 96,
                  ),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final it = data[i];
                    return ListTile(
                      leading: const Icon(Icons.pending_actions_outlined),
                      title: Text(it.name),
                      subtitle: Text(
                        '${it.category} • ${it.status}${it.amount != null ? " • ${it.amount!.toStringAsFixed(2)}" : ""}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'done') {
                            await svc.updateVariableExpense(
                              periodKey,
                              VariableExpenseItem(
                                id: it.id,
                                name: it.name,
                                category: it.category,
                                periodKey: it.periodKey,
                                status: 'done',
                                amount: it.amount,
                                linkedTxId: it.linkedTxId,
                              ),
                            );
                          } else if (v == 'planned') {
                            await svc.updateVariableExpense(
                              periodKey,
                              VariableExpenseItem(
                                id: it.id,
                                name: it.name,
                                category: it.category,
                                periodKey: it.periodKey,
                                status: 'planned',
                                amount: it.amount,
                                linkedTxId: it.linkedTxId,
                              ),
                            );
                          } else if (v == 'delete') {
                            await svc.deleteVariableExpense(periodKey, it.id);
                          }
                        },
                        itemBuilder:
                            (c) => const [
                              PopupMenuItem(
                                value: 'planned',
                                child: Text('Marcar planificado'),
                              ),
                              PopupMenuItem(
                                value: 'done',
                                child: Text('Marcar realizado'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _amount,
                    decoration: const InputDecoration(
                      labelText: '€ (opcional)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    if (_name.text.trim().isEmpty) return;
                    await svc.addVariableExpense(
                      periodKey,
                      VariableExpenseItem(
                        id: '',
                        name: _name.text.trim(),
                        category:
                            _category.text.trim().isEmpty
                                ? 'Other'
                                : _category.text.trim(),
                        periodKey: periodKey,
                        amount: double.tryParse(_amount.text),
                      ),
                    );
                    _name.clear();
                    _amount.clear();
                  },
                  child: const Text('Añadir'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
