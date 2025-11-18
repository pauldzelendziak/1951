# Flame Integration

## Purpose

Flame is a modular Flutter game engine that provides game loop, component system, collision detection, effects, and more. This document shows how to integrate Flame with your Flutter app and scaffold a basic game structure.

## Dependencies

```yaml
dependencies:
  flame: ^1.33.0
```

---

## Architecture Overview

### Flutter + Flame Integration

```
Flutter App (Material/Cupertino)
    ↓
GameScreen (Stateful Widget)
    ↓
GameWidget<YourGame>
    ↓
YourGame extends FlameGame
    ↓
Components (Player, Enemies, Collectibles, etc.)
```

**Key Concept**: Flame game runs inside a `GameWidget`, which is a Flutter widget. This allows seamless integration with Flutter UI.

---

## 1. Main Game Class

### FlameGame Setup

```dart
class SpaceAvoiderGame extends FlameGame
    with HasCollisionDetection, TapDetector, PanDetector {

  // Dependencies (passed via constructor)
  final GameLoopManager gameLoopManager;
  final AchievementService? achievementService;

  // Components (created in onLoad)
  late PlayerComponent player;

  // Game state
  final Random _random = Random();
  Timer? _obstacleSpawnTimer;
  Timer? _crystalSpawnTimer;

  SpaceAvoiderGame({
    required this.gameLoopManager,
    this.achievementService,
  });

  @override
  Future<void> onLoad() async {
    // 1. Load assets
    await _loadAssets();

    // 2. Add background elements
    await _addBackgroundStars();

    // 3. Add player
    player = PlayerComponent(
      skinId: ServiceLocator.saveGameService.currentSkin,
    );
    await add(player);

    // 4. Set up spawn timers
    _setupSpawnTimers();

    // 5. Wire up game loop callbacks
    _setupGameLoopCallbacks();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update game loop manager (score, level, difficulty)
    if (gameLoopManager.state == GameState.playing) {
      gameLoopManager.update(dt);
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    // Handle tap events
    if (gameLoopManager.state == GameState.ready) {
      gameLoopManager.startGame();
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    // Move player with drag
    if (gameLoopManager.state == GameState.playing) {
      player.position = info.eventPosition.global;
    }
  }

  Future<void> _loadAssets() async {
    // Preload images
    await images.loadAll([
      'player/ship_1.png',
      'obstacles/spike1.png',
      'collectibles/crystal.png',
      // ... more assets
    ]);
  }

  void _setupSpawnTimers() {
    _obstacleSpawnTimer = Timer(
      2.0, // Initial interval
      repeat: true,
      onTick: _spawnObstacle,
    );

    _crystalSpawnTimer = Timer(
      5.0,
      repeat: true,
      onTick: _spawnCrystal,
    );

    add(_obstacleSpawnTimer!);
    add(_crystalSpawnTimer!);
  }

  void _spawnObstacle() {
    // Adjust interval based on difficulty
    final interval = 2.0 / gameLoopManager.frequencyMultiplier;
    _obstacleSpawnTimer?.limit = interval;

    // Create obstacle component
    final obstacle = _createRandomObstacle();
    add(obstacle);
  }

  Component _createRandomObstacle() {
    final type = _random.nextInt(100);

    if (type < 40) {
      return Spike1Component();
    } else if (type < 80) {
      return Spike2Component();
    } else {
      return BlackHoleComponent(target: player);
    }
  }

  void _spawnCrystal() {
    // Only spawn if no other crystal nearby
    final existingCrystals = children.whereType<CrystalComponent>();
    if (existingCrystals.isEmpty) {
      add(CrystalComponent());
    }
  }

  void pauseGame() {
    gameLoopManager.pauseGame();
    pauseEngine(); // Flame built-in: stops update() calls
  }

  void resumeGame() {
    gameLoopManager.resumeGame();
    resumeEngine(); // Flame built-in: resumes update() calls
  }

  @override
  void onRemove() {
    _obstacleSpawnTimer?.stop();
    _crystalSpawnTimer?.stop();
    super.onRemove();
  }
}
```

**Setup Checklist**:
- [ ] Create class extending FlameGame
- [ ] Add HasCollisionDetection mixin
- [ ] Add TapDetector or PanDetector for input
- [ ] Accept dependencies via constructor
- [ ] Implement onLoad for initialization
- [ ] Implement update for game loop
- [ ] Add input handlers (onTapDown, onPanUpdate)
- [ ] Implement pause/resume methods
- [ ] Clean up in onRemove

---

## 2. Component System

### Base Component Pattern

```dart
class PlayerComponent extends PositionComponent
    with HasGameRef<SpaceAvoiderGame>, CollisionCallbacks {

  final String skinId;

  late SpriteComponent _sprite;
  late ParticleSystemComponent _trail;

  bool isImmortal = false;
  double _immortalTimer = 0;

  PlayerComponent({required this.skinId});

  @override
  Future<void> onLoad() async {
    // Set size and position
    size = Vector2(64, 64);
    position = gameRef.size / 2; // Center of screen
    anchor = Anchor.center;

    // Load sprite
    _sprite = SpriteComponent(
      sprite: await gameRef.loadSprite('player/$skinId.png'),
      size: size,
    );
    add(_sprite);

    // Add particle trail
    _trail = _createParticleTrail();
    add(_trail);

    // Add collision hitbox (smaller than sprite for better feel)
    add(CircleHitbox(
      radius: size.x * 0.3,
      anchor: Anchor.center,
      position: size / 2,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Keep player on screen
    _constrainToScreen();

    // Update immortality
    if (isImmortal) {
      _immortalTimer += dt;
      if (_immortalTimer >= 3.0) {
        isImmortal = false;
        _immortalTimer = 0;
        _sprite.paint.color = Colors.white;
      } else {
        // Blinking effect
        final blink = ((_immortalTimer * 3.33) % 1.0) > 0.5;
        _sprite.paint.opacity = blink ? 1.0 : 0.3;
      }
    }
  }

  void _constrainToScreen() {
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;

    position.x = position.x.clamp(halfWidth, gameRef.size.x - halfWidth);
    position.y = position.y.clamp(halfHeight, gameRef.size.y - halfHeight);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Spike1Component || other is Spike2Component) {
      _handleObstacleCollision(other);
    } else if (other is CrystalComponent) {
      _handleCrystalCollision(other);
    }
  }

  void _handleObstacleCollision(PositionComponent obstacle) {
    if (!isImmortal) {
      // Take damage
      gameRef.gameLoopManager.loseLife();
      isImmortal = true;
      _immortalTimer = 0;

      // Notify achievement service
      ServiceLocator.achievementService.onPlayerDeath(false);

      // Remove obstacle
      obstacle.removeFromParent();
    }
  }

  void _handleCrystalCollision(CrystalComponent crystal) {
    // Collect crystal
    gameRef.gameLoopManager.collectCrystal();
    ServiceLocator.achievementService.onCrystalCollected(isImmortal);
    ServiceLocator.audioService.playCrystalSound();

    crystal.removeFromParent();
  }

  ParticleSystemComponent _createParticleTrail() {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 30,
        lifespan: 0.8,
        generator: (i) {
          return AcceleratedParticle(
            acceleration: Vector2(0, 100),
            speed: Vector2.zero(),
            position: Vector2.zero(),
            child: CircleParticle(
              radius: 2,
              paint: Paint()..color = Colors.cyan.withOpacity(0.5),
            ),
          );
        },
      ),
    );
  }
}
```

**Component Checklist**:
- [ ] Extend PositionComponent or SpriteComponent
- [ ] Add HasGameRef mixin for game access
- [ ] Add CollisionCallbacks for collision detection
- [ ] Set size, position, anchor in onLoad
- [ ] Load sprites/assets in onLoad
- [ ] Add collision hitbox
- [ ] Implement update for per-frame logic
- [ ] Implement onCollision for collision handling
- [ ] Clean up in onRemove if needed

---

## 3. Collision Detection

### Setup

```dart
// In game class:
class MyGame extends FlameGame with HasCollisionDetection {
  // Collision detection is now automatic
}

// In component:
class ObstacleComponent extends PositionComponent with CollisionCallbacks {
  @override
  Future<void> onLoad() async {
    // Add hitbox
    add(RectangleHitbox()); // or CircleHitbox, PolygonHitbox
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is PlayerComponent) {
      // Handle collision
    }
  }
}
```

### Hitbox Types

```dart
// Circle (best for round objects)
add(CircleHitbox(
  radius: 20,
  position: Vector2(10, 10),
  anchor: Anchor.center,
));

// Rectangle (best for square objects)
add(RectangleHitbox(
  size: Vector2(32, 32),
  position: Vector2.zero(),
));

// Polygon (custom shapes)
add(PolygonHitbox([
  Vector2(0, 0),
  Vector2(32, 0),
  Vector2(16, 32),
]));
```

**Collision Best Practices**:
- Use smaller hitboxes than sprites for better feel
- Circle hitboxes are fastest for collision detection
- Only add collision to components that need it
- Use collision layers for optimization (advanced)

---

## 4. Game Screen Integration

### GameScreen Widget

```dart
class GameScreen extends StatefulWidget {
  final GameLoopManager gameLoopManager;
  final AchievementService achievementService;
  final AudioService audioService;
  final SaveGameService saveGameService;

  const GameScreen({
    required this.gameLoopManager,
    required this.achievementService,
    required this.audioService,
    required this.saveGameService,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late SpaceAvoiderGame _game;
  bool _gameLoaded = false;

  // HUD state
  int _displayedScore = 0;
  int _displayedLevel = 1;
  int _displayedLives = 2;

  @override
  void initState() {
    super.initState();

    // Create game instance
    _game = SpaceAvoiderGame(
      gameLoopManager: widget.gameLoopManager,
      achievementService: widget.achievementService,
    );

    // Set up game loop callbacks
    widget.gameLoopManager.onScoreChanged = (score) {
      setState(() => _displayedScore = score);
    };

    widget.gameLoopManager.onLevelChanged = (level) {
      setState(() => _displayedLevel = level);
    };

    widget.gameLoopManager.onLivesChanged = (lives) {
      setState(() => _displayedLives = lives);
      if (lives < 0) {
        _handleGameOver();
      }
    };

    widget.gameLoopManager.onStateChanged = (state) {
      if (state == GameState.paused) {
        _showPauseDialog();
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game canvas
          GameWidget(
            game: _game,
            onLoad: () => setState(() => _gameLoaded = true),
          ),

          // HUD overlay
          if (_gameLoaded) _buildHUD(),

          // Pause button
          Positioned(
            top: 48,
            right: 16,
            child: GameIconButton(
              icon: Icons.pause,
              onPressed: () => _game.pauseGame(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Positioned(
      top: 48,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HudStatIndicator(
            icon: Icons.star,
            label: 'Score',
            value: _displayedScore.toString(),
          ),
          SizedBox(height: 8),
          HudStatIndicator(
            icon: Icons.trending_up,
            label: 'Level',
            value: _displayedLevel.toString(),
          ),
          SizedBox(height: 8),
          HudStatIndicator(
            imageAsset: 'assets/images/ui/heart.png',
            label: 'Lives',
            value: _displayedLives.toString(),
          ),
        ],
      ),
    );
  }

  Future<void> _showPauseDialog() async {
    await GameDialog.show(
      context: context,
      title: 'Paused',
      child: PauseDialogContent(
        onResume: () {
          Navigator.pop(context);
          _game.resumeGame();
        },
        onQuit: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Close game screen
        },
      ),
      dismissible: false,
    );
  }

  Future<void> _handleGameOver() async {
    // Update best score
    await widget.saveGameService.updateBestScore(
      _displayedScore,
      _displayedLevel,
    );

    // Show game over dialog
    await GameDialog.show(
      context: context,
      title: 'Game Over',
      child: GameOverDialogContent(
        score: _displayedScore,
        level: _displayedLevel,
        bestScore: widget.saveGameService.bestScore,
        onReplay: () {
          Navigator.pop(context);
          widget.gameLoopManager.resetGame();
          _game.resumeGame();
        },
        onQuit: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
      dismissible: false,
    );
  }

  @override
  void dispose() {
    _game.onRemove();
    super.dispose();
  }
}
```

**Setup Checklist**:
- [ ] Create StatefulWidget for game screen
- [ ] Accept all required services
- [ ] Create game instance in initState
- [ ] Wire up game loop callbacks
- [ ] Build Stack with GameWidget + HUD
- [ ] Add pause button
- [ ] Implement pause dialog
- [ ] Implement game over dialog
- [ ] Clean up game in dispose

---

## 5. GameLoopManager System

### Game State & Difficulty Scaling

```dart
enum GameState { ready, playing, paused, gameOver }

class GameLoopManager {
  GameState _state = GameState.ready;
  int _score = 0;
  int _level = 1;
  int _lives = 2;
  int _crystals = 0;

  double _levelTimer = 0;
  static const double _levelDuration = 10.0; // Seconds per level

  // Difficulty scaling
  double get speedMultiplier => 1.0 + (_level - 1) * 0.1; // +10% per level
  double get frequencyMultiplier => 1.0 + (_level - 1) * 0.2; // +20% per level

  // Callbacks
  void Function(int)? onScoreChanged;
  void Function(int)? onLevelChanged;
  void Function(int)? onLivesChanged;
  void Function(int)? onCrystalsChanged;
  void Function(GameState)? onStateChanged;

  void update(double dt) {
    if (_state != GameState.playing) return;

    // Increase score over time
    _score += dt.toInt();
    onScoreChanged?.call(_score);

    // Level progression
    _levelTimer += dt;
    if (_levelTimer >= _levelDuration) {
      _levelTimer = 0;
      _level++;
      onLevelChanged?.call(_level);
    }
  }

  void startGame() {
    _state = GameState.playing;
    onStateChanged?.call(_state);
  }

  void pauseGame() {
    _state = GameState.paused;
    onStateChanged?.call(_state);
  }

  void resumeGame() {
    _state = GameState.playing;
    onStateChanged?.call(_state);
  }

  void loseLife() {
    _lives--;
    onLivesChanged?.call(_lives);

    if (_lives < 0) {
      _state = GameState.gameOver;
      onStateChanged?.call(_state);
    }
  }

  void collectCrystal() {
    _crystals++;
    onCrystalsChanged?.call(_crystals);
  }

  void resetGame() {
    _score = 0;
    _level = 1;
    _lives = 2;
    _crystals = 0;
    _levelTimer = 0;
    _state = GameState.ready;

    onScoreChanged?.call(_score);
    onLevelChanged?.call(_level);
    onLivesChanged?.call(_lives);
    onCrystalsChanged?.call(_crystals);
  }
}
```

---

## Best Practices

1. **Asset preloading**: Load in onLoad, not during gameplay
2. **Component pooling**: Reuse components instead of creating new ones (advanced)
3. **Collision optimization**: Use appropriate hitbox types
4. **Update optimization**: Only update what changes
5. **State management**: Keep game state in GameLoopManager
6. **Service access**: Use ServiceLocator for global services
7. **Dispose properly**: Clean up timers and listeners

---

## Common Pitfalls

1. **Not setting size/position**: Components won't render
2. **Missing HasGameRef**: Can't access game reference
3. **Forgetting anchor**: Components positioned incorrectly
4. **No collision hitbox**: Collisions won't detect
5. **Update in wrong state**: Game updates while paused
6. **Memory leaks**: Not removing components
7. **Black screen**: See 11_Flame_Nuances.md

---

## Next Steps

After Flame integration:
- Review **Flame Nuances** (11) for common issues
- Connect to **Achievement System** (04)
- Integrate **Audio System** (03) for game sounds
- Add **Animations** (10) for effects
