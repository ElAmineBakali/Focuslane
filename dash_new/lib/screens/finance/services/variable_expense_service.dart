import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:mi_dashboard_personal/screens/finance/models/variable_expense_model.dart';

class VariableExpenseService {
  static final VariableExpenseService I = VariableExpenseService._();
  VariableExpenseService._();

  final _col = FirebaseFirestore.instance.collection(
    'finance_variable_expenses',
  );

  String get _uid => fb_auth.FirebaseAuth.instance.currentUser!.uid;

  Stream<List<VariableExpense>> watchByMonth(int month, int year) {
    return _col
        .where('userId', isEqualTo: _uid)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .orderBy('title')
        .snapshots()
        .map((s) => s.docs.map(VariableExpense.fromDoc).toList());
  }

  Future<void> upsert(VariableExpense v) async {
    final data = v.toMap();
    if (v.id.isEmpty) {
      await _col.add(data);
    } else {
      await _col.doc(v.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> markDone(String id, String? txId) async {
    await _col.doc(id).update({'status': 'done', 'relatedTxId': txId});
  }
}

