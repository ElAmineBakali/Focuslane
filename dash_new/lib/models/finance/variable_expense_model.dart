import 'package:cloud_firestore/cloud_firestore.dart';

class VariableExpense {
  final String id;
  final String userId;
  final String title;
  final double estimatedAmount;
  final String category;
  final int month; // 1..12
  final int year;
  final String status; // pending | done
  final String? relatedTxId;

  VariableExpense({
    required this.id,
    required this.userId,
    required this.title,
    required this.estimatedAmount,
    required this.category,
    required this.month,
    required this.year,
    this.status = 'pending',
    this.relatedTxId,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'estimatedAmount': estimatedAmount,
    'category': category,
    'month': month,
    'year': year,
    'status': status,
    'relatedTxId': relatedTxId,
  };

  static VariableExpense fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return VariableExpense(
      id: doc.id,
      userId: d['userId'] as String,
      title: d['title'] as String,
      estimatedAmount: (d['estimatedAmount'] as num).toDouble(),
      category: d['category'] as String? ?? '',
      month: d['month'] as int,
      year: d['year'] as int,
      status: d['status'] as String? ?? 'pending',
      relatedTxId: d['relatedTxId'] as String?,
    );
  }
}
