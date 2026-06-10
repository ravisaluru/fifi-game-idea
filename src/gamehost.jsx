// gamehost.jsx — mounts the right playable game, applies the difficulty tier,
// records the result so the curve adapts, and settles up the online room.
import React from 'react';
import { AudioFX } from './audio.js';
import { GAMES } from './data.js';
import { diffParams, getTier, recordResult } from './difficulty.jsx';
import { leaveRoom, markFinished, updateScore } from './multiplayer.js';
import { BubbleMatchGame } from './games/bubble.jsx';
import { FireflyGlowGame } from './games/firefly.jsx';
import { SnakeChaseGame } from './games/snake.jsx';
import { StarCatchGame } from './games/star.jsx';
import { SteppingStonesGame } from './games/stones.jsx';
import { TigerDashGame } from './games/tiger.jsx';
import { TreasureHuntGame } from './games/treasure.jsx';
import { PreGameScreen } from './screens/pregame.jsx';

const GAME_COMPONENTS = {
  star: StarCatchGame,
  bubble: BubbleMatchGame,
  firefly: FireflyGlowGame,
  tiger: TigerDashGame,
  stones: SteppingStonesGame,
  snake: SnakeChaseGame,
  treasure: TreasureHuntGame,
};

export function GameHost({ state, setState, go, gameId, online, endOnline }) {
  const tier = getTier(gameId);
  const params = diffParams(gameId, tier);

  const onWin = (result) => {
    const firstWin = !state.completed.includes(gameId);
    const newTier = recordResult(gameId, true);
    const leveledUp = newTier > tier;
    AudioFX.play('win');
    if (online) {
      updateScore(online.code, online.playerId, 100, 1)
        .then(() => markFinished(online.code, online.playerId))
        .catch(() => {});
      endOnline();
    }
    setState((s) => ({
      ...s,
      coins: s.coins + (result.coins || 0),
      completed: firstWin ? [...s.completed, gameId] : s.completed,
      trophies: firstWin ? s.trophies + 1 : s.trophies,
    }));
    go('victory', { result: { ...result, gameId, firstWin, leveledUp, tier: newTier } });
  };

  const onQuit = () => {
    recordResult(gameId, false);
    if (online) {
      leaveRoom(online.code, online.playerId).catch(() => {});
      endOnline();
    }
    go('home');
  };

  const Game = GAME_COMPONENTS[gameId];
  if (!Game) return <PreGameScreen state={state} go={go} gameId={gameId} />;
  return <Game onWin={onWin} onQuit={onQuit} char={state.character} accessory={state.accessory} params={params} tier={tier} />;
}
