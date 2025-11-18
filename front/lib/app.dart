import 'package:flutter/material.dart';

import 'package:knife_hit/core/constants/colors.dart';
import 'package:knife_hit/presentation/screens/home_screen.dart';

/// Root widget that wires up app-wide theme and navigation.
/// The root widget for the Knife Hit application.
///
/// Configures global theming and the initial route (home screen).
class KnifeHitApp extends StatelessWidget {
  /// Creates a [KnifeHitApp].
  const KnifeHitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.dark,
    );

    return MaterialApp(
      title: 'Knife Hit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Roboto',
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
