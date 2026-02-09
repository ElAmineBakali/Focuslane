import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:mi_dashboard_personal/screens/finance/models/loan_model.dart';

class DebtService {
  static final DebtService I = DebtService._();
  DebtService._();

  final _col = FirebaseFirestore.instance.collection('finance_loans');

  String? get _uid => fb_auth.FirebaseAuth.instance.currentUser?.uid;

  Stream<List<Debt>> watchAll() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return const Stream<List<Debt>>.empty();
    }
    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('balance', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Debt.fromDoc).toList());
  }

  Future<void> create(Debt debt) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    final data = debt.toMap()..['userId'] = uid;
    await _col.add(data);
  }

  Future<void> update(Debt debt) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    await _col.doc(debt.id).set(debt.toMap()..['userId'] = uid, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> addPayment(String debtId, DebtPayment payment) async {
    final doc = await _col.doc(debtId).get();
    final debt = Debt.fromDoc(doc);
    final updatedLedger = List<DebtPayment>.from(debt.ledger)..add(payment);
    final newBalance = debt.balance - payment.amount;

    await _col.doc(debtId).update({
      'ledger': updatedLedger.map((e) => e.toMap()).toList(),
      'balance': newBalance,
    });
  }
}

