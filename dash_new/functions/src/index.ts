import { initializeApp } from 'firebase-admin/app';
import {
  getFirestore,
  FieldValue,
  Timestamp,
  type DocumentReference,
  type WriteResult,
} from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';

initializeApp();

type NotificationEnvelopeV1 = {
  v: 1;
  notificationId: string;
  module: string;
  content: {
    title: string;
    body: string;
  };
  action?: {
    kind?: string;
    route?: string;
    args?: Record<string, unknown>;
  };
};

type PushTokenDoc = {
  token?: string;
  isActive?: boolean;
};

type ActivePushToken = {
  token: string;
  ref: DocumentReference;
};

type PendingNotificationDoc = {
  notificationId?: string;
  userId?: string;
  enabled?: boolean;
  status?: string;
  attempts?: number;
  maxAttempts?: number;
  scheduledAt?: Timestamp;
  scheduleKind?: string;
  hour?: number;
  minute?: number;
  weekdays?: number[];
  envelope?: unknown;
};

function isEnvelopeV1(value: unknown): value is NotificationEnvelopeV1 {
  if (!value || typeof value !== 'object') return false;
  const map = value as Record<string, unknown>;
  const content = map.content as Record<string, unknown> | undefined;
  return (
    map.v === 1
    && typeof map.notificationId === 'string'
    && typeof map.module === 'string'
    && !!content
    && typeof content.title === 'string'
    && typeof content.body === 'string'
  );
}

async function activeTokensForUser(uid: string): Promise<ActivePushToken[]> {
  const snap = await getFirestore()
    .collection('users')
    .doc(uid)
    .collection('push_tokens')
    .where('isActive', '==', true)
    .get();

  const seen = new Set<string>();
  const tokens: ActivePushToken[] = [];
  for (const doc of snap.docs) {
    const token = (doc.data() as PushTokenDoc).token;
    if (typeof token !== 'string' || token.length === 0 || seen.has(token)) {
      continue;
    }
    seen.add(token);
    tokens.push({ token, ref: doc.ref });
  }
  return tokens;
}

function buildDataPayload(envelope: NotificationEnvelopeV1): Record<string, string> {
  return {
    v: '1',
    notificationId: envelope.notificationId,
    payload: JSON.stringify(envelope),
  };
}

async function sendEnvelopeToUser(uid: string, envelope: NotificationEnvelopeV1): Promise<{ attempted: number; success: number; failure: number; }> {
  const activeTokens = await activeTokensForUser(uid);
  if (activeTokens.length === 0) {
    return { attempted: 0, success: 0, failure: 0 };
  }

  const tokens = activeTokens.map((item) => item.token);
  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: envelope.content.title,
      body: envelope.content.body,
    },
    data: buildDataPayload(envelope),
    android: {
      priority: 'high',
    },
  });

  const invalidTokenCodes = new Set([
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
  ]);
  const cleanupWrites: Promise<WriteResult>[] = [];
  response.responses.forEach((item, index) => {
    const code = item.error?.code;
    if (!code || !invalidTokenCodes.has(code)) return;
    cleanupWrites.push(
      activeTokens[index].ref.set(
        {
          isActive: false,
          revokedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          lastError: code,
        },
        { merge: true },
      ),
    );
  });
  await Promise.all(cleanupWrites);

  return {
    attempted: tokens.length,
    success: response.successCount,
    failure: response.failureCount,
  };
}

export const sendPushEnvelope = onCall({ region: 'europe-southwest1' }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const envelope = request.data?.envelope;
  if (!isEnvelopeV1(envelope)) {
    throw new HttpsError('invalid-argument', 'envelope must be NotificationEnvelope v1');
  }

  const result = await sendEnvelopeToUser(uid, envelope);
  return {
    ok: true,
    ...result,
  };
});

export const dispatchNotificationOutbox = onDocumentCreated(
  {
    document: 'users/{uid}/notification_outbox/{docId}',
    region: 'europe-southwest1',
  },
  async (event) => {
    const uid = event.params.uid;
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() as { envelope?: unknown };
    if (!isEnvelopeV1(data.envelope)) {
      logger.warn('Invalid envelope in notification_outbox', { uid, docId: event.params.docId });
      await snap.ref.set(
        {
          status: 'error',
          error: 'invalid_envelope_v1',
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return;
    }

    const result = await sendEnvelopeToUser(uid, data.envelope);
    await snap.ref.set(
      {
        status: result.failure > 0 ? 'partial' : 'sent',
        attempted: result.attempted,
        success: result.success,
        failure: result.failure,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);

export const dispatchPendingNotifications = onSchedule(
  {
    schedule: 'every 1 minutes',
    region: 'europe-west1',
    timeZone: 'Europe/Madrid',
  },
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();
    const snap = await db
      .collectionGroup('pending_notifications')
      .where('status', 'in', ['pending', 'retry'])
      .where('scheduledAt', '<=', now)
      .orderBy('scheduledAt', 'asc')
      .limit(100)
      .get();

    for (const doc of snap.docs) {
      await dispatchPendingNotificationDoc(doc.ref, now);
    }
  },
);

async function dispatchPendingNotificationDoc(
  ref: DocumentReference,
  now: Timestamp,
): Promise<void> {
  const db = getFirestore();
  const lockId = `${Date.now()}_${Math.random().toString(36).slice(2)}`;

  const claimed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return null;
    const data = snap.data() as PendingNotificationDoc;
    if (data.enabled !== true) return null;
    if (data.status !== 'pending' && data.status !== 'retry') return null;
    if (!data.scheduledAt || data.scheduledAt.toMillis() > now.toMillis()) {
      return null;
    }
    if (!isEnvelopeV1(data.envelope)) {
      tx.set(
        ref,
        {
          status: 'failed',
          enabled: false,
          lastError: 'invalid_envelope_v1',
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return null;
    }

    const attempts = (data.attempts ?? 0) + 1;
    tx.set(
      ref,
      {
        status: 'dispatching',
        dispatchLockId: lockId,
        attempts,
        dispatchStartedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return { data, attempts };
  });

  if (!claimed || !isEnvelopeV1(claimed.data.envelope)) {
    return;
  }

  const uid = claimed.data.userId || ref.parent.parent?.id;
  if (!uid) {
    await markDispatchFailure(ref, claimed.data, claimed.attempts, 'missing_user_id');
    return;
  }

  try {
    const result = await sendEnvelopeToUser(uid, claimed.data.envelope);
    if (result.success > 0) {
      await markDispatchSuccess(ref, claimed.data, claimed.data.envelope, result);
      return;
    }

    await markDispatchFailure(
      ref,
      claimed.data,
      claimed.attempts,
      result.attempted === 0 ? 'no_active_fcm_tokens' : 'fcm_delivery_failed',
      result,
    );
  } catch (e) {
    logger.error('Pending notification dispatch failed', { path: ref.path, error: e });
    await markDispatchFailure(ref, claimed.data, claimed.attempts, String(e));
  }
}

async function markDispatchSuccess(
  ref: DocumentReference,
  data: PendingNotificationDoc,
  envelope: NotificationEnvelopeV1,
  result: { attempted: number; success: number; failure: number },
): Promise<void> {
  const scheduledAt = data.scheduledAt?.toDate() ?? new Date();
  const next = nextOccurrence(data, scheduledAt);
  if (next) {
    const nextEnvelope = {
      ...envelope,
      schedule: {
        ...(envelope as Record<string, any>).schedule,
        scheduledAtUtc: next.toISOString(),
      },
    };
    await ref.set(
      {
        status: 'pending',
        enabled: true,
        scheduledAt: Timestamp.fromDate(next),
        envelope: nextEnvelope,
        attempts: 0,
        lastSentAt: FieldValue.serverTimestamp(),
        lastAttempted: result.attempted,
        lastSuccess: result.success,
        lastFailure: result.failure,
        dispatchLockId: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return;
  }

  await ref.set(
    {
      status: result.failure > 0 ? 'sent_partial' : 'sent',
      enabled: false,
      sentAt: FieldValue.serverTimestamp(),
      attempted: result.attempted,
      success: result.success,
      failure: result.failure,
      dispatchLockId: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function markDispatchFailure(
  ref: DocumentReference,
  data: PendingNotificationDoc,
  attempts: number,
  error: string,
  result?: { attempted: number; success: number; failure: number },
): Promise<void> {
  const maxAttempts = data.maxAttempts ?? 3;
  const canRetry = attempts < maxAttempts;
  await ref.set(
    {
      status: canRetry ? 'retry' : 'failed',
      enabled: canRetry,
      lastError: error,
      attempted: result?.attempted ?? 0,
      success: result?.success ?? 0,
      failure: result?.failure ?? 0,
      dispatchLockId: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
      failedAt: canRetry ? FieldValue.delete() : FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

function nextOccurrence(data: PendingNotificationDoc, scheduledAt: Date): Date | null {
  const kind = data.scheduleKind;
  if (kind === 'daily') {
    let next = new Date(scheduledAt.getTime() + 24 * 60 * 60 * 1000);
    const now = Date.now();
    while (next.getTime() <= now) {
      next = new Date(next.getTime() + 24 * 60 * 60 * 1000);
    }
    return next;
  }

  if (kind === 'weekly') {
    const weekdays = Array.isArray(data.weekdays) && data.weekdays.length > 0
      ? data.weekdays
      : [toDartWeekday(scheduledAt)];
    let next = new Date(scheduledAt.getTime() + 24 * 60 * 60 * 1000);
    const now = Date.now();
    for (let i = 0; i < 370; i++) {
      const dartWeekday = toDartWeekday(next);
      if (weekdays.includes(dartWeekday) && next.getTime() > now) {
        return next;
      }
      next = new Date(next.getTime() + 24 * 60 * 60 * 1000);
    }
  }

  return null;
}

function toDartWeekday(date: Date): number {
  const jsDay = date.getUTCDay();
  return jsDay === 0 ? 7 : jsDay;
}
