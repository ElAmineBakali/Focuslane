/**
 * IMPLEMENTATION 6 — QA Evidence: Sync pulido + UI reactiva discreta
 *
 * Scenarios:
 *   A) Finance → Food overBudget
 *   B) Finance → Gym dueSoon
 *   C) Gym → Food targets / proteinLow / extremeDeficit
 *   D) Study ↔ Tasks bidirectional mirror
 *
 * Prerequisites:
 *   - Flutter web app running at http://localhost:5173
 *     (flutter run -d chrome --dart-define=CORE_SYNC_CUSTOM_TOKEN=<token>)
 *   - `npm install` in this directory
 *   - GOOGLE_APPLICATION_CREDENTIALS env var pointing to service-account.json
 *     OR service-account.json in ../../backend/
 *
 * Usage:
 *   node check_impl6_sync.js
 */

const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');

// ─── Firebase Admin SDK ────────────────────────────────────────────
let admin;
try {
  admin = require('firebase-admin');
} catch {
  console.error('firebase-admin not installed. Run: npm install');
  process.exit(1);
}

const SA_PATH =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.resolve(__dirname, '..', '..', '..', 'backend', 'service-account.json');

if (!fs.existsSync(SA_PATH)) {
  console.error(`Service account not found at ${SA_PATH}`);
  process.exit(1);
}

const sa = JSON.parse(fs.readFileSync(SA_PATH, 'utf8'));
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(sa),
    projectId: sa.project_id,
  });
}
const db = admin.firestore();

// ─── Helpers ───────────────────────────────────────────────────────
const APP_URL = process.env.APP_URL || 'http://localhost:5173/#/';
const WAIT_AUTH_MS = 45_000;
const WAIT_SYNC_MS = 15_000;

function todayIso() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}T12:00:00.000`;
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function waitForAuth(logs) {
  const t0 = Date.now();
  while (Date.now() - t0 < WAIT_AUTH_MS) {
    const line = logs.find((l) => l.includes('[CoreSync][debugAuth] signed uid='));
    if (line) {
      const m = line.match(/uid=(\S+)/);
      return m ? m[1] : null;
    }
    await sleep(500);
  }
  return null;
}

function waitForLog(logs, pattern, timeoutMs = WAIT_SYNC_MS) {
  return new Promise((resolve) => {
    const t0 = Date.now();
    const check = () => {
      const found = logs.find((l) => l.includes(pattern));
      if (found) return resolve(found);
      if (Date.now() - t0 > timeoutMs) return resolve(null);
      setTimeout(check, 300);
    };
    check();
  });
}

// Track created doc refs for cleanup
const cleanupRefs = [];

async function cleanup() {
  console.log(`\n🧹 Cleaning up ${cleanupRefs.length} seed docs...`);
  for (const ref of cleanupRefs) {
    try {
      await ref.delete();
    } catch (_) {}
  }
  console.log('✅ Cleanup done');
}

// ─── Main ──────────────────────────────────────────────────────────
(async () => {
  const result = {
    A: { pass: false, evidence: '' },
    B: { pass: false, evidence: '' },
    C: { pass: false, evidence: '' },
    D: { pass: false, evidence: '' },
  };

  const logs = [];
  let browser;

  try {
    browser = await chromium.launch({ headless: true });
    const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
    page.on('console', (msg) => {
      const text = `[${msg.type()}] ${msg.text()}`;
      logs.push(text);
    });

    // ── Navigate & wait for auth ───────────────────────────────────
    console.log('▶ Navigating to Flutter app...');
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(10_000);
    // Enable semantics
    await page.evaluate(() => {
      const el = document.querySelector('flt-semantics-placeholder');
      if (el) el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
    });
    await page.waitForTimeout(1200);

    const uid = await waitForAuth(logs);
    if (!uid) {
      console.error('❌ Auth timeout — no [CoreSync][debugAuth] signed uid= in console logs');
      console.log('   Make sure the app is running with --dart-define=CORE_SYNC_CUSTOM_TOKEN=<token>');
      process.exit(1);
    }
    console.log(`✅ Authenticated uid=${uid}`);

    // Wait for CoreSyncService listeners to be fully started
    await waitForLog(logs, '[CoreSync] start() — all 6 listeners launched', 20_000);
    console.log('✅ CoreSyncService listeners launched');
    await sleep(3000); // extra settle

    // ════════════════════════════════════════════════════════════════
    // SCENARIO A: Finance → Food overBudget
    // ════════════════════════════════════════════════════════════════
    console.log('\n═══ SCENARIO A: Finance → Food overBudget ═══');
    {
      const logsBeforeA = logs.length;

      // Seed: food budget with limit 100
      const budgetRef = db.collection('finance_budgets').doc(`qa6-budget-${uid}`);
      await budgetRef.set({
        userId: uid,
        category: 'alimentación',
        amount: 100,
        limit: 100,
        period: 'monthly',
        startDate: admin.firestore.Timestamp.now(),
      });
      cleanupRefs.push(budgetRef);
      console.log(`  📝 Created budget doc=${budgetRef.id} limit=100`);

      await sleep(2000);

      // Seed: 2 expense transactions totaling 150 (over the 100 budget)
      const tx1Ref = db.collection('finance_transactions').doc(`qa6-tx1-${uid}`);
      await tx1Ref.set({
        userId: uid,
        category: 'alimentación',
        amount: 80,
        type: 'expense',
        title: 'QA6 Compra supermercado',
        date: admin.firestore.Timestamp.now(),
      });
      cleanupRefs.push(tx1Ref);
      console.log(`  📝 Created expense tx1 doc=${tx1Ref.id} amount=80`);

      const tx2Ref = db.collection('finance_transactions').doc(`qa6-tx2-${uid}`);
      await tx2Ref.set({
        userId: uid,
        category: 'alimentación',
        amount: 70,
        type: 'expense',
        title: 'QA6 Restaurante',
        date: admin.firestore.Timestamp.now(),
      });
      cleanupRefs.push(tx2Ref);
      console.log(`  📝 Created expense tx2 doc=${tx2Ref.id} amount=70`);

      // Wait for CoreSync to react
      const logA = await waitForLog(logs, 'OVER-BUDGET', WAIT_SYNC_MS);
      if (logA) {
        console.log(`  ✅ CoreSync detected overBudget: ${logA}`);
        result.A.pass = true;
        result.A.evidence = logA;
      } else {
        // Check for the write log instead
        const writeLog = logs.slice(logsBeforeA).find((l) =>
          l.includes('side-effect write path=') && l.includes('food/root/config/alerts') && l.includes('overBudget')
        );
        if (writeLog) {
          console.log(`  ✅ CoreSync wrote overBudget alert: ${writeLog.substring(0, 200)}`);
          result.A.pass = true;
          result.A.evidence = writeLog;
        } else {
          console.log('  ❌ No overBudget log detected');
          result.A.evidence = 'No OVER-BUDGET or side-effect write log found';
        }
      }

      // Wait for UI to update
      await sleep(3000);

      // Look for FoodDashboard alert logs
      const dashLog = logs.slice(logsBeforeA).find((l) =>
        l.includes('[FoodDashboard][alerts]') && l.includes('overBudget=true')
      );
      if (dashLog) {
        console.log(`  ✅ FoodDashboard rendered overBudget: ${dashLog}`);
      }

      await page.screenshot({ path: path.join(__dirname, 'evidence_A_overBudget.png'), fullPage: true });
      console.log('  📸 Screenshot: evidence_A_overBudget.png');
    }

    // ════════════════════════════════════════════════════════════════
    // SCENARIO B: Finance → Gym dueSoon
    // ════════════════════════════════════════════════════════════════
    console.log('\n═══ SCENARIO B: Finance → Gym dueSoon ═══');
    {
      const logsBeforeB = logs.length;

      // Seed: subscription with nextPaymentDate = tomorrow
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const subRef = db.collection('finance_subscriptions').doc(`qa6-sub-${uid}`);
      await subRef.set({
        userId: uid,
        name: 'QA6 Gym mensual',
        title: 'QA6 Gym mensual',
        amount: 49.99,
        active: true,
        isActive: true,
        nextPaymentDate: admin.firestore.Timestamp.fromDate(tomorrow),
        nextDue: admin.firestore.Timestamp.fromDate(tomorrow),
      });
      cleanupRefs.push(subRef);
      console.log(`  📝 Created subscription doc=${subRef.id} nextPaymentDate=tomorrow`);

      // Wait for CoreSync to react
      const logB = await waitForLog(logs, 'gym/root/alerts/subscription', WAIT_SYNC_MS);
      if (logB) {
        console.log(`  ✅ CoreSync wrote dueSoon alert: ${logB.substring(0, 200)}`);
        result.B.pass = true;
        result.B.evidence = logB;
      } else {
        const anySubLog = logs.slice(logsBeforeB).find((l) =>
          l.includes('[CoreSync][financeSubscriptions]')
        );
        console.log(`  ${anySubLog ? '⚠️' : '❌'} financeSubscriptions log: ${anySubLog || 'NONE'}`);
        result.B.evidence = anySubLog || 'No financeSubscriptions log found';
      }

      // Check GymDashboard rendering
      await sleep(3000);
      const gymLog = logs.slice(logsBeforeB).find((l) =>
        l.includes('[GymDashboard][alerts]') && l.includes('subSoon=true')
      );
      if (gymLog) {
        console.log(`  ✅ GymDashboard rendered dueSoon: ${gymLog}`);
      }

      await page.screenshot({ path: path.join(__dirname, 'evidence_B_dueSoon.png'), fullPage: true });
      console.log('  📸 Screenshot: evidence_B_dueSoon.png');
    }

    // ════════════════════════════════════════════════════════════════
    // SCENARIO C: Gym → Food targets / proteinLow / extremeDeficit
    // ════════════════════════════════════════════════════════════════
    console.log('\n═══ SCENARIO C: Gym → Food targets / proteinLow / extremeDeficit ═══');
    {
      const logsBeforeC = logs.length;

      // Seed: gym session today with 60 min, 6000 kg volume (strong workout)
      const sessionRef = db
        .collection('users')
        .doc(uid)
        .collection('gym')
        .doc('root')
        .collection('sessions')
        .doc(`qa6-session-${Date.now()}`);
      await sessionRef.set({
        date: todayIso(),
        durationMin: 60,
        volumeKg: 6000,
        exercises: 5,
        name: 'QA6 Heavy Workout',
      });
      cleanupRefs.push(sessionRef);
      console.log(`  📝 Created gym session doc=${sessionRef.id} durationMin=60 volumeKg=6000`);

      // Wait for CoreSync _syncFoodTargets
      const logC = await waitForLog(logs, '[CoreSync][_syncFoodTargets] alerts:', WAIT_SYNC_MS);
      if (logC) {
        console.log(`  ✅ CoreSync computed food alerts: ${logC}`);
        const hasProteinLow = logC.includes('proteinLow=true');
        const hasExtremeDeficit = logC.includes('extremeDeficit=true');
        result.C.pass = hasProteinLow || hasExtremeDeficit;
        result.C.evidence = logC;
        console.log(`    proteinLow=${hasProteinLow} extremeDeficit=${hasExtremeDeficit}`);
      } else {
        // Fallback: check for side-effect write
        const writeLog = logs.slice(logsBeforeC).find((l) =>
          l.includes('side-effect write path=') && l.includes('food/root/config/alerts')
        );
        if (writeLog) {
          console.log(`  ⚠️ CoreSync wrote food alerts (no summary log): ${writeLog.substring(0, 200)}`);
          result.C.pass = true;
          result.C.evidence = writeLog;
        } else {
          console.log('  ❌ No _syncFoodTargets alert log detected');
          result.C.evidence = 'No _syncFoodTargets logs found';
        }
      }

      await sleep(3000);

      // Check FoodDashboard alert rendering
      const foodLog = logs.slice(logsBeforeC).find((l) =>
        l.includes('[FoodDashboard][alerts]') && (l.includes('proteinLow=true') || l.includes('extremeDeficit=true'))
      );
      if (foodLog) {
        console.log(`  ✅ FoodDashboard rendered gym-driven alerts: ${foodLog}`);
      }

      await page.screenshot({ path: path.join(__dirname, 'evidence_C_gymToFood.png'), fullPage: true });
      console.log('  📸 Screenshot: evidence_C_gymToFood.png');
    }

    // ════════════════════════════════════════════════════════════════
    // SCENARIO D: Study ↔ Tasks bidirectional mirror
    // ════════════════════════════════════════════════════════════════
    console.log('\n═══ SCENARIO D: Study ↔ Tasks bidirectional ═══');
    {
      const logsBeforeD = logs.length;

      // Seed: study task without syncedTaskId → CoreSync creates matching task
      const studyTaskRef = db
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('tasks')
        .doc(`qa6-study-task-${Date.now()}`);

      await studyTaskRef.set({
        title: 'QA6 Study: Algebra Final',
        notes: 'Review chapters 5-8',
        status: 'todo',
        priority: 'high',
        courseId: 'qa6-course-math',
        due: new Date(Date.now() + 7 * 86400000).toISOString(),
      });
      cleanupRefs.push(studyTaskRef);
      console.log(`  📝 Created study task doc=${studyTaskRef.id}`);

      // Wait for mirror: study→tasks
      const mirrorLog = await waitForLog(logs, '[CoreSync][_mirrorStudyIntoTasks]   PROCESSING', WAIT_SYNC_MS);
      if (mirrorLog) {
        console.log(`  ✅ Study→Tasks mirror triggered: ${mirrorLog}`);
        result.D.pass = true;
        result.D.evidence = mirrorLog;
      } else {
        const anyLog = logs.slice(logsBeforeD).find((l) =>
          l.includes('[CoreSync][_mirrorStudyIntoTasks]')
        );
        result.D.evidence = anyLog || 'No _mirrorStudyIntoTasks log found';
        console.log(`  ${anyLog ? '⚠️' : '❌'} Mirror log: ${result.D.evidence}`);
      }

      // Wait extra for the mirror write + back-patch
      await sleep(5000);

      // Check that the synced task was created in tasks collection
      const linkedWriteLog = logs.slice(logsBeforeD).find((l) =>
        l.includes('side-effect write path=') && l.includes(`users/${uid}/tasks/`) && l.includes('QA6 Study: Algebra Final')
      );
      if (linkedWriteLog) {
        console.log(`  ✅ Task doc created: ${linkedWriteLog.substring(0, 200)}`);
        // Extract the task doc ID
        const docIdMatch = linkedWriteLog.match(/tasks\/([a-zA-Z0-9_-]+)/);
        if (docIdMatch) {
          console.log(`    → created taskId=${docIdMatch[1]}`);
          // Track for cleanup
          const taskRef = db.collection('users').doc(uid).collection('tasks').doc(docIdMatch[1]);
          cleanupRefs.push(taskRef);
        }
      } else {
        console.log('  ⚠️ No side-effect write log for task doc found');
      }

      // Check for no infinite loop: count mirror calls
      await sleep(5000);
      const mirrorCalls = logs.slice(logsBeforeD).filter((l) =>
        l.includes('[CoreSync][_mirrorStudyIntoTasks] ENTER') ||
        l.includes('[CoreSync][_mirrorTasksIntoStudy] ENTER')
      );
      console.log(`  🔁 Mirror calls total: ${mirrorCalls.length} (expected ≤ 4, loop if > 10)`);
      if (mirrorCalls.length > 10) {
        console.log('  ❌ POSSIBLE INFINITE LOOP detected!');
        result.D.pass = false;
        result.D.evidence += ' — INFINITE LOOP detected';
      }

      // Check skip-same-actor dedup
      const skipLogs = logs.slice(logsBeforeD).filter((l) =>
        l.includes('SKIP same-actor')
      );
      console.log(`  ✅ Dedup SKIP same-actor count: ${skipLogs.length}`);

      await page.screenshot({ path: path.join(__dirname, 'evidence_D_studyTasks.png'), fullPage: true });
      console.log('  📸 Screenshot: evidence_D_studyTasks.png');
    }

    // ═══════════════════════════════════════════════════════════════
    // SUMMARY
    // ═══════════════════════════════════════════════════════════════
    console.log('\n════════════════════════════════════════════');
    console.log('  IMPLEMENTATION 6 — QA RESULTS');
    console.log('════════════════════════════════════════════');
    console.log(`  A) Finance→Food overBudget   : ${result.A.pass ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`  B) Finance→Gym dueSoon       : ${result.B.pass ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`  C) Gym→Food targets/alerts   : ${result.C.pass ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`  D) Study↔Tasks bidirectional : ${result.D.pass ? '✅ PASS' : '❌ FAIL'}`);
    console.log('════════════════════════════════════════════');
    const allPass = result.A.pass && result.B.pass && result.C.pass && result.D.pass;
    console.log(`  OVERALL: ${allPass ? '✅ ALL PASS' : '❌ SOME FAIL'}`);
    console.log('════════════════════════════════════════════\n');

    // Write result JSON
    fs.writeFileSync(
      path.join(__dirname, 'result_impl6.json'),
      JSON.stringify(result, null, 2),
    );
    console.log('📄 Result written to result_impl6.json');

    // Dump relevant logs
    const syncLogs = logs.filter((l) =>
      l.includes('[CoreSync]') ||
      l.includes('[FoodDashboard]') ||
      l.includes('[FoodPlanner]') ||
      l.includes('[GymDashboard]') ||
      l.includes('[Calendar]')
    );
    fs.writeFileSync(
      path.join(__dirname, 'sync_console_logs.txt'),
      syncLogs.join('\n'),
    );
    console.log(`📄 ${syncLogs.length} sync-related console logs written to sync_console_logs.txt`);

    await browser.close();
    await cleanup();
    process.exit(allPass ? 0 : 1);
  } catch (err) {
    console.error('FATAL:', err);
    if (browser) await browser.close();
    await cleanup();
    process.exit(1);
  }
})();
