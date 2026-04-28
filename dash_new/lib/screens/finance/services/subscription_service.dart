import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:focuslane/screens/finance/models/subscription_model.dart';

class SubscriptionService {
  static final SubscriptionService I = SubscriptionService._();
  SubscriptionService._();

  final _col = FirebaseFirestore.instance.collection('finance_subscriptions');

  String? get _uid => fb_auth.FirebaseAuth.instance.currentUser?.uid;

  Stream<List<Subscription>> watchAll({bool activeOnly = false}) {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return const Stream<List<Subscription>>.empty();
    }
    Query<Map<String, dynamic>> q = _col
        .where('userId', isEqualTo: uid)
        .orderBy('nextDue');
    if (activeOnly) q = q.where('active', isEqualTo: true);
    return q.snapshots().map((s) => s.docs.map(Subscription.fromDoc).toList());
  }

  Future<void> upsert(Subscription s) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    final data = s.toMap()..['userId'] = uid;
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
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    await _col.add(s.toMap()..['userId'] = uid);
    if (s.reminderDays > 0 && s.reminderEnabled) {
      await _scheduleReminder(s);
    }
  }

  Future<void> update(Subscription s) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    await _col.doc(s.id).set(s.toMap()..['userId'] = uid, SetOptions(merge: true));
    if (s.reminderDays > 0 && s.reminderEnabled) {
      await _scheduleReminder(s);
    }
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
    await NotificationsFacade.I.cancelByEntity(
      NotificationEntityRef(
        module: NotificationModule.finance,
        kind: 'subscription',
        id: id,
      ),
    );
  }

  Future<void> _scheduleReminder(Subscription s) async {
    if (s.id.isEmpty) return;
    final notifDate = s.nextDue.subtract(Duration(days: s.remindDaysBefore));
    if (notifDate.isBefore(DateTime.now())) return;

    final uid = _uid ?? 'local';
    final epoch = notifDate.toUtc().millisecondsSinceEpoch;
    final entity = NotificationEntityRef(
      module: NotificationModule.finance,
      kind: 'subscription',
      id: s.id,
    );

    await NotificationsFacade.I.cancelByEntity(entity);
    await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.finance,
        type: 'SUBSCRIPTION_DUE_SOON',
        entity: entity,
        content: NotificationContent(
          title: 'Próximo pago: ${s.title}',
          body: 'Vence en ${s.remindDaysBefore} días. Monto: ${s.amount}',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/finance',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.oneShot,
          scheduledAtUtc: notifDate.toUtc(),
          timezone: notifDate.timeZoneName,
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.pushOnly,
          channel: AndroidChannelCatalog.financeReminders,
          priority: NotificationPriority.normal,
        ),
        dedupeKey: 'finance:subscription:${s.id}:$epoch',
        userId: uid,
        source: 'finance.subscription_service',
        notificationId: 'ntf_finance_subscription_${s.id}_$epoch',
      ),
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
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return const Stream<List<Subscription>>.empty();
    }
    return _col
        .where('userId', isEqualTo: uid)
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



