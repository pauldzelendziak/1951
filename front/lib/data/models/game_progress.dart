import 'dart:collection';

import 'package:knife_hit/core/constants/asset_paths.dart';
import 'package:knife_hit/data/models/level_state_snapshot.dart';

class GameProgress {
  const GameProgress({
    required this.levelIndex,
    required this.score,
    required this.appleCoins,
    required this.equippedKnifeAsset,
    required this.unlockedKnifeAssets,
    required this.defeatedBossLevels,
    this.activeLevel,
  });

  final int levelIndex;
  final int score;
  final int appleCoins;
  final String equippedKnifeAsset;
  final Set<String> unlockedKnifeAssets;
  final Set<int> defeatedBossLevels;
  final LevelStateSnapshot? activeLevel;

  static GameProgress initial() {
    return GameProgress(
      levelIndex: 1,
      score: 0,
      appleCoins: 0,
      equippedKnifeAsset: AssetPaths.knifeTanto,
      unlockedKnifeAssets: UnmodifiableSetView({AssetPaths.knifeTanto}),
      defeatedBossLevels: UnmodifiableSetView(<int>{}),
      activeLevel: null,
    );
  }

  bool get hasProgress {
    final bool hasActiveLevelProgress = activeLevel != null &&
      (activeLevel!.levelIndex > 1 ||
        activeLevel!.knivesRemaining < activeLevel!.initialKnifeCount);
    return levelIndex > 1 ||
        score > 0 ||
        appleCoins > 0 ||
        unlockedKnifeAssets.length > 1 ||
      defeatedBossLevels.isNotEmpty ||
      hasActiveLevelProgress;
  }

  GameProgress copyWith({
    int? levelIndex,
    int? score,
    int? appleCoins,
    String? equippedKnifeAsset,
    Set<String>? unlockedKnifeAssets,
    Set<int>? defeatedBossLevels,
    LevelStateSnapshot? activeLevel,
  }) {
    final Set<String> unlocked = unlockedKnifeAssets ?? this.unlockedKnifeAssets;
    final Set<int> defeated = defeatedBossLevels ?? this.defeatedBossLevels;
    return GameProgress(
      levelIndex: levelIndex ?? this.levelIndex,
      score: score ?? this.score,
      appleCoins: appleCoins ?? this.appleCoins,
      equippedKnifeAsset: equippedKnifeAsset ?? this.equippedKnifeAsset,
      unlockedKnifeAssets: UnmodifiableSetView({...unlocked, AssetPaths.knifeTanto}),
      defeatedBossLevels: UnmodifiableSetView({...defeated}),
      activeLevel: activeLevel ?? this.activeLevel,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'levelIndex': levelIndex,
      'score': score,
      'appleCoins': appleCoins,
      'equippedKnifeAsset': equippedKnifeAsset,
      'unlockedKnifeAssets': unlockedKnifeAssets.toList(),
      'defeatedBossLevels': defeatedBossLevels.toList(),
      'activeLevel': activeLevel?.toJson(),
    };
  }

  factory GameProgress.fromJson(Map<String, Object?> json) {
    final int levelIndex = (json['levelIndex'] as int?) ?? 1;
    final int score = (json['score'] as int?) ?? 0;
    final int appleCoins = (json['appleCoins'] as int?) ?? 0;
    final String equippedKnifeAsset =
        (json['equippedKnifeAsset'] as String?) ?? AssetPaths.knifeTanto;
    final List<Object?> unlockedRaw =
        (json['unlockedKnifeAssets'] as List<Object?>?) ?? const [];
    final List<Object?> defeatedRaw =
        (json['defeatedBossLevels'] as List<Object?>?) ?? const [];

    final Set<String> unlocked = {
      for (final Object? value in unlockedRaw)
        if (value is String) value,
    };
    if (unlocked.isEmpty) {
      unlocked.add(AssetPaths.knifeTanto);
    }

    final Set<int> defeated = {
      for (final Object? value in defeatedRaw)
        if (value is int) value,
    };

    final LevelStateSnapshot? activeLevel;
    final Object? levelStateRaw = json['activeLevel'];
    if (levelStateRaw is Map<String, Object?>) {
      activeLevel = LevelStateSnapshot.fromJson(levelStateRaw);
    } else {
      activeLevel = null;
    }

    final int normalizedLevel = levelIndex < 1 ? 1 : levelIndex;
    return GameProgress(
      levelIndex: normalizedLevel,
      score: score,
      appleCoins: appleCoins,
      equippedKnifeAsset: equippedKnifeAsset,
      unlockedKnifeAssets: UnmodifiableSetView({...unlocked, AssetPaths.knifeTanto}),
      defeatedBossLevels: UnmodifiableSetView({...defeated}),
      activeLevel: activeLevel,
    );
  }
}
