import 'package:focuslane/core/notifications/contracts/notification_clock.dart';
import 'package:focuslane/core/notifications/models/notification_envelope.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';

abstract class IntentToEnvelopeMapper {
  NotificationEnvelope map(NotificationIntent intent);
}

class DefaultIntentToEnvelopeMapper implements IntentToEnvelopeMapper {
  DefaultIntentToEnvelopeMapper(this._clock);

  final NotificationClock _clock;

  @override
  NotificationEnvelope map(NotificationIntent intent) {
    final now = _clock.nowUtc();
    final notificationId =
        intent.notificationId ?? 'ntf_${intent.module.name}_${intent.entity.id}_${now.microsecondsSinceEpoch}';

    return NotificationEnvelope(
      v: 1,
      notificationId: notificationId,
      dedupeKey: intent.dedupeKey,
      module: intent.module,
      type: intent.type,
      entity: intent.entity,
      content: intent.content,
      action: intent.action,
      schedule: intent.schedule,
      delivery: intent.delivery,
      userId: intent.userId,
      source: intent.source,
      createdAtUtc: now,
      traceId: intent.traceId ?? 'trace_${now.microsecondsSinceEpoch}',
    );
  }
}

