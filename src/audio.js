// audio.js — tiny synthesized sound engine. No audio files: every sound is
// generated on the fly with Web Audio oscillators, so it adds a few KB and zero
// network requests. Same visibility-aware discipline as motion.js — the audio
// context is SUSPENDED while the tab is hidden so it never wakes the CPU/radio
// in the background. Globally mutable; remembers the choice in localStorage.
export const AudioFX = (() => {
  let ctx = null, master = null;
  let muted = false;
  try { muted = localStorage.getItem('fifi_muted') === '1'; } catch (e) { /* private mode */ }

  function ensure() {
    if (ctx) return ctx;
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = muted ? 0 : 0.16;
    master.connect(ctx.destination);
    return ctx;
  }

  function unlock() {
    const c = ensure(); if (c && c.state === 'suspended' && !document.hidden) c.resume();
  }

  // One short enveloped oscillator note.
  function tone(freq, t0, dur, type = 'sine', peak = 1) {
    const c = ctx; if (!c) return;
    const o = c.createOscillator(), g = c.createGain();
    o.type = type; o.frequency.value = freq;
    o.connect(g); g.connect(master);
    const t = c.currentTime + t0;
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(peak, t + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.start(t); o.stop(t + dur + 0.03);
  }

  const voices = {
    tap:    () => tone(440, 0, 0.08, 'sine', 0.45),
    select: () => tone(560, 0, 0.10, 'triangle', 0.6),
    pop:    () => { tone(680, 0, 0.10, 'sine', 0.8); tone(1020, 0.03, 0.09, 'sine', 0.4); },
    coin:   () => { tone(900, 0, 0.07, 'square', 0.4); tone(1350, 0.06, 0.10, 'square', 0.35); },
    wrong:  () => { tone(210, 0, 0.18, 'sawtooth', 0.4); tone(165, 0.06, 0.18, 'sawtooth', 0.35); },
    step:   () => tone(340, 0, 0.06, 'triangle', 0.45),
    win:    () => [523, 659, 784, 1047].forEach((f, i) => tone(f, i * 0.11, 0.24, 'triangle', 0.6)),
  };

  function play(name) {
    if (muted) return;
    const c = ensure(); if (!c) return;
    if (c.state === 'suspended') { if (document.hidden) return; c.resume(); }
    (voices[name] || voices.tap)();
  }

  // Pitched note (for melodic feedback like the firefly song).
  function note(freq, dur = 0.18) {
    if (muted) return;
    const c = ensure(); if (!c) return;
    if (c.state === 'suspended') { if (document.hidden) return; c.resume(); }
    tone(freq, 0, dur, 'sine', 0.6);
  }

  function setMuted(m) {
    muted = !!m;
    try { localStorage.setItem('fifi_muted', muted ? '1' : '0'); } catch (e) { /* private mode */ }
    if (master) master.gain.value = muted ? 0 : 0.16;
    if (muted && ctx) ctx.suspend();
    else if (!muted && ctx && !document.hidden) ctx.resume();
  }
  const isMuted = () => muted;

  if (typeof window !== 'undefined') {
    // Unlock the context on the first user gesture (browser autoplay policy).
    ['pointerdown', 'touchstart', 'keydown'].forEach((ev) =>
      window.addEventListener(ev, unlock, { passive: true }));

    // Visibility-aware: pause the whole audio clock in the background.
    document.addEventListener('visibilitychange', () => {
      if (!ctx) return;
      if (document.hidden) ctx.suspend();
      else if (!muted) ctx.resume();
    });
  }

  return { play, note, setMuted, isMuted, unlock };
})();
