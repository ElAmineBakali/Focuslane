const { chromium } = require('playwright');
const fs = require('fs');

async function readToken() {
  const p = '../../.tmp_owner_custom_token.txt';
  return fs.readFileSync(p, 'utf8').trim();
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 2200 } });
  const page = await context.newPage();

  const token = await readToken();
  await page.addInitScript((t) => {
    window.__TEST_OWNER_CUSTOM_TOKEN__ = t;
    window.__TEST_OWNER_UID__ = 'zwdI2qryK2aPUdafIy3QBfn0Gtu1';
  }, token);

  await page.goto('http://localhost:5173', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(12000);

  await page.getByText('Diario', { exact: false }).first().click({ timeout: 15000 });
  await page.waitForTimeout(5000);

  // Click on right side content area and wheel-scroll aggressively
  await page.mouse.click(1000, 850);
  for (let i = 0; i < 14; i++) {
    await page.mouse.wheel(0, 900);
    await page.waitForTimeout(250);
  }

  await page.screenshot({ path: 'diary_probe_full.png', fullPage: true });
  await page.screenshot({ path: 'diary_probe_clip.png', clip: { x: 300, y: 220, width: 1120, height: 1700 } });

  await browser.close();
})();
