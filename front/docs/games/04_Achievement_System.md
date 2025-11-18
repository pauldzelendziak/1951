# Achievement System

## Purpose

An achievement system increases player engagement by providing goals, tracking progress, and celebrating milestones. It adds replay value and gives players a sense of progression beyond core gameplay.

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
```

No additional packages required - uses Dart streams and built-in collections.

---

## Architecture Overview

### Three-Component System

```
┌──────────────────────────────────────┐
│  1. Achievement Model                │  ← Data structure
│     - ID, name, description          │
│     - Type, required value, icon     │
└──────────────────────────────────────┘
              ↓
┌──────────────────────────────────────┐
│  2. Achievement Service              │  ← Business logic
│     - Track stats (game & cumulative)│
│     - Check unlock conditions        │
│     - Broadcast unlock events        │
└──────────────────────────────────────┘
              ↓
┌──────────────────────────────────────┐
│  3. UI Components                    │  ← Display
│     - AchievementsScreen             │
│     - AchievementCard                │
│     - Progress indicators            │
└──────────────────────────────────────┘
```

---

## 1. Achievement Model

### Data Structure

```dart
enum AchievementType {
  score,       // Reach specific score
  level,       // Reach specific level
  collection,  // Collect items
  skill,       // Perform action without mistakes
  cumulative,  // Total across all games
  humorous,    // Fun/unexpected achievements
}

class Achievement {
  final String id;              // Unique identifier
  final String name;            // Display name
  final String description;     // What to do
  final String icon;            // Icon asset path or IconData name
  final AchievementType type;   // Category
  final int requiredValue;      // Target value to unlock
  final String trackingKey;     // Key in stats map

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.requiredValue,
    required this.trackingKey,
  });
}
```

### Example Achievements

```dart
final achievements = [
  // Score achievements
  Achievement(
    id: 'score_100',
    name: 'Beginner',
    description: 'Reach score of 100',
    icon: 'star',
    type: AchievementType.score,
    requiredValue: 100,
    trackingKey: 'game_score',
  ),

  Achievement(
    id: 'score_1000',
    name: 'Expert',
    description: 'Reach score of 1000',
    icon: 'star_border',
    type: AchievementType.score,
    requiredValue: 1000,
    trackingKey: 'game_score',
  ),

  // Level achievements
  Achievement(
    id: 'level_5',
    name: 'Level Master',
    description: 'Reach level 5',
    icon: 'trending_up',
    type: AchievementType.level,
    requiredValue: 5,
    trackingKey: 'game_level',
  ),

  // Collection achievements (cumulative)
  Achievement(
    id: 'collect_100_crystals',
    name: 'Crystal Hunter',
    description: 'Collect 100 crystals total',
    icon: 'diamond',
    type: AchievementType.cumulative,
    requiredValue: 100,
    trackingKey: 'total_crystals_collected',
  ),

  // Skill achievements
  Achievement(
    id: 'immortal_collector',
    name: 'Untouchable',
    description: 'Collect 5 items without taking damage',
    icon: 'shield',
    type: AchievementType.skill,
    requiredValue: 5,
    trackingKey: 'items_collected_without_damage',
  ),

  // Cumulative achievements
  Achievement(
    id: 'play_100_games',
    name: 'Dedicated Player',
    description: 'Play 100 games',
    icon: 'videogame_asset',
    type: AchievementType.cumulative,
    requiredValue: 100,
    trackingKey: 'total_games_played',
  ),

  // Humorous achievements
  Achievement(
    id: 'die_quickly',
    name: 'Speed Runner (Wrong Way)',
    description: 'Die in the first 5 seconds',
    icon: 'sentiment_very_dissatisfied',
    type: AchievementType.humorous,
    requiredValue: 1,
    trackingKey: 'quick_deaths',
  ),
];
```

**Setup Checklist**:
- [ ] Define AchievementType enum
- [ ] Create Achievement class
- [ ] Design 10-30 achievements across all types
- [ ] Balance required values (easy → hard progression)
- [ ] Assign unique IDs and tracking keys
- [ ] Select appropriate icons

---

## 2. Achievement Service

### Class Architecture

```dart
class AchievementService {
  // Achievement definitions
  final List<Achievement> _allAchievements = [...];

  // Stat tracking
  final Map<String, dynamic> _gameStats = {};       // Current game session
  final Map<String, dynamic> _cumulativeStats = {}; // All-time stats

  // Persistence
  final SaveGameService _saveGameService;

  // Event broadcasting
  final StreamController<Achievement> _unlockController = StreamController.broadcast();
  Stream<Achievement> get onAchievementUnlocked => _unlockController.stream;

  // Public API
  List<Achievement> get allAchievements => _allAchievements;
  List<Achievement> get unlockedAchievements { ... }
  List<Achievement> get lockedAchievements { ... }

  bool isUnlocked(String achievementId) { ... }
  double getProgress(Achievement achievement) { ... }
  String getProgressText(Achievement achievement) { ... }

  // Stat updates (called by game)
  void onGameStarted() { ... }
  void onGameEnded() { ... }
  void onScoreChanged(int score) { ... }
  void onLevelChanged(int level) { ... }
  void onCrystalCollected(bool whileImmortal) { ... }
  void onPlayerDeath(bool fromBlackHole) { ... }
  // ... more event hooks
}
```

### Core Methods

#### Initialization
```dart
AchievementService(this._saveGameService) {
  _loadCumulativeStats();
}

void _loadCumulativeStats() {
  _cumulativeStats.addAll(_saveGameService.getCumulativeStats());
}
```

#### Stat Tracking
```dart
void onGameStarted() {
  _gameStats.clear();
  _gameStats['game_score'] = 0;
  _gameStats['game_level'] = 1;
  _gameStats['game_crystals_collected'] = 0;
  _gameStats['items_collected_without_damage'] = 0;
  _gameStats['time_without_death'] = 0.0;
  // ... initialize all per-game stats
}

void onGameEnded() {
  // Update cumulative stats
  _cumulativeStats['total_games_played'] =
      (_cumulativeStats['total_games_played'] ?? 0) + 1;

  _cumulativeStats['total_score'] =
      (_cumulativeStats['total_score'] ?? 0) + _gameStats['game_score'];

  // Save to persistence
  _saveGameService.saveCumulativeStats(_cumulativeStats);
}

void onScoreChanged(int score) {
  _gameStats['game_score'] = score;
  _checkAchievements();
}

void onCrystalCollected(bool whileImmortal) {
  _gameStats['game_crystals_collected'] =
      (_gameStats['game_crystals_collected'] ?? 0) + 1;

  _cumulativeStats['total_crystals_collected'] =
      (_cumulativeStats['total_crystals_collected'] ?? 0) + 1;

  if (!whileImmortal) {
    _gameStats['items_collected_without_damage'] =
        (_gameStats['items_collected_without_damage'] ?? 0) + 1;
  } else {
    _gameStats['items_collected_without_damage'] = 0; // Reset streak
  }

  _checkAchievements();
}
```

#### Achievement Checking
```dart
void _checkAchievements() {
  final unlockedIds = _saveGameService.getUnlockedAchievements();

  for (final achievement in _allAchievements) {
    // Skip already unlocked
    if (unlockedIds.contains(achievement.id)) continue;

    // Get current value
    final currentValue = _getCurrentValue(achievement);

    // Check if unlocked
    if (currentValue >= achievement.requiredValue) {
      _unlockAchievement(achievement);
    }
  }
}

dynamic _getCurrentValue(Achievement achievement) {
  // Check game stats first (for per-game achievements)
  if (_gameStats.containsKey(achievement.trackingKey)) {
    return _gameStats[achievement.trackingKey] ?? 0;
  }

  // Fall back to cumulative stats
  return _cumulativeStats[achievement.trackingKey] ?? 0;
}

void _unlockAchievement(Achievement achievement) {
  // Save unlock
  _saveGameService.addUnlockedAchievement(achievement.id);

  // Broadcast event
  _unlockController.add(achievement);

  debugPrint('Achievement unlocked: ${achievement.name}');
}
```

#### Progress Calculation
```dart
bool isUnlocked(String achievementId) {
  return _saveGameService.getUnlockedAchievements().contains(achievementId);
}

double getProgress(Achievement achievement) {
  if (isUnlocked(achievement.id)) return 1.0;

  final currentValue = _getCurrentValue(achievement);
  return (currentValue / achievement.requiredValue).clamp(0.0, 1.0);
}

String getProgressText(Achievement achievement) {
  if (isUnlocked(achievement.id)) return 'Unlocked';

  final currentValue = _getCurrentValue(achievement);
  return '$currentValue / ${achievement.requiredValue}';
}
```

**Setup Checklist**:
- [ ] Create AchievementService class
- [ ] Accept SaveGameService dependency
- [ ] Initialize stat maps (game + cumulative)
- [ ] Implement all event hooks (onScoreChanged, etc.)
- [ ] Implement _checkAchievements logic
- [ ] Create StreamController for unlock events
- [ ] Implement progress calculation methods
- [ ] Add proper disposal (close stream controller)

---

## 3. Game Integration

### Event Hooks

Wire up game events to AchievementService:

```dart
// In GameLoopManager or game components:

class GameLoopManager {
  final AchievementService? achievementService;

  void startGame() {
    achievementService?.onGameStarted();
    // ... game start logic
  }

  void updateScore(int newScore) {
    _score = newScore;
    achievementService?.onScoreChanged(_score);
    onScoreChanged?.call(_score);
  }

  void updateLevel(int newLevel) {
    _level = newLevel;
    achievementService?.onLevelChanged(_level);
    onLevelChanged?.call(_level);
  }

  void gameOver() {
    achievementService?.onGameEnded();
    // ... game over logic
  }
}

// In game components:
class CrystalComponent extends PositionComponent {
  void onCollision() {
    final immortal = playerComponent.isImmortal;
    ServiceLocator.achievementService.onCrystalCollected(immortal);
    // ... collection logic
  }
}
```

**Setup Checklist**:
- [ ] Pass AchievementService to GameLoopManager
- [ ] Call onGameStarted when game begins
- [ ] Call onGameEnded when game finishes
- [ ] Call onScoreChanged on every score update
- [ ] Call onLevelChanged on level progression
- [ ] Call collection hooks from game components
- [ ] Track time-based stats with update(dt)

---

## 4. UI Implementation

### AchievementsScreen

```dart
class AchievementsScreen extends StatefulWidget {
  final AchievementService achievementService;
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementType? _selectedType;

  List<Achievement> get _filteredAchievements {
    if (_selectedType == null) {
      return widget.achievementService.allAchievements;
    }
    return widget.achievementService.allAchievements
        .where((a) => a.type == _selectedType)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: Column(
          children: [
            ScreenHeader(title: 'Achievements'),

            // Type filter buttons
            _buildTypeFilter(),

            // Achievement list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = _filteredAchievements[index];
                  return AchievementCard(
                    achievement: achievement,
                    achievementService: widget.achievementService,
                  );
                },
              ),
            ),

            // Completion stats
            _buildCompletionStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionStats() {
    final total = widget.achievementService.allAchievements.length;
    final unlocked = widget.achievementService.unlockedAchievements.length;
    final percentage = (unlocked / total * 100).toInt();

    return Padding(
      padding: EdgeInsets.all(16),
      child: GameLabel(
        text: 'Completed: $unlocked/$total ($percentage%)',
        size: GameLabelSize.medium,
      ),
    );
  }
}
```

### AchievementCard Widget

```dart
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final AchievementService achievementService;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievementService.isUnlocked(achievement.id);
    final progress = achievementService.getProgress(achievement);
    final progressText = achievementService.getProgressText(achievement);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.amber.withOpacity(0.2) : Colors.black45,
        border: Border.all(
          color: isUnlocked ? Colors.amber : Colors.white30,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Icon(
            _getIconData(achievement.icon),
            size: 48,
            color: isUnlocked ? Colors.amber : Colors.white54,
          ),
          SizedBox(width: 16),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameLabel(
                  text: achievement.name,
                  size: GameLabelSize.medium,
                  color: isUnlocked ? Colors.amber : Colors.white,
                ),
                SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 8),

                // Progress bar
                if (!isUnlocked) ...[
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(Colors.amber),
                  ),
                  SizedBox(height: 4),
                  Text(
                    progressText,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ] else
                  Text(
                    'Unlocked!',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Setup Checklist**:
- [ ] Create AchievementsScreen with filter UI
- [ ] Implement type filtering (optional)
- [ ] Create AchievementCard widget
- [ ] Show unlock status (locked/unlocked styling)
- [ ] Display progress bar for locked achievements
- [ ] Show completion percentage
- [ ] Sort by type or unlock status

---

## 5. Unlock Notifications

### Toast/Snackbar Notification

```dart
// In GameScreen or main app:
class _GameScreenState extends State<GameScreen> {
  StreamSubscription<Achievement>? _achievementSubscription;

  @override
  void initState() {
    super.initState();

    _achievementSubscription = widget.achievementService
        .onAchievementUnlocked
        .listen((achievement) {
      _showAchievementNotification(achievement);
    });
  }

  void _showAchievementNotification(Achievement achievement) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievement Unlocked!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(achievement.name),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Optional: Play sound
    ServiceLocator.audioService.playSound('achievement.mp3');
  }

  @override
  void dispose() {
    _achievementSubscription?.cancel();
    super.dispose();
  }
}
```

**Setup Checklist**:
- [ ] Subscribe to onAchievementUnlocked stream
- [ ] Show SnackBar or custom overlay
- [ ] Include achievement icon and name
- [ ] Play achievement sound (optional)
- [ ] Set appropriate duration (2-4 seconds)
- [ ] Cancel subscription in dispose

---

## Advanced Features (Optional)

### 1. Tiered Achievements
```dart
final scoreTiers = [
  Achievement(id: 'score_bronze', name: 'Bronze', requiredValue: 100, ...),
  Achievement(id: 'score_silver', name: 'Silver', requiredValue: 500, ...),
  Achievement(id: 'score_gold', name: 'Gold', requiredValue: 1000, ...),
];
```

### 2. Secret Achievements
```dart
class Achievement {
  final bool isSecret; // Don't show description until unlocked

  String get displayDescription =>
      isSecret && !isUnlocked ? '???' : description;
}
```

### 3. Rewards
```dart
class Achievement {
  final int crystalReward;

  void onUnlock() {
    saveGameService.addCrystals(crystalReward);
  }
}
```

### 4. Time-Limited Achievements
```dart
class Achievement {
  final DateTime? expiresAt;

  bool get isAvailable =>
      expiresAt == null || DateTime.now().isBefore(expiresAt);
}
```

---

## Best Practices

1. **Balance difficulty**: Mix easy (first play), medium (skill), and hard (mastery)
2. **Variety of types**: Don't make all achievements score-based
3. **Clear descriptions**: Players should know what to do
4. **Immediate feedback**: Show progress in real-time
5. **Celebrate unlocks**: Toast + sound + visual effect
6. **Persistent progress**: Save after every unlock
7. **Testing**: Verify all achievements are achievable

---

## Common Pitfalls

1. **Stat tracking bugs**
   - Not resetting per-game stats on game start
   - Not saving cumulative stats on game end

2. **Double unlocks**
   - Not checking if already unlocked before triggering
   - Solution: Check in _checkAchievements

3. **Stream memory leaks**
   - Not canceling achievement subscriptions
   - Solution: Cancel in dispose

4. **Progress not updating**
   - Not calling _checkAchievements after stat changes
   - Solution: Call after every stat update

5. **Lost progress**
   - Not persisting to SaveGameService
   - Solution: Save after every unlock

---

## Testing Checklist

- [ ] All achievements can be unlocked
- [ ] Progress displays correctly
- [ ] Unlock notifications appear
- [ ] Stats persist across app restarts
- [ ] Filtering works (if implemented)
- [ ] No duplicate unlocks
- [ ] Edge cases (0 progress, 100% progress)

---

## Next Steps

After implementing achievements:
- Integrate with **Statistics & Persistence** (05_Statistics_And_Persistence.md)
- Wire up to **Notification System** (09_Notification_System.md)
- Connect to **Game Loop** (07_Flame_Integration.md)
- Register in **Service Architecture** (06_Service_Architecture.md)
