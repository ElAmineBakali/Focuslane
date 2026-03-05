const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
  const logs = [];
  page.on('console', (msg) => logs.push(`[${msg.type()}] ${msg.text()}`));

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
  await page.getByRole('button', { name: /^Diario$/i }).first().click();
  await page.waitForTimeout(5000);

  const bodyText = await page.evaluate(() => document.body.innerText || '');
  console.log('HAS_FOTO_IA', /Foto \(IA\)/i.test(bodyText));
  console.log('BODY_TEXT_START');
  console.log(bodyText.slice(0, 12000));
  console.log('BODY_TEXT_END');
  console.log('LOGS_START');
  for (const line of logs.slice(-120)) console.log(line);
  console.log('LOGS_END');

  await page.screenshot({ path: 'diary_label_check.png', fullPage: true });
  await browser.close();
})();
