import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:focuslane/screens/finance/models/deposit_model.dart';

class DepositService {
  static final DepositService I = DepositService._();
  DepositService._();

  final _accCol = FirebaseFirestore.instance.collection(
    'finance_deposit_accounts',
  );
  final _movCol = FirebaseFirestore.instance.collection(
    'finance_deposit_movements',
  );

  String get _uid => fb_auth.FirebaseAuth.instance.currentUser!.uid;

  // Accounts
  Stream<List<DepositAccount>> watchAccounts() {
    return _accCol
        .where('userId', isEqualTo: _uid)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(DepositAccount.fromDoc).toList());
  }

  Future<void> upsertAccount(DepositAccount a) async {
    final data = a.toMap();
    if (a.id.isEmpty) {
      await _accCol.add(data);
    } else {
      await _accCol.doc(a.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteAccount(String id) async {
    await _accCol.doc(id).delete();
  }

  // Movements
  Stream<List<DepositMovement>> watchMovementsForAccount(String accountId) {
    return _movCol
        .where('accountId', isEqualTo: accountId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(DepositMovement.fromDoc).toList());
  }

  Future<void> upsertMovement(DepositMovement m) async {
    final data = m.toMap();
    if (m.id.isEmpty) {
      await _movCol.add(data);
    } else {
      await _movCol.doc(m.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteMovement(String id) async {
    await _movCol.doc(id).delete();
  }

  Future<double> getBalanceForAccount(String accountId) async {
    final movements = await watchMovementsForAccount(accountId).first;
    double bal = 0;
    for (final m in movements) {
      bal += m.amount;
    }
    return bal;
  }
}


