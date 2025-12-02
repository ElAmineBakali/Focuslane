import 'package:flutter/material.dart';
import 'subscription_edit_screen.dart'; // import relativo al editor
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});
  static const route = '/finance/subscriptions'; // LISTA

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos fijos / Suscripciones')),
      body: StreamBuilder<List<Subscription>>(
        stream: FinanceFirestoreService.I.watchSubscriptions(),
        builder: (context, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin suscripciones'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final x = data[i];
              return ListTile(
                leading: const Icon(Icons.repeat),
                title: Text(x.name),
                subtitle: Text(
                  '${x.amount.toStringAsFixed(2)} ${x.currency} • ${x.category} • '
                  '${x.billingCycle}${x.billingDay != null ? " • día ${x.billingDay}" : ""}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => Navigator.pushNamed(context, SubscriptionEditScreen.route, arguments: x),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, SubscriptionEditScreen.route),
        child: const Icon(Icons.add),
      ),
    );
  }
}
