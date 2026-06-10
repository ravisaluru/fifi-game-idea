// motion.js — battery-friendly, modular motion primitives shared by every game.
// Principles: at most ONE rAF loop app-wide; never burn cycles while the tab is
// hidden; let the GPU compositor do motion (transform/opacity) wherever we can.
import { useEffect, useRef, useState } from 'react';

export const prefersReduce = !!(typeof window !== 'undefined' && window.matchMedia
  && window.matchMedia('(prefers-reduced-motion: reduce)').matches);

// Single shared ticker. Auto-starts on first subscriber, fully stops when the
// last one leaves, and skips all work while the tab is backgrounded.
export const Ticker = (() => {
  const subs = new Set();
  let raf = null, last = 0;
  const loop = (now) => {
    if (document.hidden) {
      last = now;
    } else {
      const dt = last ? Math.min(64, now - last) : 16;
      last = now;
      subs.forEach((fn) => fn(dt, now));
    }
    raf = subs.size ? requestAnimationFrame(loop) : null;
  };
  return {
    add(fn) { subs.add(fn); if (raf == null) { last = 0; raf = requestAnimationFrame(loop); } },
    remove(fn) { subs.delete(fn); if (!subs.size && raf != null) { cancelAnimationFrame(raf); raf = null; } },
  };
})();

// Subscribe a per-frame callback only while `active`. Respects reduced-motion.
export function useTicker(fn, active = true) {
  const saved = useRef(fn); saved.current = fn;
  useEffect(() => {
    if (!active || prefersReduce) return undefined;
    const cb = (dt, now) => saved.current(dt, now);
    Ticker.add(cb);
    return () => Ticker.remove(cb);
  }, [active]);
}

// Visibility-aware interval — pauses while hidden so nothing spawns in the
// background. Far cheaper than a per-frame loop for discrete spawning.
export function useInterval(fn, ms, active = true) {
  const saved = useRef(fn); saved.current = fn;
  useEffect(() => {
    if (!active) return undefined;
    const id = setInterval(() => { if (!document.hidden) saved.current(); }, ms);
    return () => clearInterval(id);
  }, [ms, active]);
}

// Tracks an element's pixel height (for compositor-driven fall distance) and
// keeps it fresh on resize. One observer per use, cleaned up automatically.
export function useMeasuredHeight(ref, pad = 0) {
  const [h, setH] = useState(640);
  useEffect(() => {
    const el = ref.current; if (!el) return undefined;
    const update = () => setH(el.clientHeight + pad);
    update();
    if (!window.ResizeObserver) return undefined;
    const ro = new ResizeObserver(update);
    ro.observe(el);
    return () => ro.disconnect();
  }, [ref, pad]);
  return h;
}

// Flip a <body> flag so CSS can hard-pause EVERY animation when the tab hides.
if (typeof document !== 'undefined') {
  const apply = () => document.body && document.body.classList.toggle('is-hidden', document.hidden);
  document.addEventListener('visibilitychange', apply);
  apply();
}
