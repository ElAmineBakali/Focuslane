import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';
import 'trade_edit_screen.dart';

class TradesListScreen extends StatefulWidget {
  const TradesListScreen({super.key});
  static const route = '/trading/trades';

  @override
  State<TradesListScreen> createState() => _TradesListScreenState();
}

class _TradesListScreenState extends State<TradesListScreen> {
  String? _symbol;
  String? _strategy;
  Outcome? _outcome;

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => Navigator.pushNamed(context, TradeEditScreen.route),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros simples
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Símbolo'),
                    onChanged:
                        (v) => setState(
                          () =>
                              _symbol =
                                  v.trim().isEmpty
                                      ? null
                                      : v.trim().toUpperCase(),
                        ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Estrategia ID',
                    ),
                    onChanged:
                        (v) => setState(
                          () => _strategy = v.trim().isEmpty ? null : v.trim(),
                        ),
                  ),
                ),
                DropdownButton<Outcome>(
                  hint: const Text('Outcome'),
                  value: _outcome,
                  items:
                      Outcome.values
                          .map(
                            (o) =>
                                DropdownMenuItem(value: o, child: Text(o.name)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _outcome = v),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar'),
                  onPressed:
                      () => setState(() {
                        _symbol = null;
                        _strategy = null;
                        _outcome = null;
                      }),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Trade>>(
              stream: svc.watchTrades(
                symbol: _symbol,
                strategyId: _strategy,
                outcome: _outcome,
              ),
              builder: (_, s) {
                final data = s.data ?? [];
                if (s.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (data.isEmpty)
                  return const Center(child: Text('Sin trades'));
                return ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = data[i];
                    return ListTile(
                      leading: Icon(
                        t.outcome == Outcome.win
                            ? Icons.trending_up
                            : t.outcome == Outcome.loss
                            ? Icons.trending_down
                            : t.outcome == Outcome.breakeven
                            ? Icons.horizontal_rule
                            : Icons.hourglass_empty,
                      ),
                      title: Text(
                        '${t.symbol} • ${t.direction.name.toUpperCase()} • ${t.size.toStringAsFixed(2)}',
                      ),
                      subtitle: Text(
                        '${t.entryDate.toLocal().toString().split(" ").first} • P&L ${t.pnl.toStringAsFixed(2)} • R ${t.rMultiple?.toStringAsFixed(2) ?? "-"}',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            TradeEditScreen.route,
                            arguments: t,
                          ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
