import 'package:cloud_firestore/cloud_firestore.dart';

enum TxType { income, expense, transfer }

class FinanceAiMeta {
  final String source;
  final String? model;
  final double? confidence;
  final String? reasoningShort;
  final DateTime? classifiedAt;
  final String? inputHash;
  final bool manualOverride;

  const FinanceAiMeta({
    required this.source,
    this.model,
    this.confidence,
    this.reasoningShort,
    this.classifiedAt,
    this.inputHash,
    this.manualOverride = false,
  });

  FinanceAiMeta copyWith({
    String? source,
    String? model,
    double? confidence,
    String? reasoningShort,
    DateTime? classifiedAt,
    String? inputHash,
    bool? manualOverride,
  }) {
    return FinanceAiMeta(
      source: source ?? this.source,
      model: model ?? this.model,
      confidence: confidence ?? this.confidence,
      reasoningShort: reasoningShort ?? this.reasoningShort,
      classifiedAt: classifiedAt ?? this.classifiedAt,
      inputHash: inputHash ?? this.inputHash,
      manualOverride: manualOverride ?? this.manualOverride,
    );
  }

  Map<String, dynamic> toMap() => {
    'source': source,
    'model': model,
    'confidence': confidence,
    'reasoningShort': reasoningShort,
    'classifiedAt': classifiedAt == null ? null : Timestamp.fromDate(classifiedAt!),
    'inputHash': inputHash,
    'manualOverride': manualOverride,
  };

  static FinanceAiMeta? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final ts = map['classifiedAt'];
    DateTime? classifiedAt;
    if (ts is Timestamp) {
      classifiedAt = ts.toDate();
    } else if (ts is DateTime) {
      classifiedAt = ts;
    }
    return FinanceAiMeta(
      source: map['source']?.toString() ?? 'openai',
      model: map['model']?.toString(),
      confidence: (map['confidence'] as num?)?.toDouble(),
      reasoningShort: map['reasoningShort']?.toString(),
      classifiedAt: classifiedAt,
      inputHash: map['inputHash']?.toString(),
      manualOverride: map['manualOverride'] == true,
    );
  }
}

class FinanceTransaction {
  final String id;
  final String userId;
  final DateTime date;
  final TxType type;
  final String title;
  final double amount;
  final String? category;
  final String? subCategory;
  final String? accountId;
  final String? notes;
  final List<String> tags;
  final String? originalCurrency; // e.g., 'USD', 'EUR'
  final double? fxRate; // rate to convert to base
  final String? recurrence; // e.g., 'none','weekly','monthly','custom'
  final String? envelopeId; // optional envelope linkage
  final String? relatedTxId; // link to other tx (e.g., debt payment)
  final FinanceAiMeta? aiMeta;

  FinanceTransaction({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.title,
    required this.amount,
    this.category,
    this.subCategory,
    this.accountId,
    this.notes,
    this.tags = const [],
    this.originalCurrency,
    this.fxRate,
    this.recurrence,
    this.envelopeId,
    this.relatedTxId,
    this.aiMeta,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'type': type.name,
    'title': title,
    'amount': amount,
    'category': category,
    'subCategory': subCategory,
    'accountId': accountId,
    'notes': notes,
    'tags': tags,
    'originalCurrency': originalCurrency,
    'fxRate': fxRate,
    'recurrence': recurrence,
    'envelopeId': envelopeId,
    'relatedTxId': relatedTxId,
    'aiMeta': aiMeta?.toMap(),
  };

  static FinanceTransaction fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return FinanceTransaction(
      id: doc.id,
      userId: d['userId'] as String,
      date: (d['date'] as Timestamp).toDate(),
      type: TxType.values.firstWhere(
        (e) => e.name == (d['type'] as String? ?? 'expense'),
        orElse: () => TxType.expense,
      ),
      title: d['title'] as String? ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      category: d['category'] as String?,
      subCategory: d['subCategory'] as String?,
      accountId: d['accountId'] as String?,
      notes: d['notes'] as String?,
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      originalCurrency: d['originalCurrency'] as String?,
      fxRate: (d['fxRate'] as num?)?.toDouble(),
      recurrence: d['recurrence'] as String?,
      envelopeId: d['envelopeId'] as String?,
      relatedTxId: d['relatedTxId'] as String?,
      aiMeta: FinanceAiMeta.fromMap(d['aiMeta']),
    );
  }
}
