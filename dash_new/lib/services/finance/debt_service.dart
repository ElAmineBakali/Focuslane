import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:mi_dashboard_personal/models/finance/debt_model.dart';

class DebtService {
  static final DebtService I = DebtService._();
  DebtService._();

  final _personCol = FirebaseFirestore.instance.collection(
    'finance_debt_persons',
  );
  final _entryCol = FirebaseFirestore.instance.collection(
    'finance_debt_entries',
  );

  String get _uid => fb_auth.FirebaseAuth.instance.currentUser!.uid;

  // Persons
  Stream<List<DebtPerson>> watchPersons() {
    return _personCol
        .where('userId', isEqualTo: _uid)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(DebtPerson.fromDoc).toList());
  }

  Future<void> upsertPerson(DebtPerson p) async {
    final data = p.toMap();
    if (p.id.isEmpty) {
      await _personCol.add(data);
    } else {
      await _personCol.doc(p.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deletePerson(String id) async {
    await _personCol.doc(id).delete();
  }

  // Entries
  Stream<List<DebtEntry>> watchEntriesForPerson(String personId) {
    return _entryCol
        .where('personId', isEqualTo: personId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(DebtEntry.fromDoc).toList());
  }

  Future<void> upsertEntry(DebtEntry e) async {
    final data = e.toMap();
    if (e.id.isEmpty) {
      await _entryCol.add(data);
    } else {
      await _entryCol.doc(e.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteEntry(String id) async {
    await _entryCol.doc(id).delete();
  }

  Future<double> getBalanceForPerson(String personId) async {
    final entries = await watchEntriesForPerson(personId).first;
    double bal = 0;
    for (final e in entries) {
      bal += e.amount;
    }
    return bal;
  }
}
