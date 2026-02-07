import 'package:cloud_firestore/cloud_firestore.dart';

class Asset {
  final String id;
  final String userId;
  final String name;
  final String type; // property | vehicle | investment | savings | crypto | other
  final double currentValue;
  final double purchaseValue;
  final DateTime purchaseDate;
  final String? photoUrl;
  final String? location;
  final String? notes;
  final List<AssetValueSnapshot> valueHistory;

  Asset({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currentValue,
    required this.purchaseValue,
    required this.purchaseDate,
    this.photoUrl,
    this.location,
    this.notes,
    this.valueHistory = const [],
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'type': type,
    'currentValue': currentValue,
    'purchaseValue': purchaseValue,
    'purchaseDate': Timestamp.fromDate(purchaseDate),
    'photoUrl': photoUrl,
    'location': location,
    'notes': notes,
    'valueHistory': valueHistory.map((e) => e.toMap()).toList(),
  };

  static Asset fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Asset(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String,
      purchaseValue: (d['purchaseValue'] as num?)?.toDouble() ?? 0,
      purchaseDate: (d['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: d['type'] as String? ?? 'other',
      currentValue: (d['currentValue'] as num).toDouble(),
      photoUrl: d['photoUrl'] as String?,
      location: d['location'] as String?,
      notes: d['notes'] as String?,
      valueHistory:
          (d['valueHistory'] as List?)
              ?.map(
                (e) => AssetValueSnapshot.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}

class AssetValueSnapshot {
  final DateTime date;
  final double value;

  AssetValueSnapshot({required this.date, required this.value});

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'value': value,
  };

  static AssetValueSnapshot fromMap(Map<String, dynamic> map) {
    return AssetValueSnapshot(
      date: (map['date'] as Timestamp).toDate(),
      value: (map['value'] as num).toDouble(),
    );
  }
}
