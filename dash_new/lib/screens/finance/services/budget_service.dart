import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:mi_dashboard_personal/screens/finance/models/budget_model.dart';
import 'package:mi_dashboard_personal/screens/finance/services/transaction_service.dart';
import 'package:mi_dashboard_personal/screens/finance/models/transaction_model.dart';

class BudgetService {
  static final BudgetService I = BudgetService._();
  BudgetService._();

  final _col = FirebaseFirestore.instance.collection('finance_budgets');

  String? get _uid => fb_auth.FirebaseAuth.instance.currentUser?.uid;

  Stream<List<Budget>> watchAll() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return const Stream<List<Budget>>.empty();
    }
    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Budget.fromDoc).toList());
  }

  Future<void> upsert(Budget b) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    final data = b.toMap()..['userId'] = uid;
    if (b.id.isEmpty) {
      await _col.add(data);
    } else {
      await _col.doc(b.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> create(Budget b) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    await _col.add(b.toMap()..['userId'] = uid);
  }

  Future<void> update(Budget b) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    await _col.doc(b.id).set(b.toMap()..['userId'] = uid, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<double> getSpentForBudget(Budget b) async {
    DateTime rangeStart = b.startDate;
    DateTime rangeEnd = b.endDate ?? DateTime.now();

    // simplified monthly logic
    if (b.period == BudgetPeriod.monthly) {
      rangeStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      rangeEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    } else if (b.period == BudgetPeriod.weekly) {
      rangeStart = DateTime.now().subtract(const Duration(days: 7));
      rangeEnd = DateTime.now();
    }

    final txsStream = TransactionService.I.watch(
      from: rangeStart,
      to: rangeEnd,
      category: b.category,
      type: TxType.expense,
    );

    final txs = await txsStream.first;
    double spent = 0;
    for (final t in txs) {
      spent += t.amount;
    }
    return spent;
  }

  Stream<double> watchSpent(Budget b) {
    DateTime rangeStart = b.startDate;
    DateTime rangeEnd = b.endDate ?? DateTime.now();

    if (b.period == BudgetPeriod.monthly) {
      rangeStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      rangeEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    } else if (b.period == BudgetPeriod.weekly) {
      rangeStart = DateTime.now().subtract(const Duration(days: 7));
      rangeEnd = DateTime.now();
    }

    return TransactionService.I
        .watch(from: rangeStart, to: rangeEnd, category: b.category, type: TxType.expense)
        .map((txs) => txs.fold(0.0, (sum, tx) => sum + tx.amount));
  }

  Stream<List<BudgetWithProgress>> watchAllWithProgress() {
    return watchAll().asyncMap((budgets) async {
      final result = <BudgetWithProgress>[];
      for (final b in budgets) {
        final spent = await getSpentForBudget(b);
        result.add(BudgetWithProgress(budget: b, spent: spent));
      }
      return result;
    });
  }
}

class BudgetWithProgress {
  final Budget budget;
  final double spent;
  BudgetWithProgress({required this.budget, required this.spent});
  double get progress => spent / budget.amount;
  bool get isOverBudget => spent > budget.amount;
  bool get isNearLimit => progress >= 0.8;
}

