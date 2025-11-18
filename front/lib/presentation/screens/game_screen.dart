import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:knife_hit/game/knife_hit_game.dart';

/// Fullscreen screen that hosts the Flame [KnifeHitGame].
class GameScreen extends StatefulWidget {
  /// Creates a [GameScreen].
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final KnifeHitGame _game;

  @override
  void initState() {
    super.initState();
    // Quick runtime check: try loading the target asset directly from Flutter's
    // asset bundle to ensure the asset is packaged and readable at runtime.
    () async {
      try {
        final key = 'assets/images/targets/default_wood.webp';
        final data = await rootBundle.load(key);
        // ignore: avoid_print
        print('ASSET CHECK: loaded "$key" with ${data.lengthInBytes} bytes');
      } catch (e, s) {
        // ignore: avoid_print
        print('ASSET CHECK: failed to load asset via rootBundle: $e');
        // ignore: avoid_print
        print(s);
      }
    }();

    _game = KnifeHitGame();
  }

  @override
  void dispose() {
    _game.pauseEngine();
    _game.onDetach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The Flame game widget takes the full available space. Wrap with
          // a GestureDetector so Flutter can forward taps to the game logic.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _game.onUserTap(),
            child: GameWidget(game: _game),
          ),
          // Small overlay with a back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
