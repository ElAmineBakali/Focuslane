import 'package:flutter/material.dart';

// V2 Redesigned screens
import '../main/finance_main_screen.dart';
import '../screens/forms/transaction_form_screen.dart';
import '../screens/forms/budget_form_screen.dart';
import '../screens/forms/subscription_form_screen.dart';
import '../screens/forms/debt_form_screen.dart';
import '../screens/forms/asset_form_screen.dart';
import '../widgets/finance_access_gate.dart';

// Models for argument passing
import 'package:focuslane/screens/finance/models/transaction_model.dart';
import 'package:focuslane/screens/finance/models/budget_model.dart';
import 'package:focuslane/screens/finance/models/subscription_model.dart';
import 'package:focuslane/screens/finance/models/loan_model.dart';
import 'package:focuslane/screens/finance/models/asset_model.dart';

Widget _financeProtected(Widget child) {
  return FinanceAccessGate(child: child);
}

Map<String, WidgetBuilder> financeRoutes = {
  '/finance': (_) => _financeProtected(const FinanceMainScreen(initialIndex: 0)),
  '/finance/transactions':
    (_) => _financeProtected(const FinanceMainScreen(initialIndex: 1)),
  '/finance/budgets':
    (_) => _financeProtected(const FinanceMainScreen(initialIndex: 2)),
  '/finance/subscriptions':
    (_) => _financeProtected(const FinanceMainScreen(initialIndex: 3)),
  '/finance/assets':
    (_) => _financeProtected(const FinanceMainScreen(initialIndex: 4)),
  '/finance/debts':
    (_) => _financeProtected(const FinanceMainScreen(initialIndex: 5)),
  '/finance/analytics':
    (_) => _financeProtected(const FinanceMainScreen(initialIndex: 6)),
  '/finance/settings':
    (_) => _financeProtected(const FinanceMainScreen(initialIndex: 7)),

  TransactionFormScreen.route: (context) {
    final tx = ModalRoute.of(context)?.settings.arguments as FinanceTransaction?;
    return _financeProtected(TransactionFormScreen(transaction: tx));
  },

  BudgetFormScreen.route: (context) {
    final budget = ModalRoute.of(context)?.settings.arguments as Budget?;
    return _financeProtected(BudgetFormScreen(budget: budget));
  },

  SubscriptionFormScreen.route: (context) {
    final sub = ModalRoute.of(context)?.settings.arguments as Subscription?;
    return _financeProtected(SubscriptionFormScreen(subscription: sub));
  },

  '/finance/debts/form': (context) {
    final debt = ModalRoute.of(context)?.settings.arguments as Debt?;
    return _financeProtected(DebtFormScreen(debt: debt));
  },

  AssetFormScreen.route: (context) {
    final asset = ModalRoute.of(context)?.settings.arguments as Asset?;
    return _financeProtected(AssetFormScreen(asset: asset));
  },
};


