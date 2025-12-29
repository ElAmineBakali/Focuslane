import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/services/finance/variable_expense_service.dart';
import 'package:mi_dashboard_personal/models/finance/variable_expense_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class VariableExpensesScreen extends StatefulWidget {
  const VariableExpensesScreen({super.key});
  static const route = '/finance/variable-expenses';

  @override
  State<VariableExpensesScreen> createState() => _VariableExpensesScreenState();
}

class _VariableExpensesScreenState extends State<VariableExpensesScreen> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FinanceScreenBody(
        slivers: [
          FinanceUI.sliverAppBar(
            context,
            title: 'Gastos variables',
            backgroundIcon: Icons.receipt_long,
            actions: [
              IconButton(
                onPressed: _pickMonth,
                icon: const Icon(Icons.date_range),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: StreamBuilder<List<VariableExpense>>(
                stream: VariableExpenseService.I.watchByMonth(_month, _year),
                builder: (context, snap) {
                  final items = snap.data ?? [];
                  final total = items.fold<double>(0, (s, e) => s + e.estimatedAmount);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(total),
                      const SizedBox(height: 16),
                      if (items.isEmpty)
                        FinanceUI.emptyState(
                          context,
                          icon: Icons.inbox_outlined,
                          message: 'Sin gastos variables. Crea tu primer gasto variable para este mes.',
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _item(items[i]).animate().fadeIn(delay: Duration(milliseconds: 30 * i)),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FinanceFab(
        onPressed: () => Navigator.pushNamed(context, VariableExpenseFormScreen.route, arguments: {
          'month': _month,
          'year': _year,
        }),
        label: 'Nuevo gasto',
        icon: Icons.add,
      ),
    );
  }

  Widget _header(double total) {
    final monthText = DateFormat.MMMM('es').format(DateTime(_year, _month)).toUpperCase();
    return FinanceUI.gradientCard(
      context: context,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.15),
            child: const Icon(Icons.receipt_long, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(monthText, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('$_year', style: GoogleFonts.poppins(color: Colors.white70)),
                const SizedBox(height: 6),
                Text('${total.toStringAsFixed(2)}€', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                Text('Estimado total', style: GoogleFonts.poppins(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(VariableExpense v) {
    final statusColor = v.status == 'done' ? FinanceUI.income : FinanceUI.warning;
    return Card(
      child: ListTile(
        onTap: () => Navigator.pushNamed(
          context,
          VariableExpenseFormScreen.route,
          arguments: v,
        ),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(
            v.status == 'done' ? Icons.check : Icons.schedule,
            color: statusColor,
          ),
        ),
        title: Text(v.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(v.category, style: GoogleFonts.poppins(color: Colors.grey.shade600)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${v.estimatedAmount.toStringAsFixed(2)}€', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            Text(v.status == 'done' ? 'Pagado' : 'Pendiente', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    DateTime initial = DateTime(_year, _month);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2, 1),
      lastDate: DateTime(now.year + 2, 12),
      selectableDayPredicate: (day) => day.day == 1,
      helpText: 'Selecciona mes (usa día 1)',
    );
    if (picked != null) {
      setState(() {
        _month = picked.month;
        _year = picked.year;
      });
    }
  }
}

class VariableExpenseFormScreen extends StatefulWidget {
  const VariableExpenseFormScreen({super.key, this.expense, this.prefill});
  static const route = '/finance/variable-expenses/form';
  final VariableExpense? expense;
  final Map<String, int>? prefill; // {month, year}

  @override
  State<VariableExpenseFormScreen> createState() => _VariableExpenseFormScreenState();
}

class _VariableExpenseFormScreenState extends State<VariableExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  late int _month;
  late int _year;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.estimatedAmount.toStringAsFixed(2);
      _categoryCtrl.text = e.category;
      _month = e.month;
      _year = e.year;
      _done = e.status == 'done';
    } else {
      _month = widget.prefill?['month'] ?? DateTime.now().month;
      _year = widget.prefill?['year'] ?? DateTime.now().year;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.expense == null ? 'Nuevo gasto' : 'Editar gasto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Monto estimado', suffixText: '€'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _monthField()),
                  const SizedBox(width: 12),
                  Expanded(child: _yearField()),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Pagado'),
                value: _done,
                onChanged: (v) => setState(() => _done = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthField() {
    final months = List.generate(12, (i) => i + 1);
    return DropdownButtonFormField<int>(
      value: _month,
      decoration: const InputDecoration(labelText: 'Mes'),
      items: months
          .map((m) => DropdownMenuItem(
                value: m,
                child: Text(DateFormat.MMMM('es').format(DateTime(2024, m))),
              ))
          .toList(),
      onChanged: (v) => setState(() => _month = v ?? _month),
    );
  }

  Widget _yearField() {
    final nowYear = DateTime.now().year;
    final years = [for (int y = nowYear - 2; y <= nowYear + 2; y++) y];
    return DropdownButtonFormField<int>(
      value: _year,
      decoration: const InputDecoration(labelText: 'Año'),
      items: years
          .map((y) => DropdownMenuItem(
                value: y,
                child: Text(y.toString()),
              ))
          .toList(),
      onChanged: (v) => setState(() => _year = v ?? _year),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final exp = VariableExpense(
      id: widget.expense?.id ?? '',
      userId: widget.expense?.userId ?? '',
      title: _titleCtrl.text.trim(),
      estimatedAmount: double.parse(_amountCtrl.text),
      category: _categoryCtrl.text.isEmpty ? 'General' : _categoryCtrl.text.trim(),
      month: _month,
      year: _year,
      status: _done ? 'done' : 'pending',
      relatedTxId: widget.expense?.relatedTxId,
    );
    await VariableExpenseService.I.upsert(exp);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }
}
