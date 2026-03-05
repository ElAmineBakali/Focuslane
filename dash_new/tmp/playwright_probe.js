const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const pageLogs = [];
  page.on('console', (msg) => pageLogs.push(`[${msg.type()}] ${msg.text()}`));

  await page.goto('http://localhost:5173', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(15000);

  const bodyText = await page.evaluate(() => document.body?.innerText || '');
  const roleButtons = await page.locator('[role="button"]').allTextContents();
  const htmlButtons = await page.locator('button').allTextContents();
  const semanticsCount = await page.locator('flt-semantics').count();

  console.log('BODY_TEXT_START');
  console.log(bodyText.slice(0, 5000));
  console.log('BODY_TEXT_END');
  console.log('ROLE_BUTTONS', JSON.stringify(roleButtons));
  console.log('HTML_BUTTONS', JSON.stringify(htmlButtons));
  console.log('SEMANTICS_COUNT', semanticsCount);

  if (pageLogs.length) {
    console.log('PAGE_CONSOLE_START');
    for (const line of pageLogs.slice(-80)) console.log(line);
    console.log('PAGE_CONSOLE_END');
  }

  await page.screenshot({ path: 'tmp/probe.png', fullPage: true });
  await browser.close();
})();
