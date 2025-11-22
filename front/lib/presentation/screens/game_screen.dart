import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:knife_hit/core/constants/colors.dart';
import 'package:knife_hit/data/models/achievement_definition.dart';
import 'package:knife_hit/data/models/game_progress.dart';
import 'package:knife_hit/data/models/knife_catalog.dart';
import 'package:knife_hit/data/models/player_stats.dart';
import 'package:knife_hit/data/storage/game_progress_storage.dart';
import 'package:knife_hit/data/storage/player_stats_storage.dart';
import 'package:knife_hit/game/achievement_tracker.dart';
import 'package:knife_hit/game/boss_levels.dart';
import 'package:knife_hit/game/level_settings.dart';
import 'package:knife_hit/game/knife_hit_game.dart';
import 'package:knife_hit/presentation/widgets/achievement_notification.dart';
import 'package:knife_hit/presentation/widgets/boss_appear_popup.dart';
import 'package:knife_hit/services/background_music_manager.dart';
import 'package:knife_hit/services/sound_manager.dart';

/// Fullscreen screen that hosts the Flame [KnifeHitGame].
class GameScreen extends StatefulWidget {
  /// Creates a [GameScreen].
  const GameScreen({super.key, this.initialProgress});

  final GameProgress? initialProgress;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final KnifeHitGame _game;
  late final ValueNotifier<int> _appleCoins;
  late final ValueNotifier<int> _knivesLeft;
  late final ValueNotifier<int> _scoreNotifier;
  late final ValueNotifier<bool> _levelCompleteNotifier;
  late final ValueNotifier<bool> _levelFailedNotifier;
  late int _level;
  late int _totalKnives;
  int _lastLevelScore = 0;
  bool _bossRewardDismissed = false;
  bool _returningHome = false;
  final GameProgressStorage _progressStorage = const GameProgressStorage();
  final PlayerStatsStorage _statsStorage = const PlayerStatsStorage();
  final AchievementTracker _achievementTracker = AchievementTracker();
  bool _autosaveScheduled = false;
  late final TextEditingController _levelJumpController;
  late DateTime _sessionStart;
  bool _statsFlushed = false;
  Future<void>? _statsInitFuture;
  Timer? _achievementCheckTimer;

  @override
  void initState() {
    super.initState();
    _level = widget.initialProgress?.levelIndex ?? 1;
    _totalKnives = LevelSettings.forLevel(_level).knifeCount;
    _lastLevelScore = 0;
    // Quick runtime check: try loading the target asset directly from Flutter's
    // asset bundle to ensure the asset is packaged and readable at runtime.
    () async {
      try {
        const key = 'assets/images/targets/default_wood.webp';
        final data = await rootBundle.load(key);
        debugPrint(
          'ASSET CHECK: loaded "$key" with ${data.lengthInBytes} bytes',
        );
      } on Object catch (error, stackTrace) {
        debugPrint(
          'ASSET CHECK: failed to load asset via rootBundle: $error',
        );
        debugPrint('$stackTrace');
      }
    }();

    _game = KnifeHitGame(initialProgress: widget.initialProgress);
    unawaited(SoundManager.instance.init());
    unawaited(BackgroundMusicManager.instance.play(BackgroundTrack.game));
    _appleCoins = _game.appleCoins;
    _knivesLeft = _game.knivesLeft;
    _scoreNotifier = _game.score;
    _levelCompleteNotifier = _game.levelCompleted;
    _levelFailedNotifier = _game.levelFailed;
    _totalKnives = _game.initialKnifeCount;
    _level = _game.levelIndex;
    _levelJumpController = TextEditingController(text: _level.toString());
    _sessionStart = DateTime.now();
    _attachAutosaveListeners();
    _scheduleAutosave();
    _statsInitFuture = _recordGameStart();
    _initializeAchievementTracking();
    _attachBossLevelListener();
  }
  
  Future<void> _initializeAchievementTracking() async {
    // Initialize tracker with current stats to avoid false positives
    final stats = await _statsStorage.read();
    _achievementTracker.initialize(stats);
    
    // Listen to score changes to check achievements in real-time
    _scoreNotifier.addListener(_onScoreChanged);
  }
  
  void _attachBossLevelListener() {
    _game.isBossLevel.addListener(_onBossLevelChanged);
  }
  
  void _onBossLevelChanged() {
    if (!mounted) return;
    if (_game.isBossLevel.value) {
      final int level = _game.levelIndex;
      final BossLevelDefinition? bossDef = BossLevels.definitionForLevel(level);
      if (bossDef != null) {
        unawaited(BackgroundMusicManager.instance.play(BackgroundTrack.boss));
        final String bossName = _getBossName(level);
        // First play boss appear sound, then after a short delay show popup.
        unawaited(SoundManager.instance.play(SoundEffect.bossAppear));
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            BossAppearPopup.show(
              context,
              bossLevel: level,
              bossName: bossName,
            );
          }
        });
      } else {
        unawaited(BackgroundMusicManager.instance.play(BackgroundTrack.game));
      }
    } else {
      unawaited(BackgroundMusicManager.instance.play(BackgroundTrack.game));
    }
  }
  
  String _getBossName(int level) {
    switch (level) {
      case 5:
        return 'Cheese Wheel';
      case 10:
        return 'Tomato King';
      case 15:
        return 'Lemon Lord';
      case 20:
        return 'Sushi Master';
      case 25:
        return 'Donut Emperor';
      case 30:
        return 'Tire Titan';
      case 35:
        return 'Shield Guardian';
      case 40:
        return 'Vinyl Spinner';
      case 45:
        return 'Compass Navigator';
      case 50:
        return 'Final Boss';
      default:
        return 'Boss';
    }
  }
  
  void _onScoreChanged() {
    // Debounce achievement checks to avoid too many calls
    _achievementCheckTimer?.cancel();
    _achievementCheckTimer = Timer(
      const Duration(milliseconds: 500),
      () => _checkAchievements(),
    );
  }
  
  Future<void> _checkAchievements() async {
    if (!mounted) return;
    
    try {
      // Get base stats and add current session data
      final baseStats = await _statsStorage.read();
      final currentStats = baseStats.copyWith(
        totalKnivesThrown: baseStats.totalKnivesThrown + _game.sessionKnivesThrown,
        successfulHits: baseStats.successfulHits + _game.sessionSuccessfulHits,
        totalApplesHit: baseStats.totalApplesHit + _game.sessionApplesHit,
        bossFightsWon: baseStats.bossFightsWon + _game.sessionBossWins,
        maxLevelReached: math.max(baseStats.maxLevelReached, _game.sessionHighestLevelReached),
        totalScore: baseStats.totalScore + _game.sessionScoreEarned,
      ).recalculateAccuracy();
      
      final newAchievements = _achievementTracker.checkForNewAchievements(currentStats);
      
      for (final achievement in newAchievements) {
        if (mounted) {
          AchievementNotification.show(context, achievement);
        }
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  Future<void> _handleNextLevel() async {
    _bossRewardDismissed = false;
    _lastLevelScore = _game.lastLevelScore;
    await _game.startNextLevel();
    setState(() {
      _level = _game.levelIndex;
      _totalKnives = _game.initialKnifeCount;
      _levelJumpController.text = _level.toString();
    });
    _scheduleAutosave();
  }

  Future<void> _handleRetryLevel() async {
    _bossRewardDismissed = false;
    await _game.retryCurrentLevel();
    setState(() {
      _level = _game.levelIndex;
      _totalKnives = _game.initialKnifeCount;
      _levelJumpController.text = _level.toString();
    });
    _scheduleAutosave();
  }

  Future<void> _jumpToLevel(int level) async {
    _bossRewardDismissed = false;
    await _game.jumpToLevel(level);
    setState(() {
      _level = _game.levelIndex;
      _totalKnives = _game.initialKnifeCount;
      _levelJumpController.text = _level.toString();
    });
    _scheduleAutosave();
  }

  Future<void> _promptLevelJump() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    _levelJumpController.text = _level.toString();
    final int? targetLevel = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Jump to level'),
          content: TextField(
            controller: _levelJumpController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Level number',
              hintText: 'Enter target level',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final int? parsed =
                    int.tryParse(_levelJumpController.text.trim());
                if (parsed == null || parsed < 1) {
                  messenger?.showSnackBar(
                    const SnackBar(
                      content: Text('Enter a positive level number'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(parsed);
              },
              child: const Text('Jump'),
            ),
          ],
        );
      },
    );
    if (targetLevel != null) {
      await _jumpToLevel(targetLevel);
    }
  }


  void _attachAutosaveListeners() {
    _appleCoins.addListener(_onProgressChanged);
    _knivesLeft.addListener(_onProgressChanged);
    _scoreNotifier.addListener(_onProgressChanged);
    _levelCompleteNotifier.addListener(_onProgressChanged);
    _levelFailedNotifier.addListener(_onProgressChanged);
  }

  void _removeAutosaveListeners() {
    _appleCoins.removeListener(_onProgressChanged);
    _knivesLeft.removeListener(_onProgressChanged);
    _scoreNotifier.removeListener(_onProgressChanged);
    _levelCompleteNotifier.removeListener(_onProgressChanged);
    _levelFailedNotifier.removeListener(_onProgressChanged);
  }

  Future<void> _recordGameStart() async {
    try {
      await _statsStorage.update((stats) {
        final int knivesUnlocked = _game.unlockedKnifeSkins.value.length;
        return stats.copyWith(
          gamesPlayed: stats.gamesPlayed + 1,
          maxLevelReached: math.max(stats.maxLevelReached, _game.sessionHighestLevelReached),
          knivesUnlocked: math.max(stats.knivesUnlocked, knivesUnlocked),
        );
      });
      // Check for achievements after recording game start
      unawaited(_checkAchievements());
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to update start-of-game stats: $error');
      debugPrint('$stackTrace');
    }
  }

  void _onProgressChanged() {
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    if (_autosaveScheduled) {
      return;
    }
    _autosaveScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      _autosaveScheduled = false;
      unawaited(_saveProgress());
    });
  }

  Future<void> _saveProgress() async {
    final GameProgress snapshot = _game.snapshotProgress();
    try {
      await _progressStorage.write(snapshot);
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to persist game progress: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _returnToHome() async {
    if (_returningHome) {
      return;
    }
    _returningHome = true;
    await _ensureStatsFlushed();
    final GameProgress snapshot = _game.snapshotProgress();
    try {
      await _progressStorage.write(snapshot);
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to persist game progress on exit: $error');
      debugPrint('$stackTrace');
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(snapshot);
  }
  @override
  void dispose() {
    _achievementCheckTimer?.cancel();
    _scoreNotifier.removeListener(_onScoreChanged);
    _game.isBossLevel.removeListener(_onBossLevelChanged);
    _removeAutosaveListeners();
    unawaited(_saveProgress());
    unawaited(_ensureStatsFlushed());
    _levelJumpController.dispose();
    _game.pauseEngine();
    _game.onDetach();
    unawaited(() async {
      await BackgroundMusicManager.instance.stop();
      await BackgroundMusicManager.instance.play(BackgroundTrack.menu);
    }());
    unawaited(SoundManager.instance.stopAll());
    super.dispose();
  }

  Future<void> _ensureStatsFlushed() async {
    if (_statsFlushed) {
      return;
    }
    _statsFlushed = true;
    final Future<void>? initFuture = _statsInitFuture;
    if (initFuture != null) {
      try {
        await initFuture;
      } on Object {
        // Logged earlier.
      }
    }
    final int scoreEarned = _game.sessionScoreEarned;
    final int knivesThrown = _game.sessionKnivesThrown;
    final int successfulHits = _game.sessionSuccessfulHits;
    final int applesHit = _game.sessionApplesHit;
    final int bossWins = _game.sessionBossWins;
    final int highestLevel = _game.sessionHighestLevelReached;
    final int unlockedCount = _game.unlockedKnifeSkins.value.length;
    final Duration sessionDuration = DateTime.now().difference(_sessionStart);
    final int playtimeMinutes = sessionDuration.inMinutes;
    try {
      await _statsStorage.update((stats) {
        return stats.copyWith(
          totalScore: stats.totalScore + scoreEarned,
          highScore: math.max(stats.highScore, scoreEarned),
          totalKnivesThrown: stats.totalKnivesThrown + knivesThrown,
          successfulHits: stats.successfulHits + successfulHits,
          totalApplesHit: stats.totalApplesHit + applesHit,
          bossFightsWon: stats.bossFightsWon + bossWins,
          totalPlaytimeMinutes: stats.totalPlaytimeMinutes + playtimeMinutes,
          maxLevelReached: math.max(stats.maxLevelReached, highestLevel),
          knivesUnlocked: math.max(stats.knivesUnlocked, unlockedCount),
        );
      });
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to persist player stats: $error');
      debugPrint('$stackTrace');
    }
    
    // Check for achievements after stats update
    unawaited(_checkAchievements());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_returningHome) {
          return true;
        }
        await _returnToHome();
        return false;
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder<bool>(
        valueListenable: _game.isBossLevel,
        builder: (context, bossActive, child) {
          final gradientColors = bossActive
              ? const [
                  AppColors.bossGradientStart,
                  AppColors.bossGradientEnd,
                ]
              : const [
                  AppColors.homeGradientStart,
                  AppColors.homeGradientEnd,
                ];
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _game.onUserTap(),
                  child: GameWidget(game: _game),
                ),
            if (kDebugMode)
              Positioned(
                bottom: 24,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _DebugButton(
                      label: 'Win level',
                      onTap: () => _game.debugForceWin(),
                    ),
                    const SizedBox(height: 8),
                    _DebugButton(
                      label: 'Level...',
                      onTap: _promptLevelJump,
                    ),
                  ],
                ),
              ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: _appleCoins,
                      builder: (context, apples, _) => ValueListenableBuilder<int>(
                        valueListenable: _scoreNotifier,
                        builder: (context, score, __) => _ScoreHud(
                          apples: apples,
                          level: _level,
                          score: score,
                          onBack: () => unawaited(_returnToHome()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<int>(
                      valueListenable: _knivesLeft,
                      builder: (context, remaining, child) => _KnifeRack(
                        total: _totalKnives,
                        remaining: remaining,
                        knifeAsset: _game.equippedKnifeAsset,
                      ),
                    ),
                    const Spacer(),
                    const _ThrowHint(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _levelCompleteNotifier,
              builder: (context, completed, _) {
                if (!completed) {
                  return const SizedBox.shrink();
                }
                _lastLevelScore = _game.lastLevelScore;
                final int scoreSnapshot = _lastLevelScore;
                final String? rewardAsset = _game.currentBossRewardAsset;
                final bool showBossReward =
                    rewardAsset != null && !_bossRewardDismissed;
                if (showBossReward) {
                  final KnifeSkinInfo? info =
                      KnifeCatalog.findByAsset(rewardAsset);
                  return _BossRewardOverlay(
                    rewardName: info?.name ?? 'New Blade',
                    imageAsset: 'assets/images/$rewardAsset',
                    onDismissed: () => setState(() {
                      _bossRewardDismissed = true;
                    }),
                  );
                }
                return _LevelCompleteOverlay(
                  score: scoreSnapshot,
                  onNext: _handleNextLevel,
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _levelFailedNotifier,
              builder: (context, failed, _) {
                if (!failed) {
                  return const SizedBox.shrink();
                }
                return ValueListenableBuilder<int>(
                  valueListenable: _scoreNotifier,
                  builder: (context, score, __) => _LevelFailedOverlay(
                    score: score,
                    onRetry: _handleRetryLevel,
                    onExit: () => unawaited(_returnToHome()),
                  ),
                );
              },
            ),
              ],
            ),
          );
        },
      ),
    ),
  );
  }
}

class _ScoreHud extends StatelessWidget {
  const _ScoreHud({
    required this.apples,
    required this.level,
    required this.score,
    required this.onBack,
  });

  final int apples;
  final int level;
  final int score;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                _HudBadge(
                  label: 'Apples',
                  value: 'x$apples',
                  icon: Icons.apple,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LEVEL $level',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Stay sharp!',
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                _HudBadge(
                  label: 'Score',
                  value: '$score',
                  icon: Icons.stacked_line_chart,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _HudBadge extends StatelessWidget {
  const _HudBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(color: Colors.white70),
              ),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThrowHint extends StatelessWidget {
  const _ThrowHint();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Tap anywhere to throw',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _KnifeRack extends StatelessWidget {
  const _KnifeRack({
    required this.total,
    required this.remaining,
    required this.knifeAsset,
  });

  final int total;
  final int remaining;
  final String knifeAsset;

  String get _resolvedAssetPath {
    if (knifeAsset.startsWith('assets/')) {
      return knifeAsset;
    }
    return 'assets/images/$knifeAsset';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double knifeWidth = 32;
        const double horizontalGap = 12;
        final double availableWidth = constraints.maxWidth;
        final int itemsPerRow = availableWidth.isFinite && availableWidth > 0
            ? (availableWidth / (knifeWidth + horizontalGap)).floor().clamp(1, total)
            : total;
        final int rowCount = (total / itemsPerRow).ceil();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rowCount, (rowIndex) {
            final int start = rowIndex * itemsPerRow;
            final int end = (start + itemsPerRow).clamp(0, total);
            return Padding(
              padding: EdgeInsets.only(bottom: rowIndex == rowCount - 1 ? 0 : 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = start; i < end; i++)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: i == start || i == end - 1 ? 4 : 6,
                      ),
                      child: Opacity(
                        opacity: i < remaining ? 1 : 0.25,
                        child: Image.asset(
                          _resolvedAssetPath,
                          width: knifeWidth,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _LevelCompleteOverlay extends StatefulWidget {
  const _LevelCompleteOverlay({required this.score, required this.onNext});

  final int score;
  final Future<void> Function() onNext;

  @override
  State<_LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<_LevelCompleteOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.85),
              ],
              center: Alignment.center,
              radius: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A5F3F), Color(0xFF0D3A26)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            size: 50,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title with glow effect
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFFFD700)],
                          ).createShader(bounds),
                          child: const Text(
                            'LEVEL\nCOMPLETE!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Score container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Score: ${widget.score}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Next button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => widget.onNext(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.dark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: AppColors.primary.withValues(alpha: 0.6),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'NEXT LEVEL',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelFailedOverlay extends StatefulWidget {
  const _LevelFailedOverlay({
    required this.score,
    required this.onRetry,
    required this.onExit,
  });

  final int score;
  final Future<void> Function() onRetry;
  final VoidCallback onExit;

  @override
  State<_LevelFailedOverlay> createState() => _LevelFailedOverlayState();
}

class _LevelFailedOverlayState extends State<_LevelFailedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4)),
    );

    _shakeAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.5, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF3D1F1F).withValues(alpha: 0.6),
                Colors.black.withValues(alpha: 0.9),
              ],
              center: Alignment.center,
              radius: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5F1A1A), Color(0xFF3A0D0D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Failed icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 50,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.redAccent, Color(0xFFFF6B6B)],
                          ).createShader(bounds),
                          child: const Text(
                            'LEVEL\nFAILED',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Score container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_down, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Score: ${widget.score}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Retry button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => widget.onRetry(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.dark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: AppColors.primary.withValues(alpha: 0.6),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'TRY AGAIN',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Quit button
                        TextButton(
                          onPressed: widget.onExit,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.exit_to_app, color: Colors.white60, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Quit',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BossRewardOverlay extends StatelessWidget {
  const _BossRewardOverlay({
    required this.rewardName,
    required this.imageAsset,
    required this.onDismissed,
  });

  final String rewardName;
  final String? imageAsset;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismissed,
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              width: math.min(MediaQuery.sizeOf(context).width * 0.8, 320),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3C1053), Color(0xFFAD5389)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 30,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Boss defeated!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'New knife unlocked',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: imageAsset != null
                        ? Image.asset(
                            imageAsset!,
                            fit: BoxFit.contain,
                          )
                        : const Icon(
                            Icons.auto_awesome,
                            size: 120,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    rewardName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tap anywhere to continue',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
