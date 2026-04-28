import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:focuslane/core/notifications/models/notification_envelope.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';

abstract class PushNotificationGateway {
  Future<void> schedule(NotificationEnvelope envelope);
  Future<void> cancelByNotificationId(String notificationId);
  Future<int> cancelByEntity(NotificationEntityRef entity);
  Future<int> cancelByModule(NotificationModule module);
  Future<int> cancelByDedupeKey(String dedupeKey);
}

class FirestorePushNotificationGateway implements PushNotificationGateway {
  FirestorePushNotificationGateway({
    FirebaseFirestore? firestore,
    fb_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? fb_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _pendingForUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('pending_notifications');
  }

  String? _currentUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      return null;
    }
    return uid;
  }

  @override
  Future<void> schedule(NotificationEnvelope envelope) async {
    final uid = envelope.userId.trim().isNotEmpty && envelope.userId != 'local'
        ? envelope.userId
        : _currentUid();
    if (uid == null || uid.isEmpty) {
      throw StateError('push_requires_authenticated_user');
    }

    final scheduledAt = _effectiveScheduledAt(envelope);
    final entity = envelope.entity;
    final envelopeMap = envelope.toMap();
    final scheduleMap =
        Map<String, dynamic>.from(envelopeMap['schedule'] as Map? ?? const {});
    scheduleMap['scheduledAtUtc'] = scheduledAt.toIso8601String();
    envelopeMap['schedule'] = scheduleMap;

    await _pendingForUser(uid).doc(envelope.notificationId).set({
      'notificationId': envelope.notificationId,
      'dedupeKey': envelope.dedupeKey,
      'userId': uid,
      'module': envelope.module.name,
      'type': envelope.type,
      'entityKind': entity.kind,
      'entityId': entity.id,
      'entity': entity.toMap(),
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'timezone': envelope.schedule.timezone,
      'scheduleKind': envelope.schedule.kind.name,
      'hour': envelope.schedule.hour,
      'minute': envelope.schedule.minute,
      'weekdays': envelope.schedule.weekdays,
      'title': envelope.content.title,
      'body': envelope.content.body,
      'action': envelope.action.toMap(),
      'delivery': 'push',
      'priority': envelope.delivery.priority.name,
      'ttlSeconds': envelope.delivery.ttlSeconds,
      'enabled': true,
      'status': 'pending',
      'attempts': 0,
      'maxAttempts': 3,
      'envelope': envelopeMap,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'cancelledAt': FieldValue.delete(),
      'sentAt': FieldValue.delete(),
      'lastError': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  DateTime _effectiveScheduledAt(NotificationEnvelope envelope) {
    final now = DateTime.now();
    final raw = envelope.schedule.scheduledAtUtc?.toLocal() ?? now;
    switch (envelope.schedule.kind.name) {
      case 'daily':
        var next = DateTime(
          now.year,
          now.month,
          now.day,
          envelope.schedule.hour ?? raw.hour,
          envelope.schedule.minute ?? raw.minute,
        );
        while (!next.isAfter(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next.toUtc();
      case 'weekly':
        final weekdays = envelope.schedule.weekdays.isNotEmpty
            ? envelope.schedule.weekdays
            : <int>[raw.weekday];
        var cursor = DateTime(
          now.year,
          now.month,
          now.day,
          envelope.schedule.hour ?? raw.hour,
          envelope.schedule.minute ?? raw.minute,
        );
        for (var i = 0; i < 370; i++) {
          if (weekdays.contains(cursor.weekday) && cursor.isAfter(now)) {
            return cursor.toUtc();
          }
          cursor = cursor.add(const Duration(days: 1));
        }
        return raw.toUtc();
      case 'immediate':
        return now.toUtc();
      case 'oneShot':
      default:
        return raw.toUtc();
    }
  }

  @override
  Future<void> cancelByNotificationId(String notificationId) async {
    final uid = _currentUid();
    if (uid == null) return;
    await _pendingForUser(uid).doc(notificationId).set({
      'enabled': false,
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
      'cancelledAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<int> cancelByEntity(NotificationEntityRef entity) async {
    final uid = _currentUid();
    if (uid == null) return 0;
    final snap = await _pendingForUser(uid)
        .where('module', isEqualTo: entity.module.name)
        .where('entityKind', isEqualTo: entity.kind)
        .where('entityId', isEqualTo: entity.id)
        .where('status', whereIn: ['pending', 'retry', 'dispatching'])
        .get();
    await _cancelDocs(snap.docs);
    return snap.docs.length;
  }

  @override
  Future<int> cancelByModule(NotificationModule module) async {
    final uid = _currentUid();
    if (uid == null) return 0;
    final snap = await _pendingForUser(uid)
        .where('module', isEqualTo: module.name)
        .where('status', whereIn: ['pending', 'retry', 'dispatching'])
        .get();
    await _cancelDocs(snap.docs);
    return snap.docs.length;
  }

  @override
  Future<int> cancelByDedupeKey(String dedupeKey) async {
    final uid = _currentUid();
    if (uid == null) return 0;
    final snap = await _pendingForUser(uid)
        .where('dedupeKey', isEqualTo: dedupeKey)
        .where('status', whereIn: ['pending', 'retry', 'dispatching'])
        .get();
    await _cancelDocs(snap.docs);
    return snap.docs.length;
  }

  Future<void> _cancelDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in docs) {
      batch.set(
        doc.reference,
        {
          'enabled': false,
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
          'cancelledAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
