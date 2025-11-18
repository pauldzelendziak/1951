# Statistics and Persistence

## Purpose

Persistence systems save player progress, preferences, and statistics between sessions. This includes high scores, unlocked content, settings, and cumulative stats, creating continuity and investment in the game.

## Dependencies

```yaml
dependencies:
  shared_preferences: ^2.5.3  # Key-value storage
  # Optional for complex data:
  hive_flutter: ^1.1.0
```

---

## Architecture Overview

### Two-Service Pattern

```
┌────────────────────────────────┐
│  SettingsService               │  ← User preferences
│  - Music on/off                │
│  - Sound on/off                │
│  - Background selection        │
└────────────────────────────────┘

┌────────────────────────────────┐
│  SaveGameService               │  ← Game progress
│  - Best score/level            │
│  - Crystals/currency           │
│  - Unlocked achievements       │
│  - Cumulative statistics       │
│  - Purchased items             │
└────────────────────────────────┘
```

**Why Two Services?**
- **Separation of concerns**: Settings vs. game data
- **Different access patterns**: Settings read frequently, game data written often
- **Clear responsibilities**: Easier to test and maintain

---

## 1. SettingsService

### Purpose
Store user preferences that persist across app restarts.

### Architecture

```dart
class SettingsService {
  static const String _musicEnabledKey = 'music_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _currentBackgroundKey = 'current_background';

  late SharedPreferences _prefs;

  // Factory constructor for singleton pattern
  static SettingsService? _instance;

  factory SettingsService.initialize(SharedPreferences prefs) {
    _instance = SettingsService._internal(prefs);
    return _instance!;
  }

  SettingsService._internal(this._prefs);

  // Getters with defaults
  bool get isMusicEnabled => _prefs.getBool(_musicEnabledKey) ?? true;
  bool get isSoundEnabled => _prefs.getBool(_soundEnabledKey) ?? true;
  String get currentBackground =>
      _prefs.getString(_currentBackgroundKey) ?? 'assets/images/backgrounds/background_1.jpg';

  // Setters
  Future<void> setMusicEnabled(bool enabled) async {
    await _prefs.setBool(_musicEnabledKey, enabled);
    notifyListeners(); // If using ChangeNotifier
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(_soundEnabledKey, enabled);
  }

  Future<void> setCurrentBackground(String path) async {
    await _prefs.setString(_currentBackgroundKey, path);
    notifyListeners();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    await _prefs.clear();
  }
}
```

**Setup Checklist**:
- [ ] Create SettingsService class
- [ ] Accept SharedPreferences in constructor
- [ ] Define keys as constants
- [ ] Implement getters with default values
- [ ] Implement async setters
- [ ] Optional: Extend ChangeNotifier for reactive updates
- [ ] Add reset method

**Supported Types**:
- `bool` - Toggles (music, sound, tutorial shown)
- `int` - Numeric settings (volume levels 0-100)
- `double` - Decimal values (rarely needed)
- `String` - Text values (background paths, language)
- `List<String>` - String lists (favorite skins)

---

## 2. SaveGameService

### Purpose
Persist game progress, currency, unlocked content, and statistics.

### Architecture

```dart
class SaveGameService {
  static const String _bestScoreKey = 'best_score';
  static const String _bestLevelKey = 'best_level';
  static const String _crystalsKey = 'crystals';
  static const String _purchasedSkinsKey = 'purchased_skins';
  static const String _currentSkinKey = 'current_skin';
  static const String _unlockedAchievementsKey = 'unlocked_achievements';
  static const String _cumulativeStatsKey = 'cumulative_stats';

  late SharedPreferences _prefs;

  static SaveGameService? _instance;

  factory SaveGameService.initialize(SharedPreferences prefs) {
    _instance = SaveGameService._internal(prefs);
    return _instance!;
  }

  SaveGameService._internal(this._prefs);

  // ========== High Scores ==========
  int get bestScore => _prefs.getInt(_bestScoreKey) ?? 0;
  int get bestLevel => _prefs.getInt(_bestLevelKey) ?? 0;

  Future<void> updateBestScore(int score, int level) async {
    if (score > bestScore) {
      await _prefs.setInt(_bestScoreKey, score);
      await _prefs.setInt(_bestLevelKey, level);
    }
  }

  // ========== Currency ==========
  int get crystals => _prefs.getInt(_crystalsKey) ?? 0;

  Future<void> addCrystals(int amount) async {
    final newAmount = crystals + amount;
    await _prefs.setInt(_crystalsKey, newAmount);
  }

  Future<bool> spendCrystals(int amount) async {
    if (crystals >= amount) {
      final newAmount = crystals - amount;
      await _prefs.setInt(_crystalsKey, newAmount);
      return true;
    }
    return false;
  }

  // ========== Skins/Purchases ==========
  List<String> get purchasedSkins =>
      _prefs.getStringList(_purchasedSkinsKey) ?? ['ship_1']; // Default skin

  String get currentSkin => _prefs.getString(_currentSkinKey) ?? 'ship_1';

  Future<bool> purchaseSkin(String skinId, int cost) async {
    // Check if already owned
    if (purchasedSkins.contains(skinId)) return false;

    // Check if enough currency
    if (!await spendCrystals(cost)) return false;

    // Add to owned skins
    final skins = purchasedSkins..add(skinId);
    await _prefs.setStringList(_purchasedSkinsKey, skins);
    return true;
  }

  Future<void> setCurrentSkin(String skinId) async {
    if (purchasedSkins.contains(skinId)) {
      await _prefs.setString(_currentSkinKey, skinId);
    }
  }

  // ========== Achievements ==========
  List<String> getUnlockedAchievements() =>
      _prefs.getStringList(_unlockedAchievementsKey) ?? [];

  Future<void> addUnlockedAchievement(String achievementId) async {
    final unlocked = getUnlockedAchievements();
    if (!unlocked.contains(achievementId)) {
      unlocked.add(achievementId);
      await _prefs.setStringList(_unlockedAchievementsKey, unlocked);
    }
  }

  // ========== Cumulative Stats ==========
  Map<String, dynamic> getCumulativeStats() {
    final jsonString = _prefs.getString(_cumulativeStatsKey) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(jsonString));
  }

  Future<void> saveCumulativeStats(Map<String, dynamic> stats) async {
    final jsonString = jsonEncode(stats);
    await _prefs.setString(_cumulativeStatsKey, jsonString);
  }

  // ========== Reset ==========
  Future<void> resetAllData() async {
    await _prefs.remove(_bestScoreKey);
    await _prefs.remove(_bestLevelKey);
    await _prefs.remove(_crystalsKey);
    await _prefs.remove(_purchasedSkinsKey);
    await _prefs.remove(_currentSkinKey);
    await _prefs.remove(_unlockedAchievementsKey);
    await _prefs.remove(_cumulativeStatsKey);
  }
}
```

**Setup Checklist**:
- [ ] Create SaveGameService class
- [ ] Define all storage keys as constants
- [ ] Implement high score tracking
- [ ] Implement currency system (add/spend)
- [ ] Implement purchase system with validation
- [ ] Implement achievement unlock tracking
- [ ] Implement cumulative stats (JSON encoding)
- [ ] Add reset method
- [ ] Add proper error handling

---

## Initialization

### In main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize services
  final settingsService = SettingsService.initialize(prefs);
  final saveGameService = SaveGameService.initialize(prefs);

  // Initialize other services
  final audioService = AudioService(settingsService);
  await audioService.initialize();

  final achievementService = AchievementService(saveGameService);
  final backgroundManager = BackgroundManager();

  // Register in ServiceLocator
  ServiceLocator.initialize(
    audioService: audioService,
    settingsService: settingsService,
    achievementService: achievementService,
  );

  runApp(MyApp(
    audioService: audioService,
    settingsService: settingsService,
    saveGameService: saveGameService,
    achievementService: achievementService,
    backgroundManager: backgroundManager,
  ));
}
```

**Setup Checklist**:
- [ ] Call WidgetsFlutterBinding.ensureInitialized()
- [ ] Initialize SharedPreferences (async)
- [ ] Initialize SettingsService
- [ ] Initialize SaveGameService
- [ ] Pass services to app

---

## Data Patterns

### 1. Simple Values (int, bool, String)

```dart
// Read
final score = _prefs.getInt('score') ?? 0;

// Write
await _prefs.setInt('score', 100);
```

### 2. Lists

```dart
// Read
final skins = _prefs.getStringList('skins') ?? ['default'];

// Write
await _prefs.setStringList('skins', ['default', 'red', 'blue']);
```

### 3. Complex Objects (JSON)

```dart
// Write
final stats = {'total_games': 100, 'total_deaths': 50};
await _prefs.setString('stats', jsonEncode(stats));

// Read
final jsonString = _prefs.getString('stats') ?? '{}';
final stats = Map<String, dynamic>.from(jsonDecode(jsonString));
```

### 4. Custom Objects

```dart
class PlayerProfile {
  final String name;
  final int level;

  Map<String, dynamic> toJson() => {'name': name, 'level': level};

  factory PlayerProfile.fromJson(Map<String, dynamic> json) =>
      PlayerProfile(name: json['name'], level: json['level']);
}

// Save
final profile = PlayerProfile(name: 'Player', level: 5);
await _prefs.setString('profile', jsonEncode(profile.toJson()));

// Load
final jsonString = _prefs.getString('profile');
if (jsonString != null) {
  final profile = PlayerProfile.fromJson(jsonDecode(jsonString));
}
```

---

## Usage Examples

### High Score Update

```dart
// In GameOverDialog:
final score = gameLoopManager.score;
final level = gameLoopManager.level;

await saveGameService.updateBestScore(score, level);

final isNewBest = score > saveGameService.bestScore;
```

### Currency System

```dart
// Collect crystals in game
await saveGameService.addCrystals(10);

// Purchase in shop
final skinCost = 50;
final success = await saveGameService.purchaseSkin('ship_2', skinCost);

if (success) {
  showSuccessMessage('Skin purchased!');
} else {
  showErrorMessage('Not enough crystals');
}
```

### Achievement Tracking

```dart
// In AchievementService:
void _unlockAchievement(Achievement achievement) {
  saveGameService.addUnlockedAchievement(achievement.id);
  _unlockController.add(achievement);
}

// Check if unlocked:
final isUnlocked = saveGameService
    .getUnlockedAchievements()
    .contains('first_win');
```

### Settings Toggle

```dart
// In SettingsScreen:
SwitchListTile(
  title: Text('Music'),
  value: settingsService.isMusicEnabled,
  onChanged: (value) async {
    await settingsService.setMusicEnabled(value);
    if (value) {
      audioService.playBackgroundMusic();
    } else {
      audioService.pauseBackgroundMusic();
    }
    setState(() {});
  },
)
```

---

## Advanced Features

### 1. Data Migration

```dart
class SaveGameService {
  static const int _currentVersion = 2;
  static const String _versionKey = 'data_version';

  void _migrate() {
    final version = _prefs.getInt(_versionKey) ?? 1;

    if (version < 2) {
      // Migrate from v1 to v2
      _migrateV1ToV2();
    }

    _prefs.setInt(_versionKey, _currentVersion);
  }

  void _migrateV1ToV2() {
    // Example: Rename key
    final oldScore = _prefs.getInt('score');
    if (oldScore != null) {
      _prefs.setInt('best_score', oldScore);
      _prefs.remove('score');
    }
  }
}
```

### 2. Cloud Sync (Optional)

```dart
// Using Firebase or custom backend
class CloudSyncService {
  Future<void> uploadProgress(SaveGameService saveGame) async {
    final data = {
      'best_score': saveGame.bestScore,
      'crystals': saveGame.crystals,
      'unlocked_achievements': saveGame.getUnlockedAchievements(),
    };

    await firestore.collection('players').doc(userId).set(data);
  }

  Future<void> downloadProgress(SaveGameService saveGame) async {
    final doc = await firestore.collection('players').doc(userId).get();
    // Merge with local data (keep highest scores, union of achievements, etc.)
  }
}
```

### 3. Export/Import

```dart
class SaveGameService {
  String exportData() {
    final data = {
      'best_score': bestScore,
      'best_level': bestLevel,
      'crystals': crystals,
      'purchased_skins': purchasedSkins,
      'unlocked_achievements': getUnlockedAchievements(),
      'cumulative_stats': getCumulativeStats(),
    };
    return jsonEncode(data);
  }

  Future<void> importData(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    await _prefs.setInt(_bestScoreKey, data['best_score'] ?? 0);
    await _prefs.setInt(_bestLevelKey, data['best_level'] ?? 0);
    await _prefs.setInt(_crystalsKey, data['crystals'] ?? 0);
    // ... import all fields
  }
}
```

---

## Best Practices

1. **Always provide defaults**: Use `??` operator for null safety
2. **Validate before saving**: Check data integrity
3. **Atomic operations**: Update related values together
4. **Error handling**: Wrap in try-catch for production
5. **Keys as constants**: Prevent typos and enable refactoring
6. **Don't over-persist**: Only save what's necessary
7. **Test reset functionality**: Ensure clean state after reset

---

## Common Pitfalls

1. **Not awaiting writes**
   - Problem: Data not saved before app closes
   - Solution: Always `await` setters

2. **Forgetting defaults**
   - Problem: Null errors on first launch
   - Solution: Use `?? defaultValue` on all getters

3. **JSON encoding errors**
   - Problem: Crashes when encoding complex objects
   - Solution: Implement `toJson()` methods

4. **Large data in SharedPreferences**
   - Problem: Performance degradation
   - Solution: Use Hive or SQLite for large datasets

5. **No data validation**
   - Problem: Corrupted data causes crashes
   - Solution: Validate on read and write

6. **Lost data on update**
   - Problem: App update clears SharedPreferences
   - Solution: Should not happen, but implement backup/restore

---

## Testing Checklist

- [ ] Data persists across app restarts
- [ ] Defaults work on first launch
- [ ] Reset clears all data
- [ ] Currency transactions are atomic
- [ ] Purchase validation works
- [ ] Achievement unlocks save correctly
- [ ] Settings changes reflect immediately
- [ ] No crashes with missing keys
- [ ] JSON encoding/decoding works

---

## Data Storage Limits

### SharedPreferences
- **Best for**: Small key-value pairs
- **Limit**: ~1-2 MB (platform-dependent)
- **Use cases**: Settings, high scores, simple lists

### When to Use Alternatives

**Hive** (recommended for complex data):
- Larger data sets (100+ items)
- Complex object graphs
- Faster read/write than SharedPreferences
- Type-safe

**SQLite** (for relational data):
- Complex queries
- Large datasets (1000+ records)
- Relational data (foreign keys, joins)

---

## Migration to Hive (Optional)

```dart
// Define model
@HiveType(typeId: 0)
class PlayerData extends HiveObject {
  @HiveField(0)
  int bestScore;

  @HiveField(1)
  List<String> unlockedAchievements;
}

// Initialize
await Hive.initFlutter();
Hive.registerAdapter(PlayerDataAdapter());
final box = await Hive.openBox<PlayerData>('player');

// Read/Write
final player = box.get('data', defaultValue: PlayerData());
player.bestScore = 100;
await player.save();
```

---

## Next Steps

After implementing persistence:
- Connect to **Achievement System** (04_Achievement_System.md)
- Integrate with **Audio System** (03_Audio_System.md) for settings
- Register in **Service Architecture** (06_Service_Architecture.md)
- Create reset UI in Settings screen
