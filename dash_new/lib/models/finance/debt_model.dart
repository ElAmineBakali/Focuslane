import 'package:cloud_firestore/cloud_firestore.dart';

class DebtPerson {
  final String id;
  final String userId;
  final String name;
  final String? notes;
  final String? avatarUrl;

  DebtPerson({
    required this.id,
    required this.userId,
    required this.name,
    this.notes,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'notes': notes,
    'avatarUrl': avatarUrl,
  };

  static DebtPerson fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DebtPerson(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String,
      notes: d['notes'] as String?,
      avatarUrl: d['avatarUrl'] as String?,
    );
  }
}

class DebtEntry {
  final String id;
  final String personId;
  final double amount; // + if they owe me, - if I owe them
  final String description;
  final DateTime date;
  final String? relatedTxId;

  DebtEntry({
    required this.id,
    required this.personId,
    required this.amount,
    required this.description,
    required this.date,
    this.relatedTxId,
  });

  Map<String, dynamic> toMap() => {
    'personId': personId,
    'amount': amount,
    'description': description,
    'date': Timestamp.fromDate(date),
    'relatedTxId': relatedTxId,
  };

  static DebtEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DebtEntry(
      id: doc.id,
      personId: d['personId'] as String,
      amount: (d['amount'] as num).toDouble(),
      description: d['description'] as String? ?? '',
      date: (d['date'] as Timestamp).toDate(),
      relatedTxId: d['relatedTxId'] as String?,
    );
  }
}
