// screens/multiplayer.jsx — "Play Together": online rooms (Firebase Realtime
// Database, same rooms/{code} schema as the original app) or vs robots.
import React, { useEffect, useRef, useState } from 'react';
import { AudioFX } from '../audio.js';
import { GAMES } from '../data.js';
import { onlineAvailable } from '../firebase.js';
import {
  createRoom, joinRoom, leaveRoom, localPlayerId, removeRoom, startGame, watchRoom,
} from '../multiplayer.js';
import { Hero, ScreenHeader, Squish, shade, tint } from '../ui.jsx';

const randomPlayableGame = () => {
  const playable = GAMES.filter((g) => g.playable);
  return playable[Math.floor(Math.random() * playable.length)];
};

export function MultiplayerScreen({ state, go, startOnline }) {
  const me = state.playerName || state.character.name;
  const [mode, setMode] = useState(null); // null | 'online' | 'ai'
  const [aiCount, setAiCount] = useState(2);

  // online sub-state
  const [onlineStep, setOnlineStep] = useState('choice'); // choice | host | join
  const [code, setCode] = useState(null); // hosted room code
  const [joinCode, setJoinCode] = useState('');
  const [room, setRoom] = useState(null); // live room snapshot
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const playerId = useRef(localPlayerId());
  const unsubRef = useRef(null);
  const startedRef = useRef(false);

  const stopWatching = () => { if (unsubRef.current) { unsubRef.current(); unsubRef.current = null; } setRoom(null); };

  const watch = async (roomCode, isHost) => {
    unsubRef.current = await watchRoom(roomCode, (r) => {
      setRoom(r);
      if (r.status === 'playing' && !startedRef.current) {
        startedRef.current = true;
        startOnline({ code: roomCode, playerId: playerId.current, isHost }, r.worldId);
      }
    });
  };

  // Leaving the screen mid-lobby: tidy up the room.
  useEffect(() => () => {
    if (unsubRef.current) unsubRef.current();
    if (!startedRef.current && code) removeRoom(code).catch(() => {});
  }, [code]);

  const host = async () => {
    setBusy(true); setError(null);
    try {
      const g = randomPlayableGame();
      const c = await createRoom(playerId.current, me, g.id);
      setCode(c);
      setOnlineStep('host');
      await watch(c, true);
    } catch (e) {
      setError('Couldn’t make a room — check your connection and try again.');
    }
    setBusy(false);
  };

  const join = async () => {
    const c = joinCode.trim().toUpperCase();
    if (c.length !== 4) { setError('Codes have 4 letters.'); return; }
    setBusy(true); setError(null);
    try {
      await joinRoom(c, playerId.current, me);
      setOnlineStep('join');
      await watch(c, false);
      setCode(null);
      setJoinCode(c);
    } catch (e) {
      setError(e.message === 'Game already started' ? 'That game already started!'
        : e.message === 'Room is full' ? 'That room is full!'
        : 'Hmm, no room with that code. Double-check it!');
    }
    setBusy(false);
  };

  const beginMatch = async () => {
    try {
      await startGame(code, randomPlayableGame().id);
      // navigation happens via the room watcher, same as for guests
    } catch (e) {
      setError('Couldn’t start the match — try again.');
    }
  };

  const back = () => {
    setError(null);
    if (mode === 'online' && onlineStep !== 'choice') {
      stopWatching();
      if (onlineStep === 'host' && code) { removeRoom(code).catch(() => {}); setCode(null); }
      if (onlineStep === 'join') leaveRoom(joinCode.trim().toUpperCase(), playerId.current).catch(() => {});
      setOnlineStep('choice');
    } else if (mode) {
      setMode(null);
      setOnlineStep('choice');
    } else {
      go('home');
    }
  };

  const players = Object.entries((room && room.players) || {});
  const friendCount = players.length - 1;

  return (
    <div className="screen multi">
      <ScreenHeader title="Play together" onBack={back} />

      {!mode && (
        <div className="multi-modes">
          <p className="multi-intro">Team up or take on the computer — same games, more giggles.</p>
          <button className="mode-card squish-soft" style={{ '--c': '#00B4D8', '--lip': shade('#00B4D8', -0.24), '--soft': tint('#00B4D8', 0.86) }} onClick={() => setMode('online')}>
            <span className="mode-emoji">🌐</span>
            <span className="mode-txt"><strong>Play online</strong><em>Invite friends with a room code</em></span>
            <span className="mode-go">›</span>
          </button>
          <button className="mode-card squish-soft" style={{ '--c': '#9B5DE5', '--lip': shade('#9B5DE5', -0.24), '--soft': tint('#9B5DE5', 0.86) }} onClick={() => setMode('ai')}>
            <span className="mode-emoji">🤖</span>
            <span className="mode-txt"><strong>Play vs robots</strong><em>Race friendly computer players</em></span>
            <span className="mode-go">›</span>
          </button>
        </div>
      )}

      {mode === 'online' && !onlineAvailable && (
        <div className="multi-setup">
          <div className="room-card">
            <p className="room-label">🔌 Online rooms are taking a nap</p>
            <p className="room-hint">This copy of the game isn’t connected to the internet playroom yet. Ask a grown-up to set it up — or race the robots instead!</p>
          </div>
          <Squish color="#9B5DE5" className="wide big" onClick={() => setMode('ai')}><span className="btn-emoji">🤖</span> Play vs robots</Squish>
        </div>
      )}

      {mode === 'online' && onlineAvailable && onlineStep === 'choice' && (
        <div className="multi-setup">
          <div className="room-card">
            <p className="room-label">Make a room</p>
            <p className="room-hint">You’ll get a 4-letter code your friends can use to join.</p>
            <div style={{ marginTop: 14 }}>
              <Squish color="#00B4D8" className="wide" disabled={busy} onClick={host}>
                <span className="btn-emoji">✨</span> {busy ? 'Making room…' : 'Make a room'}
              </Squish>
            </div>
          </div>
          <div className="room-card">
            <p className="room-label">Join a friend</p>
            <div className="code-entry">
              <input className="code-input" value={joinCode} maxLength={4} placeholder="CODE"
                style={{ '--c': '#00B4D8' }}
                onChange={(e) => { setJoinCode(e.target.value.toUpperCase()); setError(null); }} />
              <Squish color="#00B4D8" disabled={busy || joinCode.trim().length !== 4} onClick={join}>Join</Squish>
            </div>
            {error && <p className="room-error">{error}</p>}
          </div>
        </div>
      )}

      {mode === 'online' && onlineAvailable && onlineStep !== 'choice' && (
        <div className="multi-setup">
          <div className="room-card">
            <p className="room-label">{onlineStep === 'host' ? 'Your room code' : 'You’re in!'}</p>
            <div className="room-code">{(onlineStep === 'host' ? code || '····' : joinCode).split('').map((c, i) => <span key={i}>{c}</span>)}</div>
            <p className="room-hint">{onlineStep === 'host'
              ? 'Share this code so a friend can join you.'
              : 'Waiting for the host to start the match…'}</p>
            <div className="room-players">
              {players.map(([id, p]) => (
                <div className="rp" key={id}>
                  {id === playerId.current
                    ? <Hero char={state.character} size={44} accessory={state.accessory} />
                    : <div className="bot">🙂</div>}
                  <span>{id === playerId.current ? me : p.name}</span>
                </div>
              ))}
              {players.length < 2 && (
                <div className="rp waiting"><span className="rp-dots">···</span><span>Waiting…</span></div>
              )}
            </div>
            {error && <p className="room-error">{error}</p>}
          </div>
          {onlineStep === 'host' && (
            <Squish color="#00B4D8" className="wide big" disabled={friendCount < 1} onClick={beginMatch}>
              <span className="btn-emoji">▶</span> {friendCount < 1 ? 'Waiting for a friend…' : 'Start match'}
            </Squish>
          )}
        </div>
      )}

      {mode === 'ai' && (
        <div className="multi-setup">
          <div className="room-card">
            <p className="room-label">How many robots?</p>
            <div className="ai-stepper">
              <button onClick={() => { AudioFX.play('tap'); setAiCount((n) => Math.max(1, n - 1)); }} aria-label="fewer">−</button>
              <div className="ai-count"><strong>{aiCount}</strong><span>robot{aiCount > 1 ? 's' : ''}</span></div>
              <button onClick={() => { AudioFX.play('tap'); setAiCount((n) => Math.min(3, n + 1)); }} aria-label="more">+</button>
            </div>
            <div className="ai-avatars">
              <div className="rp"><Hero char={state.character} size={40} accessory={state.accessory} /><span>{me}</span></div>
              {Array.from({ length: aiCount }).map((_, i) => (
                <div className="rp" key={i}><div className="bot">🤖</div><span>Robo {i + 1}</span></div>
              ))}
            </div>
          </div>
          <Squish color="#9B5DE5" className="wide big" onClick={() => go('pregame', { gameId: randomPlayableGame().id })}>
            <span className="btn-emoji">▶</span> Start match
          </Squish>
        </div>
      )}
    </div>
  );
}
