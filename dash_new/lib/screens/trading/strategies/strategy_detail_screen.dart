import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';

class StrategyDetailScreen extends StatefulWidget {
  const StrategyDetailScreen({super.key});
  static const route = '/trading/strategy';

  @override
  State<StrategyDetailScreen> createState() => _StrategyDetailScreenState();
}

class _StrategyDetailScreenState extends State<StrategyDetailScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _tf = TextEditingController(text: 'D1');
  final _entry = TextEditingController();
  final _exit = TextEditingController();
  final _risk = TextEditingController(text: '1.0');
  Strategy? s;

  static const _timeframes = <String>[
    'M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1', 'W1', 'MN'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Strategy && s == null) {
      s = arg;
      _name.text = arg.name;
      _desc.text = arg.description ?? '';
      _tf.text = arg.timeframe;
      _entry.text = arg.rulesEntry ?? '';
      _exit.text = arg.rulesExit ?? '';
      _risk.text = (arg.riskPerTradePct ?? 1.0).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (s == null) return const Scaffold(body: Center(child: Text('Sin estrategia')));
    final svc = TradingFirestoreService.I;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle estrategia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await svc.deleteStrategy(s!.id);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _tf.text.isEmpty ? 'D1' : _tf.text,
              decoration: const InputDecoration(labelText: 'Timeframe'),
              items: _timeframes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _tf.text = v ?? _tf.text),
            ),

            const SizedBox(height: 8),
            TextField(
              controller: _entry,
              decoration: const InputDecoration(labelText: 'Reglas de entrada'),
              maxLines: 3,
            ),
            TextField(
              controller: _exit,
              decoration: const InputDecoration(labelText: 'Reglas de salida'),
              maxLines: 3,
            ),
            TextField(
              controller: _risk,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Riesgo % por trade',
                helperText: 'Ej. 1.0 = 1% del equity por operación',
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () async {
                    final x = Strategy(
                      id: s!.id,
                      name: _name.text.trim(),
                      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                      timeframe: _tf.text.trim().isEmpty ? 'D1' : _tf.text.trim(),
                      rulesEntry: _entry.text.trim().isEmpty ? null : _entry.text.trim(),
                      rulesExit: _exit.text.trim().isEmpty ? null : _exit.text.trim(),
                      riskPerTradePct: double.tryParse(_risk.text),
                    );
                    await svc.updateStrategy(x);
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),

            const Divider(height: 32),
            Text('Trades con esta estrategia',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),

            StreamBuilder<List<Trade>>(
              stream: svc.watchTrades(strategyId: s!.id),
              builder: (_, ss) {
                final data = ss.data ?? [];
                if (data.isEmpty) return const ListTile(title: Text('Sin trades'));
                return Column(
                  children: data
                      .map(
                        (t) => Card(
                          child: ListTile(
                            leading: Icon(
                              t.outcome == Outcome.win
                                  ? Icons.trending_up
                                  : t.outcome == Outcome.loss
                                      ? Icons.trending_down
                                      : Icons.horizontal_rule,
                            ),
                            title: Text(
                              '${t.symbol} • ${t.direction.name.toUpperCase()}',
                            ),
                            subtitle: Text(
                              'R ${t.rMultiple?.toStringAsFixed(2) ?? "-"} • P&L ${t.pnl.toStringAsFixed(2)}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
