import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

class FoodHistoryScreen extends StatelessWidget {
  final FoodFirestoreService svc;
  const FoodHistoryScreen({super.key, required this.svc});

  String _dayId(DateTime d) => d.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final days = List.generate(14, (i) => DateTime.now().subtract(Duration(days: i)));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Consumo (14 días)'),
            Tab(text: 'Compras (listas)'),
          ]),
        ),
        body: TabBarView(
          children: [
            // Consumo
            ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, i) {
                final d = days[i];
                final id = _dayId(d);
                return FutureBuilder<DailyIntakeDoc>(
                  future: svc.getDay(id),
                  builder: (context, snap) {
                    final doc = snap.data;
                    if (doc == null) return const ListTile(title: Text('Cargando...'));
                    final t = doc.totals;
                    return Card(
                      child: ListTile(
                        title: Text(id),
                        subtitle: Text('Kcal ${t['kcal']?.toStringAsFixed(0) ?? '0'} • '
                            'P ${t['protein']?.toStringAsFixed(0) ?? '0'} • '
                            'C ${t['carbs']?.toStringAsFixed(0) ?? '0'} • '
                            'G ${t['fat']?.toStringAsFixed(0) ?? '0'} • '
                            'Fib ${t['fiber']?.toStringAsFixed(0) ?? '0'} • '
                            'Agua ${doc.waterMl} ml'),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: days.length,
            ),
            // Compras (listas actuales)
            StreamBuilder<List<ShoppingList>>(
              stream: svc.streamShoppingLists(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final lists = snap.data!;
                if (lists.isEmpty) return const Center(child: Text('Sin listas aún'));
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (_, i) {
                    final l = lists[i];
                    final total = l.items.fold<double>(0, (a, it) => a + (it.total ?? 0));
                    return Card(
                      child: ListTile(
                        title: Text(l.name),
                        subtitle: Text('${l.items.length} items • ${l.scope.name}'),
                        trailing: Text(total > 0 ? '≈ ${total.toStringAsFixed(2)}' : ''),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: lists.length,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
