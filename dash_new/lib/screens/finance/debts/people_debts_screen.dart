// lib/screens/finance/debts/people_debts_screen.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/debts/person_edit_screen.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class PeopleDebtsScreen extends StatelessWidget {
  const PeopleDebtsScreen({super.key});
  static const route = '/finance/people';

  String _fmt(double v, String cur) => '${v.toStringAsFixed(2)} $cur';

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;

    return Scaffold(
      appBar: AppBar(title: const Text('Deudas con personas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder<List<Person>>(
              stream: svc.watchPeople(),
              builder: (context, snap) {
                final people = snap.data ?? const <Person>[];
                final currency = people.isNotEmpty ? people.first.defaultCurrency : 'EUR';

                double toReceive = 0, toPayAbs = 0;
                for (final p in people) {
                  if (p.balance > 0) toReceive += p.balance;
                  if (p.balance < 0) toPayAbs += -p.balance;
                }

                return Wrap(
                  spacing: 12, runSpacing: 12,
                  children: [
                    _kpi(context, 'Me deben', _fmt(toReceive, currency), positive: true),
                    _kpi(context, 'Debo', _fmt(toPayAbs, currency), positive: false),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<List<Person>>(
              stream: svc.watchPeople(),
              builder: (context, s) {
                if (s.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final people = s.data ?? [];
                if (people.isEmpty) {
                  return const Center(child: Text('Sin personas'));
                }
                return ListView.separated(
                  padding: EdgeInsets.only(bottom: screenPad(context)),
                  itemCount: people.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = people[i];
                    final color = p.balance >= 0 ? Colors.green : Colors.red;
                    return ListTile(
                      key: ValueKey(p.id),
                      leading: const Icon(Icons.person_outline),
                      title: Text(p.name),
                      subtitle: Text('Saldo: ${_fmt(p.balance, p.defaultCurrency)}'),
                      trailing: Icon(Icons.chevron_right, color: color),
                      onTap: () => Navigator.pushNamed(context, PersonEditScreen.route, arguments: p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, PersonEditScreen.route),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _kpi(BuildContext context, String name, String value, {required bool positive}) {
    final s = Theme.of(context).colorScheme;
    final badge = positive ? s.primary : s.error;
    return SizedBox(
      width: 200,
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: badge,
            child: Icon(positive ? Icons.trending_up : Icons.trending_down, color: s.onPrimary),
          ),
          title: Text(name),
          subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
