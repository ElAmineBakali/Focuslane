import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final String id;
  final String userId;
  final String name;
  final String title;
  final double amount;
  final String category;
  final DateTime nextPaymentDate;
  final DateTime nextDue;
  final String frequency; // monthly | weekly | yearly | custom
  final int reminderDays;
  final int remindDaysBefore;
  final bool reminderEnabled;
  final bool autoMarkAsPaid;
  final bool autoMark;
  final bool isActive;
  final bool active;
  final String? notes;
  final List<String> paymentHistory; // txIds

  Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.title,
    required this.amount,
    required this.category,
    required this.nextPaymentDate,
    required this.nextDue,
    required this.frequency,
    this.reminderDays = 3,
    this.remindDaysBefore = 3,
    this.reminderEnabled = true,
    this.autoMarkAsPaid = false,
    this.autoMark = false,
    this.isActive = true,
    this.active = true,
    this.notes,
    this.paymentHistory = const [],
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'title': title,
        'amount': amount,
        'category': category,
        'nextPaymentDate': Timestamp.fromDate(nextPaymentDate),
        'nextDue': Timestamp.fromDate(nextDue),
        'frequency': frequency,
        'reminderDays': reminderDays,
        'remindDaysBefore': remindDaysBefore,
        'reminderEnabled': reminderEnabled,
        'autoMarkAsPaid': autoMarkAsPaid,
        'autoMark': autoMark,
        'isActive': isActive,
        'active': active,
        'notes': notes,
        'paymentHistory': paymentHistory,
      };

  static Subscription fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final nextDueDate = d['nextPaymentDate'] != null
        ? (d['nextPaymentDate'] as Timestamp).toDate()
        : (d['nextDue'] as Timestamp).toDate();
    return Subscription(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String? ?? d['title'] as String,
      title: d['title'] as String,
      amount: (d['amount'] as num).toDouble(),
      category: d['category'] as String? ?? '',
      nextPaymentDate: nextDueDate,
      nextDue: nextDueDate,
      frequency: d['frequency'] as String? ?? 'monthly',
      reminderDays: d['reminderDays'] as int? ?? d['remindDaysBefore'] as int? ?? 3,
      remindDaysBefore: d['remindDaysBefore'] as int? ?? 3,
      reminderEnabled: d['reminderEnabled'] as bool? ?? true,
      autoMarkAsPaid: d['autoMarkAsPaid'] as bool? ?? d['autoMark'] as bool? ?? false,
      autoMark: d['autoMark'] as bool? ?? false,
      isActive: d['isActive'] as bool? ?? d['active'] as bool? ?? true,
      active: d['active'] as bool? ?? true,
      notes: d['notes'] as String?,
      paymentHistory:
          (d['paymentHistory'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }
}
