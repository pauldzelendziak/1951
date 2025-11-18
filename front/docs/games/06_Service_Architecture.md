# Service Architecture

## Purpose

A well-designed service architecture provides clean separation of concerns, dependency management, and global access to shared functionality. It prevents tight coupling while making services easily accessible throughout your app.

## Dependencies

No additional packages required - uses Dart's built-in language features.

---

## Architecture Pattern

### Service Locator Pattern

**Why Service Locator?**
- **Global access**: Services available anywhere without deep prop drilling
- **Simplicity**: No complex DI framework needed for small-medium games
- **Type safety**: Compile-time checks for service availability
- **Testability**: Easy to mock services for testing

**Alternative**: Dependency Injection with provider/get_it
- Use if app grows to 20+ services
- Needed for complex widget trees
- Better for teams with established DI patterns

---

## Implementation

### ServiceLocator Class

```dart
class ServiceLocator {
  static AudioService? _audioService;
  static AchievementService? _achievementService;
  static SettingsService? _settingsService;
  // Add more services as needed

  // Getters with validation
  static AudioService get audioService {
    if (_audioService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _audioService!;
  }

  static AchievementService get achievementService {
    if (_achievementService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _achievementService!;
  }

  static SettingsService get settingsService {
    if (_settingsService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _settingsService!;
  }

  // Initialization (called once in main.dart)
  static void initialize({
    required AudioService audioService,
    required AchievementService achievementService,
    required SettingsService settingsService,
  }) {
    _audioService = audioService;
    _achievementService = achievementService;
    _settingsService = settingsService;
  }

  // For testing: reset services
  static void reset() {
    _audioService = null;
    _achievementService = null;
    _settingsService = null;
  }
}
```

**Setup Checklist**:
- [ ] Create ServiceLocator class
- [ ] Add private static fields for each service
- [ ] Implement getters with null checks
- [ ] Create initialize method
- [ ] Add reset method for testing
- [ ] Throw clear errors if not initialized

---

## Service Initialization Flow

### In main.dart

```dart
void main() async {
  // 1. Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize persistence layer
  final prefs = await SharedPreferences.getInstance();

  // 3. Create services (order matters for dependencies)
  final settingsService = SettingsService.initialize(prefs);
  final saveGameService = SaveGameService.initialize(prefs);

  // 4. Create services that depend on others
  final audioService = AudioService(settingsService);
  await audioService.initialize(); // Async initialization

  final achievementService = AchievementService(saveGameService);
  final backgroundManager = BackgroundManager();
  final spaceshipAnimationService = SpaceshipAnimationService();

  // 5. Register in ServiceLocator (services used globally)
  ServiceLocator.initialize(
    audioService: audioService,
    achievementService: achievementService,
    settingsService: settingsService,
  );

  // 6. Launch app with constructor-injected services
  runApp(MyApp(
    audioService: audioService,
    settingsService: settingsService,
    saveGameService: saveGameService,
    achievementService: achievementService,
    backgroundManager: backgroundManager,
    spaceshipAnimationService: spaceshipAnimationService,
  ));
}
```

**Initialization Order**:
1. **Persistence** (SharedPreferences, Hive)
2. **Settings/SaveGame** (depend on persistence)
3. **Other services** (may depend on settings/savegame)
4. **ServiceLocator registration** (register global services)
5. **App launch** (pass services via constructor)

---

## Hybrid Pattern: ServiceLocator + Constructor Injection

### When to Use Each

**ServiceLocator** (global access):
- Audio service (buttons, game components everywhere)
- Achievement service (unlocks from anywhere)
- Settings service (checked frequently)

**Constructor Injection** (explicit dependencies):
- Screen-specific services
- Services passed to top-level widgets
- Services that change between instances
- Better for testing individual widgets

### Example: Hybrid Approach

```dart
// Top-level: Constructor injection
class MyApp extends StatefulWidget {
  final AudioService audioService;
  final SettingsService settingsService;
  final SaveGameService saveGameService;
  final AchievementService achievementService;
  final BackgroundManager backgroundManager;

  const MyApp({
    required this.audioService,
    required this.settingsService,
    required this.saveGameService,
    required this.achievementService,
    required this.backgroundManager,
  });
}

// Screens: Constructor injection
class SettingsScreen extends StatelessWidget {
  final SettingsService settingsService;
  final AudioService audioService;

  const SettingsScreen({
    required this.settingsService,
    required this.audioService,
  });
}

// Widgets/Components: ServiceLocator
class GameButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ServiceLocator.audioService.playButtonSound();
        // ...
      },
    );
  }
}
```

**Benefits**:
- **Clarity**: Top-level dependencies explicit
- **Convenience**: Deep widgets use ServiceLocator
- **Testability**: Can mock both patterns
- **Flexibility**: Mix and match as needed

---

## Service Lifecycle

### Singleton Services

Most game services are singletons (one instance per app lifetime):

```dart
class SettingsService {
  static SettingsService? _instance;

  factory SettingsService.initialize(SharedPreferences prefs) {
    _instance ??= SettingsService._internal(prefs);
    return _instance!;
  }

  SettingsService._internal(this._prefs);

  late SharedPreferences _prefs;
}
```

### Scoped Services (Rare)

Some services may be game-session specific:

```dart
class GameSession {
  final GameLoopManager gameLoopManager;
  final SpaceAvoiderGame gameInstance;

  GameSession() {
    gameLoopManager = GameLoopManager();
    gameInstance = SpaceAvoiderGame(gameLoopManager: gameLoopManager);
  }

  void dispose() {
    gameLoopManager.dispose();
    // Don't register in ServiceLocator - passed via constructor
  }
}
```

---

## Service Dependencies

### Dependency Graph

```
SharedPreferences (root)
    ↓
SettingsService ────→ AudioService
    ↓                      ↓
SaveGameService    (registered in ServiceLocator)
    ↓
AchievementService
    ↓
(registered in ServiceLocator)
```

**Rules**:
1. **No circular dependencies**: Service A cannot depend on Service B if B depends on A
2. **Minimal dependencies**: Each service should depend on as few others as possible
3. **Stable foundation**: Persistence layer first, then services

### Breaking Circular Dependencies

**Problem**: AudioService needs SettingsService, SettingsService needs AudioService

**Solution**: Callbacks or streams

```dart
// SettingsService doesn't depend on AudioService
class SettingsService {
  final void Function(bool)? onMusicToggled;

  SettingsService({this.onMusicToggled});

  Future<void> setMusicEnabled(bool enabled) async {
    await _prefs.setBool('music_enabled', enabled);
    onMusicToggled?.call(enabled);
  }
}

// Wire up in main.dart
final settingsService = SettingsService(
  onMusicToggled: (enabled) {
    if (enabled) {
      audioService.playBackgroundMusic();
    } else {
      audioService.pauseBackgroundMusic();
    }
  },
);
```

---

## Testing with ServiceLocator

### Mock Services

```dart
class MockAudioService implements AudioService {
  List<String> playedSounds = [];

  @override
  Future<void> playSound(String filename, {double volume = 1.0}) async {
    playedSounds.add(filename);
  }

  // Implement other methods...
}

// In test:
void main() {
  setUp(() {
    final mockAudio = MockAudioService();
    ServiceLocator.initialize(
      audioService: mockAudio,
      // ... other mocks
    );
  });

  tearDown(() {
    ServiceLocator.reset();
  });

  test('Button plays sound', () {
    final button = GameButton(onPressed: () {});
    button.onTap();
    expect(mockAudio.playedSounds, contains('button.mp3'));
  });
}
```

---

## Service Communication Patterns

### 1. Direct Method Calls

Simple, synchronous communication:

```dart
ServiceLocator.audioService.playSound('jump.mp3');
```

### 2. Callbacks

Service notifies caller of events:

```dart
class GameLoopManager {
  void Function(int)? onScoreChanged;
  void Function(int)? onLevelChanged;

  void _updateScore(int newScore) {
    _score = newScore;
    onScoreChanged?.call(_score);
  }
}

// Usage:
gameLoopManager.onScoreChanged = (score) {
  setState(() => _displayedScore = score);
};
```

### 3. Streams

Asynchronous event broadcasting:

```dart
class AchievementService {
  final StreamController<Achievement> _unlockController =
      StreamController.broadcast();

  Stream<Achievement> get onAchievementUnlocked => _unlockController.stream;

  void _unlockAchievement(Achievement achievement) {
    _unlockController.add(achievement);
  }
}

// Usage:
achievementService.onAchievementUnlocked.listen((achievement) {
  showNotification('Achievement unlocked: ${achievement.name}');
});
```

### 4. ChangeNotifier (Optional)

For reactive UI updates:

```dart
class SettingsService extends ChangeNotifier {
  Future<void> setMusicEnabled(bool enabled) async {
    await _prefs.setBool('music_enabled', enabled);
    notifyListeners(); // Triggers rebuild of listening widgets
  }
}

// Usage with Provider:
Consumer<SettingsService>(
  builder: (context, settings, child) {
    return Switch(
      value: settings.isMusicEnabled,
      onChanged: (value) => settings.setMusicEnabled(value),
    );
  },
)
```

---

## Service Organization

### File Structure

```
lib/services/
├── service_locator.dart          # Global service registry
├── audio_service.dart            # Sound and music
├── achievement_service.dart      # Achievement tracking
├── background_manager.dart       # Background image management
├── spaceship_animation_service.dart  # Menu animations
└── storage/
    ├── save_game_service.dart    # Game progress
    └── settings_service.dart     # User preferences
```

### Service Naming Conventions

- **Suffix**: Always use `Service` or `Manager`
- **Descriptive**: Name should indicate purpose
- **Singular**: `AudioService` not `AudiosService`

---

## Advanced Patterns (Optional)

### Service Factory

For creating multiple instances:

```dart
class GameSessionFactory {
  static GameSession create({
    required SaveGameService saveGame,
    required AchievementService achievements,
  }) {
    final gameLoop = GameLoopManager();
    final game = SpaceAvoiderGame(
      gameLoopManager: gameLoop,
      achievementService: achievements,
    );

    return GameSession(
      gameLoop: gameLoop,
      game: game,
    );
  }
}
```

### Service Disposal

```dart
class ServiceLocator {
  static Future<void> dispose() async {
    await _audioService?.stopBackgroundMusic();
    _audioService = null;
    _achievementService = null;
    // ... dispose all services
  }
}

// In app:
@override
void dispose() {
  ServiceLocator.dispose();
  super.dispose();
}
```

---

## Best Practices

1. **Initialize early**: In `main()` before `runApp()`
2. **Validate initialization**: Throw errors if services not ready
3. **Minimize global services**: Only register truly global services
4. **Document dependencies**: Comment which services depend on others
5. **Avoid service bloat**: Keep services focused and single-purpose
6. **Use const constructors**: Where possible for services
7. **Handle async initialization**: Use async/await in main()

---

## Common Pitfalls

1. **Accessing before initialization**
   - Problem: ServiceLocator.audioService called before initialize()
   - Solution: Initialize in main() before runApp()

2. **Circular dependencies**
   - Problem: Service A depends on B, B depends on A
   - Solution: Use callbacks or streams

3. **Too many global services**
   - Problem: Everything in ServiceLocator
   - Solution: Use constructor injection for screen-specific services

4. **No disposal**
   - Problem: Services not cleaned up
   - Solution: Implement dispose methods and call in app disposal

5. **Testing difficulties**
   - Problem: Can't mock ServiceLocator
   - Solution: Implement reset() and use mocks in setUp()

---

## Checklist

- [ ] Create ServiceLocator class
- [ ] Define private fields for each service
- [ ] Implement getters with null checks
- [ ] Create initialize method
- [ ] Initialize services in correct order in main.dart
- [ ] Register global services in ServiceLocator
- [ ] Pass screen-specific services via constructors
- [ ] Document service dependencies
- [ ] Implement disposal if needed
- [ ] Add reset method for testing

---

## Next Steps

After setting up service architecture:
- Implement individual services (Audio, Achievement, etc.)
- Wire up services in **main.dart**
- Use ServiceLocator in **Shared UI Components** (01)
- Connect services to **Flame game components** (07)
