const path = require('path');
const { chromium } = require('playwright');

function parseKcalFromButtons(buttonTexts) {
  const matchText = buttonTexts.find((t) => /Calor/i.test(t) && /kcal/i.test(t)) || '';
  const numMatch = matchText.replace(/\n/g, ' ').match(/(\d+(?:[\.,]\d+)?)\s*kcal/i);
  return numMatch ? Number(numMatch[1].replace(',', '.')) : null;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
  const logs = [];
  page.on('console', (msg) => logs.push(`[${msg.type()}] ${msg.text()}`));

  const result = {
    step8: { pass: false, evidence: '' },
    step9: { pass: false, evidence: '' },
  };

  async function addAndConfirm(filePath) {
    const chooserPromise = page.waitForEvent('filechooser', { timeout: 15000 });
    await page.getByRole('button', { name: /Añadir por foto/i }).click();
    const chooser = await chooserPromise;
    await chooser.setFiles(filePath);

    await page.getByText('Analizando…').waitFor({ state: 'visible', timeout: 20000 });
    await page.getByText('Analizando…').waitFor({ state: 'hidden', timeout: 180000 });
    await page.getByText('Añadir por foto').waitFor({ state: 'visible', timeout: 20000 });

    await page.getByRole('button', { name: /^Confirmar$/i }).click({ timeout: 10000 });
    await page.waitForTimeout(2500);
  }

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

    const roleButtonsBefore = await page.locator('[role="button"]').allTextContents();
    const kcalBefore = parseKcalFromButtons(roleButtonsBefore);
    const saveCountBefore = logs.filter((l) => l.includes('[FoodPhotoAI] saved entry dayId=')).length;

    const photoPath = path.resolve(__dirname, 'food_photo.jpg');
    await addAndConfirm(photoPath);
    await page.screenshot({ path: 'step8_after_first_confirm.png', fullPage: true });

    await addAndConfirm(photoPath);
    await page.screenshot({ path: 'step8_after_second_confirm.png', fullPage: true });

    const roleButtonsAfter = await page.locator('[role="button"]').allTextContents();
    const kcalAfter = parseKcalFromButtons(roleButtonsAfter);
    const saveCountAfter = logs.filter((l) => l.includes('[FoodPhotoAI] saved entry dayId=')).length;

    result.step8.pass =
      kcalBefore !== null &&
      kcalAfter !== null &&
      kcalAfter > kcalBefore &&
      saveCountAfter >= saveCountBefore + 2;
    result.step8.evidence = `kcalBefore=${kcalBefore} kcalAfter=${kcalAfter} saveBefore=${saveCountBefore} saveAfter=${saveCountAfter}`;

    // Step 9: oversize abort, no backend call
    const oversizePath = path.resolve(__dirname, 'oversize_fake.png');
    const apiOkBefore = logs.filter((l) => l.includes('[FoodPhotoAI] api ok model=')).length;
    const saveBeforeOversize = logs.filter((l) => l.includes('[FoodPhotoAI] saved entry dayId=')).length;

    const chooserPromise = page.waitForEvent('filechooser', { timeout: 15000 });
    await page.getByRole('button', { name: /Añadir por foto/i }).click();
    const chooser = await chooserPromise;
    await chooser.setFiles(oversizePath);

    await page.getByText('Analizando…').waitFor({ state: 'visible', timeout: 20000 });
    await page.getByText('Analizando…').waitFor({ state: 'hidden', timeout: 120000 });

    const max2mbErrorVisible = await page.getByText(/2MB/i).isVisible().catch(() => false);
    const apiOkAfter = logs.filter((l) => l.includes('[FoodPhotoAI] api ok model=')).length;
    const saveAfterOversize = logs.filter((l) => l.includes('[FoodPhotoAI] saved entry dayId=')).length;
    const pickedLog = logs.slice().reverse().find((l) => l.includes('[FoodPhotoAI] picked bytes=')) || '';

    await page.screenshot({ path: 'step9_oversize_error.png', fullPage: true });

    result.step9.pass =
      max2mbErrorVisible &&
      apiOkAfter === apiOkBefore &&
      saveAfterOversize === saveBeforeOversize &&
      !!pickedLog;
    result.step9.evidence = `error2mb=${max2mbErrorVisible} apiOkBefore=${apiOkBefore} apiOkAfter=${apiOkAfter} saveBefore=${saveBeforeOversize} saveAfter=${saveAfterOversize} picked='${pickedLog}'`;

    console.log('RESULT_STEP8_9_START');
    console.log(JSON.stringify(result, null, 2));
    console.log('RESULT_STEP8_9_END');
    console.log('LOGS_STEP8_9_START');
    for (const line of logs.slice(-220)) console.log(line);
    console.log('LOGS_STEP8_9_END');
  } catch (error) {
    console.error('STEP8_9_ERROR', error && error.stack ? error.stack : String(error));
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
})();
