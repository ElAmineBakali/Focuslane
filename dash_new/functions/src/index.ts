import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
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

async function activeTokensForUser(uid: string): Promise<string[]> {
  const snap = await getFirestore()
    .collection('users')
    .doc(uid)
    .collection('push_tokens')
    .where('isActive', '==', true)
    .get();

  const tokens = snap.docs
    .map((doc) => (doc.data() as PushTokenDoc).token)
    .filter((token): token is string => typeof token === 'string' && token.length > 0);

  return Array.from(new Set(tokens));
}

function buildDataPayload(envelope: NotificationEnvelopeV1): Record<string, string> {
  return {
    v: '1',
    notificationId: envelope.notificationId,
    payload: JSON.stringify(envelope),
  };
}

async function sendEnvelopeToUser(uid: string, envelope: NotificationEnvelopeV1): Promise<{ attempted: number; success: number; failure: number; }> {
  const tokens = await activeTokensForUser(uid);
  if (tokens.length === 0) {
    return { attempted: 0, success: 0, failure: 0 };
  }

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
