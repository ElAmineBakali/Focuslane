const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
  await page.goto('http://localhost:5173/#/', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(12000);

  await page.evaluate(() => {
    const el = document.querySelector('flt-semantics-placeholder');
    if (el) {
      el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
    }
  });

  await page.waitForTimeout(1500);

  const foodButton = page.getByRole('button', { name: /Food\s*Entrar/i });
  await foodButton.click();
  await page.waitForTimeout(7000);

  const roleButtons = await page.locator('[role="button"]').allTextContents();
  const allText = await page.evaluate(() => document.body.innerText || '');

  console.log('ROLE_BUTTONS_FOOD_START');
  console.log(JSON.stringify(roleButtons.slice(0, 200)));
  console.log('ROLE_BUTTONS_FOOD_END');
  console.log('BODY_TEXT_FOOD_START');
  console.log(allText.slice(0, 8000));
  console.log('BODY_TEXT_FOOD_END');

  await page.screenshot({ path: 'food_buttons.png', fullPage: true });
  await browser.close();
})();
