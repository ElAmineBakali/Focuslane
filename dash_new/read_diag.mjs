// Temporary script to read diagnostic results from Firestore
import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

// Use the default credentials from gcloud/firebase CLI
initializeApp({ projectId: 'maestro-592cd' });

const db = getFirestore();
const uid = 'zwdI2qryK2aPUdafIy3QBfn0Gtu1';

async function main() {
  try {
    const doc = await db.collection('users').doc(uid).collection('diag').doc('results').get();
    if (!doc.exists) {
      console.log('Document does not exist');
      return;
    }
    const data = doc.data();
    console.log('=== PHASE:', data.phase, '===');
    console.log('=== UPDATED:', data.updatedAt?.toDate?.()?.toISOString() ?? 'N/A', '===');
    console.log('');
    console.log(data.log);
  } catch (e) {
    console.error('Error:', e.message);
  }
}

main();
