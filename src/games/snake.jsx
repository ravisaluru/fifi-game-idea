// games/snake.jsx — Snake Escape: turn-based. Grab food, dodge the snake.
import React, { useRef, useState } from 'react';
import { AudioFX } from '../audio.js';
import { GameShell, Hero } from '../ui.jsx';

export function SnakeChaseGame({ onWin, onQuit, char, accessory, params = {} }) {
  const N = 7, GOAL = params.goal || 5;
  const OBSTACLES = params.obstacles || 6;
  const CHASE = params.chase || 0.78;
  const key = (r, c) => r + ',' + c;
  const makeObstacles = (avoid) => {
    const obs = new Set();
    const kinds = ['🌳', '🪨', '🌿'];
    let tries = 0;
    while (obs.size < OBSTACLES && tries < 60) {
      tries++;
      const r = Math.floor(Math.random() * N), c = Math.floor(Math.random() * N);
      if (avoid.has(key(r, c))) continue;
      obs.add(key(r, c));
    }
    const m = {}; [...obs].forEach((k, i) => { m[k] = kinds[i % kinds.length]; });
    return m;
  };

  const startAvoid = new Set([key(N - 1, 0), key(0, N - 1), key(3, 3)]);
  const [obstacles] = useState(() => makeObstacles(startAvoid));
  const [player, setPlayer] = useState({ r: N - 1, c: 0 });
  const [snake, setSnake] = useState({ r: 0, c: N - 1 });
  const freeCell = (occupied) => {
    let r, c, t = 0;
    do { r = Math.floor(Math.random() * N); c = Math.floor(Math.random() * N); t++; }
    while ((obstacles[key(r, c)] || occupied.some((p) => p.r === r && p.c === c)) && t < 80);
    return { r, c };
  };
  const [food, setFood] = useState(() => ({ r: 3, c: 3 }));
  const [score, setScore] = useState(0);
  const [caught, setCaught] = useState(false);
  const lock = useRef(false);

  const snakeStep = (from, target) => {
    const opts = [{ r: -1, c: 0 }, { r: 1, c: 0 }, { r: 0, c: -1 }, { r: 0, c: 1 }]
      .map((d) => ({ r: from.r + d.r, c: from.c + d.c }))
      .filter((p) => p.r >= 0 && p.r < N && p.c >= 0 && p.c < N && !obstacles[key(p.r, p.c)]);
    if (!opts.length) return from;
    opts.sort((a, b) => (Math.abs(a.r - target.r) + Math.abs(a.c - target.c)) - (Math.abs(b.r - target.r) + Math.abs(b.c - target.c)));
    // chase the player most of the time, else wander for fairness
    return Math.random() < CHASE ? opts[0] : opts[Math.floor(Math.random() * opts.length)];
  };

  const move = (dr, dc) => {
    if (lock.current) return;
    const nr = player.r + dr, nc = player.c + dc;
    if (nr < 0 || nr >= N || nc < 0 || nc >= N || obstacles[key(nr, nc)]) return;
    const np = { r: nr, c: nc };

    // moved onto snake?
    if (np.r === snake.r && np.c === snake.c) { reset(); return; }

    let newScore = score, newFood = food;
    if (np.r === food.r && np.c === food.c) {
      AudioFX.play('coin');
      newScore = score + 1;
      newFood = freeCell([np, snake]);
    } else {
      AudioFX.play('step');
    }
    const ns = snakeStep(snake, np);

    setPlayer(np); setFood(newFood); setScore(newScore); setSnake(ns);

    if (newScore >= GOAL) {
      lock.current = true;
      setTimeout(() => onWin({ coins: 18, label: 'Snake Wrangler' }), 500);
      return;
    }
    if (ns.r === np.r && ns.c === np.c) reset();
  };

  const reset = () => {
    lock.current = true;
    AudioFX.play('wrong');
    setCaught(true);
    setTimeout(() => {
      setPlayer({ r: N - 1, c: 0 });
      setSnake({ r: 0, c: N - 1 });
      setCaught(false);
      lock.current = false;
    }, 800);
  };

  return (
    <GameShell accent="#80B918" onQuit={onQuit} progress={score / GOAL}
      label={<span>🍓 {score} / {GOAL}</span>}
      hint="Use the arrows — grab 🍓 and stay away from 🐍">
      <div className="play-area snake-area">
        <div className={'snake-grid' + (caught ? ' caught' : '')} style={{ gridTemplateColumns: `repeat(${N}, 1fr)` }}>
          {Array.from({ length: N * N }).map((_, i) => {
            const r = Math.floor(i / N), c = i % N;
            const isP = player.r === r && player.c === c;
            const isS = snake.r === r && snake.c === c;
            const isF = food.r === r && food.c === c;
            const ob = obstacles[key(r, c)];
            return (
              <div className={'cell' + ((r + c) % 2 ? ' alt' : '')} key={i}>
                {isP ? <span className="cell-hero"><Hero char={char} size={30} accessory={accessory} /></span>
                  : isS ? <span className="cell-emoji snake-emoji">🐍</span>
                  : isF ? <span className="cell-emoji food-emoji">🍓</span>
                  : ob ? <span className="cell-emoji ob-emoji">{ob}</span> : null}
              </div>
            );
          })}
        </div>
        {caught && <div className="caught-flash">🐍 The snake got you! Restarting…</div>}
      </div>

      <div className="dpad">
        <button className="dbtn up" onClick={() => move(-1, 0)} aria-label="Up">▲</button>
        <button className="dbtn left" onClick={() => move(0, -1)} aria-label="Left">◀</button>
        <button className="dbtn down" onClick={() => move(1, 0)} aria-label="Down">▼</button>
        <button className="dbtn right" onClick={() => move(0, 1)} aria-label="Right">▶</button>
      </div>
    </GameShell>
  );
}
