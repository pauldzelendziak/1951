# Audio System

## Purpose

A professional audio system manages background music and sound effects (SFX) with respect to user preferences, app lifecycle events, and platform constraints. It ensures audio doesn't play when the app is in the background and provides clean multichannel support for simultaneous sound effects.

## Dependencies

```yaml
dependencies:
  flame_audio: ^2.11.11  # Built on audioplayers, provides AudioPool
```

`flame_audio` provides:
- **Background music** management with looping
- **AudioPool** for multichannel SFX (simultaneous sounds)
- **Volume control** for music and effects
- **Preloading** for performance

---

## Architecture

### AudioService Class

**Purpose**: Centralized audio management with lifecycle awareness

**Architecture**:
```dart
class AudioService {
  // State
  bool _isMusicPlaying = false;
  bool _appPaused = false; // Critical for background handling

  // Settings integration
  final SettingsService _settingsService;

  // Methods:
  // - Background Music
  Future<void> initialize()
  Future<void> playBackgroundMusic()
  Future<void> pauseBackgroundMusic()
  Future<void> resumeBackgroundMusic()
  Future<void> stopBackgroundMusic()

  // - Sound Effects
  Future<void> playSound(String filename, {double volume = 1.0})
  Future<void> playButtonSound()
  Future<void> playCrystalSound()
  Future<void> playGameOverSound()

  // - Lifecycle
  void onAppPaused()
  void onAppResumed()
}
```

**Key Features**:
- Respects user settings (music on/off, SFX on/off)
- Prevents audio in background via `_appPaused` flag
- Multichannel SFX via AudioPool
- Volume clamping to 0.0-1.0 range
- Exception handling with debug logging

---

## Implementation Details

### 1. Initialization

**Setup Checklist**:
- [ ] Create AudioService class
- [ ] Accept SettingsService in constructor
- [ ] Preload all audio files in `initialize()`
- [ ] Configure audio file paths
- [ ] Set up volume defaults

**Pseudocode**:
```dart
class AudioService {
  Future<void> initialize() async {
    try {
      // Preload background music
      await FlameAudio.audioCache.load('background_music.mp3');

      // Preload sound effects
      await FlameAudio.audioCache.loadAll([
        'button.mp3',
        'crystal.mp3',
        'game_over.mp3',
        'explosion.mp3',
        // ... more SFX
      ]);

      debugPrint('Audio initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize audio: $e');
    }
  }
}
```

**Asset Organization**:
```
assets/
├── audio/
│   ├── music/
│   │   └── background_music.mp3
│   └── sfx/
│       ├── button.mp3
│       ├── crystal.mp3
│       ├── game_over.mp3
│       ├── explosion.mp3
│       └── ...
```

**pubspec.yaml**:
```yaml
flutter:
  assets:
    - assets/audio/music/
    - assets/audio/sfx/
```

---

### 2. Background Music Management

**Architecture**:
```dart
Future<void> playBackgroundMusic() async {
  if (!_settingsService.isMusicEnabled || _appPaused) return;

  try {
    await FlameAudio.bgm.play(
      'background_music.mp3',
      volume: 0.7, // 70% volume for background music
    );
    _isMusicPlaying = true;
  } catch (e) {
    debugPrint('Failed to play music: $e');
  }
}

Future<void> pauseBackgroundMusic() async {
  if (_isMusicPlaying) {
    await FlameAudio.bgm.pause();
    _isMusicPlaying = false;
  }
}

Future<void> resumeBackgroundMusic() async {
  if (!_settingsService.isMusicEnabled || _appPaused) return;

  try {
    await FlameAudio.bgm.resume();
    _isMusicPlaying = true;
  } catch (e) {
    debugPrint('Failed to resume music: $e');
  }
}

Future<void> stopBackgroundMusic() async {
  await FlameAudio.bgm.stop();
  _isMusicPlaying = false;
}
```

**Setup Checklist**:
- [ ] Implement playBackgroundMusic with volume setting
- [ ] Add pause/resume methods
- [ ] Add stop method for cleanup
- [ ] Check settings before playing
- [ ] Check _appPaused flag
- [ ] Track _isMusicPlaying state

**Key Points**:
- **Looping**: `FlameAudio.bgm.play()` automatically loops
- **Volume**: Typically 0.5-0.8 for background music (not overpowering)
- **State tracking**: `_isMusicPlaying` prevents redundant operations
- **Settings respect**: Always check `isMusicEnabled` before playing

---

### 3. Sound Effects (Multichannel)

**Architecture**:
```dart
Future<void> playSound(String filename, {double volume = 1.0}) async {
  if (!_settingsService.isSoundEnabled || _appPaused) return;

  try {
    // Clamp volume to valid range
    final clampedVolume = volume.clamp(0.0, 1.0);

    // AudioPool allows simultaneous plays of same sound
    await FlameAudio.play(filename, volume: clampedVolume);
  } catch (e) {
    debugPrint('Failed to play sound $filename: $e');
  }
}

// Convenience methods for specific sounds
Future<void> playButtonSound() => playSound('button.mp3', volume: 0.5);
Future<void> playCrystalSound() => playSound('crystal.mp3', volume: 0.5);
Future<void> playGameOverSound() => playSound('game_over.mp3', volume: 0.5);
```

**Setup Checklist**:
- [ ] Implement generic `playSound` method
- [ ] Add volume clamping (0.0-1.0)
- [ ] Check settings before playing
- [ ] Check _appPaused flag
- [ ] Create convenience methods for common sounds
- [ ] Handle exceptions gracefully

**Multichannel Support**:
`FlameAudio.play()` uses `AudioPool` internally, allowing:
- Multiple instances of the same sound simultaneously
- No interruption if sound is already playing
- Automatic cleanup of finished sounds

**Volume Guidelines**:
- UI sounds (buttons): 0.3-0.5
- Collectibles: 0.5-0.7
- Important events (game over): 0.6-0.8
- Explosions/impacts: 0.7-0.9

---

### 4. App Lifecycle Integration

**Critical Feature**: Prevent audio in background

**Architecture**:
```dart
class AudioService {
  bool _appPaused = false; // Global pause flag

  void onAppPaused() {
    _appPaused = true;
    if (_isMusicPlaying) {
      pauseBackgroundMusic();
    }
    // SFX automatically prevented by _appPaused check
  }

  void onAppResumed() {
    _appPaused = false;
    if (_settingsService.isMusicEnabled && !_isMusicPlaying) {
      resumeBackgroundMusic();
    }
  }
}
```

**Integration in main.dart**:
```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        widget.audioService.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        widget.audioService.onAppResumed();
        break;
      default:
        break;
    }
  }
}
```

**Setup Checklist**:
- [ ] Add _appPaused boolean field
- [ ] Implement onAppPaused method
- [ ] Implement onAppResumed method
- [ ] Add WidgetsBindingObserver to MyApp state
- [ ] Override didChangeAppLifecycleState
- [ ] Handle paused, inactive, resumed states
- [ ] Remove observer in dispose

**Why This Matters**:
- **Platform compliance**: iOS/Android penalize apps playing audio in background
- **User experience**: Prevents unexpected audio when switching apps
- **Battery life**: Reduces resource usage when app is backgrounded

---

## Settings Integration

### SettingsService Properties

```dart
class SettingsService {
  bool get isMusicEnabled => _prefs.getBool('music_enabled') ?? true;
  bool get isSoundEnabled => _prefs.getBool('sound_enabled') ?? true;

  Future<void> setMusicEnabled(bool enabled) async {
    await _prefs.setBool('music_enabled', enabled);
    notifyListeners(); // If using ChangeNotifier
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool('sound_enabled', enabled);
  }
}
```

### Audio Settings UI

**In SettingsScreen**:
```dart
// Music toggle
SwitchListTile(
  title: Text('Background Music'),
  value: settingsService.isMusicEnabled,
  onChanged: (value) async {
    await settingsService.setMusicEnabled(value);
    if (value) {
      audioService.playBackgroundMusic();
    } else {
      audioService.pauseBackgroundMusic();
    }
  },
)

// Sound effects toggle
SwitchListTile(
  title: Text('Sound Effects'),
  value: settingsService.isSoundEnabled,
  onChanged: (value) async {
    await settingsService.setSoundEnabled(value);
    if (value) {
      audioService.playButtonSound(); // Immediate feedback
    }
  },
)
```

**Setup Checklist**:
- [ ] Add music/sound boolean properties to SettingsService
- [ ] Persist to SharedPreferences
- [ ] Create settings UI with switches
- [ ] Connect switches to AudioService
- [ ] Provide immediate audio feedback on toggle

---

## Service Locator Integration

**Registration**:
```dart
ServiceLocator.initialize(
  audioService: audioService,
  settingsService: settingsService,
  // ... other services
);
```

**Usage Anywhere**:
```dart
// In GameButton
ServiceLocator.audioService.playButtonSound();

// In game component
ServiceLocator.audioService.playCrystalSound();
```

This allows any widget or game component to play sounds without dependency injection.

---

## Common Use Cases

### 1. Menu Music Loop
```dart
// In MenuScreen.initState():
widget.audioService.playBackgroundMusic();
```

### 2. Game Start Transition
```dart
// Stop menu music, start game music (if different)
audioService.stopBackgroundMusic();
audioService.playBackgroundMusic(); // Could load different track
```

### 3. Button Press Feedback
```dart
GameButton(
  onPressed: () {
    ServiceLocator.audioService.playButtonSound();
    // ... action
  },
)
```

### 4. In-Game Events
```dart
// In Flame component collision:
void onCollisionWith(Component other) {
  if (other is CrystalComponent) {
    ServiceLocator.audioService.playCrystalSound();
  }
}
```

### 5. Game Over
```dart
void _showGameOver() {
  audioService.playGameOverSound();
  audioService.pauseBackgroundMusic();
  // Show game over dialog
}
```

---

## Advanced Features (Optional)

### 1. Multiple Music Tracks
```dart
Future<void> playMusic(String trackName) async {
  await stopBackgroundMusic();
  await FlameAudio.bgm.play('$trackName.mp3', volume: 0.7);
}

// Usage:
audioService.playMusic('menu_theme');
audioService.playMusic('game_theme');
audioService.playMusic('boss_theme');
```

### 2. Dynamic Volume Control
```dart
Future<void> setMusicVolume(double volume) async {
  _musicVolume = volume.clamp(0.0, 1.0);
  FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
}

Future<void> setSfxVolume(double volume) async {
  _sfxVolume = volume.clamp(0.0, 1.0);
  // Store for use in playSound calls
}
```

### 3. Fade In/Out
```dart
Future<void> fadeMusicOut({Duration duration = const Duration(seconds: 2)}) async {
  const steps = 20;
  final stepDuration = duration.milliseconds ~/ steps;

  for (int i = steps; i >= 0; i--) {
    await FlameAudio.bgm.audioPlayer.setVolume(i / steps * 0.7);
    await Future.delayed(Duration(milliseconds: stepDuration));
  }

  await stopBackgroundMusic();
}
```

### 4. Sound Variations
```dart
final explosionSounds = ['explosion_1.mp3', 'explosion_2.mp3', 'explosion_3.mp3'];

Future<void> playExplosionSound() async {
  final sound = explosionSounds[Random().nextInt(explosionSounds.length)];
  await playSound(sound, volume: 0.7);
}
```

---

## Performance Optimization

### 1. Preloading
Always preload in `initialize()` to avoid runtime delays:
```dart
await FlameAudio.audioCache.loadAll([...]);
```

### 2. Audio Compression
- Use **MP3** for music (smaller file size)
- Use **MP3 or OGG** for SFX
- Avoid uncompressed WAV files
- Target bitrate: 128-192 kbps for music, 96 kbps for SFX

### 3. Short SFX
Keep sound effects under 2 seconds when possible:
- Faster loading
- Smaller memory footprint
- Better multichannel performance

### 4. Dispose Properly
Clean up in app disposal:
```dart
@override
void dispose() {
  audioService.stopBackgroundMusic();
  FlameAudio.audioCache.clearAll();
  super.dispose();
}
```

---

## Testing Recommendations

1. **Settings toggles**: Verify music/SFX can be enabled/disabled
2. **Background pause**: Test app backgrounding stops audio
3. **Foreground resume**: Test app resuming restarts audio (if enabled)
4. **Multichannel**: Play multiple SFX simultaneously
5. **Volume levels**: Ensure music doesn't overpower SFX
6. **Missing files**: Handle missing audio files gracefully
7. **Different devices**: Test on various Android/iOS devices

---

## Common Pitfalls

1. **Playing audio in background**
   - **Problem**: App plays audio when user switches away
   - **Solution**: Implement lifecycle handling with _appPaused flag

2. **No volume control**
   - **Problem**: Audio is too loud or too quiet
   - **Solution**: Set appropriate volumes for music (0.5-0.7) and SFX (0.3-0.8)

3. **SFX interrupting each other**
   - **Problem**: Only one instance of sound plays at a time
   - **Solution**: Use FlameAudio.play() which uses AudioPool

4. **Not respecting user settings**
   - **Problem**: Audio plays even when user disabled it
   - **Solution**: Always check SettingsService before playing

5. **Memory leaks**
   - **Problem**: Audio files not released
   - **Solution**: Call clearAll() on app disposal

6. **Laggy audio**
   - **Problem**: Delay when playing sounds
   - **Solution**: Preload all audio in initialize()

---

## Audio Asset Checklist

- [ ] Create `assets/audio/music/` directory
- [ ] Create `assets/audio/sfx/` directory
- [ ] Add background music track(s) (MP3, 128-192 kbps)
- [ ] Add button sound effect
- [ ] Add collectible sound effects
- [ ] Add game over sound effect
- [ ] Add success/failure sound effects
- [ ] Register all audio in pubspec.yaml
- [ ] Test all audio files load correctly

---

## Next Steps

After implementing audio system:
- Integrate with **Service Architecture** (06_Service_Architecture.md)
- Connect to **Settings & Persistence** (05_Statistics_And_Persistence.md)
- Use in **Shared UI Components** (01_Shared_UI_Components.md) for button feedback
- Wire up to **Flame game components** (07_Flame_Integration.md)
