import fs from 'fs';
import admin from 'firebase-admin';

const serviceAccount = JSON.parse(fs.readFileSync('./service-account.json', 'utf8'));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const uid = 'zwdI2qryK2aPUdafIy3QBfn0Gtu1';
const dayId = '2026-03-05';
const docPath = `users/${uid}/food/root/intake/${dayId}`;

const snap = await db.doc(docPath).get();
const data = snap.data() ?? {};
const entries = Array.isArray(data.entries) ? data.entries : [];
const photoAiEntries = entries.filter((entry) => entry?.type === 'photo_ai');

const lastTwo = photoAiEntries.slice(-2).map((entry) => ({
  type: entry.type,
  refId: entry.refId,
  nameSnapshot: entry.nameSnapshot,
  qty: entry.qty,
  unit: entry.unit,
  macrosSnapshot: entry.macrosSnapshot,
  meal: entry.meal,
  aiMeta: entry.aiMeta,
}));

console.log(
  JSON.stringify(
    {
      docPath,
      exists: snap.exists,
      totalEntries: entries.length,
      photoAiEntries: photoAiEntries.length,
      totals: data.totals ?? null,
      lastTwo,
    },
    null,
    2,
  ),
);
