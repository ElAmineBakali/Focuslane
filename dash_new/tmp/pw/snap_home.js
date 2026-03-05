const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const token = fs.readFileSync('../../.tmp_owner_custom_token.txt', 'utf8').trim();
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 2200 } });
  await page.addInitScript((t) => {
    window.__TEST_OWNER_CUSTOM_TOKEN__ = t;
    window.__TEST_OWNER_UID__ = 'zwdI2qryK2aPUdafIy3QBfn0Gtu1';
  }, token);
  await page.goto('http://localhost:5173');
  await page.waitForTimeout(15000);
  await page.screenshot({ path: 'home_probe.png', fullPage: true });
  await browser.close();
})();
