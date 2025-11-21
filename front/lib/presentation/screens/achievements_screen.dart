import 'package:flutter/material.dart';

import 'package:knife_hit/core/constants/colors.dart';
import 'package:knife_hit/data/models/achievement_definition.dart';
import 'package:knife_hit/data/models/knife_catalog.dart';
import 'package:knife_hit/data/models/player_stats.dart';
import 'package:knife_hit/data/storage/player_stats_storage.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final PlayerStatsStorage _storage = const PlayerStatsStorage();
  List<AchievementProgress> _achievements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final PlayerStats stats = (await _storage.read()).recalculateAccuracy();
    final List<AchievementDefinition> definitions = AchievementDefinition.definitions();
    final AchievementContext context = AchievementContext(totalKnives: KnifeCatalog.all.length);
    
    setState(() {
      _achievements = definitions
          .map((def) => def.evaluate(stats, context))
          .toList();
      _loading = false;
    });
  }

  int get _unlockedCount => _achievements.where((a) => a.unlocked).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2530),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '[$_unlockedCount/${_achievements.length}]',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                final achievement = _achievements[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AchievementCard(achievement: achievement),
                );
              },
            ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final AchievementProgress achievement;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = achievement.unlocked;
    final Color borderColor = unlocked ? const Color(0xFFFFD700) : Colors.white24;
    final Color bgColor = unlocked 
        ? AppColors.surface.withOpacity(0.9) 
        : AppColors.surface.withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          if (unlocked)
            BoxShadow(
              color: borderColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: unlocked ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor.withOpacity(0.5)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColorFiltered(
                colorFilter: unlocked
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.srcOver)
                    : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                child: Image.asset(
                  achievement.definition.iconAsset,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.emoji_events,
                    color: Colors.white60,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.definition.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      unlocked ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: unlocked ? AppColors.primary : Colors.white38,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.definition.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement.progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          unlocked ? AppColors.primary : Colors.white54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.progressLabel.isEmpty
                          ? (unlocked ? 'Completed' : 'In progress')
                          : achievement.progressLabel,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
