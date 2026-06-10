// games/star.jsx — Star Catch.
// Battery note: falling is a pure CSS `transform` animation running on the GPU
// compositor — there is NO requestAnimationFrame loop and NO React re-render
// while a star is in flight. JS only runs ~1.4×/sec to spawn a star, and once
// on tap to score. This is dramatically lighter than a per-frame loop.
import React, { useEffect, useRef, useState } from 'react';
import { AudioFX } from '../audio.js';
import { useInterval, useMeasuredHeight } from '../motion.js';
import { GameShell, Hero } from '../ui.jsx';

export function StarCatchGame({ onWin, onQuit, char, accessory, params = {} }) {
  const GOAL = params.goal || 12;
  const spawnMs = params.spawn || 760;
  const fallBase = params.fall || 3;
  const [stars, setStars] = useState([]);
  const [score, setScore] = useState(0);
  const [combo, setCombo] = useState(0);
  const [pops, setPops] = useState([]);
  const areaRef = useRef(null);
  const idRef = useRef(0);
  const scoreRef = useRef(0);
  const comboRef = useRef(0);
  const comboTimer = useRef(null);
  const fall = useMeasuredHeight(areaRef, 80); // px distance a star travels

  // Spawn cadence only — visibility-aware interval, paused when GOAL reached.
  useInterval(() => {
    if (scoreRef.current >= GOAL) return;
    idRef.current += 1;
    setStars((s) => s.concat({
      id: idRef.current,
      x: 6 + Math.random() * 84,
      emoji: Math.random() > 0.82 ? '🌟' : '⭐',
      dur: fallBase + Math.random() * 1.4,
      rot: (Math.random() * 26 - 13) | 0,
    }));
  }, spawnMs, score < GOAL);

  const drop = (id) => setStars((s) => s.filter((st) => st.id !== id));

  const grab = (st, e) => {
    drop(st.id);
    AudioFX.play('pop');
    const ns = scoreRef.current + 1; scoreRef.current = ns; setScore(ns);
    comboRef.current += 1; setCombo(comboRef.current);
    clearTimeout(comboTimer.current);
    comboTimer.current = setTimeout(() => { comboRef.current = 0; setCombo(0); }, 1400);
    const rect = areaRef.current.getBoundingClientRect();
    const pid = 'p' + st.id;
    setPops((p) => p.concat({
      id: pid,
      x: ((e.clientX - rect.left) / rect.width) * 100,
      y: ((e.clientY - rect.top) / rect.height) * 100,
    }));
    setTimeout(() => setPops((p) => p.filter((x) => x.id !== pid)), 600);
    if (ns >= GOAL) setTimeout(() => onWin({ coins: GOAL + comboRef.current * 2, label: 'Star Catcher' }), 650);
  };

  useEffect(() => () => clearTimeout(comboTimer.current), []);

  return (
    <GameShell accent="#FFB703" onQuit={onQuit} progress={score / GOAL}
      label={<span>⭐ {score} / {GOAL}</span>}
      extra={combo > 1 ? <div className="combo-badge">{combo}× combo!</div> : null}
      hint="Tap the stars before they reach the grass! ✨">
      <div className="play-area star-area" ref={areaRef} style={{ '--fall': fall + 'px' }}>
        <div className="sky-dust" />
        {stars.map((st) => (
          <button key={st.id} className="star-fall" aria-label="star"
            style={{ left: st.x + '%', animationDuration: st.dur + 's', '--rot': st.rot + 'deg' }}
            onAnimationEnd={() => drop(st.id)}
            onPointerDown={(e) => grab(st, e)}>
            {st.emoji}
          </button>
        ))}
        {pops.map((p) => (
          <span key={p.id} className="pop" style={{ left: p.x + '%', top: p.y + '%' }}>+1</span>
        ))}
        <div className="ground-line" />
        <div className="player-toon"><span className="bobber"><Hero char={char} size={54} accessory={accessory} /></span></div>
      </div>
    </GameShell>
  );
}
