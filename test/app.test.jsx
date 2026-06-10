import React from 'react';
import { renderToString } from 'react-dom/server';
import { beforeEach, describe, expect, it } from 'vitest';
import { App } from '../src/app.jsx';

describe('app shell', () => {
  beforeEach(() => localStorage.clear());

  it('renders the first-launch welcome screen for new players', () => {
    const html = renderToString(<App />);
    expect(html).toContain('Hi there!');
    expect(html).toContain('Pick your buddy');
  });

  it('renders the game picker for returning players', () => {
    localStorage.setItem('fifi_save_v1', JSON.stringify({
      character: { id: 'fifi', name: 'Fifi', emoji: '👧', color: '#F15BB5' },
      accessory: 'none', playerName: 'Maya', coins: 5, trophies: 1, completed: ['star'], onboarded: true,
    }));
    const html = renderToString(<App />);
    expect(html).toContain('Pick a game');
    expect(html).toContain('Maya');
    expect(html).toContain('Star Catch');
    expect(html).toContain('Treasure Flip');
    expect(html).toContain('Suggest a Game');
  });
});
