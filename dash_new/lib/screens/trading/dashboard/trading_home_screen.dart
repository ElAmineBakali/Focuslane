import 'package:flutter/material.dart';
import '../services/trading_firestore_service.dart';
import '../models/trading_models.dart';
import 'package:mi_dashboard_personal/utils/app_links.dart';

class TradingHomeScreen extends StatefulWidget {
  const TradingHomeScreen({super.key});
  static const route = '/trading';

  @override
  State<TradingHomeScreen> createState() => _TradingHomeScreenState();
}

class _TradingHomeScreenState extends State<TradingHomeScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final svc = TradingFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trading'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Atajos',
            icon: const Icon(Icons.link_rounded),
            onSelected: (v) {
              if (v == 'Exness') AppLinks.openExness();
              if (v == 'Investing') AppLinks.openInvesting();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Exness', child: Text('Exness')),
              PopupMenuItem(value: 'Investing', child: Text('Investing')),
            ],
          ),
          IconButton(
            tooltip: 'Gráfico USTEC en vivo',
            icon: const Icon(Icons.show_chart),
            onPressed: () => Navigator.pushNamed(context, '/trading/live'),
          ),
          IconButton(
            tooltip: 'Analíticas',
            icon: const Icon(Icons.insights),
            onPressed: () => Navigator.pushNamed(context, '/trading/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _month,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => _month = DateTime(d.year, d.month, 1));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: svc.kpisForMonth(_month),
              builder: (_, s) {
                final winRate = (s.data?['winRate'] ?? 0.0) as double;
                final avgR = (s.data?['avgR'] ?? 0.0) as double;
                final pnlM = (s.data?['pnlMonth'] ?? 0.0) as double;
                final count = (s.data?['count'] ?? 0) as int;

                final data = [
                  _kpiSmall(context, 'Win Rate', '${(winRate * 100).toStringAsFixed(0)}%', Icons.emoji_events),
                  _kpiSmall(context, 'R medio',  avgR.toStringAsFixed(2), Icons.stacked_bar_chart),
                  _kpiSmall(context, 'P&L mes',  pnlM.toStringAsFixed(2), Icons.attach_money),
                  _kpiSmall(context, 'Trades',   '$count', Icons.list_alt),
                ];
                return _kpiResponsive(data);
              },
            ),
            const SizedBox(height: 16),

            //_nav('Trades', Icons.list, () => Navigator.pushNamed(context, '/trading/trades')),
            //_nav('Nuevo Trade', Icons.add_circle_outline, () => Navigator.pushNamed(context, '/trading/trade/edit')),
            _nav('Estrategias', Icons.rule, () => Navigator.pushNamed(context, '/trading/strategies')),
            _nav('Diario', Icons.book_outlined, () => Navigator.pushNamed(context, '/trading/journal')),
            //_nav('Analíticas', Icons.insights, () => Navigator.pushNamed(context, '/trading/analytics')),
            _nav('Tags', Icons.tag, () => Navigator.pushNamed(context, '/trading/tags')),
            _nav('ORB / Velas', Icons.candlestick_chart, () => Navigator.pushNamed(context, '/trading/orb')),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Últimos 5 trades
            StreamBuilder<List<Trade>>(
              stream: svc.watchTrades(),
              builder: (_, s) {
                final data = (s.data ?? []).take(5).toList();
                if (data.isEmpty) return const ListTile(title: Text('Aún no hay trades'));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Últimos trades', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    ...data.map((t) => Card(
                          child: ListTile(
                            leading: Icon(
                              t.outcome == Outcome.win
                                  ? Icons.trending_up
                                  : t.outcome == Outcome.loss
                                      ? Icons.trending_down
                                      : t.outcome == Outcome.breakeven
                                          ? Icons.horizontal_rule
                                          : Icons.hourglass_empty,
                            ),
                            title: Text('${t.symbol} • ${t.direction.name.toUpperCase()}'),
                            subtitle: Text(
                                '${t.entryDate.toLocal().toString().split(" ").first} • P&L ${t.pnl.toStringAsFixed(2)} • R ${t.rMultiple?.toStringAsFixed(2) ?? "-"}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(context, '/trading/trade/edit', arguments: t),
                          ),
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // KPI compacto (dos por fila en móvil)
  Widget _kpiSmall(BuildContext context, String title, String value, IconData icon) {
    final w = MediaQuery.of(context).size.width;
    final cardW = w < 480 ? (w - 16 - 8) / 2 : 220.0;
    return SizedBox(
      width: cardW,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nav(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _kpiResponsive(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isNarrow = w < 520;
        if (!isNarrow) {
          return Wrap(spacing: 8, runSpacing: 8, children: items);
        }
        // 2 columnas en móvil; centrar último si impar
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += 2) {
          if (i + 1 < items.length) {
            rows.add(Row(
              children: [
                Expanded(child: items[i]),
                const SizedBox(width: 8),
                Expanded(child: items[i + 1]),
              ],
            ));
          } else {
            rows.add(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [SizedBox(width: (w / 2) - 4), Expanded(child: items[i])],
            ));
          }
          rows.add(const SizedBox(height: 8));
        }
        return Column(children: rows);
      },
    );
  }
}
