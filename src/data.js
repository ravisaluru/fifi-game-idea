// data.js — content + tokens for Fifi's World Adventures.
// Each game = a "deck" the player picks. No portal/world metaphor.
// Game ids intentionally match the original backend WorldId names
// (tiger/firefly/bubble/stones/star/snake/treasure) so online rooms stay
// compatible with the existing Firebase `rooms/{code}.worldId` schema.

export const GAMES = [
  {
    id: 'star',
    name: 'Star Catch',
    emoji: '⭐',
    accent: '#FFB703',
    tag: 'Speedy',
    blurb: 'Catch the falling stars before they touch the ground!',
    rule: 'Tap every star you can. Quick fingers win!',
    playable: true,
  },
  {
    id: 'bubble',
    name: 'Bubble Match',
    emoji: '🫧',
    accent: '#4CC9F0',
    tag: 'Calm',
    blurb: 'Pop the bubbles that share the same color.',
    rule: 'Tap two bubbles of the same color to pop them.',
    playable: true,
  },
  {
    id: 'firefly',
    name: 'Firefly Glow',
    emoji: '🧚',
    accent: '#9B5DE5',
    tag: 'Memory',
    blurb: 'Watch the fireflies twinkle, then repeat the song.',
    rule: 'Remember the order they glow, then tap them back.',
    playable: true,
  },
  {
    id: 'tiger',
    name: 'Tiger Dash',
    emoji: '🐯',
    accent: '#FB8500',
    tag: 'Brave',
    blurb: 'Run on green, freeze on red — don’t let the tiger catch you!',
    rule: 'Tap to run. Stop the second the light turns red.',
    playable: true,
  },
  {
    id: 'stones',
    name: 'Stone Hop',
    emoji: '🪨',
    accent: '#2A9D8F',
    tag: 'Memory',
    blurb: 'Remember the glowing path and hop your way to the beach.',
    rule: 'Memorize the lit stones, then hop across in order.',
    playable: true,
  },
  {
    id: 'snake',
    name: 'Snake Escape',
    emoji: '🐍',
    accent: '#80B918',
    tag: 'Brave',
    blurb: 'Grab the snacks and slip away from the slithering snake.',
    rule: 'Steer to collect food and dodge the snake.',
    playable: true,
  },
  {
    id: 'treasure',
    name: 'Treasure Flip',
    emoji: '🪙',
    accent: '#F15BB5',
    tag: 'Memory',
    blurb: 'Flip the leaves and find every hidden coin in time.',
    rule: 'Flip two leaves — match the coins to keep them.',
    playable: true,
  },
];

export const CHARACTERS = [
  { id: 'fifi', name: 'Fifi', emoji: '👧', color: '#F15BB5' },
  { id: 'leo', name: 'Leo', emoji: '👦', color: '#4CC9F0' },
  { id: 'zara', name: 'Zara', emoji: '🥷', color: '#9B5DE5' },
  { id: 'milo', name: 'Milo', emoji: '🧭', color: '#FB8500' },
  { id: 'luna', name: 'Luna', emoji: '🧚', color: '#00B4D8' },
  { id: 'rex', name: 'Rex', emoji: '🦕', color: '#80B918' },
];

export const OUTFIT_COLORS = [
  '#F15BB5', '#4CC9F0', '#9B5DE5', '#FB8500',
  '#80B918', '#FF5C7A', '#00B4D8', '#FFB703',
];

export const ACCESSORIES = [
  { id: 'none', emoji: '🚫', label: 'None' },
  { id: 'hat', emoji: '🎩', label: 'Top Hat' },
  { id: 'cape', emoji: '🦸', label: 'Hero Cape' },
  { id: 'shield', emoji: '🛡️', label: 'Shield' },
  { id: 'wand', emoji: '🪄', label: 'Magic Wand' },
  { id: 'crown', emoji: '👑', label: 'Crown' },
];

// Background-mood themes. The stage stays light + warm; the ambient backdrop
// blobs + accents shift mood.
export const THEMES = {
  sunny: {
    label: 'Sunny',
    bg1: '#FFE9C9', bg2: '#FFD7B0', stage: '#FFF7EE',
    blob1: '#FFD166', blob2: '#FF9F68', ink: '#4A3526',
  },
  dreamy: {
    label: 'Dreamy',
    bg1: '#EAE2FF', bg2: '#F6D9F0', stage: '#FBF7FF',
    blob1: '#B79CFF', blob2: '#F19BD6', ink: '#3E3358',
  },
  mint: {
    label: 'Mint',
    bg1: '#D6F5E8', bg2: '#C6EEF0', stage: '#F2FBF7',
    blob1: '#6FE0B5', blob2: '#67D3E6', ink: '#27463C',
  },
};
