import { createHash } from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { adminDb } from './firebase.js';
export function hashInput(input) {
    const normalized = JSON.stringify(input);
    return createHash('sha256').update(normalized).digest('hex');
}
export function buildImageInputHash(params) {
    const prefix = params.imageBase64.slice(0, 256);
    const firstNBytesHash = createHash('sha256').update(prefix).digest('hex');
    const stablePayload = {
        type: params.type,
        mimeType: params.mimeType,
        bytesLength: params.imageBase64.length,
        firstNBytesHash,
    };
    return hashInput(stablePayload);
}
export async function persistAiLog(data) {
    const ref = adminDb
        .collection('users')
        .doc(data.uid)
        .collection('ai_logs')
        .doc();
    const summary = data.resultSummary.length > 200
        ? data.resultSummary.slice(0, 200)
        : data.resultSummary;
    await ref.set({
        type: data.type,
        createdAt: FieldValue.serverTimestamp(),
        inputHash: hashInput(data.input),
        status: data.status,
        latencyMs: data.latencyMs,
        model: data.model,
        tokens: data.tokens ?? null,
        resultSummary: summary,
        requestId: data.requestId ?? null,
    });
}
