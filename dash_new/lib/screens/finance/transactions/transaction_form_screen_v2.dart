import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/transaction_model.dart';
import 'package:mi_dashboard_personal/services/finance/transaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class TransactionFormScreenV2 extends StatefulWidget {
  const TransactionFormScreenV2({super.key});
  static const route = '/finance/transactions/edit';

  @override
  State<TransactionFormScreenV2> createState() =>
      _TransactionFormScreenV2State();
}

class _TransactionFormScreenV2State extends State<TransactionFormScreenV2> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _subCategory = TextEditingController();
  final _accountId = TextEditingController();
  final _notes = TextEditingController();
  final _currency = TextEditingController();
  final _fxRate = TextEditingController();
  final _envelope = TextEditingController();
  final _tagsCtl = TextEditingController();

  DateTime _date = DateTime.now();
  TxType _type = TxType.expense;
  String? _recurrence; // none | weekly | monthly | custom
  List<String> _tags = [];

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    FinanceTransaction? existing;
    if (arg is FinanceTransaction) existing = arg;

    if (existing != null) {
      _title.text = existing!.title;
      _amount.text = existing!.amount.toStringAsFixed(2);
      _category.text = existing!.category ?? '';
      _subCategory.text = existing!.subCategory ?? '';
      _accountId.text = existing!.accountId ?? '';
      _notes.text = existing!.notes ?? '';
      _currency.text = existing!.originalCurrency ?? '';
      _fxRate.text = existing!.fxRate?.toString() ?? '';
      _envelope.text = existing!.envelopeId ?? '';
      _date = existing!.date;
      _type = existing!.type;
      _recurrence = existing!.recurrence;
      _tags = existing!.tags;
    }

    return Scaffold(
      body: FinanceScreenBody(
        slivers: [
          const FinanceHeaderLarge(
            title: 'Editar transacción',
            icon: Icons.edit,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: FinanceFormTheme(
                child: Form(
                  key: _form,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TxType>(
                              value: _type,
                              items: const [
                                DropdownMenuItem(
                                  value: TxType.expense,
                                  child: Text('Gasto'),
                                ),
                                DropdownMenuItem(
                                  value: TxType.income,
                                  child: Text('Ingreso'),
                                ),
                                DropdownMenuItem(
                                  value: TxType.transfer,
                                  child: Text('Transferencia'),
                                ),
                              ],
                              onChanged:
                                  (v) => setState(
                                    () => _type = v ?? TxType.expense,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Tipo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _amount,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator:
                                  (v) =>
                                      (v == null || double.tryParse(v) == null)
                                          ? 'Cantidad inválida'
                                          : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(labelText: 'Título'),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _category,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _subCategory,
                              decoration: const InputDecoration(
                                labelText: 'Subcategoría',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _accountId,
                              decoration: const InputDecoration(
                                labelText: 'Cuenta',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _envelope,
                              decoration: const InputDecoration(
                                labelText: 'Sobre',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _currency,
                              decoration: const InputDecoration(
                                labelText: 'Divisa original',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _fxRate,
                              decoration: const InputDecoration(
                                labelText: 'FX rate',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notes,
                        decoration: const InputDecoration(labelText: 'Notas'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.date_range),
                              title: Text(
                                'Fecha: ${_date.toLocal().toString().split(' ').first}',
                              ),
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _recurrence,
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('Sin recurrencia'),
                                ),
                                DropdownMenuItem(
                                  value: 'weekly',
                                  child: Text('Semanal'),
                                ),
                                DropdownMenuItem(
                                  value: 'monthly',
                                  child: Text('Mensual'),
                                ),
                                DropdownMenuItem(
                                  value: 'custom',
                                  child: Text('Custom'),
                                ),
                              ],
                              onChanged: (v) => setState(() => _recurrence = v),
                              decoration: const InputDecoration(
                                labelText: 'Recurrencia',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tagsCtl,
                        decoration: const InputDecoration(
                          labelText: 'Añadir tags (separados por coma)',
                        ),
                        onFieldSubmitted: (v) {
                          final parts = v
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty);
                          setState(() {
                            _tags.addAll(parts);
                            _tagsCtl.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in _tags)
                              InputChip(
                                label: Text(t),
                                onDeleted:
                                    () => setState(() => _tags.remove(t)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _save,
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final uid = fb_auth.FirebaseAuth.instance.currentUser!.uid;
    final tx = FinanceTransaction(
      id: '',
      userId: uid,
      date: _date,
      type: _type,
      title: _title.text.trim(),
      amount: double.parse(_amount.text.trim()),
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      subCategory:
          _subCategory.text.trim().isEmpty ? null : _subCategory.text.trim(),
      accountId: _accountId.text.trim().isEmpty ? null : _accountId.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      tags: _tags,
      originalCurrency:
          _currency.text.trim().isEmpty ? null : _currency.text.trim(),
      fxRate:
          _fxRate.text.trim().isEmpty
              ? null
              : double.tryParse(_fxRate.text.trim()),
      recurrence: _recurrence,
      envelopeId: _envelope.text.trim().isEmpty ? null : _envelope.text.trim(),
    );
    await TransactionService.I.upsert(tx);
    if (mounted) Navigator.pop(context);
  }
}
