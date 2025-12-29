import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/transaction_model.dart';
import 'package:mi_dashboard_personal/services/finance/transaction_service.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionsScreenV2 extends StatefulWidget {
  const TransactionsScreenV2({super.key});
  static const route = '/finance/transactions';

  @override
  State<TransactionsScreenV2> createState() => _TransactionsScreenV2State();
}

class _TransactionsScreenV2State extends State<TransactionsScreenV2> {
  DateTime? _from;
  DateTime? _to;
  TxType? _type;
  String? _category;
  String? _account;
  String? _envelope;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FinanceScreenBody(
        slivers: [
          const FinanceHeaderLarge(
            title: 'Transacciones',
            icon: Icons.receipt_long,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFiltersBar(),
                  const SizedBox(height: 12),
                  FinanceCard(child: _buildList()),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FinanceFab(
        onPressed:
            () => Navigator.pushNamed(context, '/finance/transactions/edit'),
        label: 'Añadir',
        icon: Icons.add,
      ),
    );
  }

  Widget _buildFiltersBar() {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FinanceChip(
          label: 'Todos',
          selected:
              _type == null &&
              _category == null &&
              _account == null &&
              _envelope == null &&
              _query.isEmpty,
          onTap: () {
            setState(() {
              _type = null;
              _category = null;
              _account = null;
              _envelope = null;
              _query = '';
              _from = null;
              _to = null;
            });
          },
        ),
        FinanceChip(
          label: 'Ingresos',
          selected: _type == TxType.income,
          onTap: () => setState(() => _type = TxType.income),
          color: Colors.green,
        ),
        FinanceChip(
          label: 'Gastos',
          selected: _type == TxType.expense,
          onTap: () => setState(() => _type = TxType.expense),
          color: Colors.red,
        ),
        FinanceChip(
          label: 'Transferencias',
          selected: _type == TxType.transfer,
          onTap: () => setState(() => _type = TxType.transfer),
          color: cs.secondary,
        ),
        ActionChip(
          label: const Text('Fecha'),
          avatar: const Icon(Icons.date_range, size: 18),
          onPressed: () async {
            final from = await showDatePicker(
              context: context,
              initialDate: _from ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            final to = await showDatePicker(
              context: context,
              initialDate: _to ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            setState(() {
              _from = from;
              _to = to;
            });
          },
        ),
        InputChip(
          label: Text(_category ?? 'Categoría'),
          onPressed: () async {
            final text = await _promptText('Categoría');
            if (text != null) setState(() => _category = text);
          },
          onDeleted:
              _category == null ? null : () => setState(() => _category = null),
        ),
        InputChip(
          label: Text(_account ?? 'Cuenta'),
          onPressed: () async {
            final text = await _promptText('Cuenta');
            if (text != null) setState(() => _account = text);
          },
          onDeleted:
              _account == null ? null : () => setState(() => _account = null),
        ),
        InputChip(
          label: Text(_envelope ?? 'Sobre'),
          onPressed: () async {
            final text = await _promptText('Sobre');
            if (text != null) setState(() => _envelope = text);
          },
          onDeleted:
              _envelope == null ? null : () => setState(() => _envelope = null),
        ),
        SizedBox(
          width: 220,
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<FinanceTransaction>>(
      stream: TransactionService.I.watch(
        from: _from,
        to: _to,
        type: _type,
        category: _category,
        accountId: _account,
        envelopeId: _envelope,
        query: _query,
      ),
      builder: (context, s) {
        final data = s.data ?? [];
        if (data.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Sin transacciones'),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final t = data[i];
            final sign = t.type == TxType.expense ? '-' : '+';
            return ListTile(
              leading: Icon(
                t.type == TxType.income
                    ? Icons.trending_up
                    : t.type == TxType.transfer
                    ? Icons.swap_horiz
                    : Icons.trending_down,
              ),
              title: Text(t.title),
              subtitle: Text(
                '${t.category ?? '—'} • ${t.date.toLocal().toString().split('.').first}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$sign${t.amount.toStringAsFixed(2)}'),
                  if ((t.originalCurrency ?? '').isNotEmpty &&
                      (t.fxRate ?? 0) > 0)
                    Text(
                      '${t.originalCurrency} @ ${t.fxRate}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    '/finance/transactions/edit',
                    arguments: t,
                  ),
            );
          },
        );
      },
    );
  }

  Future<String?> _promptText(String label) async {
    final ctl = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(label),
            content: TextField(
              controller: ctl,
              decoration: InputDecoration(labelText: label),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
    if (r == null || r.isEmpty) return null;
    return r;
  }
}
