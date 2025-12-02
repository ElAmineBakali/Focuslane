import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/utils/app_links.dart';
import '../services/finance_firestore_service.dart';

class FinanceHomeScreen extends StatefulWidget {
  const FinanceHomeScreen({super.key});
  static const route = '/finance';

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends State<FinanceHomeScreen> {
  DateTime month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final svc = FinanceFirestoreService.I;
    final monthStart = DateTime(month.year, month.month, 1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Atajos',
            icon: const Icon(Icons.link_rounded),
            onSelected: (v) {
              if (v == 'imagin') AppLinks.openImagin();
              if (v == 'traderepublic') AppLinks.openTradeRepublic();
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'imagin', child: Text('Imagin')),
                  PopupMenuItem(
                    value: 'traderepublic',
                    child: Text('Trade Republic'),
                  ),
                ],
          ),
          /* IconButton(
            tooltip: 'Historial (Transacciones)',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/finance/transactions'),
          ), */
          IconButton(
            tooltip: 'Analíticas',
            icon: const Icon(Icons.insights),
            onPressed: () => Navigator.pushNamed(context, '/finance/analytics'),
          ),
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/finance/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            StreamBuilder<Map<String, double>>(
              stream: svc.watchMonthTotals(month: monthStart),
              builder: (context, snap) {
                final m =
                    snap.data ?? const {'income': 0, 'expense': 0, 'saving': 0};
                final items = [
                  _kpiSmall(
                    context,
                    'Ingresos (mes)',
                    m['income']!.toStringAsFixed(2),
                    Icons.trending_up,
                  ),
                  _kpiSmall(
                    context,
                    'Gastos (mes)',
                    m['expense']!.toStringAsFixed(2),
                    Icons.trending_down,
                  ),
                  _kpiSmall(
                    context,
                    'Balance (mes)',
                    m['saving']!.toStringAsFixed(2),
                    Icons.savings,
                  ),
                ];
                return _kpiResponsive(items);
              },
            ),
            const SizedBox(height: 16),

            // ---- Navegación principal ----
            Card(
              child: ListTile(
                leading: const Icon(Icons.list),
                title: const Text('Transacciones'),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => Navigator.pushNamed(context, '/finance/transactions'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people_alt_outlined),
                title: const Text('Deudas con personas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/finance/people'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('Gastos fijos'),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      '/finance/checklist/fixed',
                    ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.pending_actions_outlined),
                title: const Text('Gastos variables'),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      '/finance/checklist/variable',
                    ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Depósitos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/finance/deposits'),
              ),
            ),

            // ---- NUEVO: Patrimonio (activos con ubicación) ----
            Card(
              child: ListTile(
                leading: const Icon(Icons.maps_home_work_outlined),
                title: const Text('Patrimonio'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/finance/assets'),
              ),
            ),

            /* Card(
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Ajustes de finanzas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/finance/settings'),
              ),
            ), */
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva transacción'),
        onPressed:
            () => Navigator.pushNamed(context, '/finance/transactions/edit'),
      ),
    );
  }

  Widget _kpiSmall(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += 2) {
          if (i + 1 < items.length) {
            rows.add(
              Row(
                children: [
                  Expanded(child: items[i]),
                  const SizedBox(width: 8),
                  Expanded(child: items[i + 1]),
                ],
              ),
            );
          } else {
            rows.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: (w / 2) - 4),
                  Expanded(child: items[i]),
                ],
              ),
            );
          }
          rows.add(const SizedBox(height: 8));
        }
        return Column(children: rows);
      },
    );
  }
}
