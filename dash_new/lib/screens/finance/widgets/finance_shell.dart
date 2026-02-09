import 'package:flutter/material.dart';
import '../../../ui/components/focus_module_header.dart';
import '../../../ui/layouts/module_shell.dart';
import '../../../ui/layouts/module_sidebar.dart';

class FinanceShell extends StatelessWidget {
  final int selectedIndex;
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showExit;

  const FinanceShell({
    super.key,
    required this.selectedIndex,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.showExit = false,
  });

  static const _routes = <String>[
    '/finance',
    '/finance/transactions',
    '/finance/budgets',
    '/finance/subscriptions',
    '/finance/assets',
    '/finance/debts',
    '/finance/analytics',
    '/finance/settings',
  ];

  static const _items = <ModuleSidebarItem>[
    ModuleSidebarItem(icon: Icons.dashboard_outlined, label: 'Panel'),
    ModuleSidebarItem(icon: Icons.receipt_long, label: 'Transacciones'),
    ModuleSidebarItem(icon: Icons.savings_outlined, label: 'Presupuestos'),
    ModuleSidebarItem(icon: Icons.subscriptions_outlined, label: 'Suscripciones'),
    ModuleSidebarItem(icon: Icons.account_balance_wallet_outlined, label: 'Activos'),
    ModuleSidebarItem(icon: Icons.account_balance_outlined, label: 'Deudas'),
    ModuleSidebarItem(icon: Icons.analytics_outlined, label: 'Analytics'),
    ModuleSidebarItem(icon: Icons.settings_outlined, label: 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    return ModuleShell(
      items: _items,
      selectedIndex: selectedIndex,
      onItemSelected: (i) => _onSelect(context, i),
      moduleTitle: 'Finanzas',
      moduleIcon: Icons.account_balance_wallet,
      actions: actions,
      floatingActionButton: floatingActionButton,
      appBarOverride: isDesktop
          ? FocusModuleHeader(
              title: title,
              subtitle: subtitle,
              leadingMode: showExit
                  ? FocusModuleLeadingMode.exitModule
                  : FocusModuleLeadingMode.backToModuleDashboard,
              onExit: () => _exitModule(context),
              onBack: () => _onSelect(context, 0),
              actions: actions,
            )
          : null,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 12),
        child: child,
      ),
    );
  }

  void _onSelect(BuildContext context, int index) {
    final route = _routes[index];
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushReplacementNamed(context, route);
  }

  void _exitModule(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
