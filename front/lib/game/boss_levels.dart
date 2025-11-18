import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:knife_hit/core/constants/asset_paths.dart';

/// Describes a milestone boss level with its presentation and rewards.
@immutable
class BossLevelDefinition {
  const BossLevelDefinition({
    required this.level,
    required this.targetAsset,
    required this.rewardKnifeAsset,
    this.extraKnives = 3,
    this.appleCoinReward = 5,
    this.rotationPattern = const BossRotationPattern(),
  });

  final int level;
  final String targetAsset;
  final String rewardKnifeAsset;
  final int extraKnives;
  final int appleCoinReward;
  final BossRotationPattern rotationPattern;
}

/// Defines how the target behaves on a boss level.
@immutable
class BossRotationPattern {
  const BossRotationPattern({
    this.minSpeedDegPerSec = 5,
    this.maxSpeedDegPerSec = 10,
    this.accelerationDegPerSec2 = 90,
    this.speedHoldDurationMinSec = 3,
    this.speedHoldDurationMaxSec = 6.0,
    this.directionFlipProbability = 0.25,
    this.directionChangeIntervalMinSec,
    this.directionChangeIntervalMaxSec,
  }) : assert(minSpeedDegPerSec > 0),
        assert(maxSpeedDegPerSec >= minSpeedDegPerSec),
        assert(accelerationDegPerSec2 >= 0),
        assert(speedHoldDurationMinSec > 0),
        assert(speedHoldDurationMaxSec >= speedHoldDurationMinSec),
        assert(directionFlipProbability >= 0 && directionFlipProbability <= 1);

  final double minSpeedDegPerSec;
  final double maxSpeedDegPerSec;
  final double accelerationDegPerSec2;
  final double speedHoldDurationMinSec;
  final double speedHoldDurationMaxSec;
  final double directionFlipProbability;
  final double? directionChangeIntervalMinSec;
  final double? directionChangeIntervalMaxSec;

  double randomSpeed(math.Random random) {
    if ((maxSpeedDegPerSec - minSpeedDegPerSec).abs() < 1e-6) {
      return minSpeedDegPerSec;
    }
    return minSpeedDegPerSec +
        random.nextDouble() * (maxSpeedDegPerSec - minSpeedDegPerSec);
  }

  double randomHoldDuration(math.Random random) {
    if ((speedHoldDurationMaxSec - speedHoldDurationMinSec).abs() < 1e-6) {
      return speedHoldDurationMinSec;
    }
    return speedHoldDurationMinSec +
        random.nextDouble() *
            (speedHoldDurationMaxSec - speedHoldDurationMinSec);
  }
}

/// Tracks whether specific boss levels were cleared and which rewards unlocked.
class BossProgressTracker {
  BossProgressTracker()
      : _progress = {
          for (final def in BossLevels.definitions)
            def.level: BossLevelProgress(definition: def),
        };

  final Map<int, BossLevelProgress> _progress;

  UnmodifiableMapView<int, BossLevelProgress> get entries =>
      UnmodifiableMapView(_progress);

  bool isBossLevel(int level) => _progress.containsKey(level);

  BossLevelDefinition? definitionForLevel(int level) =>
      _progress[level]?.definition;

  BossLevelProgress progressForLevel(int level) =>
      _progress[level] ??
      (throw ArgumentError('Level $level does not map to a boss encounter'));

  /// Marks the boss [level] as defeated and returns the updated progress entry.
  BossLevelProgress markBossDefeated(int level) {
    final entry = progressForLevel(level);
    if (entry.defeated) {
      return entry;
    }
    final updated = entry.copyWith(
      defeated: true,
      defeatedAt: DateTime.now(),
    );
    _progress[level] = updated;
    return updated;
  }

  void applyDefeatedLevels(Set<int> defeatedLevels) {
    for (final BossLevelDefinition definition in BossLevels.definitions) {
      final bool defeated = defeatedLevels.contains(definition.level);
      final BossLevelProgress? previous = _progress[definition.level];
      _progress[definition.level] = BossLevelProgress(
        definition: definition,
        defeated: defeated,
        defeatedAt: defeated ? previous?.defeatedAt : null,
      );
    }
  }

  Set<int> defeatedLevelIds() {
    return {
      for (final MapEntry<int, BossLevelProgress> entry in _progress.entries)
        if (entry.value.defeated) entry.key,
    };
  }
}

/// Immutable snapshot of a boss level's progress state.
@immutable
class BossLevelProgress {
  const BossLevelProgress({
    required this.definition,
    this.defeated = false,
    this.defeatedAt,
  });

  final BossLevelDefinition definition;
  final bool defeated;
  final DateTime? defeatedAt;

  BossLevelProgress copyWith({
    bool? defeated,
    DateTime? defeatedAt,
  }) {
    return BossLevelProgress(
      definition: definition,
      defeated: defeated ?? this.defeated,
      defeatedAt: defeatedAt ?? this.defeatedAt,
    );
  }
}

/// Static registry with all milestone boss definitions.
abstract class BossLevels {
  static const List<BossLevelDefinition> definitions = [
    BossLevelDefinition(
      level: 5,
      targetAsset: AssetPaths.targetBossCheese,
      rewardKnifeAsset: AssetPaths.knifeBossCheese,
      extraKnives: 3,
      rotationPattern: BossRotationPattern(
        minSpeedDegPerSec: 80,
        maxSpeedDegPerSec: 130,
        accelerationDegPerSec2: 160,
        speedHoldDurationMinSec: 1.8,
        speedHoldDurationMaxSec: 2.8,
        directionFlipProbability: 0.2,
        directionChangeIntervalMinSec: 1.4,
        directionChangeIntervalMaxSec: 2.2,
      ),
    ),
    BossLevelDefinition(
      level: 10,
      targetAsset: AssetPaths.targetBossTomato,
      rewardKnifeAsset: AssetPaths.knifeBossTomato,
      extraKnives: 3,
      rotationPattern: BossRotationPattern(
        minSpeedDegPerSec: 95,
        maxSpeedDegPerSec: 145,
        accelerationDegPerSec2: 180,
        speedHoldDurationMinSec: 1.7,
        speedHoldDurationMaxSec: 2.6,
        directionFlipProbability: 0.25,
        directionChangeIntervalMinSec: 1.2,
        directionChangeIntervalMaxSec: 2.0,
      ),
    ),
    BossLevelDefinition(
      level: 15,
      targetAsset: AssetPaths.targetBossLemon,
      rewardKnifeAsset: AssetPaths.knifeBossLemon,
      extraKnives: 4,
      rotationPattern: BossRotationPattern(
        minSpeedDegPerSec: 100,
        maxSpeedDegPerSec: 160,
        accelerationDegPerSec2: 200,
        speedHoldDurationMinSec: 1.6,
        speedHoldDurationMaxSec: 2.4,
        directionFlipProbability: 0.3,
        directionChangeIntervalMinSec: 1.0,
        directionChangeIntervalMaxSec: 1.8,
      ),
    ),
    BossLevelDefinition(
      level: 20,
      targetAsset: AssetPaths.targetBossSushi,
      rewardKnifeAsset: AssetPaths.knifeBossSushi,
      extraKnives: 4,
      rotationPattern: BossRotationPattern(
        minSpeedDegPerSec: 105,
        maxSpeedDegPerSec: 170,
        accelerationDegPerSec2: 220,
        speedHoldDurationMinSec: 1.5,
        speedHoldDurationMaxSec: 2.3,
        directionFlipProbability: 0.35,
        directionChangeIntervalMinSec: 0.9,
        directionChangeIntervalMaxSec: 1.6,
      ),
    ),
    BossLevelDefinition(
      level: 25,
      targetAsset: AssetPaths.targetBossDonut,
      rewardKnifeAsset: AssetPaths.knifeBossDonut,
      extraKnives: 4,
      rotationPattern: BossRotationPattern(
        minSpeedDegPerSec: 110,
        maxSpeedDegPerSec: 175,
        accelerationDegPerSec2: 230,
        speedHoldDurationMinSec: 1.4,
        speedHoldDurationMaxSec: 2.1,
        directionFlipProbability: 0.38,
        directionChangeIntervalMinSec: 0.8,
        directionChangeIntervalMaxSec: 1.5,
      ),
    ),
    BossLevelDefinition(
      level: 30,
      targetAsset: AssetPaths.targetBossTire,
      rewardKnifeAsset: AssetPaths.knifeBossGear,
      extraKnives: 5,
      rotationPattern: BossRotationPattern(
        minSpeedDegPerSec: 115,
        maxSpeedDegPerSec: 185,
        accelerationDegPerSec2: 240,
        speedHoldDurationMinSec: 1.3,
        speedHoldDurationMaxSec: 2.0,
        directionFlipProbability: 0.4,
        directionChangeIntervalMinSec: 0.7,
        directionChangeIntervalMaxSec: 1.4,
      ),
    ),
    BossLevelDefinition(
      level: 35,
      targetAsset: AssetPaths.targetBossShield,
      rewardKnifeAsset: AssetPaths.knifeBossShield,
      extraKnives: 5,
      rotationPattern: BossRotationPattern(
        minSpeedDegPerSec: 120,
        maxSpeedDegPerSec: 190,
        accelerationDegPerSec2: 250,
        speedHoldDurationMinSec: 1.2,
        speedHoldDurationMaxSec: 1.9,
        directionFlipProbability: 0.45,
        directionChangeIntervalMinSec: 0.6,
        directionChangeIntervalMaxSec: 1.2,
      ),
    ),
    BossLevelDefinition(
      level: 40,
      targetAsset: AssetPaths.targetBossVynil,
      rewardKnifeAsset: AssetPaths.knifeBossVynil,
      extraKnives: 5,
      rotationPattern: BossRotationPattern(
        minSpeedDegPerSec: 125,
        maxSpeedDegPerSec: 195,
        accelerationDegPerSec2: 260,
        speedHoldDurationMinSec: 1.1,
        speedHoldDurationMaxSec: 1.8,
        directionFlipProbability: 0.5,
        directionChangeIntervalMinSec: 0.6,
        directionChangeIntervalMaxSec: 1.1,
      ),
    ),
    BossLevelDefinition(
      level: 45,
      targetAsset: AssetPaths.targetBossTire,
      rewardKnifeAsset: AssetPaths.knifeBossGear,
      extraKnives: 5,
      rotationPattern: BossRotationPattern(
        minSpeedDegPerSec: 130,
        maxSpeedDegPerSec: 200,
        accelerationDegPerSec2: 270,
        speedHoldDurationMinSec: 1.0,
        speedHoldDurationMaxSec: 1.7,
        directionFlipProbability: 0.55,
        directionChangeIntervalMinSec: 0.5,
        directionChangeIntervalMaxSec: 1.0,
      ),
    ),
    BossLevelDefinition(
      level: 50,
      targetAsset: AssetPaths.targetBossCompass,
      rewardKnifeAsset: AssetPaths.knifeBossCompass,
      extraKnives: 1,
      rotationPattern: BossRotationPattern(
        minSpeedDegPerSec: 10,
        maxSpeedDegPerSec: 210,
        accelerationDegPerSec2: 280,
        speedHoldDurationMinSec: 1.0,
        speedHoldDurationMaxSec: 1.6,
        directionFlipProbability: 0.6,
        directionChangeIntervalMinSec: 0.5,
        directionChangeIntervalMaxSec: 0.9,
      ),
    ),
  ];

  static BossLevelDefinition? definitionForLevel(int level) {
    for (final def in definitions) {
      if (def.level == level) {
        return def;
      }
    }
    return null;
  }
}
