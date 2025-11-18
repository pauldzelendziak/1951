import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:knife_hit/core/constants/asset_paths.dart';
import 'package:knife_hit/core/constants/colors.dart';
import 'package:knife_hit/data/models/game_progress.dart';
import 'package:knife_hit/data/storage/game_progress_storage.dart';
import 'package:knife_hit/game/level_settings.dart';
import 'package:knife_hit/game/knife_hit_game.dart';

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
  final GameProgressStorage _progressStorage = const GameProgressStorage();
  bool _autosaveScheduled = false;
  late final TextEditingController _levelJumpController;

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
    _appleCoins = _game.appleCoins;
    _knivesLeft = _game.knivesLeft;
    _scoreNotifier = _game.score;
    _levelCompleteNotifier = _game.levelCompleted;
    _levelFailedNotifier = _game.levelFailed;
    _totalKnives = _game.initialKnifeCount;
    _level = _game.levelIndex;
    _levelJumpController = TextEditingController(text: _level.toString());
    _attachAutosaveListeners();
    _scheduleAutosave();
  }

  Future<void> _handleNextLevel() async {
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
    await _game.retryCurrentLevel();
    setState(() {
      _level = _game.levelIndex;
      _totalKnives = _game.initialKnifeCount;
      _levelJumpController.text = _level.toString();
    });
    _scheduleAutosave();
  }

  Future<void> _jumpToLevel(int level) async {
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
  @override
  void dispose() {
    _removeAutosaveListeners();
    unawaited(_saveProgress());
    _levelJumpController.dispose();
    _game.pauseEngine();
    _game.onDetach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: _DebugLevelJumpButton(onTap: _promptLevelJump),
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
                          onBack: () => Navigator.maybePop(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<int>(
                      valueListenable: _knivesLeft,
                      builder: (context, remaining, child) => _KnifeRack(
                        total: _totalKnives,
                        remaining: remaining,
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
                    onExit: () => Navigator.maybePop(context),
                  ),
                );
              },
            ),
              ],
            ),
          );
        },
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

class _DebugLevelJumpButton extends StatelessWidget {
  const _DebugLevelJumpButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calculate, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Level...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
  const _KnifeRack({required this.total, required this.remaining});

  final int total;
  final int remaining;

  static const String _knifeAssetPath = 'assets/images/${AssetPaths.knifeTanto}';

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
                          _knifeAssetPath,
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

class _LevelCompleteOverlay extends StatelessWidget {
  const _LevelCompleteOverlay({required this.score, required this.onNext});

  final int score;
  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Material(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Congratulations.\nLevel passed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onNext();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.dark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
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

class _LevelFailedOverlay extends StatelessWidget {
  const _LevelFailedOverlay({
    required this.score,
    required this.onRetry,
    required this.onExit,
  });

  final int score;
  final Future<void> Function() onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Material(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Try again',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onRetry();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.dark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onExit,
                    child: const Text(
                      'Quit',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
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
