import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:mi_dashboard_personal/models/finance/subscription_model.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';

class SubscriptionService {
  static final SubscriptionService I = SubscriptionService._();
  SubscriptionService._();

  final _col = FirebaseFirestore.instance.collection('finance_subscriptions');

  String get _uid => fb_auth.FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Subscription>> watchAll({bool activeOnly = false}) {
    Query<Map<String, dynamic>> q = _col
        .where('userId', isEqualTo: _uid)
        .orderBy('nextDue');
    if (activeOnly) q = q.where('active', isEqualTo: true);
    return q.snapshots().map((s) => s.docs.map(Subscription.fromDoc).toList());
  }

  Future<void> upsert(Subscription s) async {
    final data = s.toMap();
    if (s.id.isEmpty) {
      await _col.add(data);
    } else {
      await _col.doc(s.id).set(data, SetOptions(merge: true));
    }
    if (s.remindDaysBefore > 0) {
      await _scheduleReminder(s);
    }
  }

  Future<void> create(Subscription s) async {
    await _col.add(s.toMap());
    if (s.reminderDays > 0 && s.reminderEnabled) {
      await _scheduleReminder(s);
    }
  }

  Future<void> update(Subscription s) async {
    await _col.doc(s.id).set(s.toMap(), SetOptions(merge: true));
    if (s.reminderDays > 0 && s.reminderEnabled) {
      await _scheduleReminder(s);
    }
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
    await NotificationService.I.cancel(id.hashCode);
  }

  Future<void> _scheduleReminder(Subscription s) async {
    final notifDate = s.nextDue.subtract(Duration(days: s.remindDaysBefore));
    if (notifDate.isBefore(DateTime.now())) return;

    await NotificationService.I.scheduleOnce(
      id: s.id.hashCode,
      title: 'Próximo pago: ${s.title}',
      body: 'Vence en ${s.remindDaysBefore} días. Monto: ${s.amount}',
      whenLocal: notifDate,
      useExact: false,
    );
  }

  Future<void> markAsPaid(String subId, String txId) async {
    final doc = await _col.doc(subId).get();
    final sub = Subscription.fromDoc(doc);
    final updatedHistory = List<String>.from(sub.paymentHistory)..add(txId);
    await _col.doc(subId).update({'paymentHistory': updatedHistory});
  }

  Stream<List<Subscription>> upcomingPayments({int daysAhead = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: daysAhead));
    return _col
        .where('userId', isEqualTo: _uid)
        .where('active', isEqualTo: true)
        .where('nextDue', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('nextDue', isLessThanOrEqualTo: Timestamp.fromDate(future))
        .orderBy('nextDue')
        .snapshots()
        .map((s) => s.docs.map(Subscription.fromDoc).toList());
  }

  Future<void> scheduleAllReminders() async {
    final subs = await watchAll(activeOnly: true).first;
    for (final s in subs) {
      if (s.remindDaysBefore > 0) {
        await _scheduleReminder(s);
      }
    }
  }
}
