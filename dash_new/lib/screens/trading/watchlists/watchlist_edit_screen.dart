import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';

class WatchlistEditScreen extends StatefulWidget {
  const WatchlistEditScreen({super.key});
  static const route = '/trading/watchlist/edit';

  @override
  State<WatchlistEditScreen> createState() => _WatchlistEditScreenState();
}

class _WatchlistEditScreenState extends State<WatchlistEditScreen> {
  final _name = TextEditingController();
  Watchlist? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Watchlist && editing == null) {
      editing = arg;
      _name.text = arg.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: Text(editing==null ? 'Nueva watchlist' : 'Editar watchlist')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre')),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                final name = _name.text.trim();
                if (name.isEmpty) return;
                if (editing == null) {
                  await svc.addWatchlist(Watchlist(id:'', name:name));
                } else {
                  await svc.updateWatchlist(Watchlist(id: editing!.id, name: name));
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            )
          ],
        ),
      ),
    );
  }
}
