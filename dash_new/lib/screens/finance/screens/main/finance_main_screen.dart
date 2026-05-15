import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/finance/screens/analytics/analytics_screen.dart';
import 'package:focuslane/screens/finance/screens/assets/assets_screen.dart';
import 'package:focuslane/screens/finance/screens/dashboard/finance_dashboard_screen.dart';
import 'package:focuslane/screens/finance/screens/debts/debts_screen.dart';
import 'package:focuslane/screens/finance/screens/settings/finance_settings_screen.dart';
import 'package:focuslane/screens/finance/screens/subscriptions/subscriptions_screen.dart';
import 'package:focuslane/screens/finance/screens/transactions/transactions_screen.dart';

class FinanceMainScreen extends StatefulWidget {
  const FinanceMainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<FinanceMainScreen> createState() => _FinanceMainScreenState();
}

class _FinanceMainScreenState extends State<FinanceMainScreen> {
  static const _items = <FocusSectionNavItem>[
    FocusSectionNavItem(icon: Icons.dashboard_rounded, label: 'Panel'),
    FocusSectionNavItem(
      icon: Icons.receipt_long_rounded,
      label: 'Transacciones',
    ),
    FocusSectionNavItem(
      icon: Icons.subscriptions_rounded,
      label: 'Suscripciones',
    ),
    FocusSectionNavItem(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Activos',
    ),
    FocusSectionNavItem(icon: Icons.account_balance_rounded, label: 'Deudas'),
    FocusSectionNavItem(icon: Icons.analytics_rounded, label: 'Análisis'),
    FocusSectionNavItem(icon: Icons.settings_rounded, label: 'Ajustes'),
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
    return AppShell(
      title: 'Finanzas',
      subtitle: _subtitleFor(_selectedIndex),
      activeRoute: AppRoutes.financeDashboard,
      actions: [
        if (_selectedIndex == 1)
          FocusIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Nueva transacción',
            onPressed:
                () =>
                    Navigator.pushNamed(context, '/finance/transactions/form'),
          ),
        if (_selectedIndex == 2)
          FocusIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Nueva suscripción',
            onPressed:
                () =>
                    Navigator.pushNamed(context, '/finance/subscriptions/form'),
          ),
        if (_selectedIndex == 3)
          FocusIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Nuevo activo',
            onPressed:
                () => Navigator.pushNamed(context, '/finance/assets/form'),
          ),
        if (_selectedIndex == 4)
          FocusIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Nueva deuda',
            onPressed:
                () => Navigator.pushNamed(context, '/finance/debts/form'),
          ),
        const SizedBox(width: 10),
      ],
      child: Column(
        children: [
          FocusSectionNav(
            items: _items,
            selectedIndex: _selectedIndex,
            onSelected: _selectIndex,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                FinanceDashboardScreen(onSelectSection: _selectIndex),
                TransactionsScreen(onBackToDashboard: () => _selectIndex(0)),
                SubscriptionsScreen(onBackToDashboard: () => _selectIndex(0)),
                AssetsScreen(onBackToDashboard: () => _selectIndex(0)),
                DebtsScreen(onBackToDashboard: () => _selectIndex(0)),
                AnalyticsScreen(onBackToDashboard: () => _selectIndex(0)),
                FinanceSettingsScreen(onBackToDashboard: () => _selectIndex(0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitleFor(int index) {
    switch (index) {
      case 1:
        return 'Transacciones, categorías e importes.';
      case 2:
        return 'Suscripciones y proximos pagos.';
      case 3:
        return 'Activos y patrimonio registrado.';
      case 4:
        return 'Deudas y progreso de pago.';
      case 5:
        return 'Análisis de ingresos y gastos.';
      case 6:
        return 'Seguridad y bloqueo del módulo.';
      default:
        return 'Resumen protegido de presupuestos y movimientos.';
    }
  }
}
