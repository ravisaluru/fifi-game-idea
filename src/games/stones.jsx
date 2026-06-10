// games/stones.jsx — Stone Hop: memorize the glowing path, hop to the beach.
import React, { useEffect, useRef, useState } from 'react';
import { AudioFX } from '../audio.js';
import { GameShell, Hero } from '../ui.jsx';

export function SteppingStonesGame({ onWin, onQuit, char, accessory, params = {} }) {
  const ROWS = params.rows || 4, COLS = 3;
  const [safe] = useState(() => Array.from({ length: ROWS }, () => Math.floor(Math.random() * COLS)));
  const [phase, setPhase] = useState('watch'); // watch | hop | win
  const [glow, setGlow] = useState(-1); // row currently glowing during watch
  const [heroRow, setHeroRow] = useState(ROWS); // ROWS = start pad; counts down to 0 (beach)
  const [splash, setSplash] = useState(null);
  const timers = useRef([]);
  const clear = () => { timers.current.forEach(clearTimeout); timers.current = []; };

  const playWatch = () => {
    setPhase('watch'); setGlow(-1); setHeroRow(ROWS); clear();
    // glow bottom row (ROWS-1) first up to row 0
    for (let i = 0; i < ROWS; i++) {
      const row = ROWS - 1 - i;
      timers.current.push(setTimeout(() => { setGlow(row); AudioFX.note(523 + (ROWS - 1 - row) * 90, 0.16); }, 700 * i + 500));
      timers.current.push(setTimeout(() => setGlow(-1), 700 * i + 1050));
    }
    timers.current.push(setTimeout(() => setPhase('hop'), 700 * ROWS + 600));
  };

  useEffect(() => { playWatch(); return clear; }, []);

  const currentRow = heroRow - 1; // the next row to cross

  const tap = (row, col) => {
    if (phase !== 'hop' || row !== currentRow) return;
    if (safe[row] === col) {
      AudioFX.play('step');
      const nr = heroRow - 1; setHeroRow(nr);
      if (nr <= 0) {
        setPhase('win');
        timers.current.push(setTimeout(() => onWin({ coins: 16, label: 'Path Finder' }), 700));
      }
    } else {
      AudioFX.play('wrong');
      setSplash({ row, col });
      timers.current.push(setTimeout(() => { setSplash(null); playWatch(); }, 900));
    }
  };

  return (
    <GameShell accent="#2A9D8F" onQuit={onQuit} progress={(ROWS - heroRow) / ROWS}
      label={<span>🏖️ {ROWS - heroRow} / {ROWS}</span>}
      hint="Remember which stones lit up, then tap them in order 🪨">
      <div className="play-area stones-area">
        <div className="beach-strip">{heroRow <= 0 ? <Hero char={char} size={42} accessory={accessory} /> : '🏖️ Beach'}</div>
        <div className="hop-field">
          {Array.from({ length: ROWS }).map((_, row) => (
            <div className="stone-row" key={row}>
              {Array.from({ length: COLS }).map((_, col) => {
                const occupied = heroRow === row;
                const isGlow = glow === row && safe[row] === col;
                const isSplash = splash && splash.row === row && splash.col === col;
                const active = phase === 'hop' && row === currentRow;
                return (
                  <button key={col}
                    className={'stone' + (isGlow ? ' glow' : '') + (isSplash ? ' splash' : '') + (active ? ' active' : '')}
                    onClick={() => tap(row, col)}>
                    {occupied && safe[row] === col ? <Hero char={char} size={40} accessory={accessory} /> : (isSplash ? '💦' : '🪨')}
                  </button>
                );
              })}
            </div>
          ))}
          <div className="start-pad">{heroRow === ROWS ? <Hero char={char} size={40} accessory={accessory} /> : '🌿 Start'}</div>
        </div>
        <p className={'stones-status' + (phase === 'watch' ? ' watching' : '')}>
          {phase === 'watch' ? 'Watch the glowing path…' : phase === 'win' ? 'You made it! 🎉' : 'Hop along the safe stones!'}
        </p>
      </div>
    </GameShell>
  );
}
