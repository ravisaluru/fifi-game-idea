import { describe, expect, it } from 'vitest';
import { hexToRgb, shade, tint } from '../src/ui.jsx';

describe('color helpers', () => {
  it('parses hex (short and long form)', () => {
    expect(hexToRgb('#FFB703')).toEqual([255, 183, 3]);
    expect(hexToRgb('#fff')).toEqual([255, 255, 255]);
  });

  it('darkens with a negative amount and lightens with a positive one', () => {
    expect(shade('#888888', -1)).toBe('#000000');
    expect(shade('#888888', 1)).toBe('#ffffff');
    const darker = hexToRgb(shade('#FFB703', -0.22));
    expect(darker[0]).toBeLessThan(255);
    const lighter = hexToRgb(tint('#FFB703', 0.5));
    expect(lighter[2]).toBeGreaterThan(3);
  });
});
