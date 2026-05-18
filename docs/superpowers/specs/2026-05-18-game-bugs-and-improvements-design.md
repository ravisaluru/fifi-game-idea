# Fifi's World Adventures — Bug Fixes & Graphics Improvements

**Date:** 2026-05-18  
**Branch:** claude/kids-game-challenges-hemPe  

---

## Overview

Seven improvements to the game covering navigation, gameplay mechanics, and visual quality. All changes stay within the existing Flutter/emoji-based art style — no external asset libraries needed.

---

## 1. World Selection Screen

### Problem
There is no world selection UI. After character select, `GameState.pickNextWorld()` picks a random world. Players cannot choose where to go.

### Design
- New screen: `lib/screens/world_select_screen.dart`
- Inserted into nav flow: `Home → CharacterSelect (skipped if character saved) → WorldSelectScreen → /world/<id>`
- Layout: 2-column `GridView` of 7 world cards
- Each card: world emoji, world name, background gradient per world, ⭐ badge if world is in `completedWorlds`
- Top-right: small "Change Hero 🎭" button navigates to `/character` (with `pushReplacement` back to world select on confirm)
- Routes: `WorldSelectScreen` registered at `/world-select` in `main.dart`
- `CharacterSelectScreen._confirm()` navigates to `/world-select` instead of directly to a world route
- `HomeScreen` portal tap navigates to `/character` if no character saved, else directly to `/world-select`

### GameState changes
- Add `Set<WorldId> completedWorlds = {}` (replaces bare `worldsCompleted` int — keep int for backwards compat, derive it from set size)
- `completeWorld(WorldId id)` adds to set and increments count
- All world `_onWin()` calls pass their `WorldId` to `completeWorld()`

---

## 2. Blank Screen on Web Startup

### Problem
On initial `flutter run -d web-server`, the canvas is blank until a hot-reload.

### Design
- Add a CSS loading spinner to `web/index.html` inside the `#loading` div (Flutter web scaffold already shows this div while the Dart runtime loads; we just need to style it)
- Add `flutter_service_worker.js` cache-busting param on the script tag to prevent stale service worker from serving an empty shell
- In `main()`, add `WidgetsBinding.instance.addPostFrameCallback((_) => {})` no-op after `runApp` to ensure the first frame is committed on web

---

## 3. Balloon Speed — Bubble World

### Problem
Bubbles rise too fast for kids aged 4–8.

### Design
- In `bubble_world.dart` line 62, change the `AnimationController` duration from `4000 + rng.nextInt(3000)` ms to `6700 + rng.nextInt(5000)` ms
- This slows bubbles by ~40% (factor of 1/0.6 ≈ 1.67)
- No other changes needed

---

## 4. Stepping Stones Overhaul

### Problem
Only 6 stones in a narrow horizontal band. Too few, too predictable.

### Design
- `_stoneCount` raised from 6 to 12
- `_buildPositions(Size size)` rewritten: positions generated with `Random(seed)` spread across full usable area (10–90% x, 20–80% y), with a 90 px minimum distance check between any two stones to prevent overlap
- Seed is fixed per session (`Random(DateTime.now().millisecondsSinceEpoch)`) so each game session has a different layout
- Sequence length = 12 (all stones must be hopped in order)
- Stone widget size unchanged (70×40) to stay tappable
- Fifi character starts at left edge; hops to each correct stone in sequence

---

## 5. Tiger World Realism

### Problem
The running character doesn't animate while moving. The tiger is static. Getting caught has little impact feedback.

### Design

**Running character bob:**
- Add a `Ticker` (via `TickerProviderStateMixin`, already mixed in) that runs only while the player is moving (i.e., after `_onMoveInput` is called and before the next frame settles)
- Vertical oscillation: `sin(t * 8) * 6` px offset applied to the player `Positioned` widget
- While standing still (tiger is watching), oscillation stops immediately

**Tiger expressions:**
| State | Emoji | Visual |
|---|---|---|
| `lookingAway` | 🐯 | Normal, small size (64px) |
| `turningAround` | 😤 | Slightly larger (70px), quick scale-up over 400 ms |
| `lookingAtYou` | 😤 | 70px + red `BoxDecoration` glow ring around tiger container |
| `turningAway` | 😌 | Scale back down to 64px over 400 ms |

**Caught flash:**
- On `_onCaught()`, before the shake animation, overlay the full screen with a `IgnorePointer` red Container at 30% opacity, fade it out over 300 ms, then run the existing shake

---

## 6. Graphics Pass

Applied across all screens. All animations use existing `AnimationController` / `Ticker` patterns — no new packages.

### Better Backgrounds
- `AnimatedWorldBackground` gets a second `_driftController` (120 s repeat, never reverses)
- Per `BackgroundTheme`:
  - `meadow` / `grassland`: 3 drifting cloud blobs (white rounded rectangles, 60% opacity) that move horizontally on a sine path
  - `river`: 20 tiny upward-floating particles (white dots, random x, sine vertical drift)
  - Any night theme (if added later): twinkling dots using opacity oscillation

### Character Bounce
- New widget `BouncingEmoji({required String emoji, double fontSize = 36})` in `lib/widgets/`
- Uses a single `AnimationController` (800 ms, repeat reverse) for a −8 to +8 px vertical translate
- Replaces bare `Text(emoji)` in: `SteppingStonesScreen` player, `CharacterSelectScreen` preview, `WorldSelectScreen` cards (idle), `VictoryScreen` character display

### Particle Burst
- New widget `ParticleBurst` in `lib/widgets/particle_burst.dart`
- Constructor takes `color`, `particleCount` (default 12), callback to trigger
- On trigger: spawns `particleCount` colored dots that fan out at random angles, fade from opacity 1.0 → 0 over 600 ms, then widget removes itself
- Triggered at:
  - `BubbleWorldScreen`: correct pair match
  - `SteppingStonesScreen`: correct stone tap
  - `VictoryScreen`: on win (larger burst, multiple colors)
  - `StarCatcherScreen`: on star catch (if applicable)

### UI Shimmer
- New widget `ShimmerButton({required Widget child, required VoidCallback onTap})` in `lib/widgets/`
- Wraps the child in a `ClipRRect`; overlays a white gradient stripe that sweeps left→right every 3 s using `AnimationController`
- Used on: `PortalButton`, world cards in `WorldSelectScreen`, "Let's Go!" button in `CharacterSelectScreen`

### Life Lost Pulse
- In `LivesHud`, wrap each heart in an `AnimatedScale` that pulses to 1.4× when a life is lost, then springs back over 300 ms
- Triggered by watching `state.lives` and comparing to previous value

---

## File Summary

| File | Action |
|------|--------|
| `lib/screens/world_select_screen.dart` | New |
| `lib/widgets/bouncing_emoji.dart` | New |
| `lib/widgets/particle_burst.dart` | New |
| `lib/widgets/shimmer_button.dart` | New |
| `lib/models/game_state.dart` | Add `completedWorlds` set, update `completeWorld()` |
| `lib/screens/character_select_screen.dart` | Navigate to `/world-select` on confirm |
| `lib/screens/home_screen.dart` | Skip to `/world-select` if character already selected |
| `lib/worlds/bubble_world.dart` | Balloon speed fix |
| `lib/worlds/stepping_stones_world.dart` | 12 stones, random positions |
| `lib/worlds/tiger_world.dart` | Running bob, tiger expressions, caught flash |
| `lib/widgets/animated_world_background.dart` | Drifting second layer |
| `lib/widgets/lives_hud.dart` | Pulse on life lost |
| `lib/main.dart` | Add `/world-select` route |
| `web/index.html` | Loading spinner, service worker fix |
| All world `_onWin()` callers | Pass `WorldId` to `completeWorld()` |

---

## Out of Scope
- Persistent storage (SharedPreferences) — character and progress reset on app restart; that's a separate feature
- Sound effects or music changes
- New worlds or levels
