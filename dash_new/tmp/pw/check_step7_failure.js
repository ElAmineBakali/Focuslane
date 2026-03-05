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

    await page.getByRole('button', { name: /Food\s*Entrar/i }).click();
    await page.waitForTimeout(5000);

    const saveBefore = logs.filter((l) => l.includes('[FoodPhotoAI] saved entry dayId=')).length;

    const chooserPromise = page.waitForEvent('filechooser', { timeout: 15000 });
    await page.getByRole('button', { name: /Añadir por foto/i }).click();
    const chooser = await chooserPromise;
    await chooser.setFiles(path.resolve(__dirname, 'food_photo.jpg'));

    await page.getByText('Analizando…').waitFor({ state: 'visible', timeout: 20000 });
    await page.getByText('Analizando…').waitFor({ state: 'hidden', timeout: 120000 });

    const errorMessageVisible = await page.getByText(/No se pudo analizar la foto|Revisa la conexión/i).isVisible().catch(() => false);
    const saveAfter = logs.filter((l) => l.includes('[FoodPhotoAI] saved entry dayId=')).length;

    await page.screenshot({ path: 'step7_backend_failure.png', fullPage: true });

    result.pass = errorMessageVisible && saveAfter === saveBefore;
    result.evidence = `errorUI=${errorMessageVisible} saveBefore=${saveBefore} saveAfter=${saveAfter}`;

    console.log('RESULT_STEP7_START');
    console.log(JSON.stringify(result, null, 2));
    console.log('RESULT_STEP7_END');
    console.log('LOGS_STEP7_START');
    for (const line of logs.slice(-120)) console.log(line);
    console.log('LOGS_STEP7_END');
  } catch (error) {
    console.error('STEP7_ERROR', error && error.stack ? error.stack : String(error));
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
})();
