import { describe, expect, it } from 'vitest';
import { generateRoomCode, playerPayload } from '../src/multiplayer.js';
import { GAMES } from '../src/data.js';

describe('room codes', () => {
  it('are 4 characters from the unambiguous alphabet (no O/0/I/1)', () => {
    for (let i = 0; i < 200; i++) {
      const code = generateRoomCode();
      expect(code).toMatch(/^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{4}$/);
    }
  });
});

describe('player payload', () => {
  it('matches the original Firebase rooms/{code}/players schema', () => {
    expect(playerPayload('Maya')).toEqual({
      name: 'Maya', isAi: false, score: 0, progress: 0, status: 'waiting',
    });
  });
});

describe('game catalogue', () => {
  it('keeps the 7 original backend world ids so old rooms stay compatible', () => {
    const ids = GAMES.map((g) => g.id);
    expect(ids).toHaveLength(7);
    expect(new Set(ids).size).toBe(7);
    for (const id of ['tiger', 'firefly', 'bubble', 'stones', 'star', 'snake', 'treasure']) {
      expect(ids).toContain(id);
    }
  });
});
