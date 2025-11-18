import 'package:flutter/foundation.dart';

@immutable
class AppleSnapshot {
  const AppleSnapshot({
    required this.angle,
    required this.margin,
  });

  final double angle;
  final double margin;

  Map<String, Object?> toJson() => {
        'angle': angle,
        'margin': margin,
      };

  factory AppleSnapshot.fromJson(Map<String, Object?> json) {
    final num? angleValue = json['angle'] as num?;
    final num? marginValue = json['margin'] as num?;
    return AppleSnapshot(
      angle: angleValue?.toDouble() ?? 0,
      margin: marginValue?.toDouble() ?? 0,
    );
  }
}

@immutable
class StuckKnifeSnapshot {
  const StuckKnifeSnapshot({
    required this.assetKey,
    required this.localX,
    required this.localY,
    required this.angle,
  });

  final String assetKey;
  final double localX;
  final double localY;
  final double angle;

  Map<String, Object?> toJson() => {
        'assetKey': assetKey,
        'localX': localX,
        'localY': localY,
        'angle': angle,
      };

  factory StuckKnifeSnapshot.fromJson(Map<String, Object?> json) {
    final num? xValue = json['localX'] as num?;
    final num? yValue = json['localY'] as num?;
    final num? angleValue = json['angle'] as num?;
    return StuckKnifeSnapshot(
      assetKey: json['assetKey'] as String? ?? '',
      localX: xValue?.toDouble() ?? 0,
      localY: yValue?.toDouble() ?? 0,
      angle: angleValue?.toDouble() ?? 0,
    );
  }
}

@immutable
class TargetStateSnapshot {
  const TargetStateSnapshot({
    required this.angle,
    required this.clockwise,
    required this.rotationSpeed,
    required this.timeUntilDirectionFlip,
    required this.appleSnapshots,
    required this.stuckKnives,
    this.bossCurrentSpeed,
    this.bossTargetSpeed,
    this.bossSpeedTimer,
  });

  final double angle;
  final bool clockwise;
  final double rotationSpeed;
  final double? timeUntilDirectionFlip;
  final List<AppleSnapshot> appleSnapshots;
  final List<StuckKnifeSnapshot> stuckKnives;
  final double? bossCurrentSpeed;
  final double? bossTargetSpeed;
  final double? bossSpeedTimer;

  Map<String, Object?> toJson() => {
        'angle': angle,
        'clockwise': clockwise,
        'rotationSpeed': rotationSpeed,
        'timeUntilDirectionFlip': timeUntilDirectionFlip,
        'appleSnapshots': [
          for (final AppleSnapshot snapshot in appleSnapshots) snapshot.toJson(),
        ],
        'stuckKnives': [
          for (final StuckKnifeSnapshot snapshot in stuckKnives) snapshot.toJson(),
        ],
        'bossCurrentSpeed': bossCurrentSpeed,
        'bossTargetSpeed': bossTargetSpeed,
        'bossSpeedTimer': bossSpeedTimer,
      };

  factory TargetStateSnapshot.fromJson(Map<String, Object?> json) {
    final List<Object?> appleRaw =
        (json['appleSnapshots'] as List<Object?>?) ?? const [];
    final List<Object?> stuckRaw =
        (json['stuckKnives'] as List<Object?>?) ?? const [];
    return TargetStateSnapshot(
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
      clockwise: json['clockwise'] as bool? ?? true,
      rotationSpeed: (json['rotationSpeed'] as num?)?.toDouble() ?? 0,
      timeUntilDirectionFlip:
          (json['timeUntilDirectionFlip'] as num?)?.toDouble(),
      appleSnapshots: [
        for (final Object? entry in appleRaw)
          if (entry is Map<String, Object?>)
            AppleSnapshot.fromJson(entry),
      ],
      stuckKnives: [
        for (final Object? entry in stuckRaw)
          if (entry is Map<String, Object?>)
            StuckKnifeSnapshot.fromJson(entry),
      ],
      bossCurrentSpeed: (json['bossCurrentSpeed'] as num?)?.toDouble(),
      bossTargetSpeed: (json['bossTargetSpeed'] as num?)?.toDouble(),
      bossSpeedTimer: (json['bossSpeedTimer'] as num?)?.toDouble(),
    );
  }
}

@immutable
class LevelStateSnapshot {
  const LevelStateSnapshot({
    required this.levelIndex,
    required this.knivesRemaining,
    required this.initialKnifeCount,
    required this.targetState,
  });

  final int levelIndex;
  final int knivesRemaining;
  final int initialKnifeCount;
  final TargetStateSnapshot targetState;

  Map<String, Object?> toJson() => {
        'levelIndex': levelIndex,
        'knivesRemaining': knivesRemaining,
        'initialKnifeCount': initialKnifeCount,
        'targetState': targetState.toJson(),
      };

  factory LevelStateSnapshot.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> targetRaw =
        (json['targetState'] as Map<String, Object?>?) ?? const {};
    return LevelStateSnapshot(
      levelIndex: json['levelIndex'] as int? ?? 1,
      knivesRemaining: json['knivesRemaining'] as int? ?? 0,
      initialKnifeCount: json['initialKnifeCount'] as int? ?? 0,
      targetState: TargetStateSnapshot.fromJson(targetRaw),
    );
  }
}
