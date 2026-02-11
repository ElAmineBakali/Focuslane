import 'package:cloud_firestore/cloud_firestore.dart';

String dayIdFromDateTime(DateTime dt) {
  return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String dayIdFromTimestamp(Timestamp ts) => dayIdFromDateTime(ts.toDate());

String dayIdFromIso(String iso) {
  try {
    return dayIdFromDateTime(DateTime.parse(iso));
  } catch (_) {
    return dayIdFromDateTime(DateTime.now());
  }
}

DateTime parseIsoSafe(String iso) {
  try {
    return DateTime.parse(iso);
  } catch (_) {
    return DateTime.now();
  }
}

Timestamp startOfDayTs(String dayId) {
  final parts = dayId.split('-');
  final y = int.tryParse(parts.elementAt(0)) ?? DateTime.now().year;
  final m = int.tryParse(parts.elementAt(1)) ?? 1;
  final d = int.tryParse(parts.elementAt(2)) ?? 1;
  return Timestamp.fromDate(DateTime(y, m, d, 0, 0, 0));
}

Timestamp endOfDayTs(String dayId) {
  final parts = dayId.split('-');
  final y = int.tryParse(parts.elementAt(0)) ?? DateTime.now().year;
  final m = int.tryParse(parts.elementAt(1)) ?? 1;
  final d = int.tryParse(parts.elementAt(2)) ?? 1;
  return Timestamp.fromDate(DateTime(y, m, d, 23, 59, 59));
}

bool sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}