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
    step1: { pass: false, evidence: '' },
    step2: { pass: false, evidence: '' },
    step3: { pass: false, evidence: '' },
    step4: { pass: false, evidence: '' },
    step5: { pass: false, evidence: '' },
    step6: { pass: false, evidence: '' },
    kcalBefore: null,
    kcalAfter: null,
  };

  try {
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

    const roleButtonsDashboard = await page.locator('[role="button"]').allTextContents();
    const hasPhotoButton = roleButtonsDashboard.some((t) => /Añadir por foto/i.test(t));
    const photoButtonNode = await page.getByRole('button', { name: /Añadir por foto/i }).elementHandle();
    let photoButtonBox = null;
    if (photoButtonNode) photoButtonBox = await photoButtonNode.boundingBox();

    await page.screenshot({ path: 'step1_food_dashboard.png', fullPage: true });
    result.kcalBefore = parseKcalFromButtons(roleButtonsDashboard);

    result.step1.pass = hasPhotoButton && !!photoButtonBox;
    result.step1.evidence = `buttonBox=${JSON.stringify(photoButtonBox)} kcalBefore=${result.kcalBefore}`;

    const successImage = path.resolve(__dirname, 'food_photo.jpg');

    // Step 2 + Step 3: web picker works and cancel during analyzing
    {
      const chooserPromise = page.waitForEvent('filechooser', { timeout: 15000 });
      await page.getByRole('button', { name: /Añadir por foto/i }).click();
      const chooser = await chooserPromise;
      await chooser.setFiles(successImage);

      await page.getByText('Analizando…').waitFor({ state: 'visible', timeout: 20000 });
      await page.screenshot({ path: 'step3_analyzing_visible.png', fullPage: true });

      result.step2.pass = true;
      result.step2.evidence = 'filechooser_opened=true';

      await page.getByRole('button', { name: /^Cancelar$/i }).click({ timeout: 8000 });
      await page.waitForTimeout(1500);
      const analyzingStillVisible = await page.getByText('Analizando…').isVisible().catch(() => false);
      const canceledLog = logs.some((l) => l.includes('[FoodPhotoAI] analysis cancelled by user'));

      result.step3.pass = !analyzingStillVisible && canceledLog;
      result.step3.evidence = `analyzingVisibleAfterCancel=${analyzingStillVisible} cancelLog=${canceledLog}`;
    }

    // Step 4 + Step 5: preview + slider + confirm
    {
      const chooserPromise = page.waitForEvent('filechooser', { timeout: 15000 });
      await page.getByRole('button', { name: /Añadir por foto/i }).click();
      const chooser = await chooserPromise;
      await chooser.setFiles(successImage);

      await page.getByText('Analizando…').waitFor({ state: 'visible', timeout: 20000 });
      await page.getByText('Analizando…').waitFor({ state: 'hidden', timeout: 180000 });

      await page.getByText('Añadir por foto').waitFor({ state: 'visible', timeout: 20000 });
      const modelTextVisible = await page.getByText(/Modelo .* confianza/i).isVisible().catch(() => false);
      const previewBodyBefore = await page.evaluate(() => document.body.innerText || '');
      const kcalTextBefore = (previewBodyBefore.match(/(\d+)\s*kcal/i) || [])[0] || '';
      const macrosTextBefore = (previewBodyBefore.match(/Macros\s*·\s*P\s*\d+\s*g\s*·\s*C\s*\d+\s*g\s*·\s*G\s*\d+\s*g/i) || [])[0] || '';
      const ratioTextBefore = (previewBodyBefore.match(/Ajuste por ración:\s*[\d.]+x/i) || [])[0] || '';

      await page.screenshot({ path: 'step4_preview_before_slider.png', fullPage: true });

      const range = page.locator('input[type="range"]').first();
      await range.evaluate((el) => {
        el.value = '2';
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
      });
      await page.waitForTimeout(800);

      const previewBodyAfter = await page.evaluate(() => document.body.innerText || '');
      const kcalTextAfter = (previewBodyAfter.match(/(\d+)\s*kcal/i) || [])[0] || '';
      const macrosTextAfter = (previewBodyAfter.match(/Macros\s*·\s*P\s*\d+\s*g\s*·\s*C\s*\d+\s*g\s*·\s*G\s*\d+\s*g/i) || [])[0] || '';
      const ratioTextAfter = (previewBodyAfter.match(/Ajuste por ración:\s*[\d.]+x/i) || [])[0] || '';

      result.step4.pass =
        modelTextVisible &&
        !!kcalTextBefore &&
        !!kcalTextAfter &&
        !!macrosTextBefore &&
        !!macrosTextAfter &&
        kcalTextBefore !== kcalTextAfter &&
        macrosTextBefore !== macrosTextAfter &&
        ratioTextBefore !== ratioTextAfter;
      result.step4.evidence = `modelVisible=${modelTextVisible} kcalBefore='${kcalTextBefore}' kcalAfter='${kcalTextAfter}' macrosBefore='${macrosTextBefore}' macrosAfter='${macrosTextAfter}' ratioBefore='${ratioTextBefore}' ratioAfter='${ratioTextAfter}'`;

      await page.getByRole('button', { name: /^Confirmar$/i }).click({ timeout: 10000 });
      await page.waitForTimeout(2500);

      await page.screenshot({ path: 'step5_after_confirm_dashboard.png', fullPage: true });

      const saveLog = logs.some((l) => l.includes('[FoodPhotoAI] saved entry dayId='));
      const roleButtonsAfterConfirm = await page.locator('[role="button"]').allTextContents();
      result.kcalAfter = parseKcalFromButtons(roleButtonsAfterConfirm);

      // Validate diary visual label
      await page.getByRole('button', { name: /^Diario$/i }).click({ timeout: 10000 });
      await page.waitForTimeout(2500);
      const photoLabelVisible = await page.getByText(/Foto \(IA\)/i).first().isVisible().catch(() => false);
      await page.screenshot({ path: 'step5_diary_photo_entry.png', fullPage: true });

      result.step5.pass = saveLog && result.kcalAfter !== null && result.kcalBefore !== null && result.kcalAfter > result.kcalBefore && photoLabelVisible;
      result.step5.evidence = `saveLog=${saveLog} kcalBefore=${result.kcalBefore} kcalAfter=${result.kcalAfter} photoLabelVisible=${photoLabelVisible}`;

      // return dashboard for step 6
      await page.getByRole('button', { name: /^Panel$/i }).first().click({ timeout: 10000 });
      await page.waitForTimeout(1800);
    }

    // Step 6: cancel in preview should not save
    {
      const saveLogCountBefore = logs.filter((l) => l.includes('[FoodPhotoAI] saved entry dayId=')).length;

      const chooserPromise = page.waitForEvent('filechooser', { timeout: 15000 });
      await page.getByRole('button', { name: /Añadir por foto/i }).click();
      const chooser = await chooserPromise;
      await chooser.setFiles(path.resolve(__dirname, 'food_photo.jpg'));

      await page.getByText('Analizando…').waitFor({ state: 'visible', timeout: 20000 });
      await page.getByText('Analizando…').waitFor({ state: 'hidden', timeout: 180000 });
      await page.getByText('Añadir por foto').waitFor({ state: 'visible', timeout: 20000 });

      await page.getByRole('button', { name: /^Cancelar$/i }).click({ timeout: 10000 });
      await page.waitForTimeout(1500);
      await page.screenshot({ path: 'step6_preview_cancelled.png', fullPage: true });

      const saveLogCountAfter = logs.filter((l) => l.includes('[FoodPhotoAI] saved entry dayId=')).length;
      const previewStillVisible = await page.getByText('Ajuste por ración').isVisible().catch(() => false);

      result.step6.pass = saveLogCountAfter === saveLogCountBefore && !previewStillVisible;
      result.step6.evidence = `saveCountBefore=${saveLogCountBefore} saveCountAfter=${saveLogCountAfter} previewVisibleAfterCancel=${previewStillVisible}`;
    }

    console.log('RESULT_JSON_START');
    console.log(JSON.stringify(result, null, 2));
    console.log('RESULT_JSON_END');

    console.log('APP_LOGS_TAIL_START');
    for (const line of logs.slice(-180)) console.log(line);
    console.log('APP_LOGS_TAIL_END');
  } catch (error) {
    console.error('CHECK_STEPS_1_6_ERROR', error && error.stack ? error.stack : String(error));
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
})();
