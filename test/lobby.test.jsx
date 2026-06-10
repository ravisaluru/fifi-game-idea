// Regression test for the host lobby: creating a room must keep the room
// watcher alive (an unmount-style cleanup keyed on `code` used to tear it
// down the moment the code arrived), so the host actually sees guests join.
import React from 'react';
import { act } from 'react';
import { createRoot } from 'react-dom/client';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

globalThis.IS_REACT_ACT_ENVIRONMENT = true;

// In-memory stand-in for the rooms backend.
const watchers = new Map(); // code -> Set<cb>
const removeRoom = vi.fn(async () => {});

vi.mock('../src/multiplayer.js', () => ({
  onlineAvailable: true,
  localPlayerId: () => 'host-1',
  createRoom: vi.fn(async () => 'ABCD'),
  joinRoom: vi.fn(async () => ({})),
  watchRoom: vi.fn(async (code, cb) => {
    if (!watchers.has(code)) watchers.set(code, new Set());
    watchers.get(code).add(cb);
    cb({ hostId: 'host-1', status: 'lobby', players: { 'host-1': { name: 'Maya' } } });
    return () => watchers.get(code).delete(cb);
  }),
  startGame: vi.fn(async () => {}),
  leaveRoom: vi.fn(async () => {}),
  removeRoom,
  submitIdea: vi.fn(async () => {}),
}));

const { MultiplayerScreen } = await import('../src/screens/multiplayer.jsx');

const STATE = {
  character: { id: 'fifi', name: 'Fifi', emoji: '👧', color: '#F15BB5' },
  accessory: 'none', playerName: 'Maya', coins: 0, trophies: 0, completed: [],
};

const clickButton = async (label) => {
  const btn = [...document.querySelectorAll('button')].find((b) => b.textContent.includes(label));
  expect(btn, `button "${label}"`).toBeTruthy();
  await act(async () => { btn.click(); });
};

describe('host lobby', () => {
  let container, root;
  beforeEach(() => {
    watchers.clear();
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });
  afterEach(async () => {
    await act(async () => root.unmount());
    container.remove();
  });

  it('keeps watching the room after hosting and shows a joining guest', async () => {
    await act(async () => {
      root.render(<MultiplayerScreen state={STATE} go={() => {}} startOnline={() => {}} />);
    });
    await clickButton('Play online');
    await clickButton('Make a room');

    // The room code is shown and the watcher must still be subscribed.
    expect(container.textContent).toContain('Your room code');
    expect(container.textContent).toContain('Waiting…');
    expect(watchers.get('ABCD').size).toBe(1);
    expect(removeRoom).not.toHaveBeenCalled();

    // A friend joins: the lobby must list them and enable "Start match".
    await act(async () => {
      for (const cb of watchers.get('ABCD')) {
        cb({ hostId: 'host-1', status: 'lobby',
          players: { 'host-1': { name: 'Maya' }, 'guest-1': { name: 'Buddy' } } });
      }
    });
    expect(container.textContent).toContain('Buddy');
    expect(container.textContent).not.toContain('Waiting…');
    const start = [...document.querySelectorAll('button')].find((b) => b.textContent.includes('Start match'));
    expect(start.disabled).toBe(false);
  });
});
