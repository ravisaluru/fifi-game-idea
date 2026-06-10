// games/tiger.jsx — Tiger Dash: run on green, FREEZE on red.
import React, { useEffect, useRef, useState } from 'react';
import { AudioFX } from '../audio.js';
import { GameShell, Hero, shade } from '../ui.jsx';

export function TigerDashGame({ onWin, onQuit, char, accessory, params = {} }) {
  const STEP = params.step || 6.5;
  const RED_MIN = params.redMin || 800;
  const RED_MAX = params.redMax || 2100;
  const [progress, setProgress] = useState(0);
  const [light, setLight] = useState('green'); // green | red
  const [caught, setCaught] = useState(false);
  const lightRef = useRef('green');
  const timer = useRef(null);
  const doneRef = useRef(false);

  // Light cycle (setInterval-free recursive timeout).
  useEffect(() => {
    const schedule = () => {
      const next = lightRef.current === 'green' ? 'red' : 'green';
      const dur = next === 'green' ? 900 + Math.random() * 1600 : RED_MIN + Math.random() * (RED_MAX - RED_MIN);
      timer.current = setTimeout(() => {
        if (doneRef.current) return;
        lightRef.current = next; setLight(next);
        if (next === 'red') AudioFX.play('select');
        schedule();
      }, dur);
    };
    schedule();
    return () => clearTimeout(timer.current);
  }, []);

  const run = () => {
    if (doneRef.current) return;
    if (lightRef.current === 'green') {
      AudioFX.play('step');
      setProgress((p) => {
        const np = Math.min(100, p + STEP);
        if (np >= 100) { doneRef.current = true; setTimeout(() => onWin({ coins: 15, label: 'Tiger Dodger' }), 700); }
        return np;
      });
    } else {
      // Caught moving on red — slip back.
      AudioFX.play('wrong');
      setCaught(true);
      setProgress((p) => Math.max(0, p - 12));
      setTimeout(() => setCaught(false), 420);
    }
  };

  const green = light === 'green';
  return (
    <GameShell accent="#FB8500" onQuit={onQuit} progress={progress / 100}
      label={<span>🏁 {Math.round(progress)}%</span>}
      hint="Tap RUN on green — freeze the moment it turns red! 🐯">
      <div className="play-area tiger-area">
        <div className={'signal ' + (green ? 'go' : 'stop')}>
          <span className="signal-face">{green ? '🐯' : '👀🐯'}</span>
          <span className="signal-word">{green ? 'RUN!' : 'FREEZE!'}</span>
        </div>

        <div className="tiger-track">
          <div className="track-lane" />
          <div className="track-runner" style={{ left: `calc(${progress}% )`, transform: 'translateX(-50%)' }}>
            <div className={'runner-toon' + (green ? ' running' : '') + (caught ? ' caught' : '')}>
              <Hero char={char} size={50} accessory={accessory} />
            </div>
          </div>
          <span className="track-flag">🏁</span>
        </div>

        {caught && <div className="caught-flash">🐯 Caught! Don’t move on red!</div>}
      </div>

      <button className={'dash-btn squish' + (green ? '' : ' danger')}
        style={{ '--c': green ? '#43AA8B' : '#E5484D', '--lip': green ? shade('#43AA8B', -0.22) : shade('#E5484D', -0.22) }}
        onPointerDown={run}>
        {green ? '👟 RUN!' : '✋ STOP'}
      </button>
    </GameShell>
  );
}
