import 'dart:async';

import 'package:flutter/material.dart';

import 'package:knife_hit/core/constants/colors.dart';
import 'package:knife_hit/data/models/game_progress.dart';
import 'package:knife_hit/data/storage/game_progress_storage.dart';
import 'package:knife_hit/presentation/screens/achievements_screen.dart';
import 'package:knife_hit/presentation/screens/game_screen.dart';
import 'package:knife_hit/presentation/screens/knife_shop_screen.dart';
import 'package:knife_hit/presentation/screens/stats_screen.dart';
import 'package:knife_hit/services/background_music_manager.dart';

/// Home screen of the game showing main actions: Play, Shop, Stats, etc.
class HomeScreen extends StatefulWidget {
  /// Creates the `HomeScreen`.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameProgress? _cachedProgress;
  bool _loading = true;
  final GameProgressStorage _progressStorage = const GameProgressStorage();
  int _progressLoadToken = 0;

  @override
  void initState() {
    super.initState();
    _ensureMenuMusic();
    _loadProgress();
  }

  void _ensureMenuMusic() {
    unawaited(BackgroundMusicManager.instance.play(BackgroundTrack.menu));
  }

  Future<void> _loadProgress() async {
    final int requestId = ++_progressLoadToken;
    final GameProgress? progress = await _progressStorage.read();
    if (!mounted || requestId != _progressLoadToken) {
      return;
    }
    setState(() {
      _cachedProgress = progress;
      _loading = false;
    });
  }

  void _applyCachedProgress(GameProgress? progress, {bool? loading}) {
    _progressLoadToken++;
    if (!mounted) {
      return;
    }
    setState(() {
      _cachedProgress = progress;
      if (loading != null) {
        _loading = loading;
      }
    });
  }

  bool get _hasProgress => _cachedProgress != null;

  Future<void> _handlePlay() async {
    if (_loading) {
      await _startNewGame();
      return;
    }
    final _PlaySelection? selection = await showDialog<_PlaySelection>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.dialogBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Choose an action'),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: _hasProgress
                  ? () => Navigator.of(dialogContext).pop(_PlaySelection.continueGame)
                  : null,
              child: const Text('Continue'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(_PlaySelection.newGame),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.dark,
              ),
              child: const Text('New game'),
            ),
          ],
        );
      },
    );

    switch (selection) {
      case _PlaySelection.continueGame:
        await _continueGame();
        break;
      case _PlaySelection.newGame:
        await _startNewGame();
        break;
      case null:
        break;
    }
  }

  Future<void> _continueGame() async {
    final GameProgress? progress = await _resolveProgressForContinue();
    if (progress == null) {
      await _startNewGame();
      return;
    }
    _applyCachedProgress(progress, loading: false);
    await _launchGame(progress);
  }

  Future<GameProgress?> _resolveProgressForContinue() async {
    final GameProgress? cached = _cachedProgress;
    GameProgress? stored;
    try {
      stored = await _progressStorage.read();
    } on Object catch (error, stackTrace) {
      debugPrint('HomeScreen: failed to read stored progress: $error');
      debugPrint('$stackTrace');
    }
    if (cached == null) {
      return stored;
    }
    if (stored == null) {
      return cached;
    }
    final int cachedLevel =
        cached.activeLevel?.levelIndex ?? cached.levelIndex;
    final int storedLevel =
        stored.activeLevel?.levelIndex ?? stored.levelIndex;
    if (cachedLevel > storedLevel) {
      return cached;
    }
    if (cachedLevel == storedLevel) {
      final bool cachedHasSnapshot = cached.activeLevel != null;
      final bool storedHasSnapshot = stored.activeLevel != null;
      if (cachedHasSnapshot && !storedHasSnapshot) {
        return cached;
      }
    }
    return stored;
  }

  Future<void> _startNewGame() async {
    final GameProgress? previous =
        _cachedProgress ?? await _progressStorage.read();
    final GameProgress baseline = GameProgress.initial().copyWith(
      appleCoins: previous?.appleCoins ?? 0,
      unlockedKnifeAssets: previous?.unlockedKnifeAssets,
      equippedKnifeAsset: previous?.equippedKnifeAsset,
    );
    await _progressStorage.write(baseline);
    _applyCachedProgress(baseline, loading: false);
    await _launchGame(baseline);
  }

  Future<void> _launchGame(GameProgress? progress) async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }
    final GameProgress? updated = await Navigator.push<GameProgress>(
      context,
      MaterialPageRoute<GameProgress>(
        builder: (_) => GameScreen(initialProgress: progress),
      ),
    );
    _ensureMenuMusic();
    if (!mounted) {
      return;
    }
    if (updated != null) {
      _applyCachedProgress(updated, loading: false);
    } else {
      await _loadProgress();
    }
  }

  Future<void> _openShop() async {
    final GameProgress baseProgress =
        _cachedProgress ?? await _progressStorage.read() ?? GameProgress.initial();
    final GameProgress? updated = await Navigator.push<GameProgress>(
      context,
      MaterialPageRoute<GameProgress>(
        builder: (_) => KnifeShopScreen(initialProgress: baseProgress),
      ),
    );
    _ensureMenuMusic();
    if (updated != null) {
      await _progressStorage.write(updated);
      _applyCachedProgress(updated);
    }
  }

  Future<void> _openAchievements() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AchievementsScreen(),
      ),
    );
    _ensureMenuMusic();
  }

  Future<void> _openStats() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const StatsScreen(),
      ),
    );
    _ensureMenuMusic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.homeGradientStart, AppColors.homeGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                _TopBar(
                  onShopTap: _openShop,
                  onStatsTap: _openStats,
                ),
                const Spacer(flex: 2),
                const _GameLogo(),
                const SizedBox(height: 32),
                _PlayButton(onTap: _handlePlay),
                const SizedBox(height: 24),
                HomeIconButton(
                  icon: Icons.emoji_events_outlined,
                  label: 'Achievements',
                  diameter: 96,
                  onTap: _openAchievements,
                ),
                const Spacer(flex: 3),
                const _BottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PlaySelection { continueGame, newGame }

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onShopTap, required this.onStatsTap});

  final VoidCallback onShopTap;
  final VoidCallback onStatsTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        HomeIconButton(
          icon: Icons.bar_chart_rounded,
          label: 'Stats',
          onTap: onStatsTap,
        ),
        Text('KNIFE HIT', style: titleStyle),
        HomeIconButton(
          icon: Icons.storefront_outlined,
          label: 'Shop',
          onTap: onShopTap,
        ),
      ],
    );
  }
}

class _GameLogo extends StatelessWidget {
  const _GameLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.iconBackground,
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: const Icon(
        Icons.sports_martial_arts,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: AppColors.dark,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Ink(
        width: 180,
        height: 180,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFFFFF9C4), AppColors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              size: 72,
              color: AppColors.dark,
            ),
            const SizedBox(height: 8),
            Text('PLAY', style: labelStyle),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        HomeIconButton(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () {},
        ),
        HomeIconButton(
          icon: Icons.calendar_month_outlined,
          label: 'Daily',
          onTap: () {},
        ),
      ],
    );
  }
}

/// Small circular icon button used on the home screen with a label below it.
class HomeIconButton extends StatelessWidget {
  /// Creates a [HomeIconButton].
  const HomeIconButton({
    required this.icon,
    required this.label,
    this.diameter = 72,
    this.onTap,
    super.key,
  });

  /// Icon to display inside the circular container.
  final IconData icon;

  /// Text label shown beneath the icon.
  final String label;

  /// Diameter of the circular icon container.
  final double diameter;

  /// Callback invoked when the button is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.textPrimary,
      letterSpacing: 0.6,
    );

    return SizedBox(
      width: diameter + 12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(diameter / 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Ink(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                color: AppColors.iconBackground,
                borderRadius: BorderRadius.circular(diameter / 2),
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppColors.textPrimary,
                size: diameter * 0.45,
              ),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: labelStyle),
          ],
        ),
      ),
    );
  }
}
