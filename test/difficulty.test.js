import { beforeEach, describe, expect, it } from 'vitest';
import { TIERS, diffParams, getTier, recordResult } from '../src/difficulty.jsx';
import { GAMES } from '../src/data.js';

describe('difficulty curve', () => {
  beforeEach(() => localStorage.clear());

  it('starts every game at the easiest tier', () => {
    expect(getTier('star')).toBe(0);
    expect(getTier('unknown')).toBe(0);
  });

  it('steps up one tier per win and caps at the top', () => {
    expect(recordResult('star', true)).toBe(1);
    expect(recordResult('star', true)).toBe(2);
    expect(recordResult('star', true)).toBe(2); // capped
    expect(getTier('star')).toBe(2);
  });

  it('eases back down on a give-up and floors at zero', () => {
    recordResult('snake', true);
    expect(recordResult('snake', false)).toBe(0);
    expect(recordResult('snake', false)).toBe(0); // floored
  });

  it('tracks each game independently', () => {
    recordResult('star', true);
    expect(getTier('star')).toBe(1);
    expect(getTier('bubble')).toBe(0);
  });

  it('has three named tiers and params for every playable game at every tier', () => {
    expect(TIERS).toHaveLength(3);
    for (const g of GAMES.filter((x) => x.playable)) {
      for (const tier of [0, 1, 2]) {
        expect(Object.keys(diffParams(g.id, tier)).length, `${g.id} tier ${tier}`).toBeGreaterThan(0);
      }
    }
  });

  it('gets harder as the tier rises (star catch spawns faster, asks for more)', () => {
    const [easy, mid, fast] = [0, 1, 2].map((t) => diffParams('star', t));
    expect(easy.spawn).toBeGreaterThan(mid.spawn);
    expect(mid.spawn).toBeGreaterThan(fast.spawn);
    expect(fast.goal).toBeGreaterThan(easy.goal);
  });
});
