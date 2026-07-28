import 'package:flutter_test/flutter_test.dart';
import 'package:fifis_world_adventures/config/level_configs.dart';

void main() {
  group('BubbleLevelConfig', () {
    test('has exactly 10 levels', () {
      expect(BubbleLevelConfig.maxLevel, 10);
    });

    test('pairsPerLevel has maxLevel entries', () {
      expect(
          BubbleLevelConfig.pairsPerLevel.length, BubbleLevelConfig.maxLevel);
    });

    test('baseDurationMs has maxLevel entries', () {
      expect(
          BubbleLevelConfig.baseDurationMs.length, BubbleLevelConfig.maxLevel);
    });

    test('pairs are monotonically non-decreasing', () {
      for (int i = 1; i < BubbleLevelConfig.pairsPerLevel.length; i++) {
        expect(
          BubbleLevelConfig.pairsPerLevel[i],
          greaterThanOrEqualTo(BubbleLevelConfig.pairsPerLevel[i - 1]),
          reason: 'Level ${i + 1} pairs should be >= Level $i pairs',
        );
      }
    });

    test('durations are monotonically non-increasing', () {
      for (int i = 1; i < BubbleLevelConfig.baseDurationMs.length; i++) {
        expect(
          BubbleLevelConfig.baseDurationMs[i],
          lessThanOrEqualTo(BubbleLevelConfig.baseDurationMs[i - 1]),
          reason: 'Level ${i + 1} duration should be <= Level $i duration',
        );
      }
    });

    test('max pairs fit viewport (pairs <= 20)', () {
      expect(BubbleLevelConfig.pairsPerLevel.last, lessThanOrEqualTo(20));
    });

    test('all durations are positive', () {
      for (final d in BubbleLevelConfig.baseDurationMs) {
        expect(d, greaterThan(0));
      }
    });
  });

  group('StarCatcherLevelConfig', () {
    test('has exactly 10 levels', () {
      expect(StarCatcherLevelConfig.maxLevel, 10);
    });

    test('levelTargets has maxLevel entries', () {
      expect(StarCatcherLevelConfig.levelTargets.length,
          StarCatcherLevelConfig.maxLevel);
    });

    test('levelBaseDy has maxLevel entries', () {
      expect(StarCatcherLevelConfig.levelBaseDy.length,
          StarCatcherLevelConfig.maxLevel);
    });

    test('levelGravity has maxLevel entries', () {
      expect(StarCatcherLevelConfig.levelGravity.length,
          StarCatcherLevelConfig.maxLevel);
    });

    test('levelSpawnMs has maxLevel entries', () {
      expect(StarCatcherLevelConfig.levelSpawnMs.length,
          StarCatcherLevelConfig.maxLevel);
    });

    test('targets are monotonically non-decreasing', () {
      for (int i = 1; i < StarCatcherLevelConfig.levelTargets.length; i++) {
        expect(
          StarCatcherLevelConfig.levelTargets[i],
          greaterThanOrEqualTo(StarCatcherLevelConfig.levelTargets[i - 1]),
          reason: 'Level ${i + 1} target should be >= Level $i target',
        );
      }
    });

    test('base speed is monotonically non-decreasing', () {
      for (int i = 1; i < StarCatcherLevelConfig.levelBaseDy.length; i++) {
        expect(
          StarCatcherLevelConfig.levelBaseDy[i],
          greaterThanOrEqualTo(StarCatcherLevelConfig.levelBaseDy[i - 1]),
          reason: 'Level ${i + 1} speed should be >= Level $i speed',
        );
      }
    });

    test('gravity is monotonically non-decreasing', () {
      for (int i = 1; i < StarCatcherLevelConfig.levelGravity.length; i++) {
        expect(
          StarCatcherLevelConfig.levelGravity[i],
          greaterThanOrEqualTo(StarCatcherLevelConfig.levelGravity[i - 1]),
          reason: 'Level ${i + 1} gravity should be >= Level $i gravity',
        );
      }
    });

    test('spawn interval is monotonically non-increasing', () {
      for (int i = 1; i < StarCatcherLevelConfig.levelSpawnMs.length; i++) {
        expect(
          StarCatcherLevelConfig.levelSpawnMs[i],
          lessThanOrEqualTo(StarCatcherLevelConfig.levelSpawnMs[i - 1]),
          reason: 'Level ${i + 1} spawn ms should be <= Level $i spawn ms',
        );
      }
    });

    test('minimum spawn rate is at least 600ms (saturation guard)', () {
      expect(
          StarCatcherLevelConfig.levelSpawnMs.last, greaterThanOrEqualTo(600));
    });
  });

  group('SteppingStonesLevelConfig', () {
    test('has exactly 10 levels', () {
      expect(SteppingStonesLevelConfig.maxLevel, 10);
    });

    test('stonesPerLevel has maxLevel entries', () {
      expect(SteppingStonesLevelConfig.stonesPerLevel.length,
          SteppingStonesLevelConfig.maxLevel);
    });

    test('stones are monotonically non-decreasing', () {
      for (int i = 1;
          i < SteppingStonesLevelConfig.stonesPerLevel.length;
          i++) {
        expect(
          SteppingStonesLevelConfig.stonesPerLevel[i],
          greaterThanOrEqualTo(SteppingStonesLevelConfig.stonesPerLevel[i - 1]),
          reason: 'Level ${i + 1} stones should be >= Level $i stones',
        );
      }
    });

    test('max stones fit viewport (stones <= 18)', () {
      expect(
          SteppingStonesLevelConfig.stonesPerLevel.last, lessThanOrEqualTo(18));
    });
  });

  group('TreasureHuntLevelConfig', () {
    test('has exactly 10 levels', () {
      expect(TreasureHuntLevelConfig.maxLevel, 10);
    });

    test('timePerLevel has maxLevel entries', () {
      expect(TreasureHuntLevelConfig.timePerLevel.length,
          TreasureHuntLevelConfig.maxLevel);
    });

    test('spotsPerLevel has maxLevel entries', () {
      expect(TreasureHuntLevelConfig.spotsPerLevel.length,
          TreasureHuntLevelConfig.maxLevel);
    });

    test('treasuresPerLevel has maxLevel entries', () {
      expect(TreasureHuntLevelConfig.treasuresPerLevel.length,
          TreasureHuntLevelConfig.maxLevel);
    });

    test('aiSpeedFactor has maxLevel entries', () {
      expect(TreasureHuntLevelConfig.aiSpeedFactor.length,
          TreasureHuntLevelConfig.maxLevel);
    });

    test('aiCountPerLevel has maxLevel entries', () {
      expect(TreasureHuntLevelConfig.aiCountPerLevel.length,
          TreasureHuntLevelConfig.maxLevel);
    });

    test('time is monotonically non-increasing', () {
      for (int i = 1; i < TreasureHuntLevelConfig.timePerLevel.length; i++) {
        expect(
          TreasureHuntLevelConfig.timePerLevel[i],
          lessThanOrEqualTo(TreasureHuntLevelConfig.timePerLevel[i - 1]),
          reason: 'Level ${i + 1} time should be <= Level $i time',
        );
      }
    });

    test('spots are monotonically non-decreasing', () {
      for (int i = 1; i < TreasureHuntLevelConfig.spotsPerLevel.length; i++) {
        expect(
          TreasureHuntLevelConfig.spotsPerLevel[i],
          greaterThanOrEqualTo(TreasureHuntLevelConfig.spotsPerLevel[i - 1]),
          reason: 'Level ${i + 1} spots should be >= Level $i spots',
        );
      }
    });

    test('treasures are monotonically non-decreasing', () {
      for (int i = 1;
          i < TreasureHuntLevelConfig.treasuresPerLevel.length;
          i++) {
        expect(
          TreasureHuntLevelConfig.treasuresPerLevel[i],
          greaterThanOrEqualTo(
              TreasureHuntLevelConfig.treasuresPerLevel[i - 1]),
          reason: 'Level ${i + 1} treasures should be >= Level $i treasures',
        );
      }
    });

    test('AI speed factor is monotonically non-decreasing', () {
      for (int i = 1; i < TreasureHuntLevelConfig.aiSpeedFactor.length; i++) {
        expect(
          TreasureHuntLevelConfig.aiSpeedFactor[i],
          greaterThanOrEqualTo(TreasureHuntLevelConfig.aiSpeedFactor[i - 1]),
          reason: 'Level ${i + 1} AI speed should be >= Level $i AI speed',
        );
      }
    });

    test('AI count is monotonically non-decreasing', () {
      for (int i = 1; i < TreasureHuntLevelConfig.aiCountPerLevel.length; i++) {
        expect(
          TreasureHuntLevelConfig.aiCountPerLevel[i],
          greaterThanOrEqualTo(TreasureHuntLevelConfig.aiCountPerLevel[i - 1]),
          reason: 'Level ${i + 1} AI count should be >= Level $i AI count',
        );
      }
    });

    test('max spots fit viewport (spots <= 35)', () {
      expect(TreasureHuntLevelConfig.spotsPerLevel.last, lessThanOrEqualTo(35));
    });

    test('treasures never exceed spots', () {
      for (int i = 0; i < TreasureHuntLevelConfig.maxLevel; i++) {
        expect(
          TreasureHuntLevelConfig.treasuresPerLevel[i],
          lessThanOrEqualTo(TreasureHuntLevelConfig.spotsPerLevel[i]),
          reason: 'Level ${i + 1} treasures should be <= spots',
        );
      }
    });

    test('AI count never exceeds 3', () {
      for (final count in TreasureHuntLevelConfig.aiCountPerLevel) {
        expect(count, lessThanOrEqualTo(3));
      }
    });

    test('all times are positive', () {
      for (final t in TreasureHuntLevelConfig.timePerLevel) {
        expect(t, greaterThan(0));
      }
    });
  });
}
