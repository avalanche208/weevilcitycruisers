const { chromium } = require('playwright');
const assert = require('node:assert/strict');
(async () => {
  const browser = await chromium.launch({headless:true});
  const page = await browser.newPage({viewport:{width:1440,height:1000}});
  const errors=[]; page.on('pageerror',e=>errors.push(e.message));
  const base = process.env.TEST_BASE_URL;
  assert(base, 'TEST_BASE_URL is required');
  await page.goto(base); await page.locator('.album').last().waitFor();
  assert.equal(await page.locator('.album').count(), 6); // smoke fixture adds 2027
  await page.screenshot({path:'preview-desktop.png',fullPage:true});
  await page.setViewportSize({width:390,height:844});
  await page.screenshot({path:'preview-mobile.png',fullPage:true});
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth), false);
  await page.goto(base+'/car-shows/2022/'); await page.locator('.photo-tile').waitFor();
  assert.equal(await page.locator('.photo-tile').count(), 1); // private.txt is filtered
  await page.locator('.photo-tile').click(); assert(await page.locator('dialog').isVisible());
  await page.keyboard.press('ArrowRight'); await page.keyboard.press('Escape');
  assert.equal(await page.locator('dialog').isVisible(), false);
  await page.goto(base+'/car-shows/2026/');
  await page.getByText('The memories are on their way.', {exact:false}).waitFor();
  assert.deepEqual(errors, []);
  await browser.close(); console.log('Browser smoke tests passed.');
})().catch(e=>{console.error(e);process.exit(1)});
