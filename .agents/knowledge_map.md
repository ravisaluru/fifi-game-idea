# Fifi's World Adventures Knowledge Map

This document outlines the architecture, tech stack, and file structure of **Fifi's World Adventures**, a Flutter-based game project designed for kids.

## 🏗️ Tech Stack

* **Framework**: Flutter Web & Mobile (Material 3)
* **Language**: Dart
* **State Management**: `provider` (Observable GameState)
* **Realtime Multiplayer**: `firebase_database` (Firebase Realtime Database)
* **Audio**: `audioplayers` (SFX and background loop music)
* **Game Engine**: `flame`
* **Linting & Code Quality**: Custom strict `analysis_options.yaml`

## 📂 Directory Structure Overview

The project is structured into the standard Flutter layout, utilizing a layered approach:

```text
/
├── .dart_tool/              # Dart tools and cache
├── .firebase/               # Firebase configuration
├── assets/                  # Images, UI elements, fonts, and audio
├── build/                   # Build artifacts
├── docs/                    # Project documentation and specifications
├── lib/                     # Application source code
├── scripts/                 # Utility scripts (start.sh, stop.sh, etc.)
├── test/                    # Automated unit tests
├── web/                     # Web entry point files
└── ...                      # Project manifests (pubspec.yaml, firebase.json, analysis_options.yaml)
```

## 🧩 Core Components (`lib/`)

### `main.dart`
* App initialization and global **Responsive Console Wrapper** that bounds the gameplay into a mobile-app frame (`480px` wide) on desktop browsers.

### `firebase_options.dart`
* Auto-generated Firebase initialization options.

### `models/`
Defines the core data structures and state logic:
* `audio_manager.dart`: Singleton controller for loop music and sfx triggers.
* `character.dart`: Hero character definitions, emojis, and styling.
* `game_state.dart`: Observable core player state (lives, coins, worlds completed).
* `multiplayer_session.dart`: Multiplayer state tracking, AI simulators, and session types.

### `screens/`
Contains the full-screen views of the application:
* `home_screen.dart`: Welcome title screen with audio toggles.
* `character_select_screen.dart`: Carousel hero picker and color palette editor.
* `world_select_screen.dart`: "Choose a World" grid with looping gameplay previews.
* `multiplayer_menu_screen.dart`: Direct route selection for local/online play.
* `lobby_screen.dart`: Firebase online matchmaking lobby (join/host).
* `ai_setup_screen.dart`: Setup menu for local AI multiplayer matches.

### `services/`
Handles external service interactions:
* `multiplayer_service.dart`: Realtime Firebase database synchronization and connection logic.

### `widgets/`
Reusable UI components and overlays:
* `animated_world_background.dart`: Highly optimized ambient sky/grass/meadow layers.
* `portal_button.dart`: Richly styled primary CTA buttons.
* `back_to_menu_button.dart`: Overlay confirmation back button.
* `lives_hud.dart`: Floating hearts HUD.
* `multiplayer_scoreboard.dart`: Scoreboard panel for local/online multiplayer matches.
* `virtual_controls.dart`: Floating analog joystick controller.
* `particle_burst.dart`: Interactive tap particle effects emitter.
* `victory_popup.dart`: Fireworks victory overlay.

### `worlds/`
Contains the logic and views for each of the 7 distinct micro-game worlds:
1. `tiger_world.dart` (Tiger Plains): Red Light, Green Light tapping game.
2. `firefly_world.dart` (Firefly Forest): Memory sequence game.
3. `bubble_world.dart` (Bubble World): Color-matching balloon popping game.
4. `stepping_stones_world.dart` (Stepping Stones): Pathway memory game.
5. `star_catcher_world.dart` (Star Shower): Star-catching tap game.
6. `snake_chase_world.dart` (Snake Grassland): Grid evasion game with dynamic AI.
7. `treasure_hunt_world.dart` (Treasure Hunt): 3D leaf-flipping memory matching race.

## 📝 Key Documentation

* `README.md`: High-level overview of the project, worlds, and setup instructions.
* `DART_FLUTTER_BEST_PRACTICES.md`: Guidelines for Single Responsibility Principle (SRP), DRY, KISS, and memory management in Flutter.
* `docs/superpowers/specs/2026-05-18-game-bugs-and-improvements-design.md`: Design document detailing past bugs and improvements.
