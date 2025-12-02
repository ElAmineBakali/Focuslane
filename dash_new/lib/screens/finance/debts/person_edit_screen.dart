// lib/screens/finance/debts/person_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/debts/debt_entry_edit_screen.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class PersonEditScreen extends StatefulWidget {
  const PersonEditScreen({super.key});
  static const route = '/finance/people/edit';

  @override
  State<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends State<PersonEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _currency = TextEditingController(text: 'EUR');
  final _contact = TextEditingController();
  final _notes = TextEditingController();
  Person? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Person && editing == null) {
      editing = arg;
      _name.text = arg.name;
      _currency.text = arg.defaultCurrency;
      _contact.text = arg.contact ?? '';
      _notes.text = arg.notes ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: Text(editing == null ? 'Nueva persona' : 'Persona')),
      body: Column(
        children: [
          TaskFormTheme(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currency,
                      decoration: const InputDecoration(labelText: 'Divisa'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contact,
                      decoration: const InputDecoration(labelText: 'Contacto (opcional)'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notes,
                      decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () async {
                        if (!_form.currentState!.validate()) return;
                        final obj = Person(
                          id: editing?.id ?? '',
                          name: _name.text.trim(),
                          defaultCurrency: _currency.text.trim().isEmpty ? 'EUR' : _currency.text.trim(),
                          contact: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
                          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                          balance: editing?.balance ?? 0,
                        );
                        if (editing == null) {
                          await svc.addPerson(obj);
                        } else {
                          await svc.updatePerson(obj);
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Guardar'),
                    ),
                    if (editing != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar'),
                        onPressed: () async {
                          await svc.deletePerson(editing!.id);
                          if (mounted) Navigator.pop(context);
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          if (editing != null)
            Expanded(
              child: StreamBuilder<List<DebtEntry>>(
                stream: svc.watchDebtLedger(editing!.id),
                builder: (context, s) {
                  final data = s.data ?? [];
                  if (s.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.separated(
                    padding: EdgeInsets.only(bottom: screenPad(context)),
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = data[i];
                      return ListTile(
                        leading: Icon(e.amount >= 0 ? Icons.call_received : Icons.call_made),
                        title: Text(e.concept),
                        subtitle: Text(e.date.toLocal().toString().split('.').first),
                        trailing: Text(e.amount.toStringAsFixed(2)),
                        onTap: () => Navigator.pushNamed(
                          context, DebtEntryEditScreen.route,
                          arguments: {'person': editing!, 'entry': e},
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: editing == null
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.pushNamed(
                context, DebtEntryEditScreen.route, arguments: {'person': editing!}),
              child: const Icon(Icons.add),
            ),
    );
  }
}
