import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';
import 'candle_edit_screen.dart';

class OrbToolsScreen extends StatefulWidget {
  const OrbToolsScreen({super.key});
  static const route = '/trading/orb';

  @override
  State<OrbToolsScreen> createState() => _OrbToolsScreenState();
}

class _OrbToolsScreenState extends State<OrbToolsScreen> {
  final _symbol = TextEditingController(text: 'ES'); // ejemplo
  Timeframe _tf = Timeframe.m5;
  CandleMetric _metric = CandleMetric.range;
  final _nCtrl = TextEditingController(text: '20');

  int get _window => int.tryParse(_nCtrl.text) ?? 20;

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ORB / Cuartiles de velas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Añadir vela',
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  CandleEditScreen.route,
                  arguments: {
                    'symbol': _symbol.text.trim().toUpperCase(),
                    'tf': _tf,
                  },
                ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _symbol,
                    decoration: const InputDecoration(labelText: 'Símbolo'),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                DropdownButton<Timeframe>(
                  value: _tf,
                  onChanged: (v) => setState(() => _tf = v ?? _tf),
                  items:
                      Timeframe.values
                          .map(
                            (t) =>
                                DropdownMenuItem(value: t, child: Text(t.code)),
                          )
                          .toList(),
                ),
                DropdownButton<CandleMetric>(
                  value: _metric,
                  onChanged: (v) => setState(() => _metric = v ?? _metric),
                  items: const [
                    DropdownMenuItem(
                      value: CandleMetric.range,
                      child: Text('Rango (H-L)'),
                    ),
                    DropdownMenuItem(
                      value: CandleMetric.body,
                      child: Text('Cuerpo |C-O|'),
                    ),
                  ],
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _nCtrl,
                    keyboardType: const TextInputType.numberWithOptions(),
                    decoration: const InputDecoration(labelText: 'Últimas N'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Calcular'),
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, double>>(
              future:
                  (_symbol.text.trim().isEmpty)
                      ? Future.value({'n': 0})
                      : svc.quartilesFor(
                        symbol: _symbol.text.trim().toUpperCase(),
                        timeframe: _tf,
                        n: _window,
                        metric: _metric,
                      ),
              builder: (_, s) {
                final data = s.data ?? {'n': 0};
                if ((data['n'] ?? 0) == 0) {
                  return const Card(
                    child: ListTile(title: Text('Sin datos suficientes')),
                  );
                }
                final q1 = data['q1']!,
                    q2 = data['q2']!,
                    q3 = data['q3']!,
                    iqr = data['iqr']!;
                final avg = data['avg']!, mn = data['min']!, mx = data['max']!;
                final up = q3 + 1.5 * iqr;
                final dn = q1 - 1.5 * iqr;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Cuartiles ${_metric == CandleMetric.range ? "(Rango H-L)" : "(Cuerpo |C-O|)"} — $_window velas ${_tf.code}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _chip('Q1', q1),
                            _chip('Q2 (Mediana)', q2),
                            _chip('Q3', q3),
                            _chip('IQR', iqr),
                            _chip('Media', avg),
                            _chip('Min', mn),
                            _chip('Max', mx),
                            _chip('Upper (Q3+1.5·IQR)', up),
                            _chip('Lower (Q1-1.5·IQR)', dn),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sugerencia ORB: evita entradas cuando el tamaño de la vela de ruptura sea < Q1 o > (Q3 + 1.5·IQR) si buscas evitar outliers.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  (_symbol.text.trim().isEmpty)
                      ? const SizedBox()
                      : StreamBuilder<List<Candle>>(
                        stream: TradingFirestoreService.I.watchCandles(
                          symbol: _symbol.text.trim().toUpperCase(),
                          timeframe: _tf,
                          limit: 100,
                        ),
                        builder: (_, s) {
                          final data = s.data ?? [];
                          if (data.isEmpty) {
                            return const Center(
                              child: Text(
                                'Aún no hay velas. Usa “Añadir vela”.',
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: data.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final c = data[i];
                              final size =
                                  _metric == CandleMetric.range
                                      ? c.range
                                      : c.body;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      c.close >= c.open
                                          ? Colors.green.withOpacity(.2)
                                          : Colors.red.withOpacity(.2),
                                  child: Icon(
                                    c.close >= c.open
                                        ? Icons.north_east
                                        : Icons.south_east,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  '${c.symbol} ${c.timeframe.code} — ${c.time.toLocal()}',
                                ),
                                subtitle: Text(
                                  'O:${c.open.toStringAsFixed(2)} H:${c.high.toStringAsFixed(2)} '
                                  'L:${c.low.toStringAsFixed(2)} C:${c.close.toStringAsFixed(2)} '
                                  '• ${_metric == CandleMetric.range ? "Rango" : "Cuerpo"}: ${size.toStringAsFixed(4)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed:
                                      () => TradingFirestoreService.I
                                          .deleteCandle(c.id),
                                ),
                                onTap:
                                    () => Navigator.pushNamed(
                                      context,
                                      CandleEditScreen.route,
                                      arguments: {'edit': c},
                                    ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, double v) {
    return Chip(
      label: Text('$label: ${v.toStringAsFixed(4)}'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}
