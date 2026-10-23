// The gremlin from the app (GremlinView.swift), drawn as SVG in the same 200x220 design space.
// data-gremlin="head" peeks over a button; data-gremlin="full" is the whole gremlin, posed by LMGremlin.mood().
(() => {
  const C = { body: '#241F33', light: '#3A3350', dark: '#16121F', belly: '#3B3452', bellyDark: '#2E2842',
    iris: '#E59A2E', irisLight: '#FFD46B', eye: '#FFF7EA', pupil: '#120F1C', blush: '#FF8FA3', mouth: '#5A1830' };
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let uid = 0;

  // An ellipse whose edge is a ring of soft bumps (FluffShape).
  const fluff = (cx, cy, rx, ry, bumps, depth) => {
    const steps = bumps * 8;
    let d = '';
    for (let i = 0; i <= steps; i++) {
      const t = i / steps * 2 * Math.PI, b = depth * Math.abs(Math.sin(t * bumps / 2));
      d += (i ? 'L' : 'M') + (cx + (rx - depth + b) * Math.cos(t)).toFixed(1) + ',' + (cy + (ry - depth + b) * Math.sin(t)).toFixed(1);
    }
    return d + 'Z';
  };
  const ear = (x, y) => `M${x},${y + 70}Q${x + 5.8},${y + 28} ${x + 36},${y}Q${x + 58},${y + 35} ${x + 58},${y + 70}Z`;
  const earIn = (x, y) => `M${x + 12},${y + 58}Q${x + 15.4},${y + 30.4} ${x + 33.1},${y + 12}Q${x + 46},${y + 35} ${x + 46},${y + 58}Z`;
  const mouth = (d, fang, fangOpacity = 1) => `<path d="${d}" fill="${C.mouth}" stroke="${C.pupil}" stroke-width="3.5" stroke-linejoin="round"/><path d="${fang}" fill="${C.eye}" opacity="${fangOpacity}"/>`;

  const eye = (cx, side, id) => `
    <g class="gr-blink"><g class="gr-eyeball">
      <clipPath id="${id}c${side}"><ellipse cx="${cx}" cy="100" rx="19" ry="21"/></clipPath>
      <ellipse cx="${cx}" cy="100" rx="19" ry="21" fill="${C.eye}"/>
      <g clip-path="url(#${id}c${side})"><g class="gr-iris">
        <circle cx="${cx}" cy="100" r="12.5" fill="url(#${id}i)"/>
        <circle cx="${cx}" cy="100" r="7" fill="${C.pupil}"/>
        <circle cx="${cx + 5}" cy="95" r="3.5" fill="#fff"/>
        <circle cx="${cx - 5}" cy="105" r="1.5" fill="#fff" opacity=".7"/>
      </g></g>
    </g></g>
    <path class="gr-lid" d="M${cx - 15},106Q${cx},88 ${cx + 15},106" fill="none" stroke="${C.eye}" stroke-width="4.5" stroke-linecap="round"/>
    <path class="gr-lid-sleep" d="M${cx - 15},96Q${cx},112 ${cx + 15},96" fill="none" stroke="${C.eye}" stroke-width="4.5" stroke-linecap="round"/>`;

  const svg = (head) => {
    const id = 'gr' + (++uid);
    return `<svg class="gr" viewBox="${head ? '4 16 192 124' : '-14 14 244 206'}" aria-hidden="true" focusable="false">
  <defs>
    <radialGradient id="${id}f" gradientUnits="userSpaceOnUse" cx="77" cy="93" r="120">
      <stop offset=".07" stop-color="${C.light}"/><stop offset=".55" stop-color="${C.body}"/><stop offset="1" stop-color="${C.dark}"/></radialGradient>
    <linearGradient id="${id}b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${C.belly}"/><stop offset="1" stop-color="${C.bellyDark}"/></linearGradient>
    <linearGradient id="${id}t" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${C.light}"/><stop offset="1" stop-color="${C.dark}"/></linearGradient>
    <radialGradient id="${id}i"><stop offset=".15" stop-color="${C.irisLight}"/><stop offset="1" stop-color="${C.iris}"/></radialGradient>
  </defs>
  ${head ? '' : '<ellipse cx="100" cy="210" rx="65" ry="8" fill="#000" opacity=".18"/>'}
  <g class="gr-hop"><g class="gr-rig">
    ${head ? '' : `<g class="gr-tail"><path d="M160,195C230,195 170,125 214,129" fill="none" stroke="${C.body}" stroke-width="12" stroke-linecap="round"/><circle cx="214" cy="129" r="10" fill="${C.body}"/></g>`}
    <g transform="rotate(-28 48 93)"><g class="gr-ear gr-ear-l"><path d="${ear(19, 23)}" fill="${C.body}"/><path d="${earIn(19, 31)}" fill="${C.blush}" opacity=".45"/></g></g>
    <g transform="rotate(28 152 93)"><g class="gr-ear gr-ear-r"><g class="gr-twitch"><path d="${ear(123, 23)}" fill="${C.body}"/><path d="${earIn(123, 31)}" fill="${C.blush}" opacity=".45"/></g></g></g>
    <g class="gr-arm gr-arm-l"><rect x="19" y="127" width="22" height="46" rx="11" fill="${C.body}" transform="rotate(-20 30 127)"/></g>
    <g class="gr-arm gr-arm-r"><rect x="159" y="127" width="22" height="46" rx="11" fill="${C.body}" transform="rotate(20 170 127)"/></g>
    <path d="M82,65Q85.5,51.5 85.5,45.5Q94.3,50 96.1,62Q98.7,51.5 108.4,35Q107.5,50 109.3,62Q111.9,51.5 123.4,44Q120.7,50 122.5,62L126,65Z" fill="${C.body}"/>
    <path d="${fluff(100, 128, 83, 79, 26, 3.2)}" fill="url(#${id}f)"/>
    <path d="${fluff(100, 128, 83, 79, 26, 3.2)}" fill="none" stroke="#fff" stroke-opacity=".12" stroke-width="2.5"/>
    <path d="${fluff(100, 170, 46, 35, 14, 2.2)}" fill="url(#${id}b)"/>
    ${head ? '' : [49, 151].map(x => `<ellipse cx="${x}" cy="203" rx="21" ry="11" fill="url(#${id}t)"/>` +
      [-8, 0, 8].map(o => `<rect x="${x + o - 1}" y="202.5" width="2" height="7" rx="1" fill="${C.dark}" opacity=".9"/>`).join('')).join('')}
    ${eye(64, 'l', id)}${eye(136, 'r', id)}
    <rect class="gr-brow gr-brow-l" x="49" y="67.5" width="22" height="5" rx="2.5" fill="${C.pupil}" opacity=".9"/>
    <rect class="gr-brow gr-brow-r" x="129" y="67.5" width="22" height="5" rx="2.5" fill="${C.pupil}" opacity=".9"/>
    <g class="gr-blush"><ellipse cx="46" cy="128" rx="11" ry="6" fill="${C.blush}"/><ellipse cx="154" cy="128" rx="11" ry="6" fill="${C.blush}"/></g>
    <g class="gr-m gr-m-calm">${mouth('M77.3,130.2Q100,135.5 122.7,130.2Q100,139.4 77.3,130.2Z', 'M107,132.5L115,132.5L111,141.5Z', '.6')}</g>
    <g class="gr-m gr-m-happy">${mouth('M78.4,127.6Q100,136.7 121.6,127.6Q100,154.1 78.4,127.6Z', 'M106,131L114,131L110,140Z')}</g>
    ${head ? '' : `<g class="gr-m gr-m-cross">${mouth('M77.3,135.9Q100,128.3 122.7,135.9Q100,132.8 77.3,135.9Z', 'M107,131L115,131L111,140Z')}</g>
    <g class="gr-m gr-m-furious">${mouth('M77.8,137.5Q100,125.4 122.2,137.5Q100,136 77.8,137.5Z', 'M0,0Z')}
      <rect x="85" y="129.5" width="30" height="9" rx="3" fill="${C.eye}" stroke="${C.pupil}" stroke-width="2.5"/>
      <path d="M91,129.5V138.5M97,129.5V138.5M103,129.5V138.5M109,129.5V138.5M85,134H115" stroke="${C.pupil}" stroke-opacity=".7" stroke-width="1.5"/></g>`}
  </g></g>
  ${head ? '' : `<g class="gr-steam">${[0, 1, 2, 3, 4, 5].map(i => `<circle class="gr-puff gr-puff${i}" cx="${i % 2 ? 158 : 42}" cy="78" r="9" fill="#fff" stroke="#241F33" stroke-opacity=".18" stroke-width="2"/>`).join('')}</g>
  <g class="gr-zs">${[0, 1, 2].map(i => `<text class="gr-z gr-z${i}" x="${158 + i * 10}" y="${52 - i * 14}" font-size="${16 + i * 6}">z</text>`).join('')}</g>`}
</svg>`;
  };

  const MOODS = ['calm', 'happy', 'chew', 'alert', 'cross', 'furious', 'asleep'];
  const mood = (el, m) => {
    el.classList.remove(...MOODS.map(x => 'is-' + x));
    el.classList.add('is-' + m);
  };

  const all = [...document.querySelectorAll('[data-gremlin]')];
  all.forEach(el => {
    el.innerHTML = svg(el.dataset.gremlin === 'head');
    el.classList.add('gremlin');
    mood(el, 'calm');
  });
  window.LMGremlin = { mood };
  if (!all.length) return;

  // Eyes follow the pointer; with no pointer (phones) they glance around now and then.
  let px = null, py = null, frame = 0;
  const look = () => {
    frame = 0;
    for (const el of all) {
      const r = el.getBoundingClientRect();
      if (!r.width || r.bottom < 0 || r.top > innerHeight) continue;
      let dx = 0, dy = 0;
      if (px !== null) {
        dx = px - (r.left + r.width / 2); dy = py - (r.top + r.height * (el.dataset.gremlin === 'head' ? 0.6 : 0.42));
        const len = Math.hypot(dx, dy) || 1, k = Math.min(1, len / 240);
        dx = dx / len * k; dy = dy / len * k;
      } else if (el.glance) { [dx, dy] = el.glance; }
      el.querySelectorAll('.gr-iris').forEach(g => { g.style.transform = `translate(${(dx * 7).toFixed(2)}px, ${(dy * 7).toFixed(2)}px)`; });
    }
  };
  const queue = () => { if (!frame) frame = requestAnimationFrame(look); };
  addEventListener('pointermove', e => { if (e.pointerType === 'mouse') { px = e.clientX; py = e.clientY; queue(); } }, { passive: true });
  addEventListener('scroll', queue, { passive: true });
  const glances = [[0, 0], [-0.9, 0.1], [0.9, 0.2], [0.2, 0.9], [0, 0], [-0.5, -0.6]];
  let gi = 0;
  setInterval(() => {
    if (px !== null || reduced.matches) return;
    gi = (gi + 1) % glances.length;
    all.forEach((el, i) => { el.glance = glances[(gi + i) % glances.length]; });
    queue();
  }, 2600);
  queue();

  // A head on a button giggles while its button is hovered or focused.
  all.filter(el => el.dataset.gremlin === 'head').forEach(el => {
    const button = el.parentElement;
    const set = m => mood(el, m);
    button.addEventListener('pointerenter', e => { if (e.pointerType === 'mouse') set('happy'); });
    button.addEventListener('pointerleave', () => set('calm'));
    button.addEventListener('focusin', () => set('happy'));
    button.addEventListener('focusout', () => set('calm'));
  });
})();
