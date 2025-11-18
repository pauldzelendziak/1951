# Claude Collaboration Guide for Flame Games (Flutter)

**Purpose:** This guide tells Claude exactly how to generate code for Flame-based game projects so outputs stay consistent, modular, and maintainable.

**When to use:** This guide is for game projects built with the Flame engine. For business/CRUD apps, see [flutter_guide.md](flutter_guide.md).

---

## 0) Project Snapshot (fill in per game)

<ARCHITECTURE>
• Engine: Flame
• State management: Game state in FlameGame + optional Riverpod for UI
• Storage: SharedPreferences (settings) + Hive/SQLite (save games)
• Localization: flutter_localizations + ARB files
• Audio: flame_audio
• Platform: Android-first (adaptable to iOS/Web)
</ARCHITECTURE>

---

## 1) Project Rules

<CRITICAL_RULE>
**Claude MUST follow these rules in ALL code generation:**

1. **KISS:** Prefer the simplest working abstraction. No speculative layers.
2. **Separation of Concerns:** Game logic in components/systems. UI in widgets. Data in services.
3. **Single Source of Truth:** Game state lives in FlameGame. UI state in providers. Persistence in storage services.
4. **Clean architecture:** Game code doesn't import Flutter UI. UI overlays import game for display only.
5. **No magic singletons:** Use DI via constructors. Game services passed through game reference.
6. **Theming only:** No hardcoded colors/fonts/spacing in UI. Use Theme.of(context).
7. **Localization:** No hardcoded text strings. Use AppLocalizations for all user-facing text.
8. **Null safety & lints:** Fix analyzer warnings. Add types. Avoid dynamic/! unless justified.
9. **Performance first:** Target 60fps. Profile hot paths. Use object pooling where needed.
10. **Accessibility:** Respect text scaling, contrast, semantics where applicable (menus, settings).
11. **Docs:** Public classes/methods get brief /// comments; game logic gets in-line comments.
12. **Optional logging:** If AppLogger exists, use it. Otherwise debugPrint() is acceptable for games.
</CRITICAL_RULE>

---

## 2) Architecture & Structure

<ARCHITECTURE>
### 2.1 Directory layout (game-first structure)

```
lib/
  game/
    components/              # Game entities (sprites, players, enemies, items)
      player_component.dart
      ball_component.dart
      enemy_component.dart
    systems/                 # Logic systems (AI, physics, spawning)
      ai/
        simple_ai.dart       # AI behavior
      collision_system.dart  # Custom collision handlers (optional)
    [game_name].dart         # Main FlameGame class (e.g., air_hockey_game.dart)
  screens/                   # Full-screen UI
    menu_screen.dart         # Main menu
    game_screen.dart         # Game with FlameGame widget
    settings_screen.dart     # Settings UI
    pause_screen.dart        # Pause overlay
  widgets/                   # Reusable UI components
    hud_widget.dart          # Heads-up display (score, health)
    game_button.dart         # Custom styled buttons
    animated_dialog.dart     # Dialog with animations
    coin_toss_dialog.dart    # Self-contained dialogs
  theme/                     # Centralized theming
    app_theme.dart           # ThemeData, decorations
    app_colors.dart          # Color constants
  services/                  # Cross-cutting services
    storage/
      save_game_service.dart     # Save/load game progress
      settings_service.dart      # User settings (volume, language)
    audio_service.dart           # Sound/music manager
  utils/                     # Helpers, extensions
    dialog_utils.dart        # Dialog helpers
  l10n/                      # Localization
    app_en.arb               # English strings
    app_es.arb               # Spanish strings
    app_localizations.dart   # Generated (flutter gen-l10n)
  main.dart                  # App entry point
```

### 2.2 Layering rules
• **Game Layer:** Flame components, game logic, physics, AI. No Flutter UI imports.
• **UI Layer:** Flutter widgets, screens, dialogs. Can read game state but doesn't modify it directly.
• **Services Layer:** Storage, audio, settings. Shared by both game and UI.
• **Communication:** Use callbacks (VoidCallback, Function) for game → UI events.

### 2.3 Naming & files
• **Files:** snake_case.dart → player_component.dart, save_game_service.dart
• **Classes:** UpperCamelCase → PlayerComponent, SaveGameService
• **Methods/vars:** lowerCamelCase
</ARCHITECTURE>

---

## 3) Flame Component Patterns

<CODE_PATTERN>
### 3.1 Component Structure

Every Flame component follows this lifecycle:

```dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A game entity representing a player paddle
class PlayerComponent extends PositionComponent with HasGameReference<MyGame> {
  /// Player team identifier
  final Team team;

  /// Radius of the paddle
  final double radius;

  /// Current velocity vector
  Vector2 velocity = Vector2.zero();

  /// Mass for physics calculations
  final double mass = 2.0;

  PlayerComponent({
    required Vector2 position,
    required this.team,
    this.radius = 30,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Load assets, initialize state
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update position based on velocity
    position.add(velocity * dt);
    // Apply friction
    velocity.scale(0.98);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Custom rendering
    final paint = Paint()
      ..color = team == Team.red ? Colors.red : Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, paint);
  }

  /// Apply force to this component
  void applyForce(Vector2 force) {
    velocity.add(force / mass);
  }

  /// Check if component is stopped
  bool get isStopped => velocity.length < 0.1;
}
```

**Key patterns:**
- Use `HasGameReference<T>` to access game instance
- Position/size/anchor in constructor
- Load assets in `onLoad()` (async)
- Update logic in `update(dt)` (60fps)
- Custom drawing in `render(canvas)`
- Public methods for external interactions

### 3.2 Component Mixins

```dart
// Collision detection
class BallComponent extends CircleComponent
    with CollisionCallbacks, HasGameReference<MyGame> {

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (other is PlayerComponent) {
      // Handle player collision
      _bounceOff(other);
    }
  }
}

// Tap detection
class ButtonComponent extends PositionComponent
    with TapCallbacks, HasGameReference<MyGame> {

  @override
  void onTapDown(TapDownEvent event) {
    // Handle tap
    game.startGame();
  }
}

// Drag detection
class DraggableComponent extends PositionComponent
    with DragCallbacks, HasGameReference<MyGame> {

  @override
  void onDragStart(DragStartEvent event) { }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.add(event.delta);
  }

  @override
  void onDragEnd(DragEndEvent event) { }
}
```
</CODE_PATTERN>

---

## 4) Main Game Class

<CODE_PATTERN>
### 4.1 FlameGame Structure

```dart
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/events.dart';

enum GameState { menu, playing, paused, gameOver }

class MyGame extends FlameGame with HasCollisionDetection, PanDetector {
  MyGame({this.saveService});

  // Dependencies (injected)
  final SaveGameService? saveService;

  // Game state
  GameState state = GameState.menu;
  int score = 0;
  int level = 1;

  // Components (late initialized)
  late PlayerComponent player;
  late List<EnemyComponent> enemies;

  // Callbacks for UI updates
  Function(int score)? onScoreChanged;
  Function(GameState state)? onGameStateChanged;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize components
    player = PlayerComponent(position: Vector2(size.x / 2, size.y * 0.8));
    add(player);

    // Load saved game if exists
    await _loadGame();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Game-specific update logic
    if (state == GameState.playing) {
      _checkGameOver();
      _spawnEnemies(dt);
    }
  }

  // Public game actions
  void startGame() {
    state = GameState.playing;
    onGameStateChanged?.call(state);
  }

  void pauseGame() {
    state = GameState.paused;
    onGameStateChanged?.call(state);
  }

  void addScore(int points) {
    score += points;
    onScoreChanged?.call(score);
  }

  Future<void> saveGame() async {
    if (saveService != null) {
      await saveService!.saveProgress(GameProgress(
        score: score,
        level: level,
        playerPosition: player.position,
      ));
    }
  }

  Future<void> _loadGame() async {
    if (saveService != null) {
      final progress = await saveService!.loadProgress();
      if (progress != null) {
        score = progress.score;
        level = progress.level;
        player.position = progress.playerPosition;
      }
    }
  }

  void _checkGameOver() {
    if (player.health <= 0) {
      state = GameState.gameOver;
      onGameStateChanged?.call(state);
    }
  }

  void _spawnEnemies(double dt) {
    // Spawning logic
  }
}
```

**Key patterns:**
- Game state enum for clarity
- Callbacks for UI notifications
- Public methods for UI interactions
- Private methods for internal logic
- Save/load integration
</CODE_PATTERN>

---

## 5) Save System & Persistence

<CODE_PATTERN>
### 5.1 Save Game Service

```dart
// lib/services/storage/save_game_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for saving and loading game progress
class SaveGameService {
  static const String _boxName = 'game_save';
  static const String _progressKey = 'progress';

  late Box _box;

  /// Initialize Hive and open box
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    if (kDebugMode) {
      debugPrint('SaveGameService initialized');
    }
  }

  /// Save game progress
  Future<void> saveProgress(GameProgress progress) async {
    await _box.put(_progressKey, progress.toJson());
    if (kDebugMode) {
      debugPrint('Game progress saved: level ${progress.level}, score ${progress.score}');
    }
  }

  /// Load game progress
  Future<GameProgress?> loadProgress() async {
    final json = _box.get(_progressKey);
    if (json == null) return null;

    final progress = GameProgress.fromJson(Map<String, dynamic>.from(json));
    if (kDebugMode) {
      debugPrint('Game progress loaded: level ${progress.level}, score ${progress.score}');
    }
    return progress;
  }

  /// Clear all saved progress
  Future<void> clearProgress() async {
    await _box.delete(_progressKey);
    if (kDebugMode) {
      debugPrint('Game progress cleared');
    }
  }

  /// Check if save data exists
  bool hasSavedGame() {
    return _box.containsKey(_progressKey);
  }
}

/// Game progress data model
class GameProgress {
  final int score;
  final int level;
  final List<String> unlockedItems;
  final Map<String, int> achievements;

  GameProgress({
    required this.score,
    required this.level,
    this.unlockedItems = const [],
    this.achievements = const {},
  });

  Map<String, dynamic> toJson() => {
    'score': score,
    'level': level,
    'unlockedItems': unlockedItems,
    'achievements': achievements,
  };

  factory GameProgress.fromJson(Map<String, dynamic> json) => GameProgress(
    score: json['score'] as int,
    level: json['level'] as int,
    unlockedItems: List<String>.from(json['unlockedItems'] ?? []),
    achievements: Map<String, int>.from(json['achievements'] ?? {}),
  );
}
```

### 5.2 Settings Service

```dart
// lib/services/storage/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for user settings and preferences
class SettingsService {
  static const String _volumeKey = 'volume';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _sfxEnabledKey = 'sfx_enabled';
  static const String _languageKey = 'language';
  static const String _difficultyKey = 'difficulty';

  late SharedPreferences _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      debugPrint('SettingsService initialized');
    }
  }

  // Volume settings
  double get volume => _prefs.getDouble(_volumeKey) ?? 0.7;
  Future<void> setVolume(double value) async {
    await _prefs.setDouble(_volumeKey, value);
    if (kDebugMode) {
      debugPrint('Volume set to: $value');
    }
  }

  // Music toggle
  bool get musicEnabled => _prefs.getBool(_musicEnabledKey) ?? true;
  Future<void> setMusicEnabled(bool value) async {
    await _prefs.setBool(_musicEnabledKey, value);
    if (kDebugMode) {
      debugPrint('Music enabled: $value');
    }
  }

  // SFX toggle
  bool get sfxEnabled => _prefs.getBool(_sfxEnabledKey) ?? true;
  Future<void> setSfxEnabled(bool value) async {
    await _prefs.setBool(_sfxEnabledKey, value);
  }

  // Language
  String get language => _prefs.getString(_languageKey) ?? 'en';
  Future<void> setLanguage(String code) async {
    await _prefs.setString(_languageKey, code);
    if (kDebugMode) {
      debugPrint('Language set to: $code');
    }
  }

  // Difficulty
  String get difficulty => _prefs.getString(_difficultyKey) ?? 'normal';
  Future<void> setDifficulty(String value) async {
    await _prefs.setString(_difficultyKey, value);
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs.clear();
    if (kDebugMode) {
      debugPrint('Settings reset to defaults');
    }
  }
}
```

### 5.3 Usage in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final saveService = SaveGameService();
  await saveService.init();

  final settingsService = SettingsService();
  await settingsService.init();

  runApp(MyApp(
    saveService: saveService,
    settingsService: settingsService,
  ));
}

class MyApp extends StatelessWidget {
  final SaveGameService saveService;
  final SettingsService settingsService;

  const MyApp({
    super.key,
    required this.saveService,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Game',
      theme: AppTheme.theme,
      home: GameScreen(
        saveService: saveService,
        settingsService: settingsService,
      ),
    );
  }
}
```
</CODE_PATTERN>

---

## 6) Localization

<CODE_PATTERN>
### 6.1 Setup (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true  # Enable code generation
```

### 6.2 Configuration (l10n.yaml)

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### 6.3 ARB Files

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "appTitle": "Air Hockey",
  "startGame": "START GAME",
  "pauseGame": "PAUSE",
  "resumeGame": "RESUME",
  "mainMenu": "MAIN MENU",
  "settings": "SETTINGS",
  "coinToss": "COIN TOSS",
  "playerWins": "{player} wins the toss!",
  "@playerWins": {
    "description": "Message shown when a player wins the coin toss",
    "placeholders": {
      "player": {
        "type": "String",
        "example": "Red Player"
      }
    }
  },
  "theyStartFirst": "They will start first.",
  "score": "Score: {score}",
  "@score": {
    "placeholders": {
      "score": {
        "type": "int",
        "format": "decimalPattern"
      }
    }
  },
  "level": "Level {level}",
  "@level": {
    "placeholders": {
      "level": {
        "type": "int"
      }
    }
  },
  "gameOver": "GAME OVER",
  "youWin": "YOU WIN!",
  "youLose": "YOU LOSE",
  "playAgain": "PLAY AGAIN"
}
```

```json
// lib/l10n/app_es.arb
{
  "@@locale": "es",
  "appTitle": "Hockey de Aire",
  "startGame": "COMENZAR JUEGO",
  "pauseGame": "PAUSA",
  "resumeGame": "REANUDAR",
  "mainMenu": "MENÚ PRINCIPAL",
  "settings": "CONFIGURACIÓN",
  "coinToss": "LANZAMIENTO DE MONEDA",
  "playerWins": "¡{player} gana el lanzamiento!",
  "theyStartFirst": "Ellos comenzarán primero.",
  "score": "Puntuación: {score}",
  "level": "Nivel {level}",
  "gameOver": "JUEGO TERMINADO",
  "youWin": "¡GANASTE!",
  "youLose": "PERDISTE",
  "playAgain": "JUGAR DE NUEVO"
}
```

### 6.4 App Integration

```dart
// lib/main.dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Game',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('de'), // German
      ],
      theme: AppTheme.theme,
      home: const GameScreen(),
    );
  }
}
```

### 6.5 Usage in UI Widgets

```dart
// In any widget
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return ElevatedButton(
    onPressed: onStartGame,
    child: Text(l10n.startGame),  // ← Localized text
  );
}
```

### 6.6 Usage in Dialogs

```dart
// lib/widgets/coin_toss_dialog.dart
class CoinTossDialog {
  static Future<void> show({
    required BuildContext context,
    required Turn turn,
    required bool enableAI,
    required VoidCallback onStartGame,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final winner = turn == Turn.red ? 'Red Player' : 'Blue Player';
    final glowColor = AppTheme.getPlayerColor(turn == Turn.red);

    return showAnimatedDialog(
      context: context,
      glowColor: glowColor,
      barrierDismissible: false,
      content: GameDialogContent(
        title: l10n.coinToss,  // ← Localized
        icon: Icons.casino,
        glowColor: glowColor,
        children: [
          GameDialogText(
            text: l10n.playerWins(winner),  // ← With placeholder
            color: glowColor,
            withGlow: true,
          ),
          const SizedBox(height: 12),
          GameDialogText(
            text: l10n.theyStartFirst,  // ← Localized
          ),
        ],
        actions: [
          GameDialogButton(
            label: l10n.startGame,  // ← Localized
            onPressed: (dialogContext) async {
              await dismissAnimatedDialog(dialogContext);
              onStartGame();
            },
          ),
        ],
      ),
    );
  }
}
```

### 6.7 Dynamic Language Switching

```dart
// In settings screen
class SettingsScreen extends StatelessWidget {
  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DropdownButton<String>(
      value: settingsService.language,
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'es', child: Text('Español')),
        DropdownMenuItem(value: 'fr', child: Text('Français')),
      ],
      onChanged: (String? newLang) async {
        if (newLang != null) {
          await settingsService.setLanguage(newLang);
          // Restart app to apply new language
          // (or use a state management solution to rebuild)
        }
      },
    );
  }
}
```
</CODE_PATTERN>

---

## 7) UI Overlay Integration

<CODE_PATTERN>
### 7.1 GameWidget with Overlays

```dart
// lib/screens/game_screen.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  final SaveGameService saveService;
  final SettingsService settingsService;

  const GameScreen({
    super.key,
    required this.saveService,
    required this.settingsService,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MyGame _game;
  bool _showPauseMenu = false;

  @override
  void initState() {
    super.initState();
    _game = MyGame(saveService: widget.saveService);

    // Setup callbacks from game to UI
    _game.onGameStateChanged = _handleGameStateChanged;
    _game.onScoreChanged = (_) => setState(() {});
  }

  void _handleGameStateChanged(GameState state) {
    setState(() {
      _showPauseMenu = state == GameState.paused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Game canvas (full screen)
          SafeArea(
            child: SizedBox.expand(
              child: GameWidget(game: _game),
            ),
          ),

          // HUD overlay (score, health, etc.)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: HudWidget(game: _game),
          ),

          // Pause menu overlay
          if (_showPauseMenu)
            PauseMenuOverlay(
              onResume: () => _game.resumeGame(),
              onMainMenu: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}
```

### 7.2 HUD Widget

```dart
// lib/widgets/hud_widget.dart
/// Heads-up display showing game stats
class HudWidget extends StatelessWidget {
  final MyGame game;

  const HudWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: AppTheme.tronContainer(
            glowColor: AppColors.neonCyan,
            borderRadius: 8,
          ),
          child: Text(
            l10n.score(game.score),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),

        // Level
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: AppTheme.tronContainer(
            glowColor: AppColors.neonGreen,
            borderRadius: 8,
          ),
          child: Text(
            l10n.level(game.level),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}
```

### 7.3 Self-Contained Dialog Pattern

```dart
// lib/widgets/game_over_dialog.dart
/// Self-contained game over dialog with localization
class GameOverDialog {
  static Future<void> show({
    required BuildContext context,
    required bool won,
    required int finalScore,
    required VoidCallback onPlayAgain,
    required VoidCallback onMainMenu,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final glowColor = won ? AppColors.neonGreen : AppColors.neonPink;

    return showAnimatedDialog(
      context: context,
      glowColor: glowColor,
      barrierDismissible: false,
      content: GameDialogContent(
        title: l10n.gameOver,
        icon: won ? Icons.emoji_events : Icons.close,
        glowColor: glowColor,
        children: [
          GameDialogText(
            text: won ? l10n.youWin : l10n.youLose,
            color: glowColor,
            withGlow: true,
          ),
          const SizedBox(height: 16),
          GameDialogText(
            text: l10n.score(finalScore),
          ),
        ],
        actions: [
          GameDialogButton(
            label: l10n.playAgain,
            onPressed: (dialogContext) async {
              await dismissAnimatedDialog(dialogContext);
              onPlayAgain();
            },
          ),
          const SizedBox(height: 8),
          GameDialogButton(
            label: l10n.mainMenu,
            color: AppColors.textWhite70,
            onPressed: (dialogContext) async {
              await dismissAnimatedDialog(dialogContext);
              onMainMenu();
            },
          ),
        ],
      ),
    );
  }
}
```

**Key principles:**
- Dialog knows nothing about game internals
- Takes only necessary data + callbacks
- Handles its own dismissal
- Uses localization
- Self-contained and reusable
</CODE_PATTERN>

---

## 8) Input Handling

<CODE_PATTERN>
### 8.1 Touch/Tap Detection

```dart
class MyGame extends FlameGame with TapDetector {
  @override
  void onTapDown(TapDownInfo info) {
    final tapPosition = info.eventPosition.widget;

    // Check if tapped on player
    if (player.containsPoint(tapPosition)) {
      player.onTapped();
    }
  }

  @override
  void onTapUp(TapUpInfo info) {
    // Handle tap release
  }
}
```

### 8.2 Drag Detection

```dart
class MyGame extends FlameGame with PanDetector {
  Vector2? _dragStart;
  Vector2? _dragCurrent;
  bool _isDragging = false;

  @override
  void onPanStart(DragStartInfo info) {
    final position = info.eventPosition.widget;

    if (player.containsPoint(position)) {
      _isDragging = true;
      _dragStart = player.position.clone();
      _dragCurrent = position.clone();
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!_isDragging) return;

    _dragCurrent = info.eventPosition.widget;

    // Calculate drag vector
    final dragVector = _dragCurrent! - _dragStart!;

    // Apply force in opposite direction (slingshot)
    final force = -dragVector * 0.5;
    player.applyForce(force);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _isDragging = false;
    _dragStart = null;
    _dragCurrent = null;
  }
}
```

### 8.3 Multi-Touch

```dart
class MyGame extends FlameGame with MultiTouchTapDetector {
  @override
  void onTap(int pointerId, TapDownInfo info) {
    // Handle individual touch point
    final position = info.eventPosition.widget;
    _handleTouch(pointerId, position);
  }

  @override
  void onTapCancel(int pointerId) {
    // Handle touch cancellation
  }
}
```
</CODE_PATTERN>

---

## 9) Collision Detection

<CODE_PATTERN>
### 9.1 Basic Collision Setup

```dart
// Main game with collision detection
class MyGame extends FlameGame with HasCollisionDetection {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Components with collision will auto-register
  }
}

// Component with circular hitbox
class BallComponent extends CircleComponent
    with CollisionCallbacks, HasGameReference<MyGame> {

  BallComponent({
    required Vector2 position,
    double radius = 15,
  }) : super(
          position: position,
          radius: radius,
          anchor: Anchor.center,
        );

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is PlayerComponent) {
      _handlePlayerCollision(other);
    } else if (other is WallComponent) {
      _handleWallCollision();
    }
  }

  void _handlePlayerCollision(PlayerComponent player) {
    // Elastic collision physics
    final normal = (position - player.position).normalized();
    final relativeVelocity = velocity - player.velocity;
    final velocityAlongNormal = relativeVelocity.dot(normal);

    if (velocityAlongNormal > 0) return; // Moving apart

    final restitution = 0.8;
    final impulse = -(1 + restitution) * velocityAlongNormal;

    velocity.add(normal * impulse);
  }

  void _handleWallCollision() {
    // Bounce off walls
    if (position.x <= radius || position.x >= game.size.x - radius) {
      velocity.x *= -0.9; // Bounce with damping
    }
    if (position.y <= radius || position.y >= game.size.y - radius) {
      velocity.y *= -0.9;
    }
  }
}
```

### 9.2 Custom Hitboxes

```dart
class PlayerComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<MyGame> {

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add circular hitbox
    add(CircleHitbox(
      radius: 30,
      anchor: Anchor.center,
    ));
  }
}

// Rectangle hitbox
class WallComponent extends PositionComponent
    with CollisionCallbacks {

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(RectangleHitbox(
      size: size,
      position: Vector2.zero(),
    ));
  }
}

// Polygon hitbox
class TriangleComponent extends PositionComponent
    with CollisionCallbacks {

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(PolygonHitbox([
      Vector2(0, -20),
      Vector2(-15, 10),
      Vector2(15, 10),
    ]));
  }
}
```
</CODE_PATTERN>

---

## 10) Audio Management

<CODE_PATTERN>
### 10.1 Audio Service

```dart
// lib/services/audio_service.dart
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Centralized audio management service
class AudioService {
  final SettingsService settingsService;

  AudioService(this.settingsService);

  /// Initialize audio system
  Future<void> init() async {
    // Preload audio files
    await FlameAudio.audioCache.loadAll([
      'music/background.mp3',
      'sfx/hit.mp3',
      'sfx/score.mp3',
      'sfx/lose.mp3',
      'sfx/win.mp3',
    ]);

    if (kDebugMode) {
      debugPrint('AudioService initialized');
    }
  }

  /// Play background music (looping)
  Future<void> playMusic() async {
    if (!settingsService.musicEnabled) return;

    await FlameAudio.bgm.play(
      'music/background.mp3',
      volume: settingsService.volume,
    );
  }

  /// Stop background music
  void stopMusic() {
    FlameAudio.bgm.stop();
  }

  /// Pause background music
  void pauseMusic() {
    FlameAudio.bgm.pause();
  }

  /// Resume background music
  void resumeMusic() {
    FlameAudio.bgm.resume();
  }

  /// Play sound effect
  Future<void> playSfx(String filename) async {
    if (!settingsService.sfxEnabled) return;

    await FlameAudio.play(
      'sfx/$filename',
      volume: settingsService.volume,
    );
  }

  /// Update volume for all audio
  void setVolume(double volume) {
    FlameAudio.bgm.audioPlayer.setVolume(volume);
  }

  /// Dispose audio resources
  void dispose() {
    FlameAudio.bgm.dispose();
  }
}
```

### 10.2 Usage in Game

```dart
class MyGame extends FlameGame {
  final AudioService? audioService;

  MyGame({this.audioService});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    audioService?.playMusic();
  }

  void onBallHit() {
    audioService?.playSfx('hit.mp3');
  }

  void onScore() {
    audioService?.playSfx('score.mp3');
  }

  void onGameOver(bool won) {
    audioService?.playSfx(won ? 'win.mp3' : 'lose.mp3');
  }
}
```
</CODE_PATTERN>

---

## 11) Performance Optimization

<CRITICAL_RULE>
### 11.1 Target: 60 FPS

**Principles:**
- Keep `update()` methods fast (<16ms per frame)
- Minimize allocations in `update()` and `render()`
- Use object pooling for frequently created/destroyed objects
- Profile with Flutter DevTools

### 11.2 Object Pooling

```dart
// lib/game/systems/bullet_pool.dart
/// Object pool for bullets to avoid garbage collection
class BulletPool {
  final List<BulletComponent> _available = [];
  final List<BulletComponent> _inUse = [];
  final int maxSize;

  BulletPool({this.maxSize = 50});

  /// Get a bullet from the pool
  BulletComponent acquire(Vector2 position, Vector2 velocity) {
    BulletComponent bullet;

    if (_available.isNotEmpty) {
      bullet = _available.removeLast();
      bullet.reset(position, velocity);
    } else {
      bullet = BulletComponent(position: position, velocity: velocity);
    }

    _inUse.add(bullet);
    return bullet;
  }

  /// Return bullet to pool
  void release(BulletComponent bullet) {
    _inUse.remove(bullet);
    if (_available.length < maxSize) {
      _available.add(bullet);
    }
  }

  /// Clear all bullets
  void clear() {
    _available.clear();
    _inUse.clear();
  }
}

// In game
class MyGame extends FlameGame {
  late BulletPool bulletPool;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    bulletPool = BulletPool();
  }

  void fireBullet(Vector2 position, Vector2 direction) {
    final bullet = bulletPool.acquire(position, direction);
    add(bullet);
  }

  void removeBullet(BulletComponent bullet) {
    bullet.removeFromParent();
    bulletPool.release(bullet);
  }
}
```

### 11.3 Efficient Collision Detection

```dart
// Use spatial partitioning for many objects
class MyGame extends FlameGame with HasQuadTreeCollisionDetection {
  // QuadTree automatically optimizes collision checks
}

// Or manually check only nearby objects
void checkCollisionsInRadius(Vector2 position, double radius) {
  final nearbyComponents = children.query<EnemyComponent>().where((enemy) {
    return position.distanceTo(enemy.position) < radius;
  });

  for (final enemy in nearbyComponents) {
    _handleCollision(enemy);
  }
}
```

### 11.4 Minimize Widget Rebuilds

```dart
// Bad: Entire widget tree rebuilds on score change
class GameScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Stack([
      GameWidget(game: _game),
      HudWidget(score: _game.score),  // ← Rebuilds everything
    ]);
  }
}

// Good: Only HUD rebuilds
class GameScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Stack([
      GameWidget(game: _game),
      // Use ValueListenableBuilder for targeted rebuilds
      ValueListenableBuilder<int>(
        valueListenable: _scoreNotifier,
        builder: (context, score, child) {
          return HudWidget(score: score);  // ← Only HUD rebuilds
        },
      ),
    ]);
  }
}
```
</CRITICAL_RULE>

---

## 12) Testing

<CODE_PATTERN>
### 12.1 Component Tests

```dart
// test/game/components/player_component_test.dart
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerComponent', () {
    testWithGame<MyGame>(
      'applies force correctly',
      MyGame.new,
      (game) async {
        final player = PlayerComponent(
          position: Vector2(100, 100),
          team: Team.red,
        );
        await game.add(player);
        await game.ready();

        // Apply force
        player.applyForce(Vector2(10, 0));

        // Update once
        game.update(0.016); // 1 frame at 60fps

        // Check velocity changed
        expect(player.velocity.x, greaterThan(0));
      },
    );

    testWithGame<MyGame>(
      'stops when velocity is low',
      MyGame.new,
      (game) async {
        final player = PlayerComponent(
          position: Vector2(100, 100),
          team: Team.red,
        );
        await game.add(player);
        await game.ready();

        // Set very low velocity
        player.velocity = Vector2(0.05, 0.05);

        expect(player.isStopped, isTrue);
      },
    );
  });
}
```

### 12.2 Game Logic Tests

```dart
// test/game/air_hockey_game_test.dart
void main() {
  group('AirHockeyGame', () {
    testWithGame<AirHockeyGame>(
      'starts with correct initial state',
      AirHockeyGame.new,
      (game) async {
        await game.ready();

        expect(game.redScore, 0);
        expect(game.blueScore, 0);
        expect(game.currentTurn, isNotNull);
      },
    );

    testWithGame<AirHockeyGame>(
      'score changes trigger callback',
      AirHockeyGame.new,
      (game) async {
        await game.ready();

        int callbackScore = 0;
        game.onScoreChanged = (red, blue) {
          callbackScore = red;
        };

        game.redScore = 5;
        game.onScoreChanged?.call(game.redScore, game.blueScore);

        expect(callbackScore, 5);
      },
    );
  });
}
```

### 12.3 Widget Tests for UI

```dart
// test/widgets/coin_toss_dialog_test.dart
void main() {
  testWidgets('CoinTossDialog shows correct text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  CoinTossDialog.show(
                    context: context,
                    turn: Turn.red,
                    enableAI: false,
                    onStartGame: () {},
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('COIN TOSS'), findsOneWidget);
    expect(find.text('Red Player wins the toss!'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);
  });
}
```
</CODE_PATTERN>

---

## 13) Working with Claude

<CLAUDE_INSTRUCTION>
### 13.1 Prompt Template for Flame Games

```
You are contributing to a Flame game project.

Architecture:
- Game logic: Flame components in lib/game/
- UI overlays: Flutter widgets in lib/screens/ and lib/widgets/
- Services: Storage (save games, settings) and audio in lib/services/
- State: Game state in FlameGame class; UI state via callbacks
- Localization: flutter_localizations with ARB files
- Theme: Material 3 for UI; custom rendering for game

Rules:
- KISS, SoC, SSOT
- No hardcoded text (use AppLocalizations)
- No hardcoded styles (use Theme/AppTheme)
- Performance: Target 60fps, minimize allocations
- Use debugPrint() for logging (acceptable in games)

Task: [Your specific task - e.g., "Add enemy spawning system with difficulty scaling"]

Context: [Current architecture details, existing components to reuse]

Constraints:
- [Any specific limitations or requirements]

Output: Code blocks per file with full contents and file paths.
```

### 13.2 Example Prompts

**Adding a new component:**
```
Task: Create a PowerUpComponent that randomly spawns on the field, rotates slowly, and gives the player a speed boost when collected.

Context:
- Game: AirHockeyGame with HasCollisionDetection
- Existing: PlayerComponent with applyForce() method
- Theme: Use AppColors.neonAmber for power-up glow

Constraints:
- Power-up should despawn after 10 seconds if not collected
- Use object pooling pattern (see BulletPool example)
- Add collection sound effect via audioService?.playSfx()

Output: lib/game/components/power_up_component.dart
```

**Adding save/load functionality:**
```
Task: Add save/load functionality for game progress including current level, high score, and unlocked power-ups.

Context:
- SaveGameService already exists with saveProgress/loadProgress methods
- Game class: AirHockeyGame with level, score, unlockedPowerUps properties
- Need to save on game over, load on game start

Constraints:
- Use existing GameProgress model
- Add save button in pause menu
- Show "Continue" option in main menu if save exists

Output:
- Modifications to lib/game/air_hockey_game.dart
- Modifications to lib/screens/menu_screen.dart
```

**Adding localization:**
```
Task: Add Spanish localization for all UI text.

Context:
- English ARB: lib/l10n/app_en.arb
- Existing widgets use AppLocalizations.of(context)

Constraints:
- Maintain placeholder structure for parameterized strings
- Use proper Spanish game terminology

Output: lib/l10n/app_es.arb with all translated strings
```

### 13.3 Guardrails for Claude

**DO:**
- Follow Flame component lifecycle (onLoad, update, render)
- Use HasGameReference<T> for accessing game instance
- Keep game logic separate from UI code
- Use localization for all user-facing text
- Profile performance-critical code
- Add /// documentation to public APIs

**DON'T:**
- Import Flutter UI packages in game components
- Hardcode strings or style values
- Create new singletons (use dependency injection)
- Ignore null safety warnings
- Allocate objects in update() loop
- Use print() (use debugPrint() instead)
</CLAUDE_INSTRUCTION>

---

## 14) Common Patterns Library

<TEMPLATE>
### 14.1 Main.dart with Services

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final saveService = SaveGameService();
  await saveService.init();

  final settingsService = SettingsService();
  await settingsService.init();

  final audioService = AudioService(settingsService);
  await audioService.init();

  runApp(MyApp(
    saveService: saveService,
    settingsService: settingsService,
    audioService: audioService,
  ));
}

class MyApp extends StatelessWidget {
  final SaveGameService saveService;
  final SettingsService settingsService;
  final AudioService audioService;

  const MyApp({
    super.key,
    required this.saveService,
    required this.settingsService,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Game',
      debugShowCheckedModeBanner: false,

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],

      // Theme
      theme: AppTheme.theme,

      // Home
      home: MenuScreen(
        saveService: saveService,
        settingsService: settingsService,
        audioService: audioService,
      ),
    );
  }
}
```

### 14.2 Menu Screen with Continue Option

```dart
// lib/screens/menu_screen.dart
class MenuScreen extends StatelessWidget {
  final SaveGameService saveService;
  final SettingsService settingsService;
  final AudioService audioService;

  const MenuScreen({
    super.key,
    required this.saveService,
    required this.settingsService,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasSave = saveService.hasSavedGame();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkNavy, AppColors.pureBlack],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    shadows: AppTheme.createTextGlow(AppColors.neonCyan),
                  ),
                ),

                const SizedBox(height: 60),

                // Continue button (if save exists)
                if (hasSave) ...[
                  GameMenuButton(
                    label: l10n.continueGame,
                    glowColor: AppColors.neonGreen,
                    onPressed: () => _continueGame(context),
                  ),
                  const SizedBox(height: 16),
                ],

                // New game button
                GameMenuButton(
                  label: l10n.newGame,
                  glowColor: AppColors.neonCyan,
                  onPressed: () => _startNewGame(context),
                ),

                const SizedBox(height: 16),

                // Settings button
                GameMenuButton(
                  label: l10n.settings,
                  glowColor: AppColors.neonAmber,
                  onPressed: () => _openSettings(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _continueGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          saveService: saveService,
          settingsService: settingsService,
          audioService: audioService,
          loadSave: true,
        ),
      ),
    );
  }

  void _startNewGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          saveService: saveService,
          settingsService: settingsService,
          audioService: audioService,
          loadSave: false,
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          settingsService: settingsService,
          audioService: audioService,
        ),
      ),
    );
  }
}
```

### 14.3 Pause Menu Overlay

```dart
// lib/widgets/pause_menu_overlay.dart
class PauseMenuOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onSave;
  final VoidCallback onMainMenu;

  const PauseMenuOverlay({
    super.key,
    required this.onResume,
    required this.onSave,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.tronContainer(
            glowColor: AppColors.neonCyan,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.paused,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 32),

              GameDialogButton(
                label: l10n.resumeGame,
                onPressed: (_) => onResume(),
              ),
              const SizedBox(height: 12),

              GameDialogButton(
                label: l10n.saveGame,
                color: AppColors.neonGreen,
                onPressed: (_) => onSave(),
              ),
              const SizedBox(height: 12),

              GameDialogButton(
                label: l10n.mainMenu,
                color: AppColors.textWhite70,
                onPressed: (_) => onMainMenu(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
</TEMPLATE>

---

## 15) Definition of Done

<CRITICAL_RULE>
**Checklist for every feature/PR:**

• Follows KISS, SoC, SSOT; no globals introduced
• Game logic in components/systems, UI in widgets
• All user-facing text uses localization (AppLocalizations)
• No hardcoded visual styles (uses Theme/AppTheme)
• Save/load works correctly if applicable
• Performance: Runs at 60fps on target devices
• No allocations in hot paths (update/render loops)
• Audio plays correctly with volume/mute settings
• Unit tests for game logic and components
• Widget tests for UI overlays
• Accessibility pass where applicable
• Analyzer passes with no warnings
• Documentation comments on public APIs
</CRITICAL_RULE>

---

## 16) Quick Reference

<CLAUDE_INSTRUCTION>
### Package Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flame: ^1.32.0
  flame_audio: ^2.1.0
  shared_preferences: ^2.5.3
  hive_flutter: ^1.1.0
  intl: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flame_test: ^1.32.0
  very_good_analysis: ^9.0.0
```

### Common Commands

```bash
# Run game
flutter run

# Generate localizations
flutter gen-l10n

# Run tests
flutter test

# Profile performance
flutter run --profile

# Build release
flutter build apk --release
```

### Project Structure at a Glance

```
lib/
  game/                 # Flame game code
    components/         # Game entities
    systems/            # AI, physics
    [game_name].dart    # Main game class
  screens/              # Full UI screens
  widgets/              # Reusable UI
  theme/                # Styling
  services/             # Storage, audio
  l10n/                 # Translations
  main.dart             # Entry point
```

**Reminder for Claude:**
- Games need save/load systems for progress persistence
- Always use localization for text (AppLocalizations)
- Performance is critical (60fps target)
- Game logic stays in Flame components
- UI overlays use Flutter widgets
- Services handle cross-cutting concerns
</CLAUDE_INSTRUCTION>
