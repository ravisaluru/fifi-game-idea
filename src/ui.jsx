// ui.jsx — shared building blocks for the Squish design system.
// Relies on utility classes defined in styles.css.
import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { AudioFX } from './audio.js';
import { ACCESSORIES } from './data.js';
import { updateScore } from './multiplayer.js';

// Active online match (null when playing solo). Provided by App so GameShell
// can publish live progress to the room and show opponents — no per-game code.
export const OnlineContext = createContext(null);

// Tactile puffy button with a colored "lip" that squishes on press.
export function Squish({ color = '#FFB703', lip, onClick, children, style, className = '', disabled, ...rest }) {
  const lipColor = lip || shade(color, -0.22);
  const handle = (e) => { AudioFX.play('tap'); onClick && onClick(e); };
  return (
    <button
      className={`squish ${className}`}
      disabled={disabled}
      onClick={handle}
      style={{ '--c': color, '--lip': lipColor, ...style }}
      {...rest}
    >
      {children}
    </button>
  );
}

// Kid-friendly speaker toggle (used in the home/pre-game headers).
export function SoundToggle() {
  const [muted, setMutedState] = useState(() => AudioFX.isMuted());
  const toggle = () => {
    const m = !muted;
    AudioFX.setMuted(m);
    if (!m) AudioFX.play('select');
    setMutedState(m);
  };
  return (
    <button className="sound-toggle" onClick={toggle} aria-label={muted ? 'Turn sound on' : 'Turn sound off'}>
      {muted ? '🔇' : '🔊'}
    </button>
  );
}

// Round icon button (back, close, sound).
export function IconButton({ children, onClick, label, color = '#FFFFFF', style }) {
  return (
    <button className="iconbtn" aria-label={label} onClick={onClick}
            style={{ '--c': color, '--lip': shade(color, -0.18), ...style }}>
      {children}
    </button>
  );
}

// Character avatar: emoji hero on a colored disc with optional accessory badge.
export function Hero({ char, size = 64, accessory = 'none', ring = false }) {
  const acc = ACCESSORIES.find((a) => a.id === accessory);
  return (
    <div className="hero" style={{ width: size, height: size,
        background: char.color, boxShadow: `0 ${size * 0.09}px 0 ${shade(char.color, -0.22)}`,
        outline: ring ? '4px solid #fff' : 'none' }}>
      <span style={{ fontSize: size * 0.52, lineHeight: 1 }}>{char.emoji}</span>
      {acc && acc.id !== 'none' && (
        <span className="hero-acc" style={{ fontSize: size * 0.34 }}>{acc.emoji}</span>
      )}
    </div>
  );
}

// Coins + trophies HUD pill.
export function Hud({ coins, trophies }) {
  return (
    <div className="hud">
      <div className="hud-stat"><span>🪙</span><b>{coins}</b></div>
      <div className="hud-divider" />
      <div className="hud-stat"><span>🏆</span><b>{trophies}</b></div>
    </div>
  );
}

export function Pill({ children, color = '#FFB703', tone = 'soft' }) {
  const bg = tone === 'soft' ? tint(color, 0.78) : color;
  const fg = tone === 'soft' ? shade(color, -0.45) : '#fff';
  return <span className="pill" style={{ background: bg, color: fg }}>{children}</span>;
}

export function ScreenHeader({ title, onBack, right }) {
  return (
    <div className="scr-head">
      {onBack ? <IconButton label="Back" onClick={onBack} color="#FFFFFF">‹</IconButton> : <div style={{ width: 46 }} />}
      <h2 className="scr-title">{title}</h2>
      <div className="scr-head-right">{right || <div style={{ width: 46 }} />}</div>
    </div>
  );
}

// Lightweight confetti / particle burst overlay.
export function Confetti({ count = 80, run = true }) {
  const ref = useRef(null);
  useEffect(() => {
    if (!run || !ref.current) return undefined;
    const host = ref.current;
    const colors = ['#FFB703', '#F15BB5', '#4CC9F0', '#9B5DE5', '#80B918', '#FB8500'];
    const bits = [];
    for (let i = 0; i < count; i++) {
      const b = document.createElement('div');
      b.className = 'confetti-bit';
      const left = Math.random() * 100;
      const size = 8 + Math.random() * 10;
      b.style.left = left + '%';
      b.style.width = size + 'px';
      b.style.height = size * (0.4 + Math.random() * 0.8) + 'px';
      b.style.background = colors[i % colors.length];
      b.style.borderRadius = Math.random() > 0.5 ? '50%' : '3px';
      b.style.animationDelay = Math.random() * 0.5 + 's';
      b.style.animationDuration = 1.6 + Math.random() * 1.6 + 's';
      b.style.setProperty('--drift', (Math.random() * 200 - 100) + 'px');
      b.style.setProperty('--spin', (Math.random() * 720 - 360) + 'deg');
      host.appendChild(b);
      bits.push(b);
    }
    return () => bits.forEach((b) => b.remove());
  }, [run, count]);
  return <div className="confetti" ref={ref} aria-hidden="true" />;
}

// Live opponent strip shown in the game HUD during online matches.
function OpponentChips({ online }) {
  const others = Object.entries(online.players || {})
    .filter(([id]) => id !== online.playerId)
    .slice(0, 3);
  if (!others.length) return null;
  return (
    <div className="opp-chips">
      {others.map(([id, p]) => (
        <span key={id} className="opp-chip" title={p.name}>
          <span className="opp-dot">{p.isAi ? '🤖' : '🙂'}</span>
          {Math.round((p.progress || 0) * 100)}%
        </span>
      ))}
    </div>
  );
}

// Shared game chrome: the HUD (quit + progress bar + optional slot) and footer
// hint that every mini-game inherits. One place to maintain the common look.
// During an online match it also publishes the local player's progress to the
// room (throttled) and shows everyone else's — zero per-game wiring needed.
export function GameShell({ accent, onQuit, progress = 0, label, hint, extra, children }) {
  const online = useContext(OnlineContext);
  const pct = Math.max(0, Math.min(1, progress)) * 100;
  const lastSent = useRef(0);

  useEffect(() => {
    if (!online) return;
    const now = Date.now();
    if (now - lastSent.current < 900) return; // throttle realtime writes
    lastSent.current = now;
    updateScore(online.code, online.playerId, Math.round(pct), pct / 100).catch(() => {});
  }, [pct, online]);

  return (
    <div className="game-screen" style={{ '--c': accent }}>
      <div className="game-hud">
        <button className="game-quit" onClick={onQuit} aria-label="Quit">✕</button>
        <div className="game-progress">
          <div className="game-progress-fill" style={{ width: pct + '%', background: accent }} />
          <span className="game-progress-txt">{label}</span>
        </div>
        {online ? <OpponentChips online={online} /> : null}
        {extra}
      </div>
      {children}
      {hint ? <p className="game-hint">{hint}</p> : null}
    </div>
  );
}

// --- color helpers ---
export function hexToRgb(h) {
  h = h.replace('#', '');
  if (h.length === 3) h = h.split('').map((c) => c + c).join('');
  return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
}
export function rgbToHex(r, g, b) {
  const c = (n) => Math.max(0, Math.min(255, Math.round(n))).toString(16).padStart(2, '0');
  return '#' + c(r) + c(g) + c(b);
}
export function shade(hex, amt) { // amt<0 darken, >0 lighten
  const [r, g, b] = hexToRgb(hex);
  const f = amt < 0 ? 0 : 255;
  const p = Math.abs(amt);
  return rgbToHex(r + (f - r) * p, g + (f - g) * p, b + (f - b) * p);
}
export function tint(hex, amt) { return shade(hex, amt); } // alias for clarity (lighten)
