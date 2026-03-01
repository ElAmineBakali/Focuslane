import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getAppCheck } from 'firebase-admin/app-check';
import { getFirestore } from 'firebase-admin/firestore';

import { config } from './config.js';

function initFirebaseAdmin() {
  if (getApps().length > 0) {
    return getApps()[0]!;
  }

  const serviceAccountJson = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
  if (serviceAccountJson) {
    const serviceAccount = JSON.parse(serviceAccountJson);
    return initializeApp({ credential: cert(serviceAccount), projectId: config.firebaseProjectId || serviceAccount.project_id });
  }

  return initializeApp({
    credential: applicationDefault(),
    projectId: config.firebaseProjectId || undefined,
  });
}

const app = initFirebaseAdmin();

export const adminAuth = getAuth(app);
export const adminAppCheck = getAppCheck(app);
export const adminDb = getFirestore(app);
