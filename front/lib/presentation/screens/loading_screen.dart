import 'dart:async';

import 'package:flutter/material.dart';

import 'package:knife_hit/core/constants/colors.dart';
import 'package:knife_hit/presentation/screens/home_screen.dart';
import 'package:knife_hit/services/sound_manager.dart';

/// Splash/loading screen that prepares audio assets before starting the game.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preloadAssets());
  }

  Future<void> _preloadAssets() async {
    try {
      await SoundManager.instance.warmUpAll();
    } on Object catch (error, stackTrace) {
      debugPrint('LoadingScreen: failed to warm up audio: $error');
      debugPrint('$stackTrace');
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? labelStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.homeGradientStart, AppColors.homeGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text('Loading assets…', style: labelStyle),
              const SizedBox(height: 8),
              Text(
                'Getting ready for battle',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
