import 'package:cloud_firestore/cloud_firestore.dart';

enum BudgetPeriod { weekly, monthly, custom }

class Budget {
  final String id;
  final String userId;
  final String name;
  final String category;
  final double amount;
  final double limit;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final double alertThreshold;
  final double thresholdPercent; // alert when threshold crossed, e.g. 0.80
  final bool notifyOnThreshold;

  Budget({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.amount,
    required this.limit,
    required this.period,
    required this.startDate,
    this.endDate,
    required this.alertThreshold,
    this.thresholdPercent = 0.80,
    this.notifyOnThreshold = true,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'category': category,
    'amount': amount,
    'limit': limit,
    'period': period.name,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'alertThreshold': alertThreshold,
    'thresholdPercent': thresholdPercent,
    'notifyOnThreshold': notifyOnThreshold,
  };

  static Budget fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Budget(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String? ?? '',
      category: d['category'] as String,
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      limit: (d['limit'] as num).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == (d['period'] as String? ?? 'monthly'),
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: (d['startDate'] as Timestamp).toDate(),
      endDate: d['endDate'] != null ? (d['endDate'] as Timestamp).toDate() : null,
      alertThreshold: (d['alertThreshold'] as num?)?.toDouble() ?? 0.80,
      thresholdPercent: (d['thresholdPercent'] as num?)?.toDouble() ?? 0.80,
      notifyOnThreshold: d['notifyOnThreshold'] as bool? ?? true,
    );
  }
}
