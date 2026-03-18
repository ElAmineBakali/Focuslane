const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const APP_URL = process.env.APP_URL || 'http://127.0.0.1:5173/#/';
const OUT_DIR = __dirname;

function nowIsoCompact() {
  return new Date().toISOString().replace(/[:.]/g, '-');
}

(async () => {
  const result = {
    appUrl: APP_URL,
    timestamp: new Date().toISOString(),
    routeLoaded: false,
    hasLoginGate: false,
    tabs: {},
    tabClicks: {},
    controls: {},
    semantics: {},
    uiTextSample: '',
    likelyCalendarScreen: false,
    errors: [],
    screenshots: [],
  };

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1600, height: 1100 } });
  const logs = [];
  page.on('console', (msg) => logs.push(`[${msg.type()}] ${msg.text()}`));

  try {
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded', timeout: 120000 });
    await page.waitForTimeout(12000);

    await page.evaluate(() => {
      const el = document.querySelector('flt-semantics-placeholder');
      if (el) {
        el.dispatchEvent(
          new MouseEvent('click', {
            bubbles: true,
            cancelable: true,
            view: window,
          }),
        );
      }
    });
    await page.waitForTimeout(1200);

    const bodyText = await page.evaluate(() => document.body?.innerText || '');
    const bodyLower = bodyText.toLowerCase();

    result.routeLoaded = true;
    result.hasLoginGate =
      bodyLower.includes('inicia sesión') ||
      bodyLower.includes('iniciar sesión') ||
      bodyLower.includes('login') ||
      bodyLower.includes('sign in');

    const tabs = {
      Anual: ['Anual'],
      Mensual: ['Mensual'],
      Semanal: ['Semanal'],
      Dia: ['Dia', 'Día'],
      Agenda: ['Agenda'],
    };

    if (!result.hasLoginGate) {
      const navCandidates = ['Calendario', 'Calendar'];
      for (const navText of navCandidates) {
        const count = await page.getByText(navText, { exact: true }).count();
        if (count > 0) {
          await page.getByText(navText, { exact: true }).first().click({ timeout: 5000 });
          await page.waitForTimeout(1200);
          break;
        }
      }
    }

    const roleTabsCount = await page.locator('[role="tab"]').count();
    const roleButtonsCount = await page.locator('[role="button"]').count();
    result.semantics.roleTabsCount = roleTabsCount;
    result.semantics.roleButtonsCount = roleButtonsCount;

    let visibleTabs = 0;
    for (const variants of Object.values(tabs)) {
      let found = false;
      for (const variant of variants) {
        const exactCount = await page.getByText(variant, { exact: true }).count();
        const looseCount = await page.getByText(new RegExp(variant, 'i')).count();
        if (exactCount > 0 || looseCount > 0) {
          found = true;
          break;
        }
      }
      if (found) visibleTabs += 1;
    }

    if (!result.hasLoginGate && visibleTabs == 0) {
      const directUrl = 'http://127.0.0.1:5173/#/calendar';
      await page.goto(directUrl, { waitUntil: 'domcontentloaded', timeout: 120000 });
      await page.waitForTimeout(5000);
      result.directCalendarRouteAttempted = true;
    }

    for (const [logicalTab, variants] of Object.entries(tabs)) {
      let matchedLabel = null;
      for (const variant of variants) {
        const exactCount = await page.getByText(variant, { exact: true }).count();
        const looseCount = await page.getByText(new RegExp(variant, 'i')).count();
        if (exactCount > 0 || looseCount > 0) {
          matchedLabel = variant;
          break;
        }
      }

      result.tabs[logicalTab] = matchedLabel != null;
      if (matchedLabel != null) {
        try {
          await page.getByText(new RegExp(matchedLabel, 'i')).first().click({ timeout: 4000 });
          await page.waitForTimeout(800);
          result.tabClicks[logicalTab] = true;
          const file = `calendar_tab_${logicalTab.toLowerCase()}_${nowIsoCompact()}.png`;
          const target = path.join(OUT_DIR, file);
          await page.screenshot({ path: target, fullPage: true });
          result.screenshots.push(file);
        } catch (e) {
          result.tabClicks[logicalTab] = false;
          result.errors.push(`click_tab_${logicalTab}: ${e.message}`);
        }
      } else {
        result.tabClicks[logicalTab] = false;
      }
    }

    const controls = ['Hoy', 'Anterior', 'Siguiente', 'Evento'];
    for (const control of controls) {
      const count = await page.getByText(control, { exact: true }).count();
      result.controls[control] = count > 0;
    }

    const bodyTextAfter = await page.evaluate(() => document.body?.innerText || '');
    result.uiTextSample = bodyTextAfter.slice(0, 3000);
    result.likelyCalendarScreen =
      /anual|mensual|semanal|agenda|calendario|evento|hoy/i.test(bodyTextAfter);

    const finalShot = `calendar_smoke_final_${nowIsoCompact()}.png`;
    const finalShotPath = path.join(OUT_DIR, finalShot);
    await page.screenshot({ path: finalShotPath, fullPage: true });
    result.screenshots.push(finalShot);

    const summaryFile = path.join(OUT_DIR, 'result_calendar_smoke.json');
    fs.writeFileSync(summaryFile, JSON.stringify(result, null, 2));

    console.log('CALENDAR_SMOKE_RESULT_START');
    console.log(JSON.stringify(result, null, 2));
    console.log('CALENDAR_SMOKE_RESULT_END');

    const logFile = path.join(OUT_DIR, 'calendar_smoke_console_logs.txt');
    fs.writeFileSync(logFile, logs.join('\n'));

    if (result.hasLoginGate) {
      console.log('WARN: Login gate detected; interaction coverage may be partial.');
    }
  } catch (e) {
    result.errors.push(e.message);
    const summaryFile = path.join(OUT_DIR, 'result_calendar_smoke.json');
    fs.writeFileSync(summaryFile, JSON.stringify(result, null, 2));
    console.error('Smoke execution failed:', e.message);
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
})();
