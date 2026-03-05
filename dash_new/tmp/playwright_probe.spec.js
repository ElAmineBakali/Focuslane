const { test } = require('playwright/test');

test('probe flutter dom and semantics', async ({ page }) => {
  const logs = [];
  page.on('console', (msg) => logs.push(`[${msg.type()}] ${msg.text()}`));

  await page.goto('http://localhost:5173', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(15000);

  const bodyText = await page.evaluate(() => document.body?.innerText || '');
  const roleButtons = await page.locator('[role="button"]').allTextContents();
  const allButtons = await page.locator('button').allTextContents();
  const semanticsNodes = await page.locator('flt-semantics').count();

  console.log('BODY_TEXT_START');
  console.log(bodyText.slice(0, 5000));
  console.log('BODY_TEXT_END');

  console.log('ROLE_BUTTONS', JSON.stringify(roleButtons));
  console.log('HTML_BUTTONS', JSON.stringify(allButtons));
  console.log('SEMANTICS_COUNT', semanticsNodes);

  if (logs.length > 0) {
    console.log('PAGE_CONSOLE_START');
    for (const l of logs.slice(-50)) console.log(l);
    console.log('PAGE_CONSOLE_END');
  }

  await page.screenshot({ path: 'tmp/probe.png', fullPage: true });
});
