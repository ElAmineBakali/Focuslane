import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';

class SymbolEditScreen extends StatefulWidget {
  const SymbolEditScreen({super.key});
  static const route = '/trading/watchlist/symbol/edit';

  @override
  State<SymbolEditScreen> createState() => _SymbolEditScreenState();
}

class _SymbolEditScreenState extends State<SymbolEditScreen> {
  final _ticker = TextEditingController();
  final _note = TextEditingController();
  int _prio = 2;
  Watchlist? wl;
  WatchSymbol? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      wl = args['wl'] as Watchlist;
      if (args['sym'] is WatchSymbol && editing == null) {
        editing = args['sym'] as WatchSymbol;
        _ticker.text = editing!.ticker;
        _note.text = editing!.note ?? '';
        _prio = editing!.priority;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (wl == null)
      return const Scaffold(body: Center(child: Text('Sin lista')));
    final svc = TradingFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Añadir símbolo' : 'Editar símbolo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _ticker,
              decoration: const InputDecoration(labelText: 'Ticker'),
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota'),
            ),
            Row(
              children: [
                const Expanded(child: Text('Prioridad')),
                DropdownButton<int>(
                  value: _prio,
                  items:
                      [1, 2, 3]
                          .map(
                            (e) =>
                                DropdownMenuItem(value: e, child: Text('$e')),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _prio = v ?? 2),
                ),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                final sym = WatchSymbol(
                  id: editing?.id ?? '',
                  ticker: _ticker.text.trim().toUpperCase(),
                  note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                  priority: _prio,
                );
                if (editing == null) {
                  await svc.addSymbol(wl!.id, sym);
                } else {
                  await svc.updateSymbol(wl!.id, sym);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
