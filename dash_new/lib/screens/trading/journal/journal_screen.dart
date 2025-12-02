import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';
import 'journal_edit_screen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});
  static const route = '/trading/journal';

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  TradingJournalEditScreen.route,
                ),
          ),
        ],
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: svc.watchJournal(),
        builder: (_, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (data.isEmpty)
            return const Center(child: Text('Sin entradas de diario'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final x = data[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${x.mood}')),
                title: Text(x.title),
                subtitle: Text(
                  '${x.date.toLocal().toString().split(" ").first} • ${x.checklist.join(" • ")}',
                ),
                trailing: const Icon(Icons.edit),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      TradingJournalEditScreen.route,
                      arguments: x,
                    ),
              );
            },
          );
        },
      ),
    );
  }
}
