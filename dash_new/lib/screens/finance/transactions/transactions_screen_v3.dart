import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/transaction_model.dart';
import 'package:mi_dashboard_personal/services/finance/transaction_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

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
  String _query = '';
  bool _showTemplates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          FinanceUI.sliverAppBar(
            context,
            title: 'Transacciones',
            backgroundIcon: Icons.receipt_long,
            actions: [
              IconButton(
                icon: Icon(_showTemplates ? Icons.list : Icons.star_outline),
                onPressed: () => setState(() => _showTemplates = !_showTemplates),
                tooltip: _showTemplates ? 'Ver lista' : 'Ver plantillas',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFiltersBar(),
                  const SizedBox(height: 16),
                  if (_showTemplates) _buildTemplates() else _buildList(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/finance/transactions/form'),
        icon: const Icon(Icons.add),
        label: Text('Nueva', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar transacciones...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _query = ''),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      onChanged: (v) => setState(() => _query = v),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildFiltersBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Todos'),
          selected: _type == null && _category == null && _from == null,
          onSelected: (_) {
            setState(() {
              _type = null;
              _category = null;
              _from = null;
              _to = null;
            });
          },
        ),
        FilterChip(
          label: const Text('Ingresos'),
          selected: _type == TxType.income,
          onSelected: (_) => setState(() => _type = _type == TxType.income ? null : TxType.income),
          avatar: Icon(Icons.trending_up, size: 18, color: FinanceUI.income),
        ),
        FilterChip(
          label: const Text('Gastos'),
          selected: _type == TxType.expense,
          onSelected: (_) => setState(() => _type = _type == TxType.expense ? null : TxType.expense),
          avatar: Icon(Icons.trending_down, size: 18, color: FinanceUI.expense),
        ),
        FilterChip(
          label: Text(_from == null ? 'Fecha' : DateFormat('d MMM').format(_from!)),
          selected: _from != null,
          onSelected: (_) async {
            if (_from != null) {
              setState(() {
                _from = null;
                _to = null;
              });
              return;
            }
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                _from = picked.start;
                _to = picked.end;
              });
            }
          },
          avatar: const Icon(Icons.date_range, size: 18),
        ),
        FutureBuilder<List<String>>(
          future: TransactionService.I.recentCategories(limit: 10),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox();
            return PopupMenuButton<String>(
              child: Chip(
                label: Text(_category ?? 'Categoría'),
                deleteIcon: _category != null ? const Icon(Icons.clear, size: 18) : null,
                onDeleted: _category != null ? () => setState(() => _category = null) : null,
              ),
              onSelected: (cat) => setState(() => _category = cat),
              itemBuilder: (_) => snap.data!
                  .map(
                    (cat) => PopupMenuItem(value: cat, child: Text(cat)),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTemplates() {
    return FutureBuilder<List<FinanceTransaction>>(
      future: TransactionService.I.getTemplates(limit: 10),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final templates = snap.data!;
        if (templates.isEmpty) {
          return FinanceUI.emptyState(
            context,
            message: 'No hay transacciones frecuentes aún',
            icon: Icons.star_outline,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FinanceUI.sectionTitle(context, 'Plantillas Frecuentes', subtitle: 'Toca para crear una copia'),
            ...templates.map((t) => Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (t.type == TxType.income ? FinanceUI.income : FinanceUI.expense).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        t.type == TxType.income ? Icons.trending_up : Icons.trending_down,
                        color: t.type == TxType.income ? FinanceUI.income : FinanceUI.expense,
                      ),
                    ),
                    title: Text(t.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text('${t.category ?? '—'} • ${t.amount.toStringAsFixed(2)}€'),
                    trailing: const Icon(Icons.copy),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/finance/transactions/form',
                        arguments: FinanceTransaction(
                          id: '',
                          userId: t.userId,
                          date: DateTime.now(),
                          type: t.type,
                          title: t.title,
                          amount: t.amount,
                          category: t.category,
                          subCategory: t.subCategory,
                          accountId: t.accountId,
                          notes: t.notes,
                          tags: t.tags,
                        ),
                      );
                    },
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<FinanceTransaction>>(
      stream: TransactionService.I.watch(
        from: _from,
        to: _to,
        type: _type,
        category: _category,
        query: _query.isEmpty ? null : _query,
      ),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final txs = snap.data!;
        if (txs.isEmpty) {
          return FinanceUI.emptyState(
            context,
            message: 'No hay transacciones',
            icon: Icons.receipt_long_outlined,
            actionText: 'Nueva transacción',
            onAction: () => Navigator.pushNamed(context, '/finance/transactions/form'),
          );
        }

        final grouped = _groupByDate(txs);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    entry.key,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                ...entry.value.map((t) => _buildTransactionCard(t)),
              ],
            );
          }).toList(),
        );
      },
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTransactionCard(FinanceTransaction t) {
    final sign = t.type == TxType.expense ? '-' : '+';
    final color = t.type == TxType.income ? FinanceUI.income : FinanceUI.expense;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            t.type == TxType.income ? Icons.trending_up : Icons.trending_down,
            color: color,
          ),
        ),
        title: Text(t.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t.category ?? '—'} ${t.subCategory != null ? '• ${t.subCategory}' : ''}'),
            if (t.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: t.tags.take(3).map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$sign${t.amount.toStringAsFixed(2)}€',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: color),
            ),
            Text(
              DateFormat('HH:mm').format(t.date),
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, '/finance/transactions/form', arguments: t),
        onLongPress: () => _showDeleteDialog(t),
      ),
    );
  }

  Map<String, List<FinanceTransaction>> _groupByDate(List<FinanceTransaction> txs) {
    final grouped = <String, List<FinanceTransaction>>{};
    for (final tx in txs) {
      final key = DateFormat('EEEE, d MMM yyyy', 'es').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  Future<void> _showDeleteDialog(FinanceTransaction t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: Text('¿Eliminar "${t.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await TransactionService.I.delete(t.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transacción eliminada', style: GoogleFonts.poppins())),
        );
      }
    }
  }
}
