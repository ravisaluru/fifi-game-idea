// difficulty.jsx — a gentle, replay-friendly difficulty curve.
// "Again-friendly": each WIN nudges that game up one tier (Easy → Just right →
// Speedy); giving up eases it back down so a stuck kid gets a kinder round next
// time. Per-game tuning lives in ONE table, so balancing is a single-file edit.
const DIFF_KEY = 'fifi_diff_v1';
export const TIERS = ['Easy', 'Just right', 'Speedy'];

function loadDiff() {
  try { return JSON.parse(localStorage.getItem(DIFF_KEY)) || {}; } catch (e) { return {}; }
}
function saveDiff(d) { try { localStorage.setItem(DIFF_KEY, JSON.stringify(d)); } catch (e) { /* private mode */ } }

export function getTier(gameId) {
  const t = loadDiff()[gameId];
  return Math.max(0, Math.min(2, t == null ? 0 : t));
}

// Returns the NEW tier after recording a result.
export function recordResult(gameId, won) {
  const d = loadDiff();
  let t = d[gameId] == null ? 0 : d[gameId];
  t = won ? Math.min(2, t + 1) : Math.max(0, t - 1);
  d[gameId] = t; saveDiff(d);
  return t;
}

// Per-game parameters for each tier [easy, just-right, speedy].
const DIFF_TABLE = {
  star:     [{ spawn: 860, fall: 3.6, goal: 10 }, { spawn: 720, fall: 3.1, goal: 12 }, { spawn: 580, fall: 2.6, goal: 14 }],
  bubble:   [{ pairs: 4 }, { pairs: 5 }, { pairs: 6 }],
  firefly:  [{ goal: 4, speed: 640 }, { goal: 5, speed: 560 }, { goal: 6, speed: 470 }],
  tiger:    [{ step: 8, redMin: 950, redMax: 2000 }, { step: 6.5, redMin: 820, redMax: 1700 }, { step: 5.4, redMin: 700, redMax: 1400 }],
  stones:   [{ rows: 3 }, { rows: 4 }, { rows: 5 }],
  snake:    [{ goal: 4, obstacles: 5, chase: 0.70 }, { goal: 5, obstacles: 6, chase: 0.78 }, { goal: 6, obstacles: 7, chase: 0.86 }],
  treasure: [{ pairs: 4 }, { pairs: 5 }, { pairs: 6 }],
};

export function diffParams(gameId, tier) {
  const a = DIFF_TABLE[gameId];
  if (!a) return {};
  return a[Math.max(0, Math.min(a.length - 1, tier))];
}

// Small reusable tier indicator (three dots + label).
export function TierDots({ tier, accent = '#FFB703', light }) {
  return (
    <span className="tier-dots" style={{ color: light ? 'rgba(255,255,255,.9)' : 'inherit' }}>
      {[0, 1, 2].map((i) => (
        <span key={i} className="tier-dot" style={{ background: i <= tier ? accent : 'currentColor', opacity: i <= tier ? 1 : 0.25 }} />
      ))}
      <em className="tier-name">{TIERS[tier]}</em>
    </span>
  );
}
