const { chromium, webkit } = require('playwright');
const assert = require('node:assert/strict');
(async () => {
  for (const [engineName, engine] of [["chromium", chromium], ["webkit", webkit]]) {
  const browser = await engine.launch({headless:true});
  const page = await browser.newPage({viewport:{width:1440,height:1000}});
  const errors=[]; page.on('pageerror',e=>errors.push(e.message));
  const base = process.env.TEST_BASE_URL;
  assert(base, 'TEST_BASE_URL is required');
  await page.goto(base); await page.locator('.album').last().waitFor();
  assert.equal(await page.locator('.album').count(), 6); // smoke fixture adds 2027
  await page.screenshot({path:`preview-${engineName}-desktop.png`,fullPage:true});
  for (const width of [320, 390, 430, 768]) {
    await page.setViewportSize({width,height:844});
    await page.locator('.hero-art img').evaluate(img=>img.decode());
    const layout=await page.evaluate(()=>{
      const image=document.querySelector('.hero-art img');
      const rect=image.getBoundingClientRect();
      const caption=document.querySelector('.art-caption').getBoundingClientRect();
      const links=[...document.querySelectorAll('header nav a')].filter(a=>getComputedStyle(a).display!=='none').map(a=>a.getBoundingClientRect());
      return {overflow:document.documentElement.scrollWidth>innerWidth, ratio:rect.width/rect.height, naturalRatio:image.naturalWidth/image.naturalHeight, captionGap:caption.top-rect.bottom, navCenters:links.map(r=>r.top+r.height/2)};
    });
    assert.equal(layout.overflow,false,`${engineName} ${width}: overflow`);
    assert(Math.abs(layout.ratio-layout.naturalRatio)<0.03,`${engineName} ${width}: distorted artwork`);
    assert(layout.captionGap>=12,`${engineName} ${width}: caption overlaps image`);
    assert(Math.max(...layout.navCenters)-Math.min(...layout.navCenters)<2,`${engineName} ${width}: navigation misaligned`);
    if(width===390) await page.screenshot({path:`preview-${engineName}-mobile.png`,fullPage:true});
  }
  await page.goto(base+'/car-shows/2022/'); await page.locator('.photo-tile').waitFor();
  assert.equal(await page.locator('.photo-tile').count(), 1); // private.txt is filtered
  await page.locator('.photo-tile').click(); assert(await page.locator('dialog').isVisible());
  await page.keyboard.press('ArrowRight'); await page.keyboard.press('Escape');
  assert.equal(await page.locator('dialog').isVisible(), false);
  await page.goto(base+'/car-shows/2026/');
  await page.getByText('The memories are on their way.', {exact:false}).waitFor();
  assert.deepEqual(errors, []);
  await browser.close(); console.log(`${engineName} browser smoke tests passed.`);
  }
})().catch(e=>{console.error(e);process.exit(1)});
