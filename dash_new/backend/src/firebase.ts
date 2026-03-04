import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getAppCheck } from 'firebase-admin/app-check';
import { getFirestore } from 'firebase-admin/firestore';
import fs from 'node:fs';
import path from 'node:path';

import { config } from './config.js';

function initFirebaseAdmin() {
  if (getApps().length > 0) {
    return getApps()[0]!;
  }

  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (credentialsPath) {
    const resolvedPath = path.isAbsolute(credentialsPath)
      ? credentialsPath
      : path.resolve(process.cwd(), credentialsPath);
    if (fs.existsSync(resolvedPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(resolvedPath, 'utf8'));
      return initializeApp({
        credential: cert(serviceAccount),
        projectId: config.firebaseProjectId || serviceAccount.project_id,
      });
    }
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
