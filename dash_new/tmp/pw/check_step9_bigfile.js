const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
  const logs = [];
  page.on('console', (msg) => logs.push(`[${msg.type()}] ${msg.text()}`));

  const result = { pass: false, evidence: '' };

  try {
    await page.goto('http://localhost:5173/#/', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(10000);
    await page.evaluate(() => {
      const el = document.querySelector('flt-semantics-placeholder');
      if (el) {
        el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
      }
    });
    await page.waitForTimeout(1200);

    const addPhotoVisible = await page.getByRole('button', { name: /Añadir por foto/i }).isVisible().catch(() => false);
    if (!addPhotoVisible) {
      await page.getByRole('button', { name: /Food\s*Entrar/i }).click({ timeout: 30000 });
      await page.waitForTimeout(5000);
    }

    const apiBefore = logs.filter((l) => l.includes('[FoodPhotoAI] api ok model=')).length;
    const saveBefore = logs.filter((l) => l.includes('[FoodPhotoAI] saved entry dayId=')).length;

    const chooserPromise = page.waitForEvent('filechooser', { timeout: 15000 });
    await page.getByRole('button', { name: /Añadir por foto/i }).click();
    const chooser = await chooserPromise;
    await chooser.setFiles(path.resolve(__dirname, 'food_photo_big.jpg'));

    await page.getByText('Analizando…').waitFor({ state: 'visible', timeout: 20000 });
    await page.getByText('Analizando…').waitFor({ state: 'hidden', timeout: 120000 });

    const error2mb = await page.getByText(/2MB/i).isVisible().catch(() => false);
    const apiAfter = logs.filter((l) => l.includes('[FoodPhotoAI] api ok model=')).length;
    const saveAfter = logs.filter((l) => l.includes('[FoodPhotoAI] saved entry dayId=')).length;
    const pickedBigLog = logs.find((l) => l.includes('[FoodPhotoAI] picked bytes=') && l.includes('resizedBytes=0')) || '';

    await page.screenshot({ path: 'step9_bigfile_error.png', fullPage: true });

    result.pass = error2mb && apiAfter === apiBefore && saveAfter === saveBefore && !!pickedBigLog;
    result.evidence = `error2mb=${error2mb} apiBefore=${apiBefore} apiAfter=${apiAfter} saveBefore=${saveBefore} saveAfter=${saveAfter} pickedBig='${pickedBigLog}'`;

    console.log('RESULT_STEP9_BIG_START');
    console.log(JSON.stringify(result, null, 2));
    console.log('RESULT_STEP9_BIG_END');
    console.log('LOGS_STEP9_BIG_START');
    for (const line of logs.slice(-180)) console.log(line);
    console.log('LOGS_STEP9_BIG_END');
  } catch (error) {
    console.error('STEP9_BIG_ERROR', error && error.stack ? error.stack : String(error));
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
})();
