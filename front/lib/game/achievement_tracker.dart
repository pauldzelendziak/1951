import 'package:flutter/foundation.dart';
import 'package:knife_hit/data/models/achievement_definition.dart';
import 'package:knife_hit/data/models/knife_catalog.dart';
import 'package:knife_hit/data/models/player_stats.dart';

/// Service that tracks achievements and detects newly unlocked ones
class AchievementTracker {
  AchievementTracker() {
    _previouslyUnlocked = <String>{};
  }

  late Set<String> _previouslyUnlocked;
  final int _totalKnives = KnifeCatalog.all.length;

  /// Check current stats and return newly unlocked achievements
  List<AchievementDefinition> checkForNewAchievements(PlayerStats stats) {
    final List<AchievementDefinition> definitions = AchievementDefinition.definitions();
    final AchievementContext context = AchievementContext(totalKnives: _totalKnives);
    final List<AchievementDefinition> newlyUnlocked = [];

    for (final definition in definitions) {
      final progress = definition.evaluate(stats, context);
      
      // If unlocked and wasn't previously unlocked, it's new!
      if (progress.unlocked && !_previouslyUnlocked.contains(definition.id)) {
        newlyUnlocked.add(definition);
        _previouslyUnlocked.add(definition.id);
        debugPrint('🏆 Achievement unlocked: ${definition.title}');
      }
    }

    return newlyUnlocked;
  }

  /// Initialize with current stats to avoid false positives on first check
  void initialize(PlayerStats stats) {
    final List<AchievementDefinition> definitions = AchievementDefinition.definitions();
    final AchievementContext context = AchievementContext(totalKnives: _totalKnives);

    for (final definition in definitions) {
      final progress = definition.evaluate(stats, context);
      if (progress.unlocked) {
        _previouslyUnlocked.add(definition.id);
      }
    }
  }

  /// Reset tracker (useful for testing)
  void reset() {
    _previouslyUnlocked.clear();
  }
}
