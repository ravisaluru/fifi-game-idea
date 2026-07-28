// Level configuration constants for all mini-game worlds.
//
// Extracted from private widget state into public classes to enable
// direct unit testing of difficulty curves and viewport safety bounds.
//
// Design principle: all games use 10 levels with monotonically increasing
// difficulty, capped at element counts safe for the 480px mobile viewport.

/// Bubble World (color-matching balloon popping game).
///
/// Difficulty levers:
/// - [pairsPerLevel]: number of color pairs to match (2→20)
/// - [baseDurationMs]: bubble float duration — lower = faster = harder (9600→6000)
///
/// Viewport safety: max 20 pairs = 40 bubbles at 70px each in ~480×640 = ~75% fill.
class BubbleLevelConfig {
  BubbleLevelConfig._();

  static const int maxLevel = 10;

  static const List<int> pairsPerLevel = [
    2, // Level 1: Tutorial
    3, // Level 2: Intro
    4, // Level 3: Easy
    6, // Level 4: Medium
    8, // Level 5: Moderate
    10, // Level 6: Challenging
    12, // Level 7: Hard
    14, // Level 8: Very hard
    16, // Level 9: Expert
    20, // Level 10: Master (max safe for 480px viewport)
  ];

  static const List<int> baseDurationMs = [
    9600, // Level 1: Very slow float
    9200, // Level 2
    8800, // Level 3
    8400, // Level 4
    8000, // Level 5
    7600, // Level 6
    7200, // Level 7
    6800, // Level 8
    6400, // Level 9
    6000, // Level 10: Fastest float
  ];
}

/// Star Catcher (star-catching tap game).
///
/// Difficulty levers:
/// - [levelTargets]: stars to catch per level (10→30)
/// - [levelBaseDy]: base downward velocity (0.0008→0.0028)
/// - [levelGravity]: gravity acceleration (0.00006→0.00025)
/// - [levelSpawnMs]: spawn interval in ms — lower = more frequent (1400→600)
///
/// Saturation guard: 600ms floor with ~2s fall time = max ~3-4 stars on screen.
class StarCatcherLevelConfig {
  StarCatcherLevelConfig._();

  static const int maxLevel = 10;

  static const List<int> levelTargets = [
    10, // Level 1
    12, // Level 2
    14, // Level 3
    16, // Level 4
    18, // Level 5
    20, // Level 6
    22, // Level 7
    24, // Level 8
    26, // Level 9
    30, // Level 10
  ];

  static const List<double> levelBaseDy = [
    0.0008, // Level 1: Very slow
    0.001, // Level 2
    0.0012, // Level 3
    0.0014, // Level 4
    0.0016, // Level 5
    0.0018, // Level 6
    0.002, // Level 7
    0.0022, // Level 8
    0.0024, // Level 9
    0.0028, // Level 10: Fastest
  ];

  static const List<double> levelGravity = [
    0.00006, // Level 1
    0.00008, // Level 2
    0.0001, // Level 3
    0.00012, // Level 4
    0.00014, // Level 5
    0.00016, // Level 6
    0.00018, // Level 7
    0.0002, // Level 8
    0.00022, // Level 9
    0.00025, // Level 10
  ];

  static const List<int> levelSpawnMs = [
    1400, // Level 1: Infrequent
    1200, // Level 2
    1100, // Level 3
    1000, // Level 4
    900, // Level 5
    800, // Level 6
    750, // Level 7
    700, // Level 8
    650, // Level 9
    600, // Level 10: 600ms floor prevents saturation
  ];
}

/// Stepping Stones (pathway memory game).
///
/// Difficulty lever:
/// - [stonesPerLevel]: number of stones in the sequence to memorize (4→18)
///
/// Layout safety: 18 stones with 90px min spacing in ~480×480 play area.
/// The _buildPositions algorithm supports ~28 valid positions, so 18 stones
/// gives comfortable margin (64% fill) without hitting 1000-attempt bailout.
class SteppingStonesLevelConfig {
  SteppingStonesLevelConfig._();

  static const int maxLevel = 10;

  static const List<int> stonesPerLevel = [
    4, // Level 1: Tutorial
    6, // Level 2: Easy
    8, // Level 3: Gentle ramp
    9, // Level 4: Medium
    10, // Level 5: Moderate
    12, // Level 6: Challenging
    13, // Level 7: Hard
    15, // Level 8: Very hard
    16, // Level 9: Expert
    18, // Level 10: Master (max safe for 480px viewport)
  ];
}

/// Treasure Hunt (3D leaf-flipping treasure finding race).
///
/// Difficulty levers:
/// - [timePerLevel]: seconds per level — decreasing (90→45)
/// - [spotsPerLevel]: total cover spots (12→35)
/// - [treasuresPerLevel]: hidden treasures per level (5→15)
/// - [aiSpeedFactor]: AI discovery speed multiplier (0.6→1.6)
/// - [aiCountPerLevel]: number of AI opponents (1→3)
///
/// Win/loss per level: compare player's per-level coins vs max AI per-level coins.
/// Player's total coins accumulate across levels for the final reward.
///
/// Viewport safety: 35 spots at ~48px each in 480×520 play area = ~70% fill.
class TreasureHuntLevelConfig {
  TreasureHuntLevelConfig._();

  static const int maxLevel = 10;

  static const List<int> timePerLevel = [
    90, // Level 1
    90, // Level 2
    80, // Level 3
    80, // Level 4
    70, // Level 5
    70, // Level 6
    60, // Level 7
    60, // Level 8
    50, // Level 9
    45, // Level 10
  ];

  static const List<int> spotsPerLevel = [
    12, // Level 1
    16, // Level 2
    18, // Level 3
    20, // Level 4
    22, // Level 5
    25, // Level 6
    28, // Level 7
    30, // Level 8
    32, // Level 9
    35, // Level 10
  ];

  static const List<int> treasuresPerLevel = [
    5, // Level 1
    7, // Level 2
    8, // Level 3
    9, // Level 4
    10, // Level 5
    11, // Level 6
    12, // Level 7
    13, // Level 8
    14, // Level 9
    15, // Level 10
  ];

  static const List<double> aiSpeedFactor = [
    0.6, // Level 1: Slow
    0.7, // Level 2
    0.8, // Level 3
    0.85, // Level 4
    0.9, // Level 5
    1.0, // Level 6: Original speed
    1.1, // Level 7
    1.2, // Level 8
    1.4, // Level 9
    1.6, // Level 10: Very aggressive
  ];

  static const List<int> aiCountPerLevel = [
    1, // Level 1-2: Just Robo
    1, // Level 2
    2, // Level 3-6: Robo + Ghost
    2, // Level 4
    2, // Level 5
    2, // Level 6
    3, // Level 7-10: Robo + Ghost + Fox
    3, // Level 8
    3, // Level 9
    3, // Level 10
  ];
}
