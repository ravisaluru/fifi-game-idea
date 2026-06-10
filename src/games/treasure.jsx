// games/treasure.jsx — Treasure Flip: flip leaves, match the treasures.
import React, { useRef, useState } from 'react';
import { AudioFX } from '../audio.js';
import { GameShell } from '../ui.jsx';

const TREASURES = ['🪙', '💎', '⭐', '🐚', '🍯', '🌰'];

function shuffle(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
  return a;
}

export function TreasureHuntGame({ onWin, onQuit, params = {} }) {
  const PAIRS = Math.min(TREASURES.length, params.pairs || TREASURES.length);
  const pool = TREASURES.slice(0, PAIRS);
  const [cards, setCards] = useState(() =>
    shuffle(pool.concat(pool)).map((t, i) => ({ id: i, t, flipped: false, matched: false })));
  const [open, setOpen] = useState([]); // ids currently face-up & unmatched
  const [matched, setMatched] = useState(0);
  const lock = useRef(false);

  const flip = (card) => {
    if (lock.current || card.flipped || card.matched) return;
    AudioFX.play('tap');
    const nextCards = cards.map((c) => c.id === card.id ? { ...c, flipped: true } : c);
    setCards(nextCards);
    const nowOpen = [...open, card.id];

    if (nowOpen.length === 2) {
      lock.current = true;
      const [a, b] = nowOpen.map((id) => nextCards.find((c) => c.id === id));
      if (a.t === b.t) {
        setTimeout(() => {
          AudioFX.play('pop');
          setCards((cs) => cs.map((c) => (c.id === a.id || c.id === b.id) ? { ...c, matched: true } : c));
          const nm = matched + 1; setMatched(nm);
          setOpen([]); lock.current = false;
          if (nm >= PAIRS) setTimeout(() => onWin({ coins: 16, label: 'Treasure Hunter' }), 500);
        }, 480);
      } else {
        setTimeout(() => {
          setCards((cs) => cs.map((c) => (c.id === a.id || c.id === b.id) ? { ...c, flipped: false } : c));
          setOpen([]); lock.current = false;
        }, 780);
      }
    } else {
      setOpen(nowOpen);
    }
  };

  return (
    <GameShell accent="#F15BB5" onQuit={onQuit} progress={matched / PAIRS}
      label={<span>🪙 {matched} / {PAIRS}</span>}
      hint="Flip two leaves to find matching treasures 🍃🪙">
      <div className="play-area treasure-area">
        <div className="leaf-grid">
          {cards.map((c) => (
            <button key={c.id} className={'leaf-card' + (c.flipped || c.matched ? ' open' : '') + (c.matched ? ' matched' : '')}
              onClick={() => flip(c)}>
              <span className="leaf-inner">
                <span className={'leaf-face ' + (c.flipped || c.matched ? 'back' : 'front')}>
                  {c.flipped || c.matched ? c.t : '🍃'}
                </span>
              </span>
            </button>
          ))}
        </div>
      </div>
    </GameShell>
  );
}
