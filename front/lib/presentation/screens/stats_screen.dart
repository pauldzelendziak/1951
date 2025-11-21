import 'package:flutter/material.dart';

import 'package:knife_hit/core/constants/colors.dart';
import 'package:knife_hit/data/models/player_stats.dart';
import 'package:knife_hit/data/storage/player_stats_storage.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final PlayerStatsStorage _storage = const PlayerStatsStorage();
  PlayerStats _stats = PlayerStats.zero;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final PlayerStats stats = await _storage.read();
    if (!mounted) {
      return;
    }
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF120D1C), Color(0xFF1F2B30)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _StatsContent(stats: _stats),
          ),
        ),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<_StatCardData> cards = [
      _StatCardData(
        title: 'Total Score',
        value: _formatNumber(stats.totalScore),
        subtitle: 'Overall points earned',
        icon: Icons.scoreboard_outlined,
        accentColor: Colors.greenAccent.shade400,
      ),
      _StatCardData(
        title: 'High Score',
        value: _formatNumber(stats.highScore),
        subtitle: 'Best single run',
        icon: Icons.military_tech_outlined,
        accentColor: Colors.greenAccent.shade200,
      ),
      _StatCardData(
        title: 'Total Knives Thrown',
        value: _formatNumber(stats.totalKnivesThrown),
        subtitle: 'Lifetime throws',
        icon: Icons.radar_outlined,
        accentColor: Colors.tealAccent.shade400,
      ),
      _StatCardData(
        title: 'Successful Hits',
        value: _formatNumber(stats.successfulHits),
        subtitle: 'Stuck knives',
        icon: Icons.adjust_outlined,
        accentColor: Colors.lightGreenAccent.shade400,
      ),
      _StatCardData(
        title: 'Accuracy',
        value: _formatPercentage(stats.computedAccuracy),
        subtitle: 'Hits vs throws',
        icon: Icons.speed_outlined,
        accentColor: Colors.green.shade400,
      ),
      _StatCardData(
        title: 'Total Apples Hit',
        value: _formatNumber(stats.totalApplesHit),
        subtitle: 'Sliced bonus fruit',
        icon: Icons.local_pizza_outlined,
        accentColor: Colors.lightGreenAccent.shade700,
      ),
      _StatCardData(
        title: 'Max Level Reached',
        value: stats.maxLevelReached.toString(),
        subtitle: 'Deepest progression',
        icon: Icons.terrain_outlined,
        accentColor: Colors.greenAccent.shade700,
      ),
      _StatCardData(
        title: 'Boss Fights Won',
        value: _formatNumber(stats.bossFightsWon),
        subtitle: 'Defeated bosses',
        icon: Icons.auto_awesome_outlined,
        accentColor: Colors.limeAccent.shade400,
      ),
      _StatCardData(
        title: 'Total Playtime',
        value: _formatPlaytime(stats.totalPlaytimeMinutes),
        subtitle: 'Across all sessions',
        icon: Icons.schedule_outlined,
        accentColor: Colors.cyanAccent.shade400,
      ),
      _StatCardData(
        title: 'Games Played',
        value: _formatNumber(stats.gamesPlayed),
        subtitle: 'Sessions started',
        icon: Icons.play_circle_outline,
        accentColor: Colors.greenAccent.shade100,
      ),
      _StatCardData(
        title: 'Knives Unlocked',
        value: _formatNumber(stats.knivesUnlocked),
        subtitle: 'Collection progress',
        icon: Icons.kitchen_outlined,
        accentColor: Colors.greenAccent.shade200,
      ),
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Player Stats',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final _StatCardData card = cards[index];
                return _StatCard(data: card);
              },
              childCount: cards.length,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  static String _formatPercentage(double percent) {
    if (percent.isNaN || percent.isInfinite) {
      return '0%';
    }
    return '${percent.clamp(0, 100).toStringAsFixed(1)}%';
  }

  static String _formatPlaytime(int minutes) {
    if (minutes <= 0) {
      return '0m';
    }
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;
    if (hours == 0) {
      return '${remainingMinutes}m';
    }
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }
}

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double orientationFactor =
            constraints.maxHeight > constraints.maxWidth ? 0.84 : 0.72;
        final double dynamicFontScale = constraints.biggest.shortestSide / 180;
        final double baseFontScale = dynamicFontScale.clamp(0.72, 1.05);
        final double paddingScale = baseFontScale.clamp(0.85, 1.15);
        final double gapScale = baseFontScale.clamp(0.75, 1.0);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: data.accentColor.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: data.accentColor.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(18.0 * paddingScale.clamp(0.9, 1.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: data.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(12 * paddingScale),
                child: Icon(
                  data.icon,
                  color: data.accentColor,
                  size: 28 * paddingScale.clamp(0.85, 1.1),
                ),
              ),
              SizedBox(height: 12 * gapScale),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.value,
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: (textTheme.headlineMedium?.fontSize ?? 28) *
                          orientationFactor *
                          baseFontScale,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6 * gapScale),
                  Text(
                    data.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: data.accentColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      fontSize:
                          (textTheme.titleSmall?.fontSize ?? 14) * baseFontScale,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * gapScale),
                  Text(
                    data.subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.7),
                      letterSpacing: 0.4,
                      fontSize:
                          (textTheme.bodySmall?.fontSize ?? 12) * baseFontScale,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
