import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:knife_hit/core/constants/asset_paths.dart';
import 'package:knife_hit/data/models/knife_catalog.dart';
import 'package:knife_hit/data/models/player_stats.dart';

enum AchievementTier { basic, intermediate, advanced, extreme }

enum _ProgressDisplay { count, percent, custom }

@immutable
class AchievementContext {
  const AchievementContext({required this.totalKnives});

  final int totalKnives;
}

@immutable
class AchievementProgress {
  const AchievementProgress({
    required this.definition,
    required this.progress,
    required this.progressLabel,
    required this.unlocked,
  });

  final AchievementDefinition definition;
  final double progress;
  final String progressLabel;
  final bool unlocked;
}

typedef _CustomBuilder = AchievementProgress Function(
  PlayerStats stats,
  AchievementContext context,
  AchievementDefinition definition,
);

@immutable
class AchievementDefinition {
  const AchievementDefinition._({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.tier,
    AchievementMetric? metric,
    double target = 0,
    _ProgressDisplay display = _ProgressDisplay.count,
    _CustomBuilder? customBuilder,
  })  : _metric = metric,
        _target = target,
        _displayType = display,
        _customBuilder = customBuilder;

  factory AchievementDefinition.metric({
    required String id,
    required String title,
    required String description,
    required String iconAsset,
    required AchievementTier tier,
    required AchievementMetric metric,
    required double target,
    _ProgressDisplay display = _ProgressDisplay.count,
  }) {
    return AchievementDefinition._(
      id: id,
      title: title,
      description: description,
      iconAsset: iconAsset,
      tier: tier,
      metric: metric,
      target: target,
      display: display,
    );
  }

  factory AchievementDefinition.custom({
    required String id,
    required String title,
    required String description,
    required String iconAsset,
    required AchievementTier tier,
    required _CustomBuilder builder,
  }) {
    return AchievementDefinition._(
      id: id,
      title: title,
      description: description,
      iconAsset: iconAsset,
      tier: tier,
      display: _ProgressDisplay.custom,
      customBuilder: builder,
    );
  }

  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final AchievementTier tier;

  final AchievementMetric? _metric;
  final double _target;
  final _ProgressDisplay _displayType;
  final _CustomBuilder? _customBuilder;

  AchievementProgress evaluate(PlayerStats stats, AchievementContext context) {
    final _CustomBuilder? builder = _customBuilder;
    if (builder != null) {
      return builder(stats, context, this);
    }
    final double target = _resolveTarget(context);
    final double current = _resolveCurrent(stats);
    final double ratio = target <= 0 ? (current > 0 ? 1 : 0) : (current / target);
    final double clamped = ratio.clamp(0, 1);
    final bool unlocked = target <= 0 ? current > 0 : current >= target;
    final String progressLabel = _buildProgressLabel(current, target);
    return AchievementProgress(
      definition: this,
      progress: clamped,
      progressLabel: progressLabel,
      unlocked: unlocked,
    );
  }

  double _resolveTarget(AchievementContext context) =>
      _metric == AchievementMetric.knivesUnlocked && _target == 0
          ? context.totalKnives.toDouble()
          : _target;

  double _resolveCurrent(PlayerStats stats) {
    switch (_metric) {
      case AchievementMetric.totalScore:
        return stats.totalScore.toDouble();
      case AchievementMetric.knivesThrown:
        return stats.totalKnivesThrown.toDouble();
      case AchievementMetric.applesHit:
        return stats.totalApplesHit.toDouble();
      case AchievementMetric.bossesDefeated:
        return stats.bossFightsWon.toDouble();
      case AchievementMetric.maxLevel:
        return stats.maxLevelReached.toDouble();
      case AchievementMetric.accuracy:
        return stats.computedAccuracy;
      case AchievementMetric.knivesUnlocked:
        return stats.knivesUnlocked.toDouble();
      case null:
        return 0;
    }
  }

  String _buildProgressLabel(double current, double target) {
    switch (_displayType) {
      case _ProgressDisplay.count:
        final int targetInt = target.round();
        final int currentInt = math.min(current.round(), targetInt);
        return '$currentInt/$targetInt';
      case _ProgressDisplay.percent:
        final double cappedCurrent = math.min(current, target);
        return '${cappedCurrent.toStringAsFixed(0)}% / ${target.toStringAsFixed(0)}%';
      case _ProgressDisplay.custom:
        return '';
    }
  }

  static List<AchievementDefinition> definitions() {
    final int totalKnives = KnifeCatalog.all.length;
    return [
      AchievementDefinition.metric(
        id: 'first_blood',
        title: 'First Blood',
        description: 'Throw your first knife',
        iconAsset: AssetPaths.achievementFirstBlood,
        tier: AchievementTier.basic,
        metric: AchievementMetric.knivesThrown,
        target: 1,
      ),
      AchievementDefinition.metric(
        id: 'apple_slayer',
        title: 'Apple Slayer',
        description: 'Hit 10 apples',
        iconAsset: AssetPaths.achievementAppleSlayer,
        tier: AchievementTier.basic,
        metric: AchievementMetric.applesHit,
        target: 10,
      ),
      AchievementDefinition.metric(
        id: 'apprentice',
        title: 'Apprentice',
        description: 'Reach level 5',
        iconAsset: AssetPaths.achievementApprentice,
        tier: AchievementTier.basic,
        metric: AchievementMetric.maxLevel,
        target: 5,
      ),
      AchievementDefinition.metric(
        id: 'accurate',
        title: 'Accurate',
        description: 'Reach 80% accuracy overall',
        iconAsset: AssetPaths.achievementAccurate,
        tier: AchievementTier.basic,
        metric: AchievementMetric.accuracy,
        target: 80,
        display: _ProgressDisplay.percent,
      ),
      AchievementDefinition.metric(
        id: 'boss_hunter',
        title: 'Boss Hunter',
        description: 'Defeat 5 bosses',
        iconAsset: AssetPaths.achievementBossHunter,
        tier: AchievementTier.intermediate,
        metric: AchievementMetric.bossesDefeated,
        target: 5,
      ),
      AchievementDefinition.metric(
        id: 'collector',
        title: 'Collector',
        description: 'Unlock 10 knives',
        iconAsset: AssetPaths.achievementCollector,
        tier: AchievementTier.intermediate,
        metric: AchievementMetric.knivesUnlocked,
        target: 10,
      ),
      AchievementDefinition.metric(
        id: 'apple_maniac',
        title: 'Apple Maniac',
        description: 'Slice 100 apples',
        iconAsset: AssetPaths.achievementAppleManiac,
        tier: AchievementTier.intermediate,
        metric: AchievementMetric.applesHit,
        target: 100,
      ),
      AchievementDefinition.metric(
        id: 'skilled_thrower',
        title: 'Skilled Thrower',
        description: 'Throw 500 knives',
        iconAsset: AssetPaths.achievementSkilledThrower,
        tier: AchievementTier.intermediate,
        metric: AchievementMetric.knivesThrown,
        target: 500,
      ),
      AchievementDefinition.metric(
        id: 'level_25',
        title: 'Level 25',
        description: 'Reach level 25',
        iconAsset: AssetPaths.achievementLevel25,
        tier: AchievementTier.intermediate,
        metric: AchievementMetric.maxLevel,
        target: 25,
      ),
      AchievementDefinition.metric(
        id: 'master_thrower',
        title: 'Master Thrower',
        description: 'Throw 2000 knives',
        iconAsset: AssetPaths.achievementMasterThrower,
        tier: AchievementTier.advanced,
        metric: AchievementMetric.knivesThrown,
        target: 2000,
      ),
      AchievementDefinition.custom(
        id: 'perfect_aim',
        title: 'Perfect Aim',
        description: 'Maintain 100% accuracy with 20 throws',
        iconAsset: AssetPaths.achievementPerfectAim,
        tier: AchievementTier.advanced,
        builder: (stats, context, definition) {
          final double accuracy = stats.computedAccuracy;
          final double accuracyRatio = (accuracy / 100).clamp(0, 1);
          final double throwRatio = stats.totalKnivesThrown >= 20
              ? 1
              : (stats.totalKnivesThrown / 20).clamp(0, 1);
          final double progress = math.min(1, (accuracyRatio + throwRatio) / 2);
          final bool unlocked = stats.totalKnivesThrown >= 20 && accuracy >= 100;
          final String label =
              '${accuracy.toStringAsFixed(0)}% · ${math.min(stats.totalKnivesThrown, 20)}/20';
          return AchievementProgress(
            definition: definition,
            progress: progress,
            progressLabel: label,
            unlocked: unlocked,
          );
        },
      ),
      AchievementDefinition.metric(
        id: 'apple_king',
        title: 'Apple King',
        description: 'Slice 500 apples',
        iconAsset: AssetPaths.achievementAppleKing,
        tier: AchievementTier.advanced,
        metric: AchievementMetric.applesHit,
        target: 500,
      ),
      AchievementDefinition.metric(
        id: 'boss_master',
        title: 'Boss Master',
        description: 'Defeat 20 bosses',
        iconAsset: AssetPaths.achievementBossMaster,
        tier: AchievementTier.advanced,
        metric: AchievementMetric.bossesDefeated,
        target: 20,
      ),
      AchievementDefinition.metric(
        id: 'full_collection',
        title: 'Full Collection',
        description: 'Unlock every knife skin',
        iconAsset: AssetPaths.achievementFullCollection,
        tier: AchievementTier.advanced,
        metric: AchievementMetric.knivesUnlocked,
        target: totalKnives.toDouble(),
      ),
      AchievementDefinition.metric(
        id: 'level_50',
        title: 'Level 50',
        description: 'Reach level 50',
        iconAsset: AssetPaths.achievementLevel50,
        tier: AchievementTier.advanced,
        metric: AchievementMetric.maxLevel,
        target: 50,
      ),
      AchievementDefinition.metric(
        id: 'legend',
        title: 'Legend',
        description: 'Reach level 100',
        iconAsset: AssetPaths.achievementLegend,
        tier: AchievementTier.extreme,
        metric: AchievementMetric.maxLevel,
        target: 100,
      ),
      AchievementDefinition.metric(
        id: 'ultimate_boss',
        title: 'Ultimate Boss',
        description: 'Defeat 50 bosses',
        iconAsset: AssetPaths.achievementUltimateBoss,
        tier: AchievementTier.extreme,
        metric: AchievementMetric.bossesDefeated,
        target: 50,
      ),
      AchievementDefinition.metric(
        id: 'knife_god',
        title: 'Knife God',
        description: 'Throw 10,000 knives',
        iconAsset: AssetPaths.achievementKnifeGod,
        tier: AchievementTier.extreme,
        metric: AchievementMetric.knivesThrown,
        target: 10000,
      ),
      AchievementDefinition.metric(
        id: 'apple_legend',
        title: 'Apple Legend',
        description: 'Slice 2000 apples',
        iconAsset: AssetPaths.achievementAppleLegend,
        tier: AchievementTier.extreme,
        metric: AchievementMetric.applesHit,
        target: 2000,
      ),
    ];
  }
}

enum AchievementMetric {
  totalScore,
  knivesThrown,
  applesHit,
  bossesDefeated,
  maxLevel,
  accuracy,
  knivesUnlocked,
}
