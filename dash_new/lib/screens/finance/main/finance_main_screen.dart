import 'package:flutter/material.dart';
import '../../../design/ui/layouts/module_shell.dart';
import '../../../design/ui/layouts/module_sidebar.dart';
import '../screens/dashboard/finance_dashboard_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/budgets/budgets_screen.dart';
import '../screens/subscriptions/subscriptions_screen.dart';
import '../screens/assets/assets_screen.dart';
import '../screens/debts/debts_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/settings/finance_settings_screen.dart';

class FinanceMainScreen extends StatefulWidget {
  const FinanceMainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<FinanceMainScreen> createState() => _FinanceMainScreenState();
}

class _FinanceMainScreenState extends State<FinanceMainScreen> {
  static const _items = <ModuleSidebarItem>[
    ModuleSidebarItem(icon: Icons.dashboard_outlined, label: 'Panel'),
    ModuleSidebarItem(icon: Icons.receipt_long, label: 'Transacciones'),
    ModuleSidebarItem(icon: Icons.savings_outlined, label: 'Presupuestos'),
    ModuleSidebarItem(icon: Icons.subscriptions_outlined, label: 'Suscripciones'),
    ModuleSidebarItem(icon: Icons.account_balance_wallet_outlined, label: 'Activos'),
    ModuleSidebarItem(icon: Icons.account_balance_outlined, label: 'Deudas'),
    ModuleSidebarItem(icon: Icons.analytics_outlined, label: 'Analítica'),
    ModuleSidebarItem(icon: Icons.settings_outlined, label: 'Ajustes'),
  ];

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _items.length - 1);
  }

  void _selectIndex(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ModuleShell(
      items: _items,
      selectedIndex: _selectedIndex,
      onItemSelected: _selectIndex,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          FinanceDashboardScreen(onSelectSection: _selectIndex),
          TransactionsScreen(onBackToDashboard: () => _selectIndex(0)),
          BudgetsScreen(onBackToDashboard: () => _selectIndex(0)),
          SubscriptionsScreen(onBackToDashboard: () => _selectIndex(0)),
          AssetsScreen(onBackToDashboard: () => _selectIndex(0)),
          DebtsScreen(onBackToDashboard: () => _selectIndex(0)),
          AnalyticsScreen(onBackToDashboard: () => _selectIndex(0)),
          FinanceSettingsScreen(onBackToDashboard: () => _selectIndex(0)),
        ],
      ),
      moduleTitle: 'Finanzas',
      moduleIcon: Icons.account_balance_wallet,
    );
  }
}

