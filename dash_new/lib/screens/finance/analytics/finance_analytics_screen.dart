import 'package:flutter/material.dart';
import '../services/finance_firestore_service.dart';
import '../models/finance_models.dart';

class FinanceAnalyticsScreen extends StatefulWidget {
  const FinanceAnalyticsScreen({super.key});
  static const route = '/finance/analytics';

  @override
  State<FinanceAnalyticsScreen> createState() => _FinanceAnalyticsScreenState();
}

class _FinanceAnalyticsScreenState extends State<FinanceAnalyticsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  DateTime get _start => DateTime(_month.year, _month.month, 1);
  DateTime get _end => DateTime(_month.year, _month.month + 1, 0, 23, 59, 59);

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analíticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _month,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                helpText: 'Selecciona un día del mes',
              );
              if (picked != null) {
                setState(() => _month = DateTime(picked.year, picked.month, 1));
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FutureBuilder<Map<String, double>>(
            future: svc.monthTotals(month: _start),
            builder: (context, snap) {
              final m =
                  snap.data ?? const {'income': 0, 'expense': 0, 'saving': 0};
              final balance = (m['income'] ?? 0) - (m['expense'] ?? 0);
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpiCard('Ingresos', m['income'] ?? 0, Icons.trending_up),
                  _kpiCard('Gastos', m['expense'] ?? 0, Icons.trending_down),
                  _kpiCard('Balance', balance, Icons.account_balance_wallet),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          _sectionTitle(
            'Gasto por categoría (mes)',
            subtitle:
                '${_start.year}-${_start.month.toString().padLeft(2, '0')} • reparto del 100%',
          ),
          const SizedBox(height: 8),

          StreamBuilder<List<FinanceTransaction>>(
            stream: FinanceFirestoreService.I.watchTransactions(
              from: _start,
              to: _end,
            ),
            builder: (context, s) {
              final txs = s.data ?? [];
              if (s.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              double totalExpense = 0;
              final Map<String, double> byCat = {};
              for (final t in txs) {
                if (t.type == TxType.expense) {
                  totalExpense += t.amount;
                  byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
                }
              }
              final entries =
                  byCat.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

              if (entries.isEmpty) {
                return _card(
                  child: const ListTile(title: Text('Sin gastos este mes')),
                );
              }

              final parts =
                  entries
                      .map(
                        (e) => _CategoryPart(
                          name: e.key,
                          amount: e.value,
                          pct: totalExpense <= 0 ? 0 : (e.value / totalExpense),
                        ),
                      )
                      .toList();

              return _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _stackedBar(parts),
                    const SizedBox(height: 12),
                    ...parts.map(
                      (p) => ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.label_outline,
                          color: _colorFor(p.name),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          '${(p.pct * 100).toStringAsFixed(1)}%  •  ${p.amount.toStringAsFixed(2)}',
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.show_chart),
                      title: const Text('Resumen'),
                      subtitle: Text(
                        'Categorías con gasto: ${entries.length}   •   Total gasto: ${totalExpense.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, double value, IconData icon) {
    return SizedBox(
      width: 220,
      child: _card(
        child: ListTile(
          leading: Icon(icon),
          title: Center(child: Text(title)),
          subtitle: Center(child: Text(value.toStringAsFixed(2))),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: child,
      ),
    );
  }

  Widget _stackedBar(List<_CategoryPart> parts) {
    final totalPct = parts.fold<double>(0, (p, e) => p + e.pct);
    if (totalPct <= 0) {
      return Container(
        height: 12,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children:
            parts.map((p) {
              final flex = (p.pct * 1000).round().clamp(1, 1000);
              return Expanded(
                flex: flex,
                child: Container(
                  height: 12,
                  color: _colorFor(p.name).withOpacity(0.85),
                ),
              );
            }).toList(),
      ),
    );
  }

  Color _colorFor(String key) {
    final h = key.hashCode & 0xFFFFFF;
    final r = 80 + (h % 120);
    final g = 80 + ((h >> 8) % 120);
    final b = 120 + ((h >> 16) % 100);
    return Color.fromARGB(255, r, g, b);
  }
}

class _CategoryPart {
  final String name;
  final double amount;
  final double pct;
  _CategoryPart({required this.name, required this.amount, required this.pct});
}
