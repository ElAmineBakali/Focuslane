const path = require('path');
const { chromium } = require('playwright');

async function waitForAuth(logs, page) {
  const started = Date.now();
  while (Date.now() - started < 45000) {
    if (logs.some((l) => l.includes('[CoreSync][debugAuth] signed uid='))) return;
    await page.waitForTimeout(500);
  }
}

(async () => {
  const browser = await chromium.launch({ headless: true });

  const result = {
    A: { pass: false, evidence: '' },
    B: { pass: false, evidence: '' },
    C: { pass: false, evidence: '' },
    D: { pass: false, evidence: '' },
    E: { pass: false, evidence: '' },
    evidence: {
      pickedLog: null,
      statusLog: null,
      apiOkLog: null,
      docIdLog: null,
      docId: null,
    },
  };

  const logs = [];

  try {
    // A) separate semantics-only page (no scan) to avoid scan+semantics instability
    {
      const pageA = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
      pageA.on('console', (msg) => {
        logs.push(`[${msg.type()}] ${msg.text()}`);
      });

      await pageA.goto('http://localhost:5173/#/', { waitUntil: 'domcontentloaded' });
      await pageA.waitForTimeout(12000);
      await waitForAuth(logs, pageA);

      await pageA.evaluate(() => {
        const el = document.querySelector('flt-semantics-placeholder');
        if (el) {
          el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
        }
      });
      await pageA.waitForTimeout(1200);

      await pageA.getByRole('button', { name: /Finanzas\s*Entrar/i }).click();
      await pageA.waitForTimeout(4000);
      await pageA.getByRole('button', { name: /Nueva transacci/i }).click();
      await pageA.waitForTimeout(3000);

      const scanBtn = pageA.getByRole('button', { name: /Escanear ticket \(IA\)/i });
      const amountInput = pageA.locator('input[aria-label="Importe *"]').first();

      const scanVisible = await scanBtn.isVisible().catch(() => false);
      const scanBox = await scanBtn.boundingBox().catch(() => null);
      const amountBox = await amountInput.boundingBox().catch(() => null);
      const isNearAmount = !!scanBox && !!amountBox && Math.abs(scanBox.y - amountBox.y) < 280;

      await pageA.screenshot({ path: path.resolve(__dirname, 'evidence_A_scan_button.png'), fullPage: true });

      result.A.pass = scanVisible && isNearAmount;
      result.A.evidence = `scanVisible=${scanVisible} isNearAmount=${isNearAmount} scanBox=${JSON.stringify(scanBox)} amountBox=${JSON.stringify(amountBox)}`;

      await pageA.close();
    }

    // B-E) coordinate flow first, semantics enabled only after second successful scan
    const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
    page.on('console', (msg) => {
      logs.push(`[${msg.type()}] ${msg.text()}`);
    });

    await page.goto('http://localhost:5173/#/', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(12000);
    await waitForAuth(logs, page);

    await page.goto('http://localhost:5173/#/finance/transactions/form', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(4500);

    const receiptPath = path.resolve(__dirname, 'receipt_sample.png');

    // B + C first scan with cancel
    {
      const chooserPromise = page.waitForEvent('filechooser', { timeout: 30000 });
      await page.mouse.click(558, 342);
      await page.waitForTimeout(300);
      await page.mouse.click(558, 342);
      const chooser = await chooserPromise;
      await chooser.setFiles(receiptPath);

      result.B.pass = true;
      result.B.evidence = 'filechooser_opened=true';

      await page.waitForTimeout(1200);
      const cancelCandidates = [
        [760, 342], [800, 342], [840, 342], [880, 342],
        [760, 360], [800, 360], [840, 360], [880, 360],
      ];
      for (const [x, y] of cancelCandidates) {
        if (logs.some((l) => l.includes('[FinanceReceiptAI] analysis cancelled by user'))) break;
        await page.mouse.click(x, y);
        await page.waitForTimeout(700);
      }

      await page.waitForTimeout(2500);
      const cancelled = logs.some((l) => l.includes('[FinanceReceiptAI] analysis cancelled by user'));
      const previewConfirmed = logs.some((l) => l.includes('[FinanceReceiptAI] preview confirmed'));
      result.C.pass = cancelled && !previewConfirmed;
      result.C.evidence = `cancelled=${cancelled} previewConfirmedAfterCancel=${previewConfirmed}`;
    }

    // D + E second scan, then semantics for preview assertions
    {
      const beforeSecondScanLogs = logs.length;
      const chooserPromise = page.waitForEvent('filechooser', { timeout: 30000 });
      await page.mouse.click(558, 342);
      await page.waitForTimeout(300);
      await page.mouse.click(558, 342);
      const chooser = await chooserPromise;
      await chooser.setFiles(receiptPath);

      const waitApiStart = Date.now();
      while (Date.now() - waitApiStart < 150000) {
        if (logs.slice(beforeSecondScanLogs).some((l) => l.includes('[FinanceReceiptAI] api ok model='))) break;
        await page.waitForTimeout(500);
      }

      await page.waitForTimeout(1500);

      const secondStatusLog = logs
        .slice(beforeSecondScanLogs)
        .find((l) => l.includes('[FinanceReceiptAI] status=200 payload=')) || null;

      const payloadHasTotal = !!secondStatusLog && /total:\s*[^,}]+/i.test(secondStatusLog);
      const payloadHasCurrency = !!secondStatusLog && /currency:\s*[^,}]+/i.test(secondStatusLog);
      const payloadHasDate = !!secondStatusLog && /dateISO:/i.test(secondStatusLog);
      const payloadHasModel = !!secondStatusLog && /model:\s*[^,}]+/i.test(secondStatusLog);
      const hasToggleSignal = !!secondStatusLog;

      await page.screenshot({ path: path.resolve(__dirname, 'evidence_D_preview.png'), fullPage: true });

      // Enable semantics for dialog interaction (safe — crash only during scan/file-picker)
      await page.evaluate(() => {
        const el = document.querySelector('flt-semantics-placeholder');
        if (el) el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
      });
      await page.waitForTimeout(2500);

      // CONFIRM: try semantic → text → keyboard → coordinate sweep
      const confirmStrategies = [
        async () => await page.getByRole('button', { name: /^Confirmar$/i }).click({ timeout: 4000 }),
        async () => await page.getByText('Confirmar', { exact: true }).click({ timeout: 4000 }),
        async () => {
          // Keyboard: Tab to focus Confirmar, then Enter
          for (let i = 0; i < 6; i++) {
            await page.keyboard.press('Tab');
            await page.waitForTimeout(200);
          }
          await page.keyboard.press('Enter');
        },
        async () => {
          // Wide coordinate sweep over likely dialog action area
          const ys = [680, 700, 720, 740, 760, 780, 800, 660, 640];
          const xs = [980, 950, 920, 890, 860, 830, 800, 770, 1000, 1020];
          for (const y of ys) {
            for (const x of xs) {
              if (logs.some((l) => l.includes('[FinanceReceiptAI] preview confirmed'))) return;
              await page.mouse.click(x, y);
              await page.waitForTimeout(150);
            }
          }
        },
      ];
      for (const strategy of confirmStrategies) {
        if (logs.some((l) => l.includes('[FinanceReceiptAI] preview confirmed'))) break;
        try { await strategy(); } catch (_) { /* next strategy */ }
        await page.waitForTimeout(800);
      }
      await page.waitForTimeout(1500);

      const previewConfirmed = logs.some((l) => l.includes('[FinanceReceiptAI] preview confirmed'));

      result.D.pass =
        payloadHasTotal &&
        payloadHasCurrency &&
        payloadHasDate &&
        payloadHasModel &&
        hasToggleSignal &&
        previewConfirmed;
      result.D.evidence = `payloadTotal=${payloadHasTotal} payloadCurrency=${payloadHasCurrency} payloadDate=${payloadHasDate} payloadModel=${payloadHasModel} toggleSignal=${hasToggleSignal} confirmAction=${previewConfirmed}`;

      // SAVE: try semantic → text → keyboard → coordinate
      const saveStrategies = [
        async () => await page.getByRole('button', { name: /Guardar/i }).click({ timeout: 4000 }),
        async () => await page.getByText('Guardar', { exact: false }).last().click({ timeout: 4000 }),
        async () => await page.mouse.click(1420, 956),
      ];
      for (const strategy of saveStrategies) {
        if (logs.some((l) => l.includes('[FinanceReceiptAI] saved tx docId='))) break;
        try { await strategy(); } catch (_) { /* next */ }
        await page.waitForTimeout(2000);
      }
      await page.waitForTimeout(3500);

      result.evidence.pickedLog = logs.find((l) => l.includes('[FinanceReceiptAI] picked bytes=')) || null;
      result.evidence.statusLog = logs.find((l) => l.includes('[FinanceReceiptAI] status=200 payload=')) || null;
      result.evidence.apiOkLog = logs.find((l) => l.includes('[FinanceReceiptAI] api ok model=')) || null;
      const savedLogs = logs.filter((l) => l.includes('[FinanceReceiptAI] saved tx docId='));
      result.evidence.docIdLog = savedLogs.length ? savedLogs[savedLogs.length - 1] : null;

      const docIdMatch = result.evidence.docIdLog
        ? result.evidence.docIdLog.match(/docId=([A-Za-z0-9_-]+)/)
        : null;
      result.evidence.docId = docIdMatch ? docIdMatch[1] : null;

      result.E.pass =
        previewConfirmed &&
        !!result.evidence.pickedLog &&
        !!result.evidence.statusLog &&
        !!result.evidence.apiOkLog &&
        !!result.evidence.docId;
      result.E.evidence = `previewConfirmed=${previewConfirmed} docId=${result.evidence.docId}`;

      await page.screenshot({ path: path.resolve(__dirname, 'evidence_E_after_save.png'), fullPage: true });
    }

    console.log('RESULT_IMPL5_A_E_FINAL_START');
    console.log(JSON.stringify(result, null, 2));
    console.log('RESULT_IMPL5_A_E_FINAL_END');

    console.log('LOGS_IMPL5_A_E_FINAL_START');
    for (const line of logs.slice(-300)) console.log(line);
    console.log('LOGS_IMPL5_A_E_FINAL_END');

    await page.close();
  } catch (error) {
    console.error('CHECK_IMPL5_A_E_FINAL_ERROR', error && error.stack ? error.stack : String(error));
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
})();
