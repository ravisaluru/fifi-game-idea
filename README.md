# Fifi's World Adventures 🌟🎮

A magical, tactile, kid-first game for ages 4–8. Seven mini-games, a hero
customizer, online rooms, and a "Suggest a Game" idea box — built as a fast
static web app with **React + Vite**, styled with the **"Squish" design system**
from the Claude Design handoff, with online multiplayer on
**Cloudflare Durable Objects** (free plan — no external services).

---

## 🎨 The "Squish" design

No more portal/world metaphor — the home screen is a friendly **game picker**.
Warm cream canvas, puffy white cards with colored "lips" that squish when
pressed, one signature color per game, morphing blobs, floating emoji heroes,
**Baloo 2 + Nunito** type. Fully responsive: full-bleed on phones, a centered
console floating on an ambient backdrop on iPad/desktop.

## ⚡ Performance principles (the "new engine")

Every moving thing follows the same battery/CPU discipline (`src/motion.js`):

* **No per-frame React.** Star Catch's falling stars are a pure CSS `transform`
  animation on the GPU compositor — zero JS while a star is in flight.
  The other six games are turn/tap-based by design.
* **At most one rAF loop app-wide** (`Ticker`), which fully stops when idle.
* **Hidden tab = everything stops.** A `body.is-hidden` flag hard-pauses all
  CSS animations, spawn intervals skip, and the Web Audio clock suspends.
* **Transform/opacity only** for decorative motion (no `border-radius` /
  `box-shadow` / `margin` keyframes, which force repaints).
* **Reduced-motion** drops decorative loops only; gameplay stays usable.
* Sound is **synthesized on the fly** (`src/audio.js`, Web Audio oscillators) —
  no audio files to download.

## 🕹️ The 7 games

All seven share one `GameShell` (HUD, progress bar, hint, quit) and the
replay-friendly difficulty curve in `src/difficulty.jsx` — each win nudges that
game up a tier (Easy → Just right → Speedy), giving up eases it back down.

1. **⭐ Star Catch** — tap falling stars (combo meter, pop effects)
2. **🫧 Bubble Match** — pair up same-colored bubbles
3. **🧚 Firefly Glow** — watch-and-repeat memory with a pentatonic song
4. **🐯 Tiger Dash** — run on green, freeze on red
5. **🪨 Stone Hop** — memorize the glowing path, hop to the beach
6. **🐍 Snake Escape** — turn-based grid: grab 🍓, dodge the chasing snake
7. **🪙 Treasure Flip** — flip leaves to match hidden treasures

## 🌐 Online multiplayer (Cloudflare Durable Objects)

Rooms live in a Cloudflare Worker (`worker/index.js`): one **Durable Object
per 4-letter room code**, talked to over WebSocket at `/api/rooms/{CODE}/ws`.
The room state keeps the **same schema** as the original Firebase app:

```
{ hostId, worldId, status: 'lobby' | 'playing', createdAt,
  players: { [id]: { name, isAi, score, progress, status } } }
```

Hosts get a 4-letter room code (unambiguous alphabet, no O/0/I/1); friends join
with the code; the host starts the match and everyone plays the same game while
`GameShell` publishes live progress (throttled) and shows opponents' progress
chips. The server broadcasts the full snapshot after every change (like
Firebase's `onValue`) and cleans up when sockets drop — a guest's player is
removed, a host's room is torn down (like `onDisconnect`). Stale rooms expire
after 6 hours via a Durable Object alarm.

"Suggest a Game" ideas are saved locally **and** POSTed to `/api/ideas`, which
stores them in a singleton Durable Object. Reading them back requires a secret:
`wrangler secret put IDEAS_READ_KEY`, then
`curl -H "Authorization: Bearer <key>" https://<site>/api/ideas`.

**No configuration needed** — the backend deploys with the site and everything
runs on the Workers **free plan** (SQLite-backed Durable Objects, WebSocket
hibernation, 100k requests/day). Smoke-test the whole room lifecycle with
`npm run dev:worker` + `node scripts/smoke-online.mjs`.

## 📐 Project structure

```bash
index.html              # Entry — fonts + #root
src/
├── main.jsx            # React bootstrap
├── app.jsx             # Router, persisted save, online session, ambient backdrop
├── styles.css          # The whole Squish design system
├── data.js             # Games, characters, outfits, accessories, themes
├── ui.jsx              # Squish/Hero/Hud/GameShell + color helpers + OnlineContext
├── motion.js           # Shared ticker, visibility-aware interval, height measure
├── audio.js            # Synthesized SFX engine (visibility-aware)
├── difficulty.jsx      # Tier curve + per-game tuning table
├── multiplayer.js      # Realtime rooms client — WebSocket to the worker
├── gamehost.jsx        # Mounts the right game, applies tier, settles the room
├── screens/            # welcome, home, character, pregame, victory, multiplayer, suggest
└── games/              # star, bubble, firefly, tiger, stones, snake, treasure
worker/index.js         # Cloudflare Worker — Room + Ideas Durable Objects
wrangler.jsonc          # Worker config: static assets + DO bindings
test/                   # Vitest suite (difficulty, rooms, colors, app smoke)
scripts/smoke-online.mjs # End-to-end rooms test against a running worker
```

## 🚀 Running locally

```bash
./start.sh        # dev server in the background on http://localhost:8080
./stop.sh         # stop it
npm test          # run the test suite
npm run build     # production build → dist/
npm run dev:worker # rooms backend on :8787 (vite proxies /api to it)
```

(Or just `npm install && npm run dev`. Solo and vs-robots play need no
backend; run `dev:worker` alongside to try online rooms locally.)

## ☁️ Deploying

One command ships the whole thing — static site and multiplayer backend — as a
single Cloudflare Worker (free plan):

```bash
npm run deploy    # vite build + wrangler deploy
```

Live at **https://fifis-world-adventures.&lt;your-subdomain&gt;.workers.dev** —
no environment variables or external services required.

## 🔁 CI

GitHub Actions (`.github/workflows/ci.yml`) runs `npm test` + `npm run build`
on every push/PR. Install the local pre-push hook with
`sh scripts/setup-hooks.sh`.
