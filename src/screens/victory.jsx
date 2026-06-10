// screens/victory.jsx — celebration after winning a game.
import React from 'react';
import { GAMES } from '../data.js';
import { TIERS } from '../difficulty.jsx';
import { Confetti, Hero, Squish, shade, tint } from '../ui.jsx';

export function VictoryScreen({ state, result, go, replay, confetti = true }) {
  const g = GAMES.find((x) => x.id === result.gameId) || GAMES[0];
  const char = state.character;
  const me = state.playerName || char.name;
  const firstWin = result.firstWin;
  return (
    <div className="screen victory" style={{ '--c': g.accent, '--soft': tint(g.accent, 0.84) }}>
      <Confetti run={confetti} count={90} />
      <div className="vic-card">
        {result.leveledUp && <div className="levelup-chip">⚡ Level up! Now {TIERS[result.tier]}</div>}
        <div className="vic-badge" style={{ background: g.accent, boxShadow: `0 10px 0 ${shade(g.accent, -0.24)}` }}>
          <span className="vic-emoji">{g.emoji}</span>
        </div>
        <h1 className="vic-title">You did it!</h1>
        <p className="vic-sub">{result.label || g.name} complete</p>

        <div className="vic-rewards">
          <div className="vic-reward">
            <span className="vic-r-emoji">🪙</span>
            <strong>+{result.coins}</strong>
            <span className="vic-r-label">coins</span>
          </div>
          {firstWin && (
            <div className="vic-reward">
              <span className="vic-r-emoji">🏆</span>
              <strong>+1</strong>
              <span className="vic-r-label">trophy</span>
            </div>
          )}
        </div>

        <div className="vic-hero">
          <Hero char={char} size={56} accessory={state.accessory} />
          <span>{firstWin ? `${me} won a new trophy!` : `Great catching, ${me}!`}</span>
        </div>

        <div className="vic-actions">
          <Squish color={g.accent} className="wide" onClick={replay}>
            <span className="btn-emoji">↻</span> Play again
          </Squish>
          <Squish color="#FFFFFF" lip="#E6DED3" className="wide ghost" onClick={() => go('home')}>
            <span className="btn-emoji">🏠</span> More games
          </Squish>
        </div>
      </div>
    </div>
  );
}
