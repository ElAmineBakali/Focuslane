// lib/services/finance_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/finance_models.dart';

class FinanceFirestoreService {
  FinanceFirestoreService._();
  static final FinanceFirestoreService I = FinanceFirestoreService._();
  final _db = FirebaseFirestore.instance;
  // 🔁 Cambio mínimo: exigir usuario autenticado (eliminar fallback 'local')
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// ---------- Paths ----------
  CollectionReference get _txCol => _db
      .collection('users')
      .doc(_uid)
      .collection('finance')
      .doc('data')
      .collection('transactions');
  CollectionReference get _budgetsCol => _db
      .collection('users')
      .doc(_uid)
      .collection('finance')
      .doc('data')
      .collection('budgets');
  CollectionReference get _subsCol => _db
      .collection('users')
      .doc(_uid)
      .collection('finance')
      .doc('data')
      .collection('subscriptions');
  CollectionReference get _peopleCol => _db
      .collection('users')
      .doc(_uid)
      .collection('finance')
      .doc('data')
      .collection('people');
  CollectionReference _personLedgerCol(String personId) =>
      _peopleCol.doc(personId).collection('ledger');
  CollectionReference get _varExpCol => _db
      .collection('users')
      .doc(_uid)
      .collection('finance')
      .doc('data')
      .collection('variableExpenses');
  CollectionReference get _depositsCol => _db
      .collection('users')
      .doc(_uid)
      .collection('finance')
      .doc('data')
      .collection('deposits');
  DocumentReference get _metaDoc =>
      _db.collection('users').doc(_uid).collection('finance').doc('meta');

  /// ---------- Transactions ----------
  Stream<List<FinanceTransaction>> watchTransactions({
    DateTime? from,
    DateTime? to,
    String? category,
    TxType? type,
  }) {
    Query q = _txCol.orderBy('date', descending: true);
    if (type != null) q = q.where('type', isEqualTo: type.name);
    if (category != null) q = q.where('category', isEqualTo: category);
    if (from != null)
      q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    if (to != null)
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    return q.snapshots().map(
      (s) => s.docs.map(FinanceTransaction.fromSnap).toList(),
    );
  }

  Future<void> addTransaction(FinanceTransaction t) async {
    await _txCol.add(t.toMap());
  }

  Future<void> updateTransaction(FinanceTransaction t) async {
    await _txCol.doc(t.id).update(t.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _txCol.doc(id).delete();
  }

  /// ---------- Budgets ----------
  Stream<List<Budget>> watchBudgets() => _budgetsCol
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Budget.fromSnap).toList());

  Future<void> addBudget(Budget b) async {
    final m = b.toMap();
    final bool isActive = (m['active'] ?? m['_active'] ?? true) as bool;
    m['active'] = isActive;
    m['_active'] = isActive; // compatibilidad hacia atrás
    await _budgetsCol.add(m);
  }

  Future<void> updateBudget(Budget b) async {
    final m = b.toMap();
    final bool isActive = (m['active'] ?? m['_active'] ?? true) as bool;
    m['active'] = isActive;
    m['_active'] = isActive;
    await _budgetsCol.doc(b.id).update(m);
  }

  Future<void> deleteBudget(String id) async => _budgetsCol.doc(id).delete();

  /// ---------- Subscriptions (Fijos) ----------
  Stream<List<Subscription>> watchSubscriptions() => _subsCol
      .orderBy('order', descending: false)
      .snapshots()
      .map((s) => s.docs.map(Subscription.fromSnap).toList());

  Future<void> addSubscription(Subscription x) async {
    final m = x.toMap();
    m['order'] = m['order'] ?? DateTime.now().millisecondsSinceEpoch;
    await _subsCol.add(m);
  }

  Future<void> updateSubscription(Subscription x) async =>
      _subsCol.doc(x.id).update(x.toMap());

  Future<void> updateSubscriptionsOrder(List<Subscription> subs) async {
    final batch = _db.batch();
    for (var i = 0; i < subs.length; i++) {
      final s = subs[i];
      final ref = _subsCol.doc(s.id);
      batch.update(ref, {'order': i});
    }
    await batch.commit();
  }

  /// Backfill: asigna 'order' secuencial solo a los que no lo tengan.
  Future<void> backfillSubscriptionsOrder() async {
    final snap = await _subsCol.get();
    final batch = _db.batch();
    int idx = 0;
    for (final d in snap.docs) {
      final data = d.data() as Map<String, dynamic>;
      if (!data.containsKey('order')) {
        batch.update(d.reference, {'order': idx});
      }
      idx++; // mantiene orden actual del snapshot (por nombre)
    }
    await batch.commit();
  }

  Future<void> deleteSubscription(String id) async => _subsCol.doc(id).delete();

  /// ---------- People / Debts ----------
  Stream<List<Person>> watchPeople() => _peopleCol
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Person.fromSnap).toList());

  Future<void> addPerson(Person p) async => _peopleCol.add(p.toMap());

  // 🔧 CAMBIO: no sobrescribir 'balance' cuando se edita la persona.
  Future<void> updatePerson(Person p) async {
    final m = p.toMap();
    m.remove('balance'); // <- lo gestiona el ledger/recalc
    await _peopleCol.doc(p.id).update(m);
  }

  Future<void> deletePerson(String id) async => _peopleCol.doc(id).delete();

  Stream<List<DebtEntry>> watchDebtLedger(String personId) =>
      _personLedgerCol(personId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs.map(DebtEntry.fromSnap).toList());

  Future<void> addDebtEntry(String personId, DebtEntry e) async {
    await _personLedgerCol(personId).add(e.toMap());
    await _recalcPersonBalance(personId);
  }

  Future<void> updateDebtEntry(String personId, DebtEntry e) async {
    await _personLedgerCol(personId).doc(e.id).update(e.toMap());
    await _recalcPersonBalance(personId);
  }

  Future<void> deleteDebtEntry(String personId, String entryId) async {
    await _personLedgerCol(personId).doc(entryId).delete();
    await _recalcPersonBalance(personId);
  }

  Future<void> _recalcPersonBalance(String personId) async {
    final personRef = _peopleCol.doc(personId);
    final ledger = await _personLedgerCol(personId).get();

    double sum = 0;
    for (final d in ledger.docs) {
      final v = d.data() as Map<String, dynamic>;
      final a = (v['amount'] is num) ? (v['amount'] as num).toDouble() : 0.0;
      sum += a;
    }

    final batch = _db.batch();
    batch.update(personRef, {'balance': sum, 'updatedAt': Timestamp.now()});

    // recalcular meta global
    final peopleSnap = await _peopleCol.get();
    double toReceive = 0, toPay = 0;
    for (final p in peopleSnap.docs) {
      final b = ((p.data() as Map<String, dynamic>)['balance'] ?? 0);
      final bal = (b is num) ? b.toDouble() : 0.0;
      if (bal > 0) {
        toReceive += bal;
      } else {
        toPay += bal; // bal es negativo
      }
    }

    batch.set(_metaDoc, {
      'debtsSummary': {
        'totalToReceive': toReceive,
        'totalToPay': toPay.abs(),
        'lastUpdated': Timestamp.now(),
      },
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<Map<String, dynamic>?> watchDebtsSummary() =>
      _metaDoc.snapshots().map((d) => d.data() as Map<String, dynamic>?);

  /// ---------- Variable Expenses ----------
  Stream<List<VariableExpenseItem>> watchVariableExpenses(String periodKey) =>
      _varExpCol
          .doc(periodKey)
          .collection('items')
          .orderBy('name')
          .snapshots()
          .map((s) => s.docs.map(VariableExpenseItem.fromSnap).toList());

  Future<void> addVariableExpense(
    String periodKey,
    VariableExpenseItem v,
  ) async => _varExpCol.doc(periodKey).collection('items').add(v.toMap());

  Future<void> updateVariableExpense(
    String periodKey,
    VariableExpenseItem v,
  ) async =>
      _varExpCol.doc(periodKey).collection('items').doc(v.id).update(v.toMap());

  Future<void> deleteVariableExpense(String periodKey, String id) async =>
      _varExpCol.doc(periodKey).collection('items').doc(id).delete();

  /// ---------- Deposits ----------
  Stream<List<Deposit>> watchDeposits() => _depositsCol
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Deposit.fromSnap).toList());

  Future<void> addDeposit(Deposit d) async => _depositsCol.add(d.toMap());

  Future<void> updateDeposit(Deposit d) async =>
      _depositsCol.doc(d.id).update(d.toMap());

  Future<void> deleteDeposit(String id) async => _depositsCol.doc(id).delete();

  Stream<QuerySnapshot> watchDepositMovements(String depositId) =>
      _depositsCol
          .doc(depositId)
          .collection('movements')
          .orderBy('date', descending: true)
          .snapshots();

  Future<void> addDepositMovement(
    String depositId, {
    required double amount,
    required DateTime date,
    String? reason,
    String? txRef,
  }) async {
    final ref = _depositsCol.doc(depositId);
    await ref.collection('movements').add({
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'reason': reason,
      'txRef': txRef,
    });
    final snap = await ref.get();
    final cur = ((snap['amount'] ?? 0) as num).toDouble();
    await ref.update({'amount': cur + amount});
  }

  /// ---------- Simple KPIs para dashboard (puntual) ----------
  Future<Map<String, double>> monthTotals({required DateTime month}) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final qs =
        await _txCol
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();
    double inc = 0, exp = 0;
    for (final d in qs.docs) {
      final type = (d['type'] ?? 'expense').toString();
      final amount = ((d['amount'] ?? 0) as num).toDouble();
      if (type == 'income') {
        inc += amount;
      } else if (type == 'expense')
        exp += amount;
    }
    return {'income': inc, 'expense': exp, 'saving': inc - exp};
  }

  /// ---------- KPIs en vivo para dashboard (reactivo) ----------
  Stream<Map<String, double>> watchMonthTotals({required DateTime month}) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _txCol
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((s) {
          double inc = 0, exp = 0;
          for (final d in s.docs) {
            final m = d.data() as Map<String, dynamic>;
            final t = (m['type'] ?? 'expense').toString();
            final a = (m['amount'] as num?)?.toDouble() ?? 0.0;
            if (t == 'income') {
              inc += a;
            } else if (t == 'expense')
              exp += a;
          }
          return {'income': inc, 'expense': exp, 'saving': inc - exp};
        });
  }

  String periodKey(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}";

  // === Historial mensual dentro de cada suscripción ===
  DocumentReference _subHistoryDoc(String subId, String pk) {
    return _subsCol.doc(subId).collection('history').doc(pk);
  }

  Stream<bool> watchSubscriptionPaidForMonth(String subId, String pk) {
    return _subHistoryDoc(subId, pk).snapshots().map((d) {
      final data = d.data() as Map<String, dynamic>?;
      return data?['paid'] == true;
    });
  }

  Future<void> markSubscriptionPaidForMonth(
    Subscription s,
    DateTime when,
  ) async {
    final pk = periodKey(when);
    final txRef = await _txCol.add(
      FinanceTransaction(
        id: '',
        title: s.name,
        amount: s.amount,
        type: TxType.expense,
        category: s.category,
        date: when,
      ).toMap(),
    );

    await _subHistoryDoc(s.id, pk).set({
      'paid': true,
      'paidAt': Timestamp.fromDate(when),
      'txId': txRef.id,
      'amount': s.amount,
    });
  }

  Future<void> unmarkSubscriptionPaidForMonth(
    Subscription s,
    DateTime when,
  ) async {
    final pk = periodKey(when);
    final hist = await _subHistoryDoc(s.id, pk).get();
    final data = hist.data() as Map<String, dynamic>?;
    final txId = data?['txId'] as String?;
    if (txId != null && txId.isNotEmpty) {
      await _txCol.doc(txId).delete();
    }
    await _subHistoryDoc(s.id, pk).delete();
  }

  // Totales por categorías (privado, por si lo re-usas)
  // ignore: unused_element
  Future<Map<String, double>> _monthExpensesTotals({
    required DateTime month,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final qs =
        await _txCol
            .where('type', isEqualTo: TxType.expense.name)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();

    final byCat = <String, double>{};
    for (final d in qs.docs) {
      final m = d.data() as Map<String, dynamic>;
      final cat = (m['category'] ?? 'Other') as String;
      final amt = (m['amount'] as num?)?.toDouble() ?? 0.0;
      byCat[cat] = (byCat[cat] ?? 0) + amt;
    }
    return byCat;
  }

  /// ---------- Presupuestos: progreso ----------
  Future<List<Map<String, dynamic>>> budgetsProgress({
    required DateTime month,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snap = await _budgetsCol.get();

    bool isActive(Map<String, dynamic> m) {
      final a = m['active'];
      final b = m['_active'];
      if (a is bool) return a;
      if (b is bool) return b;
      if (a is String) return a.toLowerCase() == 'true';
      if (b is String) return b.toLowerCase() == 'true';
      return true;
    }

    String periodOf(Map<String, dynamic> m) {
      final p = (m['period'] ?? 'monthly').toString().toLowerCase().trim();
      return p;
    }

    final docs =
        snap.docs.where((d) {
          final m = d.data() as Map<String, dynamic>;
          final per = periodOf(m);
          return isActive(m) && (per == 'monthly' || per == 'mensual');
        }).toList();

    final budgets = docs.map(Budget.fromSnap).toList();

    final List<Map<String, dynamic>> out = [];

    for (final b in budgets) {
      Query q = _txCol
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));

      if (b.category != null && b.category!.trim().isNotEmpty) {
        q = q.where('category', isEqualTo: b.category);
      }

      final txs = await q.get();
      double spent = 0;
      for (final d in txs.docs) {
        spent += ((d['amount'] ?? 0) as num).toDouble();
      }

      final limit = b.limit;
      final remaining = (limit - spent);
      final pct = (limit <= 0) ? 0.0 : (spent / limit).clamp(0.0, 1.0);

      out.add({
        'budget': b,
        'spent': spent,
        'limit': limit,
        'remaining': remaining,
        'pct': pct,
      });
    }

    out.sort((a, b) => (b['pct'] as double).compareTo(a['pct'] as double));
    return out;
  }
}

class FinanceAssetsFirestoreService {
  FinanceAssetsFirestoreService._();
  static final I = FinanceAssetsFirestoreService._();

  final root = FirebaseFirestore.instance.collection('finance');

  // Usa un doc global “assets”, subcolección “items” por usuario (si ya tienes userId, añade el scope).
  CollectionReference<Map<String, dynamic>> _items() =>
      FirebaseFirestore.instance.collection('finance_assets');

  Stream<List<AssetItem>> watchAssets() {
    return _items()
        .orderBy('acquiredAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AssetItem.fromSnap).toList());
  }

  Future<String> addAsset(AssetItem a) async {
    final doc = await _items().add(a.toMap());
    return doc.id;
  }

  Future<void> updateAsset(AssetItem a) async {
    await _items().doc(a.id).set(a.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteAsset(String id) async {
    await _items().doc(id).delete();
  }
}
