# Fifi's World Adventures 🌟🎮

A magical, interactive, and premium adventure game designed for kids ages 4-8. Built with **Flutter**, **Dart**, **Provider**, and **Firebase**, this game features 7 distinct game worlds, multiplayer gameplay (both local AI and online peer-to-peer), and highly polished animations.

---

## 🌟 Project Overview

**Fifi's World Adventures** is structured to run seamlessly across mobile, tablet, and web viewports. It implements a gorgeous **Responsive Console Viewport** that bounds and centers the gameplay into a high-end mobile-app frame (`480px` wide) on desktop browsers, keeping the layout focused, immersive, and visually consistent.

### 🛠️ Tech Stack
* **Framework**: Flutter Web & Mobile (Material 3)
* **Language**: Dart (Strict type-safety, null-safety)
* **State Management**: `provider` (Observable GameState)
* **Realtime Multiplayer**: `firebase_database` (Firebase Realtime Database)
* **Audio**: `audioplayers` (Polished SFX and ambient background loop music)
* **Linting & Code Quality**: Custom strict `analysis_options.yaml` (Treats missing params/returns as build errors)

---

## 🗺️ The 7 Game Worlds

Each world represents a unique micro-game designed to challenge memory, coordination, and speed:

1. **🐯 Tiger Plains (`WorldId.tiger`)**:
   * **Gameplay**: A suspenseful "Red Light, Green Light" tapping game. Tapping makes your hero run forward.
   * **Mechanics**: You must stop tapping immediately when the light turns **RED** (announced by a tiger roar!). Getting caught moves you backward. Features an tapping cooldown to reward pacing over speed.
2. **🧚 Firefly Forest (`WorldId.firefly`)**:
   * **Gameplay**: A magical repeating memory sequence game.
   * **Mechanics**: Players must watch a group of glowing fireflies flash in order, then tap them in the correct sequence to advance!
3. **🫧 Bubble World (`WorldId.bubble`)**:
   * **Gameplay**: A relaxed, beautiful color-matching game spanning 5 levels.
   * **Mechanics**: Balloons float up slowly at a constant pace. Find and tap matching pairs! Colors are dynamically generated in HSL space for each level to ensure perfect uniqueness (no duplicates!).
4. **🪨 Stepping Stones (`WorldId.stones`)**:
   * **Gameplay**: A pathway memory game spanning 3 difficulty levels.
   * **Mechanics**: Remember the path of glowing stones, then hop your hero from stone to stone in perfect parabolic arcs to reach the safety of the beach!
5. **⭐ Star Shower (`WorldId.star`)**:
   * **Gameplay**: A fast-paced star-catching game spanning 3 levels.
   * **Mechanics**: Direct-tap falling stars before they touch the ground. Your caught-stars score restarts at `0` for each level to track progress cleanly.
6. **🐍 Snake Grassland (`WorldId.snake`)**:
   * **Gameplay**: An action-packed grid evasion game.
   * **Mechanics**: Steer your character to collect food while escaping a slithering snake. Features randomly spawning obstacles (trees, rocks, bushes) that you must navigate around, while the snake AI dynamically paths around obstacles to hunt you!
7. **🪙 Treasure Hunt (`WorldId.treasure`)**:
   * **Gameplay**: A leaf-flipping memory matching race.
   * **Mechanics**: Tap leaves to flip them over in 3D-space, revealing hidden coins underneath. Find all 10 coins before time runs out. Played concurrently against active AI explorers!

---

## 🎨 Premium Visual Elements

* **Interactive Menu Previews**: The **Choose a World** selection screen renders **custom looping micro-animations** of actual gameplay in each card (such as a running hero, glowing firefly vectors, rising/popping bubble streams, and slithering snakes) rather than static assets.
* **Global Back Button**: An elegant semi-transparent overlay widget (`BackToMenuButton`) sits in the top-right corner of all worlds, opening a gorgeous confirmation modal before returning players to the main menu.
* **Fireworks Victory Popup**: Standardized random firework particle-burst system (`VictoryPopup`) overlayed natively in the world stack, completely eliminating redundant screens.

---

## 📐 Project Structure

```bash
lib/
├── main.dart                 # App initialization & global Responsive Console Wrapper
├── models/
│   ├── audio_manager.dart    # Singleton controller for loop music and sfx triggers
│   ├── character.dart        # Hero character definitions, emojis, and styling
│   ├── game_state.dart       # Observable core player state (lives, coins, worlds completed)
│   └── multiplayer_session.dart  # Multiplayer state tracking, AI simulators, and session types
├── screens/
│   ├── ai_setup_screen.dart  # Setup menu for local AI multiplayer matches
│   ├── character_select_screen.dart # Carousel hero picker and color palette editor
│   ├── home_screen.dart      # Welcome title screen with audio toggles
│   ├── lobby_screen.dart     # Firebase online matchmaking lobby (join/host)
│   ├── multiplayer_menu_screen.dart # Direct route selection for local/online play
│   └── world_select_screen.dart # Choose a World grid with looping gameplay previews
├── services/
│   └── multiplayer_service.dart # Realtime Firebase database sync connector
├── widgets/
│   ├── animated_world_background.dart # Highly optimized ambient sky/grass/meadow layers
│   ├── back_to_menu_button.dart # Overlay confirmation back button
│   ├── lives_hud.dart        # Floating hearts HUD
│   ├── multiplayer_scoreboard.dart # Scoreboard panel for local/online multiplayer matches
│   ├── particle_burst.dart   # Interactive tap particle effects emitter
│   ├── portal_button.dart    # Richly styled primary CTA buttons
│   ├── victory_popup.dart    # Fireworks victory overlay
│   └── virtual_controls.dart # Floating analog joystick controller
└── worlds/
    ├── bubble_world.dart     # Bubble World logic
    ├── firefly_world.dart    # Firefly Forest logic
    ├── snake_chase_world.dart # Snake Grassland logic
    ├── star_catcher_world.dart # Star Shower logic
    ├── stepping_stones_world.dart # Stepping Stones logic
    ├── tiger_world.dart      # Tiger Plains logic
    └── treasure_hunt_world.dart # Treasure Hunt logic
```

---

## 🚀 Running Locally

Useful convenience bash scripts are included in the root directory to manage your local development environment:

### 1. Start the Dev Server
Run the local Flutter Web dev server on port `8080` in the background:
```bash
./start.sh
```
Once started, open **`http://localhost:8080`** in your browser to play!

### 2. Stop the Dev Server
Gracefully terminate the background web server process:
```bash
./stop.sh
```

### 3. Check Code Quality
Run static analysis with our strict custom lints:
```bash
flutter analyze
```

### 4. Run Automated Tests
Execute the comprehensive unit test suite:
```bash
flutter test
```

---

## 📜 Architectural Blueprint
For a detailed guide on Single Responsibility Principle (SRP), DRY refactoring patterns, KISS simplicity, and memory management guidelines, refer to [DART_FLUTTER_BEST_PRACTICES.md](file:///Users/rsaluruvenkata/Documents/GitHub/fifi-game-idea/DART_FLUTTER_BEST_PRACTICES.md) in the project root.
