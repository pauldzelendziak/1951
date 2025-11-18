import 'dart:math' as math;

import 'package:knife_hit/core/constants/asset_paths.dart';
import 'package:knife_hit/game/boss_levels.dart';

/// Describes gameplay parameters for a particular level.
class LevelSettings {
  const LevelSettings({
    required this.knifeCount,
    required this.rotationSpeedMinDegPerSec,
    required this.rotationSpeedMaxDegPerSec,
    required this.minimumApples,
    required this.maximumApples,
    this.directionChangeIntervalMinSec,
    this.directionChangeIntervalMaxSec,
    this.targetSpriteAsset = AssetPaths.targetDefaultWood,
    this.bossDefinition,
  });

  /// Number of knives the player must throw this level.
  final int knifeCount;

  /// Minimum rotation speed in degrees per second.
  final double rotationSpeedMinDegPerSec;

  /// Maximum rotation speed in degrees per second.
  final double rotationSpeedMaxDegPerSec;

  /// Minimum number of apples that should appear.
  final int minimumApples;

  /// Maximum number of apples that may appear.
  final int maximumApples;

  /// Minimum time between target direction flips (seconds).
  final double? directionChangeIntervalMinSec;

  /// Maximum time between target direction flips (seconds).
  final double? directionChangeIntervalMaxSec;

  /// Target sprite asset used for this level.
  final String targetSpriteAsset;

  /// Optional boss descriptor when this level is a milestone encounter.
  final BossLevelDefinition? bossDefinition;

  /// Whether the level features a boss battle.
  bool get isBossLevel => bossDefinition != null;

  /// Whether the level should schedule direction changes for the target.
  bool get hasDirectionChanges =>
      directionChangeIntervalMinSec != null &&
      directionChangeIntervalMaxSec != null;

  /// Picks a random rotation speed (deg/sec) within the configured bounds.
  double randomRotationSpeed(math.Random random) {
    if ((rotationSpeedMaxDegPerSec - rotationSpeedMinDegPerSec).abs() <
        1e-6) {
      return rotationSpeedMinDegPerSec;
    }
    final double span = rotationSpeedMaxDegPerSec - rotationSpeedMinDegPerSec;
    return rotationSpeedMinDegPerSec + random.nextDouble() * span;
  }

  /// Picks a random interval (seconds) for the next direction change.
  double? randomDirectionChangeInterval(math.Random random) {
    if (!hasDirectionChanges) {
      return null;
    }
    final double min = directionChangeIntervalMinSec!;
    final double max = directionChangeIntervalMaxSec!;
    if ((max - min).abs() < 1e-6) {
      return min;
    }
    return min + random.nextDouble() * (max - min);
  }

  /// Picks a random apple count for the level.
  int randomAppleCount(math.Random random) {
    if (maximumApples <= minimumApples) {
      return minimumApples;
    }
    return minimumApples + random.nextInt((maximumApples - minimumApples) + 1);
  }

  LevelSettings copyWith({
    int? knifeCount,
    double? rotationSpeedMinDegPerSec,
    double? rotationSpeedMaxDegPerSec,
    int? minimumApples,
    int? maximumApples,
    double? directionChangeIntervalMinSec,
    double? directionChangeIntervalMaxSec,
    String? targetSpriteAsset,
    BossLevelDefinition? bossDefinition,
  }) {
    return LevelSettings(
      knifeCount: knifeCount ?? this.knifeCount,
      rotationSpeedMinDegPerSec:
          rotationSpeedMinDegPerSec ?? this.rotationSpeedMinDegPerSec,
      rotationSpeedMaxDegPerSec:
          rotationSpeedMaxDegPerSec ?? this.rotationSpeedMaxDegPerSec,
      minimumApples: minimumApples ?? this.minimumApples,
      maximumApples: maximumApples ?? this.maximumApples,
      directionChangeIntervalMinSec:
          directionChangeIntervalMinSec ?? this.directionChangeIntervalMinSec,
      directionChangeIntervalMaxSec:
          directionChangeIntervalMaxSec ?? this.directionChangeIntervalMaxSec,
      targetSpriteAsset: targetSpriteAsset ?? this.targetSpriteAsset,
      bossDefinition: bossDefinition ?? this.bossDefinition,
    );
  }

  /// Returns level settings matching [level] based on the difficulty table.
  static LevelSettings forLevel(int level) {
    final LevelSettings base;
    if (level <= 5) {
      base = const LevelSettings(
        knifeCount: 7,
        rotationSpeedMinDegPerSec: 60,
        rotationSpeedMaxDegPerSec: 60,
        minimumApples: 0,
        maximumApples: 1,
      );
    } else if (level <= 10) {
      base = const LevelSettings(
        knifeCount: 8,
        rotationSpeedMinDegPerSec: 80,
        rotationSpeedMaxDegPerSec: 80,
        minimumApples: 0,
        maximumApples: 2,
        directionChangeIntervalMinSec: 5.0,
        directionChangeIntervalMaxSec: 7.0,
      );
    } else if (level <= 15) {
      base = const LevelSettings(
        knifeCount: 9,
        rotationSpeedMinDegPerSec: 100,
        rotationSpeedMaxDegPerSec: 100,
        minimumApples: 0,
        maximumApples: 2,
        directionChangeIntervalMinSec: 3.5,
        directionChangeIntervalMaxSec: 5.0,
      );
    } else if (level <= 20) {
      base = const LevelSettings(
        knifeCount: 10,
        rotationSpeedMinDegPerSec: 120,
        rotationSpeedMaxDegPerSec: 120,
        minimumApples: 1,
        maximumApples: 2,
        directionChangeIntervalMinSec: 1.8,
        directionChangeIntervalMaxSec: 3.0,
      );
    } else if (level <= 30) {
      base = const LevelSettings(
        knifeCount: 11,
        rotationSpeedMinDegPerSec: 140,
        rotationSpeedMaxDegPerSec: 140,
        minimumApples: 1,
        maximumApples: 2,
        directionChangeIntervalMinSec: 1.2,
        directionChangeIntervalMaxSec: 2.0,
      );
    } else {
      base = const LevelSettings(
        knifeCount: 12,
        rotationSpeedMinDegPerSec: 150,
        rotationSpeedMaxDegPerSec: 165,
        minimumApples: 1,
        maximumApples: 2,
        directionChangeIntervalMinSec: 0.6,
        directionChangeIntervalMaxSec: 1.0,
      );
    }

    final BossLevelDefinition? boss =
        BossLevels.definitionForLevel(level);
    if (boss == null) {
      return base;
    }

    final BossRotationPattern pattern = boss.rotationPattern;
    return base.copyWith(
      knifeCount: base.knifeCount + boss.extraKnives,
      rotationSpeedMinDegPerSec: pattern.minSpeedDegPerSec,
      rotationSpeedMaxDegPerSec: pattern.maxSpeedDegPerSec,
      directionChangeIntervalMinSec:
          pattern.directionChangeIntervalMinSec ??
              base.directionChangeIntervalMinSec,
      directionChangeIntervalMaxSec:
          pattern.directionChangeIntervalMaxSec ??
              base.directionChangeIntervalMaxSec,
      minimumApples: 0,
      maximumApples: 0,
      bossDefinition: boss,
      targetSpriteAsset: boss.targetAsset,
    );
  }
}
