import 'package:flutter/material.dart';

import 'package:knife_hit/core/constants/colors.dart';
import 'package:knife_hit/presentation/screens/game_screen.dart';

/// Home screen of the game showing main actions: Play, Shop, Stats, etc.
class HomeScreen extends StatelessWidget {
  /// Creates the `HomeScreen`.
  const HomeScreen({super.key});

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
                const _TopBar(),
                const Spacer(flex: 2),
                const _GameLogo(),
                const SizedBox(height: 32),
                const _PlayButton(),
                const SizedBox(height: 24),
                HomeIconButton(
                  icon: Icons.emoji_events_outlined,
                  label: 'Achievements',
                  diameter: 96,
                  onTap: () {},
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

class _TopBar extends StatelessWidget {
  const _TopBar();

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
          onTap: () {},
        ),
        Text('KNIFE HIT', style: titleStyle),
        HomeIconButton(
          icon: Icons.storefront_outlined,
          label: 'Shop',
          onTap: () {},
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
        size: 72,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: AppColors.dark,
    );

    return InkWell(
      onTap: () {
        Navigator.push<Widget>(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      },
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
