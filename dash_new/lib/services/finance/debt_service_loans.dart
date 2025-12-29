import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:mi_dashboard_personal/models/finance/loan_model.dart';

class DebtService {
  static final DebtService I = DebtService._();
  DebtService._();

  final _col = FirebaseFirestore.instance.collection('finance_loans');

  String get _uid => fb_auth.FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Debt>> watchAll() {
    return _col
        .where('userId', isEqualTo: _uid)
        .orderBy('balance', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Debt.fromDoc).toList());
  }

  Future<void> create(Debt debt) async {
    final data = debt.toMap();
    await _col.add(data..['userId'] = _uid);
  }

  Future<void> update(Debt debt) async {
    await _col.doc(debt.id).set(debt.toMap(), SetOptions(merge: true));
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
