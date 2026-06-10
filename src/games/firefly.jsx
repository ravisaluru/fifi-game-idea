// games/firefly.jsx — Firefly Glow: watch the twinkle order, then repeat it.
import React, { useEffect, useRef, useState } from 'react';
import { AudioFX } from '../audio.js';
import { GameShell, Hero, Squish } from '../ui.jsx';

const FLY_POS = [
  { x: 50, y: 16 }, { x: 82, y: 40 }, { x: 70, y: 78 },
  { x: 30, y: 78 }, { x: 18, y: 40 },
];

const FLY_NOTES = [523, 587, 659, 784, 880]; // pentatonic, one per firefly

export function FireflyGlowGame({ onWin, onQuit, char, accessory, params = {} }) {
  const GOAL = params.goal || 5; // final sequence length
  const SPEED = params.speed || 600; // ms per step in playback
  const [seq, setSeq] = useState([]);
  const [phase, setPhase] = useState('intro'); // intro | watch | input | wrong | won
  const [lit, setLit] = useState(-1);
  const [inputAt, setInputAt] = useState(0);
  const timers = useRef([]);

  const clearTimers = () => { timers.current.forEach(clearTimeout); timers.current = []; };

  const nextRound = (prev) => {
    const ns = prev.concat(Math.floor(Math.random() * FLY_POS.length));
    setSeq(ns);
    playback(ns);
  };

  const playback = (s) => {
    setPhase('watch'); setInputAt(0); setLit(-1);
    clearTimers();
    s.forEach((idx, i) => {
      timers.current.push(setTimeout(() => { setLit(idx); AudioFX.note(FLY_NOTES[idx] || 660); }, SPEED * i + 400));
      timers.current.push(setTimeout(() => setLit(-1), SPEED * i + SPEED * 0.6 + 160));
    });
    timers.current.push(setTimeout(() => { setPhase('input'); setLit(-1); }, SPEED * s.length + 500));
  };

  useEffect(() => () => clearTimers(), []);

  const start = () => nextRound([]);

  const tap = (idx) => {
    if (phase !== 'input') return;
    if (seq[inputAt] === idx) {
      AudioFX.note(FLY_NOTES[idx] || 660, 0.14);
      setLit(idx); setTimeout(() => setLit(-1), 220);
      const at = inputAt + 1;
      setInputAt(at);
      if (at === seq.length) {
        if (seq.length >= GOAL) {
          setPhase('won');
          setTimeout(() => onWin({ coins: 16, label: 'Memory Master' }), 600);
        } else {
          setPhase('watch');
          timers.current.push(setTimeout(() => nextRound(seq), 700));
        }
      }
    } else {
      AudioFX.play('wrong');
      setPhase('wrong');
      setLit(-2);
      timers.current.push(setTimeout(() => { setLit(-1); playback(seq); }, 900));
    }
  };

  const label = phase === 'intro' ? 'Tap start to begin'
    : phase === 'watch' ? 'Watch closely…'
    : phase === 'input' ? 'Now repeat the song!'
    : phase === 'wrong' ? 'Oops — try again!' : 'You did it! 🎉';

  return (
    <GameShell accent="#9B5DE5" onQuit={onQuit} progress={Math.max(0, seq.length - 1) / GOAL}
      label={<span>🧚 Level {Math.max(1, seq.length)} / {GOAL}</span>}
      hint="Remember the glowing order 🧚✨">
      <div className="play-area firefly-area">
        <p className={'fly-status' + (phase === 'wrong' ? ' bad' : '')}>{label}</p>
        <div className="fly-field">
          {FLY_POS.map((p, i) => (
            <button key={i} className={'firefly' + (lit === i ? ' lit' : '') + (lit === -2 ? ' allbad' : '')}
              onClick={() => tap(i)} style={{ left: p.x + '%', top: p.y + '%' }} aria-label={'firefly ' + i}>
              🧚
            </button>
          ))}
          <div className="player-toon fly-toon"><span className="bobber"><Hero char={char} size={44} accessory={accessory} /></span></div>
        </div>
        {phase === 'intro' && (
          <Squish color="#9B5DE5" className="start-btn" onClick={start}>
            <span className="btn-emoji">▶</span> Start
          </Squish>
        )}
      </div>
    </GameShell>
  );
}
