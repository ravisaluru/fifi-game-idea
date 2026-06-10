// screens/home.jsx — game picker (replaces the old portal/world screen).
import React from 'react';
import { AudioFX } from '../audio.js';
import { GAMES } from '../data.js';
import { Hero, Hud, SoundToggle, Squish, shade, tint } from '../ui.jsx';

export function HomeScreen({ state, go, openCharacter }) {
  const char = state.character;
  const me = state.playerName || char.name;
  return (
    <div className="screen home">
      <div className="home-top">
        <button className="avatar-chip" onClick={openCharacter}>
          <Hero char={char} size={48} accessory={state.accessory} />
          <div className="avatar-chip-txt">
            <span className="hi">Hi,</span>
            <strong>{me}!</strong>
          </div>
          <span className="avatar-edit">✎</span>
        </button>
        <div className="home-top-right">
          <SoundToggle />
          <Hud coins={state.coins} trophies={state.trophies} />
        </div>
      </div>

      <div className="home-head">
        <h1 className="home-title">Pick a game</h1>
        <p className="home-sub">{state.trophies > 0
          ? `You’ve won ${state.trophies} of ${GAMES.length} games — keep going!`
          : 'Tap a card to start playing right away.'}</p>
      </div>

      <div className="game-grid">
        {GAMES.map((g) => {
          const done = state.completed.includes(g.id);
          return (
            <button key={g.id} className="game-card squish-soft"
              style={{ '--c': g.accent, '--lip': shade(g.accent, -0.24), '--soft': tint(g.accent, 0.86) }}
              onClick={() => { AudioFX.play('select'); go('pregame', { gameId: g.id }); }}>
              {done && <span className="card-stamp">★ Won</span>}
              <div className="card-emoji-wrap">
                <span className="card-blob" />
                <span className="card-emoji">{g.emoji}</span>
              </div>
              <div className="card-meta">
                <strong className="card-name">{g.name}</strong>
                <span className="card-tag" style={{ color: shade(g.accent, -0.45), background: tint(g.accent, 0.8) }}>{g.tag}</span>
              </div>
            </button>
          );
        })}
      </div>

      <div className="home-actions">
        <Squish color="#9B5DE5" className="wide" onClick={() => go('multiplayer')}>
          <span className="btn-emoji">👯</span> Play Together
        </Squish>
        <Squish color="#FFB703" className="wide" onClick={() => go('suggest')}>
          <span className="btn-emoji">💡</span> Suggest a Game
        </Squish>
      </div>
    </div>
  );
}
