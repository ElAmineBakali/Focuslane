import 'package:cloud_firestore/cloud_firestore.dart';

class DepositAccount {
  final String id;
  final String userId;
  final String name;
  final String? bank;
  final String? type; // savings | checking | investment | crypto
  final String? notes;
  final String? currency;
  final String? iban;
  final double? balance;
  final DateTime? createdAt;

  DepositAccount({
    required this.id,
    required this.userId,
    required this.name,
    this.bank,
    this.type,
    this.notes,
    this.currency,
    this.iban,
    this.balance,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'bank': bank,
    'type': type,
    'notes': notes,
    'currency': currency,
    'iban': iban,
    'balance': balance,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
  };

  static DepositAccount fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DepositAccount(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String,
      bank: d['bank'] as String?,
      type: d['type'] as String? ?? 'savings',
      notes: d['notes'] as String?,
      currency: d['currency'] as String?,
      iban: d['iban'] as String?,
      balance: (d['balance'] as num?)?.toDouble(),
      createdAt: d['createdAt'] != null ? (d['createdAt'] as Timestamp).toDate() : null,
    );
  }
}

class DepositMovement {
  final String id;
  final String accountId;
  final double amount; // + deposit, - withdrawal
  final DateTime date;
  final String? description;
  final String? txRef; // link to a transaction
  final String type; // deposit | withdrawal | interest

  DepositMovement({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.date,
    this.description,
    this.txRef,
    this.type = 'deposit',
  });

  Map<String, dynamic> toMap() => {
    'accountId': accountId,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'description': description,
    'txRef': txRef,
    'type': type,
  };

  static DepositMovement fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DepositMovement(
      id: doc.id,
      accountId: d['accountId'] as String,
      amount: (d['amount'] as num).toDouble(),
      date: (d['date'] as Timestamp).toDate(),
      description: d['description'] as String?,
      txRef: d['txRef'] as String?,
      type: d['type'] as String? ?? 'deposit',
    );
  }
}
