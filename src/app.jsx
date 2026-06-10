// app.jsx — root: persisted state, screen router, ambient backdrop, online session.
import React, { useEffect, useState } from 'react';
import { CHARACTERS, THEMES } from './data.js';
import { GameHost } from './gamehost.jsx';
import { watchRoom } from './multiplayer.js';
import { CharacterScreen } from './screens/character.jsx';
import { HomeScreen } from './screens/home.jsx';
import { MultiplayerScreen } from './screens/multiplayer.jsx';
import { PreGameScreen } from './screens/pregame.jsx';
import { SuggestScreen } from './screens/suggest.jsx';
import { VictoryScreen } from './screens/victory.jsx';
import { WelcomeScreen } from './screens/welcome.jsx';
import { OnlineContext } from './ui.jsx';

const SAVE_KEY = 'fifi_save_v1';
function loadSave() {
  try {
    const s = JSON.parse(localStorage.getItem(SAVE_KEY));
    if (s && s.character) return s;
  } catch (e) { /* corrupt/absent save */ }
  return null;
}

// Look & feel knobs (theme moods live in data.js THEMES).
const LOOK = { theme: 'sunny', confetti: true };

export function App() {
  const saved = loadSave();
  const [state, setState] = useState(() => saved || {
    character: CHARACTERS[0], accessory: 'none', playerName: '', coins: 0, trophies: 0, completed: [], onboarded: false,
  });
  const [route, setRoute] = useState(() =>
    (saved && saved.playerName) ? { name: 'home', payload: {} } : { name: 'welcome', payload: {} });

  // Active online match: { code, playerId, isHost } + live players from the room.
  const [online, setOnline] = useState(null);
  const [onlinePlayers, setOnlinePlayers] = useState({});
  useEffect(() => {
    if (!online) { setOnlinePlayers({}); return undefined; }
    let unsub = null, gone = false;
    watchRoom(online.code, (room) => setOnlinePlayers(room.players || {}))
      .then((u) => { if (gone) u(); else unsub = u; })
      .catch(() => {});
    return () => { gone = true; if (unsub) unsub(); };
  }, [online]);

  useEffect(() => {
    const { coins, trophies, completed, character, accessory, playerName, onboarded } = state;
    try { localStorage.setItem(SAVE_KEY, JSON.stringify({ coins, trophies, completed, character, accessory, playerName, onboarded })); } catch (e) { /* private mode */ }
  }, [state]);

  const go = (name, payload = {}) => {
    setRoute({ name, payload });
    const stage = document.querySelector('.stage-scroll');
    if (stage) stage.scrollTop = 0;
  };

  const startOnline = (session, gameId) => {
    setOnline(session);
    go('play', { gameId });
  };
  const endOnline = () => setOnline(null);

  const theme = THEMES[LOOK.theme] || THEMES.sunny;

  let screen;
  const { name, payload } = route;
  if (name === 'welcome') screen = <WelcomeScreen setState={setState} go={go} />;
  else if (name === 'character') screen = <CharacterScreen state={state} setState={setState} go={go} />;
  else if (name === 'pregame') screen = <PreGameScreen state={state} go={go} gameId={payload.gameId} />;
  else if (name === 'play') screen = <GameHost state={state} setState={setState} go={go} gameId={payload.gameId} online={online} endOnline={endOnline} />;
  else if (name === 'victory') screen = <VictoryScreen state={state} result={payload.result} go={go}
      replay={() => go('play', { gameId: payload.result.gameId })} confetti={LOOK.confetti} />;
  else if (name === 'multiplayer') screen = <MultiplayerScreen state={state} go={go} startOnline={startOnline} />;
  else if (name === 'suggest') screen = <SuggestScreen state={state} go={go} gameId={payload.gameId} />;
  else screen = <HomeScreen state={state} go={go} openCharacter={() => go('character')} />;

  const onlineValue = online ? { ...online, players: onlinePlayers } : null;

  return (
    <OnlineContext.Provider value={onlineValue}>
      <div className={'app-root' + (name === 'play' ? ' in-game' : '')}
        style={{ '--bg1': theme.bg1, '--bg2': theme.bg2, '--stage': theme.stage,
                 '--ink': theme.ink, '--blob1': theme.blob1, '--blob2': theme.blob2 }}>
        <div className="ambient" aria-hidden="true">
          <span className="amb amb1" /><span className="amb amb2" /><span className="amb amb3" />
        </div>

        <div className="stage">
          <div className="stage-scroll">{screen}</div>
        </div>
      </div>
    </OnlineContext.Provider>
  );
}
