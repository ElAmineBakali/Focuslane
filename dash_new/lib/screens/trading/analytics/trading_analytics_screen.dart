import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';

class TradingAnalyticsScreen extends StatefulWidget {
  const TradingAnalyticsScreen({super.key});
  static const route = '/trading/analytics';

  @override
  State<TradingAnalyticsScreen> createState() => _TradingAnalyticsScreenState();
}

class _TradingAnalyticsScreenState extends State<TradingAnalyticsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analíticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _month,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null)
                setState(() => _month = DateTime(d.year, d.month, 1));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: svc.kpisForMonth(_month),
            builder: (_, s) {
              final winRate = (s.data?['winRate'] ?? 0.0) as double;
              final avgR = (s.data?['avgR'] ?? 0.0) as double;
              final pnlM = (s.data?['pnlMonth'] ?? 0.0) as double;
              final count = (s.data?['count'] ?? 0) as int;
              final items = [
                _kpi(
                  'Win Rate',
                  '${(winRate * 100).toStringAsFixed(0)}%',
                  Icons.emoji_events,
                ),
                _kpi(
                  'R medio',
                  avgR.toStringAsFixed(2),
                  Icons.stacked_bar_chart,
                ),
                _kpi('P&L mes', pnlM.toStringAsFixed(2), Icons.attach_money),
                _kpi('Trades', '$count', Icons.list_alt),
              ];
              return _kpiResponsive(items);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Curva de capital (mes)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          FutureBuilder<Map<DateTime, double>>(
            future: svc.equityCurveMonth(_month),
            builder: (_, s) {
              final data = s.data ?? {};
              if (data.isEmpty) return const ListTile(title: Text('Sin datos'));
              final items =
                  data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
              final minV = items
                  .map((e) => e.value)
                  .reduce((a, b) => a < b ? a : b);
              final maxV = items
                  .map((e) => e.value)
                  .reduce((a, b) => a > b ? a : b);
              final span = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children:
                        items.map((e) {
                          final pct = ((e.value - minV) / span).clamp(0, 1);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 72,
                                  child: Text(
                                    e.key.day.toString().padLeft(2, "0"),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.25 + 0.6 * pct),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 90,
                                  child: Text(e.value.toStringAsFixed(2)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _kpi(String title, String value, IconData icon) {
    return SizedBox(
      width: 230,
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Center(child: Text(title)),
          subtitle: Center(child: Text(value)),
        ),
      ),
    );
  }

  Widget _kpiResponsive(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isNarrow = w < 560;
        if (!isNarrow) {
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: items,
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += 2) {
          if (i + 1 < items.length) {
            rows.add(
              Row(
                children: [
                  Expanded(child: items[i]),
                  const SizedBox(width: 12),
                  Expanded(child: items[i + 1]),
                ],
              ),
            );
          } else {
            rows.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: (w / 2) - 6),
                  Expanded(child: items[i]),
                ],
              ),
            );
          }
          rows.add(const SizedBox(height: 12));
        }
        return Column(children: rows);
      },
    );
  }
}
