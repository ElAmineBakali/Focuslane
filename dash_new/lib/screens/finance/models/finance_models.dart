import 'package:cloud_firestore/cloud_firestore.dart';

String yyyymm(DateTime d) =>
    "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}";

// ------------ TRANSACCIONES ------------
enum TxType { income, expense, transfer }

class FinanceTransaction {
  final String id;
  final String title;
  final double amount;
  final TxType type;
  final String category;
  final String? subCategory;
  final DateTime date;
  final String? accountId;
  final String? notes;
  final List<String>? tags;
  final bool isRecurring;
  final String? recurrence;
  final String? envelopeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? originalCurrency;
  final double? originalAmount;
  final double? fxRate;

  FinanceTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.subCategory,
    required this.date,
    this.accountId,
    this.notes,
    this.tags,
    this.isRecurring = false,
    this.recurrence,
    this.envelopeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.originalCurrency,
    this.originalAmount,
    this.fxRate,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'type': type.name,
    'category': category,
    'subCategory': subCategory,
    'date': Timestamp.fromDate(date),
    'accountId': accountId,
    'notes': notes,
    'tags': tags,
    'isRecurring': isRecurring,
    'recurrence': recurrence,
    'envelopeId': envelopeId,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'originalCurrency': originalCurrency,
    'originalAmount': originalAmount,
    'fxRate': fxRate,
  };

  static FinanceTransaction fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    double asDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return FinanceTransaction(
      id: s.id,
      title: (d['title'] ?? '') as String,
      amount: asDouble(d['amount']),
      type: TxType.values.firstWhere(
        (e) => e.name == (d['type'] ?? 'expense'),
        orElse: () => TxType.expense,
      ),
      category: (d['category'] ?? 'Other') as String,
      subCategory: d['subCategory'] as String?,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      accountId: d['accountId'] as String?,
      notes: d['notes'] as String?,
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList(),
      isRecurring: (d['isRecurring'] ?? false) as bool,
      recurrence: d['recurrence'] as String?,
      envelopeId: d['envelopeId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      originalCurrency: d['originalCurrency'] as String?,
      originalAmount:
          (d['originalAmount'] is num)
              ? (d['originalAmount'] as num).toDouble()
              : null,
      fxRate: (d['fxRate'] is num) ? (d['fxRate'] as num).toDouble() : null,
    );
  }
}

// ------------ PRESUPUESTOS ------------
class Budget {
  final String id;
  final String name;
  final String? category;
  final double limit;
  final String period;
  final int startDayOfPeriod;
  final bool active;

  Budget({
    required this.id,
    required this.name,
    this.category,
    required this.limit,
    this.period = 'monthly',
    this.startDayOfPeriod = 1,
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'limit': limit,
    'period': period,
    'startDayOfPeriod': startDayOfPeriod,
    'active': active,
  };

  static Budget fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    double asDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return Budget(
      id: s.id,
      name: (d['name'] ?? '') as String,
      category: d['category'] as String?,
      limit: asDouble(d['limit']),
      period: (d['period'] ?? 'monthly') as String,
      startDayOfPeriod: (d['startDayOfPeriod'] ?? 1) as int,
      active: (d['active'] ?? true) as bool,
    );
  }
}

// ------------ SUSCRIPCIONES ------------
class Subscription {
  final String id;
  final String name;
  final double amount;
  final String currency;
  final String category;
  final String billingCycle;
  final int? billingDay;
  final bool isFixed;
  final int remindDaysBefore;
  final bool autoMarkPaid;
  final int? order; // posición para reordenar en checklist

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    this.currency = 'EUR',
    required this.category,
    this.billingCycle = 'monthly',
    this.billingDay,
    this.isFixed = true,
    this.remindDaysBefore = 3,
    this.autoMarkPaid = false,
    this.order,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'currency': currency,
    'category': category,
    'billingCycle': billingCycle,
    'billingDay': billingDay,
    'isFixed': isFixed,
    'remindDaysBefore': remindDaysBefore,
    'autoMarkPaid': autoMarkPaid,
    'order': order,
  };

  static Subscription fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    double asDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return Subscription(
      id: s.id,
      name: (d['name'] ?? '') as String,
      amount: asDouble(d['amount']),
      currency: (d['currency'] ?? 'EUR') as String,
      category: (d['category'] ?? 'Other') as String,
      billingCycle: (d['billingCycle'] ?? 'monthly') as String,
      billingDay: d['billingDay'] as int?,
      isFixed: (d['isFixed'] ?? true) as bool,
      remindDaysBefore: (d['remindDaysBefore'] ?? 3) as int,
      autoMarkPaid: (d['autoMarkPaid'] ?? false) as bool,
      order: (d['order'] is num) ? (d['order'] as num).toInt() : null,
    );
  }
}

// ------------ PERSONAS / DEUDAS ------------
class Person {
  final String id;
  final String name;
  final String defaultCurrency;
  final String? contact;
  final String? notes;
  final double balance; // >0 me deben, <0 debo

  Person({
    required this.id,
    required this.name,
    this.defaultCurrency = 'EUR',
    this.contact,
    this.notes,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'defaultCurrency': defaultCurrency,
    'contact': contact,
    'notes': notes,
    'balance': balance,
  };

  static Person fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    double asDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return Person(
      id: s.id,
      name: (d['name'] ?? '') as String,
      defaultCurrency: (d['defaultCurrency'] ?? 'EUR') as String,
      contact: d['contact'] as String?,
      notes: d['notes'] as String?,
      balance: asDouble(d['balance']),
    );
  }
}

class DebtEntry {
  final String id;
  final double amount; // + me deben, - le debo
  final DateTime date;
  final String concept;
  final String? relatedTxId;

  DebtEntry({
    required this.id,
    required this.amount,
    required this.date,
    required this.concept,
    this.relatedTxId,
  });

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'concept': concept,
    'relatedTxId': relatedTxId,
  };

  static DebtEntry fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    double asDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return DebtEntry(
      id: s.id,
      amount: asDouble(d['amount']),
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      concept: (d['concept'] ?? '') as String,
      relatedTxId: d['relatedTxId'] as String?,
    );
  }
}

// ------------ VARIABLE EXPENSES ------------
class VariableExpenseItem {
  final String id;
  final String name;
  final String category;
  final String periodKey; // yyyy-mm
  final String status; // planned|done|skipped
  final double? amount;
  final String? linkedTxId;

  VariableExpenseItem({
    required this.id,
    required this.name,
    required this.category,
    required this.periodKey,
    this.status = 'planned',
    this.amount,
    this.linkedTxId,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'periodKey': periodKey,
    'status': status,
    'amount': amount,
    'linkedTxId': linkedTxId,
  };

  static VariableExpenseItem fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return VariableExpenseItem(
      id: s.id,
      name: (d['name'] ?? '') as String,
      category: (d['category'] ?? 'Other') as String,
      periodKey: (d['periodKey'] ?? '') as String,
      status: (d['status'] ?? 'planned') as String,
      amount: (d['amount'] is num) ? (d['amount'] as num).toDouble() : null,
      linkedTxId: d['linkedTxId'] as String?,
    );
  }
}

// ------------ DEPÓSITOS ------------
class Deposit {
  final String id;
  final String name;
  final String where;
  final double amount;
  final String currency;
  final bool isMine;
  final String? category;
  final String? ownerNote;

  Deposit({
    required this.id,
    required this.name,
    required this.where,
    required this.amount,
    this.currency = 'EUR',
    this.isMine = true,
    this.category,
    this.ownerNote,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'where': where,
    'amount': amount,
    'currency': currency,
    'isMine': isMine,
    'category': category,
    'ownerNote': ownerNote,
  };

  static Deposit fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    double asDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return Deposit(
      id: s.id,
      name: (d['name'] ?? '') as String,
      where: (d['where'] ?? '') as String,
      amount: asDouble(d['amount']),
      currency: (d['currency'] ?? 'EUR') as String,
      isMine: (d['isMine'] ?? true) as bool,
      category: d['category'] as String?,
      ownerNote: d['ownerNote'] as String?,
    );
  }
}

enum AssetKind { house, car, land, other }

class AssetItem {
  final String id;
  final String name;
  final AssetKind kind;
  final double? estValue; // valor estimado
  final String? currency; // p.ej. EUR
  final String? address; // dirección libre
  final String? notes; // notas
  final DateTime? acquiredAt; // fecha adquisición
  final String? colorHex; // UI opcional

  AssetItem({
    required this.id,
    required this.name,
    required this.kind,
    this.estValue,
    this.currency,
    this.address,
    this.notes,
    this.acquiredAt,
    this.colorHex,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'kind': kind.name,
    'estValue': estValue,
    'currency': currency,
    'address': address,
    'notes': notes,
    'acquiredAt': acquiredAt != null ? Timestamp.fromDate(acquiredAt!) : null,
    'colorHex': colorHex,
  };

  static AssetItem fromSnap(DocumentSnapshot s) {
    final d = s.data() as Map<String, dynamic>;
    return AssetItem(
      id: s.id,
      name: (d['name'] ?? '') as String,
      kind: AssetKind.values.firstWhere(
        (e) => e.name == (d['kind'] ?? 'other'),
        orElse: () => AssetKind.other,
      ),
      estValue: (d['estValue'] as num?)?.toDouble(),
      currency: d['currency'] as String?,
      address: d['address'] as String?,
      notes: d['notes'] as String?,
      acquiredAt: (d['acquiredAt'] as Timestamp?)?.toDate(),
      colorHex: d['colorHex'] as String?,
    );
  }
}
