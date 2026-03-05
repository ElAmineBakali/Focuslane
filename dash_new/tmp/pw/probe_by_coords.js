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
  await page.waitForTimeout(14000);
  await page.screenshot({ path: 'coord_0_home.png', fullPage: true });

  // try open Food module in sidebar
  await page.mouse.click(100, 280);
  await page.waitForTimeout(2500);
  await page.screenshot({ path: 'coord_1_food.png', fullPage: true });

  // try click Diario tab/menu
  await page.mouse.click(95, 318);
  await page.waitForTimeout(3500);
  await page.screenshot({ path: 'coord_2_diary.png', fullPage: true });

  await page.mouse.click(980, 860);
  for (let i = 0; i < 16; i++) {
    await page.mouse.wheel(0, 1000);
    await page.waitForTimeout(220);
  }
  await page.screenshot({ path: 'coord_3_diary_scrolled.png', fullPage: true });
  await page.screenshot({ path: 'coord_3_diary_clip.png', clip: { x: 280, y: 220, width: 1120, height: 1700 } });

  await browser.close();
})();
