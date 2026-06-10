// screens/welcome.jsx — warm first-launch screen. Asks the kid's name and buddy
// before they ever reach the home grid, so their identity is set from the start.
import React, { useState } from 'react';
import { AudioFX } from '../audio.js';
import { CHARACTERS } from '../data.js';
import { Hero, Squish, tint } from '../ui.jsx';

export function WelcomeScreen({ setState, go }) {
  const [idx, setIdx] = useState(0);
  const [name, setName] = useState('');
  const char = CHARACTERS[idx];

  const start = () => {
    const finalName = name.trim() || char.name;
    setState((s) => ({ ...s, character: char, playerName: finalName, onboarded: true }));
    AudioFX.play('win');
    go('home');
  };

  return (
    <div className="screen welcome">
      <div className="welcome-sky" aria-hidden="true">
        <span className="w-star s1">⭐</span>
        <span className="w-star s2">✨</span>
        <span className="w-star s3">🌟</span>
      </div>

      <div className="welcome-top">
        <h1 className="welcome-title">Hi there!</h1>
        <p className="welcome-sub">Let’s get you ready to play.</p>
      </div>

      <div className="welcome-hero" style={{ '--c': char.color, background: `linear-gradient(160deg, ${tint(char.color, 0.5)}, ${char.color})` }}>
        <span className="welcome-blob b1" />
        <div className="welcome-stage">
          <Hero char={char} size={120} accessory="none" ring />
          <span className="hero-shadow" />
        </div>
        <div className="name-ribbon">{name.trim() || 'Player'}</div>
      </div>

      <div className="welcome-field">
        <label className="sug-label">What’s your name?</label>
        <div className="name-wrap" style={{ '--c': char.color }}>
          <span className="name-ico">😀</span>
          <input className="name-field" value={name} maxLength={14} autoFocus
            onChange={(e) => setName(e.target.value)}
            placeholder={`Type your name (e.g. ${char.name})`} />
          {name && <button className="name-clear" onClick={() => setName('')} aria-label="Clear">✕</button>}
        </div>
      </div>

      <div className="welcome-field">
        <label className="sug-label">Pick your buddy</label>
        <div className="buddy-row">
          {CHARACTERS.map((c, i) => (
            <button key={c.id} className={'buddy-thumb' + (i === idx ? ' sel' : '')}
              onClick={() => { setIdx(i); AudioFX.play('select'); }}
              style={{ '--c': i === idx ? c.color : '#E9E0D3' }}>
              <Hero char={c} size={48} accessory="none" />
              <span className="buddy-name">{c.name}</span>
            </button>
          ))}
        </div>
      </div>

      <div className="welcome-go">
        <Squish color={char.color} className="wide big" onClick={start}>
          <span className="btn-emoji">▶</span> Let’s play!
        </Squish>
        <p className="welcome-note">You can change this anytime from the home screen.</p>
      </div>
    </div>
  );
}
