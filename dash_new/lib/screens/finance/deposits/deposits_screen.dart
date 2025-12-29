import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/services/finance/deposit_service.dart';
import 'package:mi_dashboard_personal/models/finance/deposit_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class DepositsScreen extends StatelessWidget {
  const DepositsScreen({super.key});
  static const route = '/finance/deposits';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FinanceScreenBody(
        slivers: [
          const FinanceHeaderLarge(title: 'Depósitos', icon: Icons.savings_outlined),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: StreamBuilder<List<DepositAccount>>(
                stream: DepositService.I.watchAccounts(),
                builder: (context, snap) {
                  final accounts = snap.data ?? [];
                  if (accounts.isEmpty) {
                    return FinanceUI.emptyState(
                      context,
                      icon: Icons.inbox_outlined,
                      message: 'Sin cuentas. Crea tu primera cuenta de depósito.',
                    );
                  }
                  return Column(
                    children: [
                      _totalCard(context, accounts),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: accounts.length,
                        itemBuilder: (context, i) => _accountTile(context, accounts[i]).animate().fadeIn(delay: Duration(milliseconds: 40 * i)),
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
        onPressed: () => Navigator.pushNamed(context, DepositFormScreen.route),
        label: 'Nueva cuenta',
        icon: Icons.add,
      ),
    );
  }

  Widget _totalCard(BuildContext context, List<DepositAccount> accounts) {
    final total = accounts.fold<double>(0, (sum, a) => sum + (a.balance ?? 0));
    return FinanceUI.gradientCard(
      context: context,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.15),
            child: const Icon(Icons.savings, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total ahorros', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('Cuentas', style: GoogleFonts.poppins(color: Colors.white70)),
                const SizedBox(height: 6),
                Text('${total.toStringAsFixed(2)}€', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                Text('Saldo combinado', style: GoogleFonts.poppins(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountTile(BuildContext context, DepositAccount acc) {
    return FutureBuilder<double>(
      future: DepositService.I.getBalanceForAccount(acc.id),
      builder: (context, snap) {
        final bal = snap.data ?? acc.balance ?? 0;
        return Card(
          child: ListTile(
            onTap: () => Navigator.pushNamed(
              context,
              DepositMovementsScreen.route,
              arguments: acc,
            ),
            title: Text(acc.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text(acc.bank ?? '—', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${bal.toStringAsFixed(2)}€', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                Text(acc.type ?? 'Cuenta', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DepositFormScreen extends StatefulWidget {
  const DepositFormScreen({super.key, this.account});
  static const route = '/finance/deposits/form';
  final DepositAccount? account;

  @override
  State<DepositFormScreen> createState() => _DepositFormScreenState();
}

class _DepositFormScreenState extends State<DepositFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _nameCtrl.text = a.name;
      _bankCtrl.text = a.bank ?? '';
      _typeCtrl.text = a.type ?? '';
      _ibanCtrl.text = a.iban ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.account == null ? 'Nueva cuenta' : 'Editar cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankCtrl,
                decoration: const InputDecoration(labelText: 'Banco'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeCtrl,
                decoration: const InputDecoration(labelText: 'Tipo (ahorro, vista...)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ibanCtrl,
                decoration: const InputDecoration(labelText: 'IBAN / Nº cuenta'),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final acc = DepositAccount(
      id: widget.account?.id ?? '',
      userId: widget.account?.userId ?? '',
      name: _nameCtrl.text.trim(),
      bank: _bankCtrl.text.trim().isEmpty ? null : _bankCtrl.text.trim(),
      type: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
      iban: _ibanCtrl.text.trim().isEmpty ? null : _ibanCtrl.text.trim(),
      balance: widget.account?.balance,
      createdAt: widget.account?.createdAt ?? DateTime.now(),
    );
    await DepositService.I.upsertAccount(acc);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bankCtrl.dispose();
    _typeCtrl.dispose();
    _ibanCtrl.dispose();
    super.dispose();
  }
}

class DepositMovementsScreen extends StatelessWidget {
  const DepositMovementsScreen({super.key, required this.account});
  static const route = '/finance/deposits/movements';
  final DepositAccount account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
      body: StreamBuilder<List<DepositMovement>>(
        stream: DepositService.I.watchMovementsForAccount(account.id),
        builder: (context, snap) {
          final movs = snap.data ?? [];
          if (movs.isEmpty) {
            return Center(
              child: FinanceUI.emptyState(
                context,
                icon: Icons.swap_vert,
                message: 'Sin movimientos. Registra depósitos o retiros.',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: movs.length,
            itemBuilder: (context, i) => _movementTile(context, movs[i]),
          );
        },
      ),
      floatingActionButton: FinanceFab(
        onPressed: () => Navigator.pushNamed(
          context,
          DepositMovementFormScreen.route,
          arguments: account,
        ),
        label: 'Nuevo movimiento',
        icon: Icons.add,
      ),
    );
  }

  Widget _movementTile(BuildContext context, DepositMovement m) {
    final isDeposit = m.type == 'deposit' || m.type == 'interest';
    final color = isDeposit ? FinanceUI.income : FinanceUI.expense;
    return Card(
      child: ListTile(
        title: Text(m.description ?? m.type, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(DateFormat('d MMM yyyy').format(m.date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${m.amount.toStringAsFixed(2)}€', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: color)),
            Text(m.type, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class DepositMovementFormScreen extends StatefulWidget {
  const DepositMovementFormScreen({super.key, required this.account, this.movement});
  static const route = '/finance/deposits/movements/form';
  final DepositAccount account;
  final DepositMovement? movement;

  @override
  State<DepositMovementFormScreen> createState() => _DepositMovementFormScreenState();
}

class _DepositMovementFormScreenState extends State<DepositMovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'deposit';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final m = widget.movement;
    if (m != null) {
      _amountCtrl.text = m.amount.toStringAsFixed(2);
      _descCtrl.text = m.description ?? '';
      _type = m.type;
      _date = m.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.movement == null ? 'Nuevo movimiento' : 'Editar movimiento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'deposit', child: Text('Depósito')),
                  DropdownMenuItem(value: 'withdrawal', child: Text('Retiro')),
                  DropdownMenuItem(value: 'interest', child: Text('Interés')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'deposit'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Monto', suffixText: '€'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n == 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha'),
                subtitle: Text(DateFormat('d MMM yyyy').format(_date)),
                trailing: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text);
    final m = DepositMovement(
      id: widget.movement?.id ?? '',
      accountId: widget.account.id,
      amount: amount,
      type: _type,
      date: _date,
      description: _descCtrl.text.isEmpty ? null : _descCtrl.text.trim(),
    );
    await DepositService.I.upsertMovement(m);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
}
