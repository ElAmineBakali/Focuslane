import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:mi_dashboard_personal/screens/finance/models/transaction_model.dart';

class TransactionService {
  static final TransactionService I = TransactionService._();
  TransactionService._();

  final _col = FirebaseFirestore.instance.collection('finance_transactions');

  String? get _uid => fb_auth.FirebaseAuth.instance.currentUser?.uid;

  Stream<List<FinanceTransaction>> watch({
    DateTime? from,
    DateTime? to,
    TxType? type,
    String? category,
    String? accountId,
    String? envelopeId,
    String? query,
  }) {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return const Stream<List<FinanceTransaction>>.empty();
    }
    Query<Map<String, dynamic>> q = _col
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true);
    if (from != null) {
      q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    if (type != null) q = q.where('type', isEqualTo: type.name);
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    if (accountId != null && accountId.isNotEmpty) {
      q = q.where('accountId', isEqualTo: accountId);
    }
    if (envelopeId != null && envelopeId.isNotEmpty) {
      q = q.where('envelopeId', isEqualTo: envelopeId);
    }

    final base = q.snapshots().map(
      (s) => s.docs.map(FinanceTransaction.fromDoc).toList(),
    );
    if (query != null && query.trim().isNotEmpty) {
      final ql = query.trim().toLowerCase();
      return base.map(
        (list) =>
            list.where((t) {
              final text =
                  '${t.title} ${t.category ?? ''} ${t.subCategory ?? ''} ${(t.notes ?? '')} ${t.tags.join(' ')}'
                      .toLowerCase();
              return text.contains(ql);
            }).toList(),
      );
    }
    return base;
  }

  Future<void> upsert(FinanceTransaction tx) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    final data = tx.toMap()..['userId'] = uid;
    if (tx.id.isEmpty) {
      await _col.add(data);
    } else {
      await _col.doc(tx.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> create(FinanceTransaction tx) async {
    await createAndReturnId(tx);
  }

  Future<String?> createAndReturnId(FinanceTransaction tx) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return null;
    final doc = await _col.add(tx.toMap()..['userId'] = uid);
    return doc.id;
  }

  Future<void> update(FinanceTransaction tx) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    await _col.doc(tx.id).set(tx.toMap()..['userId'] = uid, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<List<String>> recentTags({int limit = 25}) async {
    final qs =
        await _col
            .where('userId', isEqualTo: _uid)
            .orderBy('date', descending: true)
            .limit(200)
            .get();
    final tags = <String>{};
    for (final d in qs.docs) {
      final raw = d.data()['tags'] as List?;
      if (raw != null) {
        for (final t in raw) {
          tags.add(t.toString());
          if (tags.length >= limit) break;
        }
      }
      if (tags.length >= limit) break;
    }
    return tags.toList();
  }

  Future<List<String>> recentCategories({int limit = 50}) async {
    final qs =
        await _col
            .where('userId', isEqualTo: _uid)
            .orderBy('date', descending: true)
            .limit(200)
            .get();
    final cats = <String>{};
    for (final d in qs.docs) {
      final cat = d.data()['category'] as String?;
      if (cat != null && cat.isNotEmpty) {
        cats.add(cat);
        if (cats.length >= limit) break;
      }
    }
    return cats.toList();
  }

  Future<List<FinanceTransaction>> getTemplates({int limit = 5}) async {
    final qs =
        await _col
            .where('userId', isEqualTo: _uid)
            .orderBy('date', descending: true)
            .limit(100)
            .get();
    final freq = <String, int>{};
    final txMap = <String, FinanceTransaction>{};
    for (final d in qs.docs) {
      final tx = FinanceTransaction.fromDoc(d);
      final key = '${tx.title}|${tx.category}|${tx.amount}';
      freq[key] = (freq[key] ?? 0) + 1;
      txMap[key] = tx;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => txMap[e.key]!).toList();
  }

  Stream<Map<String, double>> monthlyStats(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return watch(from: start, to: end).map((txs) {
      double income = 0, expense = 0;
      for (final tx in txs) {
        if (tx.type == TxType.income) income += tx.amount;
        if (tx.type == TxType.expense) expense += tx.amount;
      }
      return {'income': income, 'expense': expense, 'balance': income - expense};
    });
  }
}

