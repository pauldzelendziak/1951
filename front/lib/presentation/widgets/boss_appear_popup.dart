import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:knife_hit/core/constants/colors.dart';

/// Animated boss appearance popup with dramatic visual effects.
///
/// Displays when a boss level starts (levels 5, 10, 15... 50), featuring
/// scale/fade animations, glow effects, and tap-to-dismiss.
class BossAppearPopup extends StatefulWidget {
  const BossAppearPopup({
    super.key,
    required this.bossLevel,
    required this.bossName,
    this.onDismissed,
  });

  final int bossLevel;
  final String bossName;
  final VoidCallback? onDismissed;

  @override
  State<BossAppearPopup> createState() => _BossAppearPopupState();

  /// Shows the boss popup as a fullscreen overlay with backdrop blur.
  static void show(
    BuildContext context, {
    required int bossLevel,
    required String bossName,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => BossAppearPopup(
        bossLevel: bossLevel,
        bossName: bossName,
        onDismissed: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _BossAppearPopupState extends State<BossAppearPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation: dramatic entrance
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Fade animation: backdrop and content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Glow animation: pulsing effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _scaleController.reverse().then((_) {
      widget.onDismissed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Blurred backdrop
            FadeTransition(
              opacity: _fadeAnimation,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ),
            // Boss announcement card
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildBossCard(),
                ),
              ),
            ),
            // Tap hint at bottom
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Text(
                    'TAP TO CONTINUE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBossCard() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 340,
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2C0A0A),
                Color(0xFF1A0505),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.8 * _glowAnimation.value),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5 * _glowAnimation.value),
                blurRadius: 40,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "BOSS LEVEL" label with glow effect
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppColors.primary,
                    const Color(0xFFFFD700),
                  ],
                ).createShader(bounds),
                child: Text(
                  'BOSS LEVEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: AppColors.primary.withOpacity(_glowAnimation.value),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Level number - big and bold
              Text(
                'LEVEL ${widget.bossLevel}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withOpacity(0.8 * _glowAnimation.value),
                      blurRadius: 30,
                    ),
                    const Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Boss name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.bossName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Warning message
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.amber.withOpacity(0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PREPARE FOR BATTLE',
                    style: TextStyle(
                      color: Colors.amber.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.amber.withOpacity(0.9),
                    size: 20,
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
