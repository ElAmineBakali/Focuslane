import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mi_dashboard_personal/screens/finance/services/transaction_service.dart';
import 'package:intl/intl.dart';

class FinanceSettingsService {
  static final I = FinanceSettingsService._();
  FinanceSettingsService._();

  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final doc = await _db.collection('users').doc(_uid).collection('settings').doc('finance').get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('settings')
        .doc('finance')
        .set({key: value}, SetOptions(merge: true));
  }

  Future<String> exportTransactionsToCSV(DateTime start, DateTime end) async {
    // Get transactions
    final txs = await TransactionService.I.watch(from: start, to: end).first;

    // Create CSV
    final rows = [
      ['Fecha', 'Tipo', 'Título', 'Importe', 'Categoría', 'Subcategoría', 'Cuenta', 'Etiquetas', 'Notas'],
      ...txs.map((tx) => [
            DateFormat('yyyy-MM-dd HH:mm:ss').format(tx.date),
            tx.type.name,
            tx.title,
            tx.amount.toStringAsFixed(2),
            tx.category ?? '',
            tx.subCategory ?? '',
            tx.accountId ?? '',
            tx.tags.join(', '),
            tx.notes ?? '',
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);

    // Save to file
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'transacciones_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    return file.path;
  }

  Future<void> clearAllData() async {
    // WARNING: This deletes ALL finance data
    final batch = _db.batch();
    
    final collections = ['transactions', 'budgets', 'subscriptions', 'debts', 'assets', 'deposits', 'variable_expenses'];
    for (final col in collections) {
      final snapshot = await _db.collection('users').doc(_uid).collection(col).get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }
}

