// games/bubble.jsx — Bubble Match: tap two bubbles of the same color to pop them.
import React, { useMemo, useRef, useState } from 'react';
import { AudioFX } from '../audio.js';
import { GameShell, Hero, shade } from '../ui.jsx';

const BUBBLE_COLORS = ['#FF5C7A', '#4CC9F0', '#FFB703', '#80B918', '#9B5DE5', '#FB8500'];

function shuffle(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function BubbleMatchGame({ onWin, onQuit, char, accessory, params = {} }) {
  const PAIRS = params.pairs || 6;
  const initial = useMemo(() => {
    const colors = shuffle(BUBBLE_COLORS.slice(0, PAIRS).concat(BUBBLE_COLORS.slice(0, PAIRS)));
    return colors.map((c, i) => ({
      id: i, color: c,
      x: 10 + (i % 4) * 26 + (Math.random() * 6 - 3),
      y: 12 + Math.floor(i / 4) * 28 + (Math.random() * 6 - 3),
      delay: (Math.random() * 2).toFixed(2),
      dur: (3 + Math.random() * 2).toFixed(2),
    }));
  }, [PAIRS]);

  const [bubbles, setBubbles] = useState(initial);
  const [sel, setSel] = useState(null);
  const [wrong, setWrong] = useState(null);
  const [popped, setPopped] = useState(0);
  const lock = useRef(false);

  const tap = (b) => {
    if (lock.current || !bubbles.find((x) => x.id === b.id)) return;
    if (sel == null) { AudioFX.play('select'); setSel(b.id); return; }
    if (sel === b.id) { setSel(null); return; }
    const first = bubbles.find((x) => x.id === sel);
    if (first && first.color === b.color) {
      AudioFX.play('pop');
      const newPopped = popped + 1;
      setBubbles((bs) => bs.filter((x) => x.id !== b.id && x.id !== sel));
      setSel(null);
      setPopped(newPopped);
      if (newPopped >= PAIRS) setTimeout(() => onWin({ coins: 14, label: 'Bubble Popper' }), 600);
    } else {
      AudioFX.play('wrong');
      lock.current = true;
      setWrong([sel, b.id]);
      setTimeout(() => { setWrong(null); setSel(null); lock.current = false; }, 480);
    }
  };

  return (
    <GameShell accent="#4CC9F0" onQuit={onQuit} progress={popped / PAIRS}
      label={<span>🫧 {popped} / {PAIRS}</span>}
      hint="Tap two bubbles that match! 🫧">
      <div className="play-area bubble-area">
        {bubbles.map((b) => {
          const isSel = sel === b.id;
          const isWrong = wrong && wrong.includes(b.id);
          return (
            <button key={b.id}
              className={'bubble' + (isSel ? ' sel' : '') + (isWrong ? ' wrong' : '')}
              onClick={() => tap(b)}
              style={{ left: b.x + '%', top: b.y + '%', background: b.color,
                       boxShadow: `inset -6px -8px 0 ${shade(b.color, -0.18)}, 0 6px 14px ${shade(b.color, -0.2)}66`,
                       animationDelay: b.delay + 's', animationDuration: b.dur + 's' }}>
              <span className="bubble-shine" />
            </button>
          );
        })}
        <div className="player-toon bubble-toon"><span className="bobber"><Hero char={char} size={48} accessory={accessory} /></span></div>
      </div>
    </GameShell>
  );
}
