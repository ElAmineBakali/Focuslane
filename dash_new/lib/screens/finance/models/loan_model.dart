import 'package:cloud_firestore/cloud_firestore.dart';

// Loan model for personal loans/debts with payment history
class Debt {
  final String id;
  final String userId;
  final String name;
  final String creditor; // Who you owe money to
  final double originalAmount;
  final double balance; // Current remaining balance
  final double? interestRate;
  final DateTime startDate;
  final DateTime? dueDate;
  final List<DebtPayment> ledger; // Payment history
  final String? notes;

  Debt({
    required this.id,
    required this.userId,
    required this.name,
    required this.creditor,
    required this.originalAmount,
    required this.balance,
    this.interestRate,
    required this.startDate,
    this.dueDate,
    this.ledger = const [],
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'creditor': creditor,
        'originalAmount': originalAmount,
        'balance': balance,
        'interestRate': interestRate,
        'startDate': Timestamp.fromDate(startDate),
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'ledger': ledger.map((e) => e.toMap()).toList(),
        'notes': notes,
      };

  static Debt fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Debt(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String,
      creditor: d['creditor'] as String? ?? '',
      originalAmount: (d['originalAmount'] as num).toDouble(),
      balance: (d['balance'] as num).toDouble(),
      interestRate: (d['interestRate'] as num?)?.toDouble(),
      startDate: (d['startDate'] as Timestamp).toDate(),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      ledger: (d['ledger'] as List?)?.map((e) => DebtPayment.fromMap(e as Map<String, dynamic>)).toList() ?? const [],
      notes: d['notes'] as String?,
    );
  }
}

class DebtPayment {
  final DateTime date;
  final double amount;
  final String? notes;
  final String? transactionId;

  DebtPayment({
    required this.date,
    required this.amount,
    this.notes,
    this.transactionId,
  });

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'amount': amount,
        'notes': notes,
        'transactionId': transactionId,
      };

  static DebtPayment fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      date: (map['date'] as Timestamp).toDate(),
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      transactionId: map['transactionId'] as String?,
    );
  }
}
