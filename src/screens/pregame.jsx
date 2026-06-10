// screens/pregame.jsx — "Get Ready" rules card before a game. Honest about
// which games are playable vs. still being built (ties into Suggest-a-Game).
import React from 'react';
import { GAMES } from '../data.js';
import { TierDots, getTier } from '../difficulty.jsx';
import { Hero, Pill, ScreenHeader, SoundToggle, Squish, shade, tint } from '../ui.jsx';

export function PreGameScreen({ state, go, gameId }) {
  const g = GAMES.find((x) => x.id === gameId) || GAMES[0];
  const char = state.character;
  const me = state.playerName || char.name;
  const tier = getTier(gameId);
  return (
    <div className="screen pregame" style={{ '--c': g.accent, '--soft': tint(g.accent, 0.86), '--lip': shade(g.accent, -0.24) }}>
      <ScreenHeader title="Get ready!" onBack={() => go('home')} right={<SoundToggle />} />

      <div className="pg-hero">
        <span className="pg-blob" />
        <span className="pg-emoji">{g.emoji}</span>
      </div>

      <h1 className="pg-name">{g.name}</h1>
      <div className="pg-tag"><Pill color={g.accent} tone="soft">{g.tag}</Pill></div>
      <p className="pg-blurb">{g.blurb}</p>

      <div className="pg-rule">
        <span className="pg-rule-icon">👆</span>
        <span>{g.rule}</span>
      </div>

      {g.playable ? (
        <div className="pg-foot">
          <div className="pg-tier">
            <span className="tier-label">Difficulty</span>
            <TierDots tier={tier} accent={g.accent} />
          </div>
          <div className="pg-ready">
            <Hero char={char} size={40} accessory={state.accessory} />
            <span>{me} is ready to play!</span>
          </div>
          <Squish color={g.accent} className="wide big" onClick={() => go('play', { gameId })}>
            <span className="btn-emoji">▶</span> Let’s Play!
          </Squish>
        </div>
      ) : (
        <div className="pg-foot">
          <div className="pg-soon">
            <span className="pg-soon-emoji">🛠️</span>
            <div>
              <strong>We’re still building this one!</strong>
              <p>Tell us how it should work and we’ll make it for you.</p>
            </div>
          </div>
          <Squish color="#FFB703" className="wide big" onClick={() => go('suggest', { gameId })}>
            <span className="btn-emoji">💡</span> Share your idea
          </Squish>
        </div>
      )}
    </div>
  );
}
