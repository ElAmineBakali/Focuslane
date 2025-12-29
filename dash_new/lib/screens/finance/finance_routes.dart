import 'package:flutter/material.dart';

// V2 Redesigned screens
import 'finance_home_screen_v2.dart';
import 'transactions/transactions_screen_v3.dart';
import 'transactions/transaction_form_screen.dart';
import 'budgets/budgets_screen_v2.dart';
import 'budgets/budget_form_screen.dart';
import 'subscriptions/subscriptions_screen_v2.dart';
import 'subscriptions/subscription_form_screen.dart';
import 'debts/debts_screen_v2.dart';
import 'debts/debt_form_screen.dart';
import 'assets/assets_screen_v2.dart';
import 'assets/asset_form_screen.dart';
import 'analytics/analytics_screen_v2.dart';
import 'settings/settings_screen_v2.dart';
import 'variable_expenses/variable_expenses_screen.dart';
import 'deposits/deposits_screen.dart';

// Models for argument passing
import 'package:mi_dashboard_personal/models/finance/transaction_model.dart';
import 'package:mi_dashboard_personal/models/finance/budget_model.dart';
import 'package:mi_dashboard_personal/models/finance/subscription_model.dart';
import 'package:mi_dashboard_personal/models/finance/loan_model.dart';
import 'package:mi_dashboard_personal/models/finance/asset_model.dart';
import 'package:mi_dashboard_personal/models/finance/deposit_model.dart';
import 'package:mi_dashboard_personal/models/finance/variable_expense_model.dart';

Map<String, WidgetBuilder> financeRoutes = {
  FinanceHomeScreenV2.route: (_) => const FinanceHomeScreenV2(),

  // Transactions
  TransactionsScreenV2.route: (_) => const TransactionsScreenV2(),
  TransactionFormScreen.route: (context) {
    final tx = ModalRoute.of(context)?.settings.arguments as FinanceTransaction?;
    return TransactionFormScreen(transaction: tx);
  },

  // Budgets
  BudgetsScreenV2.route: (_) => const BudgetsScreenV2(),
  BudgetFormScreen.route: (context) {
    final budget = ModalRoute.of(context)?.settings.arguments as Budget?;
    return BudgetFormScreen(budget: budget);
  },

  // Subscriptions
  SubscriptionsScreenV2.route: (_) => const SubscriptionsScreenV2(),
  SubscriptionFormScreen.route: (context) {
    final sub = ModalRoute.of(context)?.settings.arguments as Subscription?;
    return SubscriptionFormScreen(subscription: sub);
  },

  // Debts
  DebtsScreenV2.route: (_) => const DebtsScreenV2(),
  '/finance/debts/form': (context) {
    final debt = ModalRoute.of(context)?.settings.arguments as Debt?;
    return DebtFormScreen(debt: debt);
  },

  // Variable expenses
  VariableExpensesScreen.route: (_) => const VariableExpensesScreen(),
  VariableExpenseFormScreen.route: (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is VariableExpense) {
      return VariableExpenseFormScreen(expense: args);
    } else if (args is Map<String, int>) {
      return VariableExpenseFormScreen(prefill: args);
    }
    return const VariableExpenseFormScreen();
  },

  // Deposits
  DepositsScreen.route: (_) => const DepositsScreen(),
  DepositFormScreen.route: (context) {
    final acc = ModalRoute.of(context)?.settings.arguments as DepositAccount?;
    return DepositFormScreen(account: acc);
  },
  DepositMovementsScreen.route: (context) {
    final acc = ModalRoute.of(context)!.settings.arguments as DepositAccount;
    return DepositMovementsScreen(account: acc);
  },
  DepositMovementFormScreen.route: (context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map) {
      return DepositMovementFormScreen(
        account: args['account'] as DepositAccount,
        movement: args['movement'] as DepositMovement?,
      );
    }
    final acc = args as DepositAccount;
    return DepositMovementFormScreen(account: acc);
  },

  // Assets
  AssetsScreenV2.route: (_) => const AssetsScreenV2(),
  AssetFormScreen.route: (context) {
    final asset = ModalRoute.of(context)?.settings.arguments as Asset?;
    return AssetFormScreen(asset: asset);
  },

  // Analytics
  AnalyticsScreenV2.route: (_) => const AnalyticsScreenV2(),

  // Settings
  SettingsScreenV2.route: (_) => const SettingsScreenV2(),
};
