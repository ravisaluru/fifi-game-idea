// screens/character.jsx — rich hero customizer + player name (your online identity).
import React, { useState } from 'react';
import { ACCESSORIES, CHARACTERS, OUTFIT_COLORS } from '../data.js';
import { Hero, ScreenHeader, Squish, tint } from '../ui.jsx';

export function CharacterScreen({ state, setState, go }) {
  const idx0 = Math.max(0, CHARACTERS.findIndex((c) => c.id === state.character.id));
  const [idx, setIdx] = useState(idx0);
  const [outfit, setOutfit] = useState(state.character.color);
  const [acc, setAcc] = useState(state.accessory);
  const [pname, setPname] = useState(state.playerName || '');

  const base = CHARACTERS[idx];
  const char = { ...base, color: outfit };
  const display = pname.trim() || 'You';

  const surprise = () => {
    const ni = Math.floor(Math.random() * CHARACTERS.length);
    setIdx(ni);
    setOutfit(OUTFIT_COLORS[Math.floor(Math.random() * OUTFIT_COLORS.length)]);
    setAcc(ACCESSORIES[Math.floor(Math.random() * ACCESSORIES.length)].id);
  };

  const save = () => {
    setState((s) => ({ ...s, character: { ...base, color: outfit }, accessory: acc, playerName: pname.trim() }));
    go('home');
  };

  return (
    <div className="screen character">
      <ScreenHeader title="Make your hero" onBack={() => go('home')}
        right={<button className="surprise-btn" onClick={surprise}>🎲 Surprise</button>} />

      {/* Live identity card */}
      <div className="hero-card" style={{ background: `linear-gradient(160deg, ${tint(outfit, 0.5)}, ${outfit})` }}>
        <span className="hero-card-blob b1" />
        <span className="hero-card-blob b2" />
        <div className="hero-stage">
          <Hero char={char} size={132} accessory={acc} ring />
          <span className="hero-shadow" />
        </div>
        <div className="name-ribbon">{display}</div>
        <div className="hero-card-stats">
          <span>🪙 {state.coins}</span><i />
          <span>🏆 {state.trophies}</span>
        </div>
      </div>

      {/* Name */}
      <div className="picker">
        <h3 className="picker-label">What should we call you?</h3>
        <div className="name-wrap" style={{ '--c': outfit }}>
          <span className="name-ico">😀</span>
          <input className="name-field" value={pname} maxLength={14}
            onChange={(e) => setPname(e.target.value)}
            placeholder={`Type your name (e.g. ${base.name})`} />
          {pname && <button className="name-clear" onClick={() => setPname('')} aria-label="Clear">✕</button>}
        </div>
        <p className="name-tip">Friends will see this name when you play online together.</p>
      </div>

      {/* Buddy picker */}
      <div className="picker">
        <h3 className="picker-label">Choose your buddy</h3>
        <div className="buddy-row">
          {CHARACTERS.map((c, i) => (
            <button key={c.id} className={'buddy-thumb' + (i === idx ? ' sel' : '')}
              onClick={() => { setIdx(i); setOutfit(c.color); }}
              style={{ '--c': i === idx ? outfit : '#E9E0D3' }}>
              <Hero char={i === idx ? char : c} size={48} accessory="none" />
              <span className="buddy-name">{c.name}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Outfit color */}
      <div className="picker">
        <h3 className="picker-label">Outfit color</h3>
        <div className="swatch-row">
          {OUTFIT_COLORS.map((c) => (
            <button key={c} className={'swatch' + (c === outfit ? ' sel' : '')}
              style={{ background: c }} aria-label={'Color ' + c} onClick={() => setOutfit(c)}>
              {c === outfit && <span className="swatch-check">✓</span>}
            </button>
          ))}
        </div>
      </div>

      {/* Accessory */}
      <div className="picker">
        <h3 className="picker-label">Add an extra</h3>
        <div className="acc-row">
          {ACCESSORIES.map((a) => (
            <button key={a.id} className={'acc-chip' + (a.id === acc ? ' sel' : '')}
              onClick={() => setAcc(a.id)} style={{ '--c': outfit }}>
              <span className="acc-emoji">{a.emoji}</span>
              <span className="acc-label">{a.label}</span>
            </button>
          ))}
        </div>
      </div>

      <div className="char-save">
        <Squish color={outfit} className="wide big" onClick={save}>
          <span className="btn-emoji">✓</span> That’s me!
        </Squish>
      </div>
    </div>
  );
}
