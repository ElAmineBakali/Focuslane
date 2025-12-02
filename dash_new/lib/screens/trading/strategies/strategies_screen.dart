import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';
import 'strategy_detail_screen.dart';

class StrategiesScreen extends StatelessWidget {
  const StrategiesScreen({super.key});
  static const route = '/trading/strategies';

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estrategias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await svc.addStrategy(Strategy(id: '', name: 'Nueva estrategia'));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Strategy>>(
        stream: svc.watchStrategies(),
        builder: (_, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin estrategias'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final x = data[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.rule),
                  title: Text(x.name),
                  subtitle: Text(x.timeframe),
                  trailing: const Icon(Icons.chevron_right),
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        StrategyDetailScreen.route,
                        arguments: x,
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
