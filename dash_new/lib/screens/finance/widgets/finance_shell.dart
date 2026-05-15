import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';

class FinanceShell extends StatelessWidget {
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

  final int selectedIndex;
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showExit;

  static const _routes = <String>[
    '/finance',
    '/finance/transactions',
    '/finance/subscriptions',
    '/finance/assets',
    '/finance/debts',
    '/finance/analytics',
    '/finance/settings',
  ];

  @override
  Widget build(BuildContext context) {
    final activeRoute =
        selectedIndex >= 0 && selectedIndex < _routes.length
            ? _routes[selectedIndex]
            : AppRoutes.financeDashboard;

    return AppShell(
      title: title,
      subtitle: subtitle,
      activeRoute: activeRoute,
      actions: [
        FocusIconButton(
          icon: showExit ? Icons.close_rounded : Icons.arrow_back_rounded,
          tooltip: showExit ? 'Salir de Finanzas' : 'Volver a Finanzas',
          onPressed: () => _goBack(context),
        ),
        const SizedBox(width: 10),
        ...?actions,
        if (actions != null && actions!.isNotEmpty) const SizedBox(width: 10),
      ],
      floatingActionButton: floatingActionButton,
      child: child,
    );
  }

  void _goBack(BuildContext context) {
    if (showExit) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.financeDashboard);
  }
}
