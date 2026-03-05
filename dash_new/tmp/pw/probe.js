const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
  const pageLogs = [];
  page.on('console', (msg) => pageLogs.push(`[${msg.type()}] ${msg.text()}`));

  await page.goto('http://localhost:5173', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(18000);

  const bodyText = await page.evaluate(() => document.body?.innerText || '');
  const roleButtons = await page.locator('[role="button"]').allTextContents();
  const htmlButtons = await page.locator('button').allTextContents();
  const semanticsCount = await page.locator('flt-semantics').count();
  const allTexts = await page.locator('*').allTextContents();

  console.log('BODY_TEXT_START');
  console.log(bodyText.slice(0, 8000));
  console.log('BODY_TEXT_END');
  console.log('ROLE_BUTTONS', JSON.stringify(roleButtons.slice(0, 100)));
  console.log('HTML_BUTTONS', JSON.stringify(htmlButtons.slice(0, 100)));
  console.log('SEMANTICS_COUNT', semanticsCount);
  console.log('SAMPLE_TEXTS', JSON.stringify(allTexts.filter(Boolean).map((x) => x.trim()).filter(Boolean).slice(0, 120)));

  if (pageLogs.length) {
    console.log('PAGE_CONSOLE_START');
    for (const line of pageLogs.slice(-120)) console.log(line);
    console.log('PAGE_CONSOLE_END');
  }

  await page.screenshot({ path: 'probe.png', fullPage: true });
  await browser.close();
})();
