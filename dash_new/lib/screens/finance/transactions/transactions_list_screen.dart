import 'package:flutter/material.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class TransactionsListScreen extends StatelessWidget {
  const TransactionsListScreen({super.key});
  static const route = '/finance/transactions';

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: const Text('Transacciones')),
      body: StreamBuilder<List<FinanceTransaction>>(
        stream: svc.watchTransactions(),
        builder: (context, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty)
            return const Center(child: Text('Sin transacciones'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = data[i];
              return ListTile(
                leading: Icon(
                  t.type == TxType.income
                      ? Icons.trending_up
                      : Icons.trending_down,
                ),
                title: Text(t.title),
                subtitle: Text(
                  "${t.category} • ${t.date.toLocal().toString().split('.').first}",
                ),
                trailing: Text(
                  (t.type == TxType.expense ? '-' : '+') +
                      t.amount.toStringAsFixed(2),
                ),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      '/finance/transactions/edit',
                      arguments: t,
                    ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.pushNamed(context, '/finance/transactions/edit'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
