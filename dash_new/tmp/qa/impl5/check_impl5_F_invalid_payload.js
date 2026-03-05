const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
  const logs = [];
  page.on('console', (msg) => {
    const line = `[${msg.type()}] ${msg.text()}`;
    logs.push(line);
  });

  const result = {
    pass: false,
    evidence: '',
    docId: null,
    errorLogged: false,
  };

  try {
    await page.route('**/v1/ai/finance/receipt_scan', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          merchant: null,
          total: null,
          currency: 'EUR',
          dateISO: null,
          items: [],
          confidence: 0.99,
          model: 'forced-invalid',
        }),
      });
    });

    await page.goto('http://localhost:5173/#/', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(12000);

    const authStart = Date.now();
    while (Date.now() - authStart < 40000) {
      if (logs.some((l) => l.includes('[CoreSync][debugAuth] signed uid='))) break;
      await page.waitForTimeout(500);
    }

    await page.goto('http://localhost:5173/#/finance/transactions/form', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(4500);

    const chooserPromise = page.waitForEvent('filechooser', { timeout: 30000 });
    await page.mouse.click(558, 342);
    await page.waitForTimeout(300);
    await page.mouse.click(558, 342);
    const chooser = await chooserPromise;
    await chooser.setFiles(path.resolve(__dirname, 'receipt_sample.png'));

    const waitErrorStart = Date.now();
    while (Date.now() - waitErrorStart < 120000) {
      if (logs.some((l) => l.includes('[FinanceReceiptAI] scan error message='))) break;
      await page.waitForTimeout(500);
    }
    await page.waitForTimeout(1200);

    await page.screenshot({ path: path.resolve(__dirname, 'evidence_F_invalid_error.png'), fullPage: true });

    const errorLine = logs.find((l) => l.includes('[FinanceReceiptAI] scan error message=')) || null;
    const hasError = !!errorLine && /datos válidos del ticket/i.test(errorLine);
    const previewConfirmed = logs.some((l) => l.includes('[FinanceReceiptAI] preview confirmed'));

    await page.mouse.click(620, 240);
    await page.keyboard.press('Control+A');
    await page.keyboard.type('Manual tras error IA');

    await page.mouse.click(620, 296);
    await page.keyboard.press('Control+A');
    await page.keyboard.type('8.90');

    await page.mouse.click(1420, 956);
    await page.waitForTimeout(5000);

    result.errorLogged = hasError;

    const docIdLog = logs.find((l) => l.includes('[FinanceReceiptAI] saved tx docId=')) || null;
    const docIdMatch = docIdLog ? docIdLog.match(/docId=([A-Za-z0-9_-]+)/) : null;
    result.docId = docIdMatch ? docIdMatch[1] : null;

    result.pass = hasError && !previewConfirmed && !!result.docId;
    result.evidence = `errorLine=${errorLine} previewConfirmed=${previewConfirmed} docId=${result.docId}`;

    console.log('RESULT_IMPL5_F_INVALID_START');
    console.log(JSON.stringify(result, null, 2));
    console.log('RESULT_IMPL5_F_INVALID_END');

    console.log('LOGS_IMPL5_F_INVALID_START');
    for (const line of logs.slice(-200)) console.log(line);
    console.log('LOGS_IMPL5_F_INVALID_END');
  } catch (error) {
    console.error('CHECK_IMPL5_F_INVALID_ERROR', error && error.stack ? error.stack : String(error));
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
})();
