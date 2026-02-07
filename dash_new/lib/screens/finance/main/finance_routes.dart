import 'package:flutter/material.dart';

// V2 Redesigned screens
import '../main/finance_main_screen.dart';
import '../screens/transactions/transaction_form_screen.dart';
import '../screens/budgets/budget_form_screen.dart';
import '../screens/subscriptions/subscription_form_screen.dart';
import '../screens/debts/debt_form_screen.dart';
import '../screens/assets/asset_form_screen.dart';

// Models for argument passing
import 'package:mi_dashboard_personal/screens/finance/models/transaction_model.dart';
import 'package:mi_dashboard_personal/screens/finance/models/budget_model.dart';
import 'package:mi_dashboard_personal/screens/finance/models/subscription_model.dart';
import 'package:mi_dashboard_personal/screens/finance/models/loan_model.dart';
import 'package:mi_dashboard_personal/screens/finance/models/asset_model.dart';

Map<String, WidgetBuilder> financeRoutes = {
  '/finance': (_) => const FinanceMainScreen(initialIndex: 0),
  '/finance/transactions': (_) => const FinanceMainScreen(initialIndex: 1),
  '/finance/budgets': (_) => const FinanceMainScreen(initialIndex: 2),
  '/finance/subscriptions': (_) => const FinanceMainScreen(initialIndex: 3),
  '/finance/assets': (_) => const FinanceMainScreen(initialIndex: 4),
  '/finance/debts': (_) => const FinanceMainScreen(initialIndex: 5),
  '/finance/analytics': (_) => const FinanceMainScreen(initialIndex: 6),
  '/finance/settings': (_) => const FinanceMainScreen(initialIndex: 7),

  TransactionFormScreen.route: (context) {
    final tx = ModalRoute.of(context)?.settings.arguments as FinanceTransaction?;
    return TransactionFormScreen(transaction: tx);
  },

  BudgetFormScreen.route: (context) {
    final budget = ModalRoute.of(context)?.settings.arguments as Budget?;
    return BudgetFormScreen(budget: budget);
  },

  SubscriptionFormScreen.route: (context) {
    final sub = ModalRoute.of(context)?.settings.arguments as Subscription?;
    return SubscriptionFormScreen(subscription: sub);
  },

  '/finance/debts/form': (context) {
    final debt = ModalRoute.of(context)?.settings.arguments as Debt?;
    return DebtFormScreen(debt: debt);
  },

  AssetFormScreen.route: (context) {
    final asset = ModalRoute.of(context)?.settings.arguments as Asset?;
    return AssetFormScreen(asset: asset);
  },
};

