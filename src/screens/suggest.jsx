// screens/suggest.jsx — kid-friendly "Suggest a Game" idea form.
// Ideas always save locally; when Firebase is configured they're also sent to
// the `ideas/` collection so the game makers actually receive them.
import React, { useState } from 'react';
import { AudioFX } from '../audio.js';
import { GAMES } from '../data.js';
import { onlineAvailable } from '../firebase.js';
import { submitIdea } from '../multiplayer.js';
import { Confetti, ScreenHeader, Squish, tint } from '../ui.jsx';

const IDEA_EMOJIS = ['🚀', '🦄', '🐙', '🍩', '🏰', '🎈', '🐧', '🌈', '🦖', '⚽', '🎸', '🪐'];
const STORE_KEY = 'fifi_ideas_v1';

function loadIdeas() {
  try { return JSON.parse(localStorage.getItem(STORE_KEY) || '[]'); } catch (e) { return []; }
}

export function SuggestScreen({ state, go, gameId }) {
  const seed = GAMES.find((g) => g.id === gameId);
  const [emoji, setEmoji] = useState(seed ? seed.emoji : '🚀');
  const [name, setName] = useState('');
  const [idea, setIdea] = useState('');
  const [sent, setSent] = useState(false);
  const me = state.playerName || state.character.name;
  const count = loadIdeas().length;

  const submit = () => {
    const entry = { emoji, name: name.trim() || 'My Game', idea: idea.trim(), by: me, at: Date.now() };
    const all = loadIdeas(); all.push(entry);
    try { localStorage.setItem(STORE_KEY, JSON.stringify(all)); } catch (e) { /* private mode */ }
    if (onlineAvailable) submitIdea(entry).catch(() => {});
    AudioFX.play('win');
    setSent(true);
  };

  if (sent) {
    return (
      <div className="screen suggest" style={{ '--c': '#FFB703', '--soft': tint('#FFB703', 0.85) }}>
        <Confetti run={true} count={70} />
        <div className="thanks-card">
          <div className="thanks-badge"><span>{emoji}</span></div>
          <h1 className="thanks-title">Idea received!</h1>
          <p className="thanks-sub">Our game makers will read “<strong>{name.trim() || 'My Game'}</strong>” and might build it just for you.</p>
          <div className="thanks-preview">
            <span className="tp-emoji">{emoji}</span>
            <div><strong>{name.trim() || 'My Game'}</strong><em>by {me}</em></div>
          </div>
          <div className="vic-actions">
            <Squish color="#FFB703" className="wide" onClick={() => { setSent(false); setName(''); setIdea(''); }}>
              <span className="btn-emoji">＋</span> Another idea
            </Squish>
            <Squish color="#FFFFFF" lip="#E6DED3" className="wide ghost" onClick={() => go('home')}>
              <span className="btn-emoji">🏠</span> Back home
            </Squish>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="screen suggest" style={{ '--c': '#FFB703', '--soft': tint('#FFB703', 0.85) }}>
      <ScreenHeader title="Dream up a game" onBack={() => go('home')}
        right={count > 0 ? <span className="ideas-count">💡 {count}</span> : null} />

      <p className="sug-intro">Got an idea for a new game? Tell us and we might build it! 🛠️</p>

      <div className="sug-field">
        <label className="sug-label">Pick an icon</label>
        <div className="emoji-grid">
          {IDEA_EMOJIS.map((e) => (
            <button key={e} className={'emoji-pick' + (e === emoji ? ' sel' : '')} onClick={() => setEmoji(e)}>{e}</button>
          ))}
        </div>
      </div>

      <div className="sug-field">
        <label className="sug-label">Name your game</label>
        <input className="sug-input" value={name} maxLength={28}
          onChange={(e) => setName(e.target.value)} placeholder="e.g. Rocket Puppy Rescue" />
      </div>

      <div className="sug-field">
        <label className="sug-label">How do you play it?</label>
        <textarea className="sug-textarea" value={idea} rows={4} maxLength={240}
          onChange={(e) => setIdea(e.target.value)}
          placeholder="Tell us what you do, what you collect, who the hero is…" />
      </div>

      <div className="sug-submit">
        <Squish color="#FFB703" className="wide big" disabled={!idea.trim()} onClick={submit}>
          <span className="btn-emoji">💌</span> Send my idea
        </Squish>
      </div>
    </div>
  );
}
