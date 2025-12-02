import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/assets/assets_list_screen.dart';

import 'dashboard/finance_home_screen.dart';

import 'transactions/transactions_list_screen.dart';
import 'transactions/transaction_edit_screen.dart';

import 'budgets/budgets_screen.dart';
import 'budgets/budget_edit_screen.dart';

import 'subscriptions/subscriptions_screen.dart';
import 'subscriptions/subscription_edit_screen.dart';

import 'debts/people_debts_screen.dart';
import 'debts/person_edit_screen.dart';
import 'debts/debt_entry_edit_screen.dart';

import 'checklists/fixed_expenses_checklist_screen.dart'; // <- nombre correcto (sin 's' extra)
import 'checklists/variable_expenses_screen.dart';

import 'deposits/deposits_screen.dart';
import 'deposits/deposit_edit_screen.dart';
import 'deposits/deposit_movement_edit_screen.dart';

import 'analytics/finance_analytics_screen.dart';
import 'settings/finance_settings_screen.dart';

Map<String, WidgetBuilder> financeRoutes = {
  FinanceHomeScreen.route: (_) => const FinanceHomeScreen(),

  TransactionsListScreen.route: (_) => const TransactionsListScreen(),
  TransactionEditScreen.route: (_) => const TransactionEditScreen(),

  BudgetsScreen.route: (_) => const BudgetsScreen(),
  BudgetEditScreen.route: (_) => const BudgetEditScreen(),

  SubscriptionsScreen.route: (_) => const SubscriptionsScreen(),
  SubscriptionEditScreen.route: (_) => const SubscriptionEditScreen(),

  PeopleDebtsScreen.route: (_) => const PeopleDebtsScreen(),
  PersonEditScreen.route: (_) => const PersonEditScreen(),
  DebtEntryEditScreen.route: (_) => const DebtEntryEditScreen(),

  // NOMBRES EXACTOS (coinciden con las clases reales)
  FixedExpensesChecklistScreen.route:
      (_) => const FixedExpensesChecklistScreen(),
  VariableExpensesScreen.route: (_) => const VariableExpensesScreen(),

  DepositsScreen.route: (_) => const DepositsScreen(),
  DepositEditScreen.route: (_) => const DepositEditScreen(),
  DepositMovementEditScreen.route: (_) => const DepositMovementEditScreen(),

  FinanceAnalyticsScreen.route: (_) => const FinanceAnalyticsScreen(),
  FinanceSettingsScreen.route: (_) => const FinanceSettingsScreen(),
  AssetsListScreen.route: (_) => const AssetsListScreen(),
};
