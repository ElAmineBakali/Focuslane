import admin from 'firebase-admin';
import fs from 'node:fs';

const serviceAccount = JSON.parse(
  fs.readFileSync(new URL('./service-account.json', import.meta.url), 'utf8'),
);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();
const uid = 'zwdI2qryK2aPUdafIy3QBfn0Gtu1';

const intakeCol = db
  .collection('users')
  .doc(uid)
  .collection('food')
  .doc('root')
  .collection('intake');

const snap = await intakeCol.get();
const docs = snap.docs
  .map((doc) => ({ id: doc.id, data: doc.data() }))
  .sort((a, b) => String(a.id).localeCompare(String(b.id)))
  .reverse();

const isPhotoType = (value) => {
  const normalized = String(value ?? '').toLowerCase();
  return normalized === 'photo_ai' || normalized === 'photoai' || normalized === 'photo-ai';
};

const toJsonSafe = (value) =>
  JSON.parse(
    JSON.stringify(value, (_key, fieldValue) => {
      if (
        fieldValue &&
        typeof fieldValue === 'object' &&
        typeof fieldValue.toDate === 'function'
      ) {
        return fieldValue.toDate().toISOString();
      }
      return fieldValue;
    }),
  );

let found = null;

for (const doc of docs) {
  const entries = Array.isArray(doc.data.entries) ? doc.data.entries : [];
  for (let idx = entries.length - 1; idx >= 0; idx -= 1) {
    if (!isPhotoType(entries[idx]?.type)) continue;
    found = {
      docId: doc.id,
      entryIndex: idx,
      entriesCount: entries.length,
      totals: doc.data.totals ?? null,
      sampleEntry: toJsonSafe(entries[idx]),
    };
    break;
  }
  if (found) break;
}

if (!found) {
  console.log('NO_PHOTO_AI_FOUND');
  process.exit(0);
}

const serialized = JSON.stringify(found.sampleEntry);
const hasBase64 = serialized.includes('base64') || Object.prototype.hasOwnProperty.call(found.sampleEntry, 'imageBase64');

console.log('PHOTO_AI_DOC_START');
console.log(
  JSON.stringify(
    {
      docId: found.docId,
      entryIndex: found.entryIndex,
      entriesCount: found.entriesCount,
      totals: found.totals,
      sampleEntry: found.sampleEntry,
      hasBase64,
    },
    null,
    2,
  ),
);
console.log('PHOTO_AI_DOC_END');
