// The playable phone in the hero: the app's home screen with a live gremlin. Pet it, feed it, play, nap,
// or poke it until it's furious. Nothing is saved.
(() => {
  const phone = document.querySelector('.live-phone');
  if (!phone || !window.LMGremlin) return;
  const $ = s => phone.querySelector(s);
  const screen = $('.screen'), g = $('[data-gremlin="full"]'), bubble = $('.bubble'), petZone = $('.pet-zone');
  const fine = matchMedia('(hover: hover) and (pointer: fine)');
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const st = { score: 1248, up: 78, down: 10, hungry: 50, bored: 40, sleepy: 40, asleep: false, furious: false,
    pokes: [], lastPet: 0, calm: 0, happy: 0, last: Date.now() };
  const LINES = ['hehehe', 'more.', 'again.', 'that’s the spot.', 'ok fine, you’re nice.'];

  const mood = m => window.LMGremlin.mood(g, m);
  let restT, sayT;
  const rest = ms => {
    clearTimeout(restT);
    restT = setTimeout(() => mood(st.asleep ? 'asleep' : st.furious ? 'furious' : 'calm'), ms);
  };
  const say = (text, ms = 1900) => {
    bubble.textContent = text;
    bubble.classList.add('on');
    clearTimeout(sayT);
    sayT = setTimeout(() => bubble.classList.remove('on'), ms);
  };
  const render = () => {
    $('.score-n').textContent = st.score.toLocaleString('en-US');
    $('.up').textContent = '+' + st.up;
    $('.down').textContent = '−' + st.down;
    for (const [need, v] of [['feed', st.hungry], ['play', st.bored], ['nap', st.sleepy]]) {
      const b = $(`[data-need="${need}"]`);
      b.querySelector('.ring').setAttribute('stroke-dasharray', `${Math.max(2, v)} 100`);
      b.querySelector('i').textContent = v;
    }
  };
  const points = n => {
    st.score += n;
    if (n > 0) st.up += n; else st.down -= n;
    const f = document.createElement('span');
    f.className = 'float ' + (n > 0 ? 'gain' : 'loss');
    f.textContent = (n > 0 ? '+' : '−') + Math.abs(n);
    $('.score').append(f);
    setTimeout(() => f.remove(), 1000);
    render();
  };
  const touched = () => { st.last = Date.now(); };

  const happyMoment = () => {
    st.happy++;
    if (st.happy !== 3) return;
    if (phone.hasAttribute('data-flip') && fine.matches) {
      setTimeout(() => say('want me on your real phone?', 2600), 900);
      setTimeout(() => phone.classList.add('is-flipped'), 2600);
    }
  };

  const pet = () => {
    touched();
    const now = Date.now();
    if (st.asleep) return say('zzz…');
    st.pokes = st.pokes.filter(t => now - t < 5000);
    st.pokes.push(now);
    const gap = now - st.lastPet;
    st.lastPet = now;
    if (st.furious) {
      if (gap < 700) { points(-1); return say('NOT. NOW.'); }
      if (++st.calm < 2) return say('…keep going.');
      st.furious = false;
      screen.classList.remove('is-furious');
      st.pokes = [];
      mood('happy'); say('fine. hehehe.'); rest(1300);
      return;
    }
    if (st.pokes.length >= 7) {
      st.furious = true; st.calm = 0;
      screen.classList.add('is-furious');
      mood('furious'); say('too many pokes.', 2600); points(-1);
      return;
    }
    mood('happy');
    say(LINES[Math.floor(Math.random() * LINES.length)]);
    points(1);
    st.bored = Math.max(0, st.bored - 4);
    render(); rest(1100); happyMoment();
  };

  const flyCookie = done => {
    if (reduced.matches) return done();
    const from = $('[data-need="feed"] .icon').getBoundingClientRect(), to = petZone.getBoundingClientRect(), s = screen.getBoundingClientRect();
    const c = document.createElement('span');
    c.className = 'cookie-fly';
    screen.append(c);
    const x0 = from.left - s.left + from.width / 2, y0 = from.top - s.top + from.height / 2;
    const x1 = to.left - s.left + to.width / 2, y1 = to.top - s.top + to.height * 0.6;
    c.animate([
      { transform: `translate(${x0}px, ${y0}px) translate(-50%, -50%) scale(1)` },
      { transform: `translate(${(x0 + x1) / 2}px, ${Math.min(y0, y1) - 40}px) translate(-50%, -50%) scale(1.15)`, offset: 0.5 },
      { transform: `translate(${x1}px, ${y1}px) translate(-50%, -50%) scale(.4)` },
    ], { duration: 520, easing: 'ease-in' }).onfinish = () => { c.remove(); done(); };
  };

  const actions = {
    feed() {
      if (st.asleep) return say('zzz…');
      if (st.furious) return say('not hungry. ANGRY.');
      if (st.hungry <= 10) { mood('cross'); say('I’m full.'); return rest(1200); }
      flyCookie(() => {
        mood('chew'); say('nom.');
        st.hungry = Math.max(0, st.hungry - 25);
        points(2); rest(1500); happyMoment();
      });
    },
    play() {
      if (st.asleep) return say('zzz…');
      if (st.furious) return say('no games. pet me.');
      mood('happy'); say('again!');
      g.classList.remove('hopping'); void g.offsetWidth; g.classList.add('hopping');
      st.bored = Math.max(0, st.bored - 30); st.sleepy = Math.min(100, st.sleepy + 6);
      points(3); rest(1300); happyMoment();
    },
    nap() {
      if (st.furious) return say('too angry to sleep.');
      if (st.asleep) { st.asleep = false; mood('alert'); say('I was awake.'); return rest(900); }
      st.asleep = true; mood('asleep'); bubble.classList.remove('on');
      clearTimeout(restT);
      restT = setTimeout(() => {
        st.asleep = false; st.sleepy = Math.max(5, st.sleepy - 35);
        points(2); mood('alert'); say('I’m up. happy?'); rest(1200);
      }, 4200);
    },
  };

  petZone.addEventListener('click', pet);
  // Stroking it with the mouse counts as petting, a pat at most every second.
  let travel = 0, lastStroke = 0;
  petZone.addEventListener('pointermove', e => {
    if (e.pointerType !== 'mouse') return;
    travel += Math.abs(e.movementX) + Math.abs(e.movementY);
    if (travel > 140 && Date.now() - lastStroke > 1000) { travel = 0; lastStroke = Date.now(); pet(); }
  });
  phone.querySelectorAll('[data-need]').forEach(b => b.addEventListener('click', () => { touched(); actions[b.dataset.need](); }));
  $('.flip-back')?.addEventListener('click', () => phone.classList.remove('is-flipped'));

  // Left alone, it fidgets.
  setInterval(() => {
    if (reduced.matches || st.asleep || st.furious || Date.now() - st.last < 6000 || phone.classList.contains('is-flipped')) return;
    mood('alert'); rest(700);
  }, 7000);
  render();
})();
