// lib/screens/finance/deposits/deposits_screen.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/deposits/deposit_edit_screen.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class DepositsScreen extends StatelessWidget {
  const DepositsScreen({super.key});
  static const route = '/finance/deposits';

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: const Text('Depósitos')),
      body: StreamBuilder<List<Deposit>>(
        stream: svc.watchDeposits(),
        builder: (context, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (data.isEmpty) return const Center(child: Text('Sin depósitos'));
          final total = data.fold<double>(0, (p, e) => p + e.amount);
          final mine = data
              .where((e) => e.isMine)
              .fold<double>(0, (p, e) => p + e.amount);
          final third = total - mine;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _kpi('Total', total),
                    _kpi('Míos', mine),
                    _kpi('Terceros', third),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.only(bottom: screenPad(context)),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = data[i];
                    return ListTile(
                      leading: Icon(
                        d.isMine ? Icons.lock_open : Icons.lock_outline,
                      ),
                      title: Text('${d.name} • ${d.where}'),
                      subtitle: Text(
                        '${d.amount.toStringAsFixed(2)} ${d.currency}${d.category != null ? " • ${d.category}" : ""}',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            DepositEditScreen.route,
                            arguments: d,
                          ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, DepositEditScreen.route),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _kpi(String name, double v) => SizedBox(
    width: 180,
    child: Card(
      child: ListTile(title: Text(name), subtitle: Text(v.toStringAsFixed(2))),
    ),
  );
}
