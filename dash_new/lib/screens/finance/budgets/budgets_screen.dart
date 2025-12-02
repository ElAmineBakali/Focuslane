import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/budgets/budget_edit_screen.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});
  static const route = '/finance/budgets';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos')),
      body: StreamBuilder<List<Budget>>(
        stream: FinanceFirestoreService.I.watchBudgets(),
        builder: (context, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin presupuestos'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = data[i];
              return ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(b.name),
                subtitle: Text('Límite: ${b.limit.toStringAsFixed(2)} • ${b.category ?? "Global"} • ${b.period}'),
                trailing: const Icon(Icons.edit),
                onTap: () => Navigator.pushNamed(context, BudgetEditScreen.route, arguments: b),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, BudgetEditScreen.route),
        child: const Icon(Icons.add),
      ),
    );
  }
}

