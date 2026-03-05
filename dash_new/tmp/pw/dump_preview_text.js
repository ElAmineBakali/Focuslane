const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
  const logs = [];
  page.on('console', (msg) => logs.push(`[${msg.type()}] ${msg.text()}`));

  await page.goto('http://localhost:5173/#/', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(12000);
  await page.evaluate(() => {
    const el = document.querySelector('flt-semantics-placeholder');
    if (el) {
      el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
    }
  });
  await page.waitForTimeout(1200);
  await page.getByRole('button', { name: /Food\s*Entrar/i }).click();
  await page.waitForTimeout(7000);

  const chooserPromise = page.waitForEvent('filechooser', { timeout: 15000 });
  await page.getByRole('button', { name: /Añadir por foto/i }).click();
  const chooser = await chooserPromise;
  await chooser.setFiles(path.resolve(__dirname, 'food_photo.jpg'));

  await page.getByText('Analizando…').waitFor({ state: 'visible', timeout: 20000 });
  await page.getByText('Analizando…').waitFor({ state: 'hidden', timeout: 180000 });
  await page.waitForTimeout(1500);

  const bodyText = await page.evaluate(() => document.body.innerText || '');
  const roleButtons = await page.locator('[role="button"]').allTextContents();
  const allTexts = await page.locator('*').allTextContents();

  console.log('PREVIEW_BODY_START');
  console.log(bodyText.slice(0, 12000));
  console.log('PREVIEW_BODY_END');
  console.log('PREVIEW_ROLE_BUTTONS', JSON.stringify(roleButtons.slice(0, 200)));
  console.log('PREVIEW_SAMPLE_TEXTS', JSON.stringify(allTexts.map((x) => (x || '').trim()).filter(Boolean).slice(0, 240)));

  console.log('PREVIEW_LOGS_START');
  for (const line of logs.slice(-120)) console.log(line);
  console.log('PREVIEW_LOGS_END');

  await page.screenshot({ path: 'preview_dump.png', fullPage: true });
  await browser.close();
})();
