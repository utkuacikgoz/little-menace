// App Store marketing frames: headline + highlighter + phone, in the psst style.
// Usage: node scripts/store-frames/compose.js <A|B|final> [out-dir]
// 'final' renders each slide's chosen copy ("pick" in slides.json) as NN.jpg for upload.
// Reads raw 1320x2868 captures from docs/app-store-screenshots and writes PNGs
// at the same size. Needs Playwright with a Chromium (PLAYWRIGHT_CHROMIUM overrides the path).
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const here = __dirname;
const root = path.resolve(here, '../..');
const shots = path.join(root, 'docs/app-store-screenshots');
const variant = (process.argv[2] || 'A').toUpperCase();
const out = path.resolve(process.argv[3] || path.join(shots, 'marketing'));
const slides = JSON.parse(fs.readFileSync(path.join(here, 'slides.json'), 'utf8'));
fs.mkdirSync(out, { recursive: true });

// Fonts and screenshots are inlined: a page set from a string can't load local files.
const b64 = f => fs.readFileSync(f).toString('base64');
const font = (w, f) => `@font-face{font-family:"Inter Tight";font-weight:${w};src:url(data:font/woff2;base64,${b64(path.join(here, 'fonts', f))}) format("woff2");}`;

function html(s) {
  const copy = s[variant === 'FINAL' ? s.pick : variant];
  return `<!doctype html><html><head><meta charset="utf-8"><style>
${font(900, 'InterTight-Black.woff2')}${font(800, 'InterTight-ExtraBold.woff2')}${font(700, 'InterTight-Bold.woff2')}
*{box-sizing:border-box;margin:0}
html,body{width:1320px;height:2868px;overflow:hidden}
body{background:${s.bg};color:${s.ink};font-family:"Inter Tight",sans-serif;-webkit-font-smoothing:antialiased;position:relative}
.word{position:absolute;left:96px;top:118px;font-weight:900;font-size:96px;letter-spacing:-.035em;line-height:1;color:${s.brand}}
h1{position:absolute;left:88px;right:72px;top:268px;white-space:nowrap;font-weight:900;font-size:190px;line-height:.93;letter-spacing:-.035em;word-spacing:.04em}
mark{background:none;color:inherit;position:relative;white-space:nowrap}
mark::after{content:"";position:absolute;left:1%;right:2%;bottom:-.07em;height:.1em;border-radius:99px;background:${s.mark};transform:rotate(-1.2deg)}
.sub{position:absolute;left:96px;right:80px;top:${'SUBTOP'}px;font-weight:800;font-size:66px;line-height:1.1;letter-spacing:-.01em;opacity:.95}
.phone{position:absolute;left:50%;width:860px;transform:translateX(-50%);top:${'PHONETOP'}px;padding:22px;background:#0E0C12;border-radius:132px;
  box-shadow:0 60px 120px -40px rgba(20,14,30,.55),0 0 0 4px #2B2833 inset}
.phone img{display:block;width:100%;border-radius:112px}
</style></head><body>
<div class="word">little menace</div>
<h1 id="h">${copy.head}</h1>
<div class="sub" id="s">${copy.sub}</div>
<div class="phone" id="p"><img src="data:image/jpeg;base64,${b64(path.join(shots, s.shot))}"></div>
</body></html>`;
}

(async () => {
  const exe = process.env.PLAYWRIGHT_CHROMIUM || '/opt/pw-browsers/chromium';
  const browser = await chromium.launch(fs.existsSync(exe) ? { executablePath: exe } : {});
  const page = await browser.newPage({ viewport: { width: 1320, height: 2868 } });
  for (const s of slides) {
    if (!fs.existsSync(path.join(shots, s.shot))) { console.log(`skip ${s.id}: missing ${s.shot}`); continue; }
    await page.setContent(html(s).replace('SUBTOP', '0').replace('PHONETOP', '0'), { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    // Long headlines shrink until every line fits the width.
    await page.$eval('#h', e => {
      let size = 190;
      while (size > 120 && e.scrollWidth > e.clientWidth + 1) { size -= 6; e.style.fontSize = size + 'px'; }
    });
    // Stack: headline, then the sub-line, then the phone; the phone may run off the bottom like a hand-held shot.
    const hBottom = await page.$eval('#h', e => e.getBoundingClientRect().bottom);
    const subTop = Math.round(hBottom + 58);
    await page.$eval('#s', (e, t) => { e.style.top = t + 'px'; }, subTop);
    const sBottom = await page.$eval('#s', e => e.getBoundingClientRect().bottom);
    await page.$eval('#p', (e, t) => { e.style.top = t + 'px'; }, Math.round(sBottom + 96));
    const final = variant === 'FINAL';
    const file = path.join(out, final ? `${s.id}.jpg` : `${s.id}-${variant}.png`);
    await page.screenshot(final ? { path: file, type: 'jpeg', quality: 92 } : { path: file });
    console.log('wrote', path.relative(root, file));
  }
  await browser.close();
})();
