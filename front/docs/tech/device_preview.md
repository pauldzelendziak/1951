# Device Preview Implementation Guide

This guide documents how to implement Flutter's `device_preview` package with persistent settings control in debug mode only.

## Overview

This implementation provides:
- Debug-only device preview functionality
- User-controlled toggle in Settings
- Persistent state across app restarts
- Clean separation between debug and release builds

## Dependencies

```yaml
# pubspec.yaml
dev_dependencies:
  device_preview: ^1.3.1
```

Note: Keep as `dev_dependencies` to exclude from release builds.

## Architecture

### Components

1. **PrefsStore** - Persistence layer using SharedPreferences
2. **SettingsProvider** - State management with Provider pattern
3. **main.dart** - Initial DevicePreview setup
4. **splash_page.dart** - State synchronization on app start
5. **settings_page.dart** - User toggle control

### Data Flow

```
App Start
  ↓
main.dart: DevicePreview initialized with default state (disabled)
  ↓
splash_page.dart: Load SettingsProvider → Apply saved state to DevicePreview
  ↓
User opens Settings
  ↓
settings_page.dart: Toggle changes both DevicePreview AND SettingsProvider
  ↓
State persisted to SharedPreferences
  ↓
Next app start: Saved state applied
```

## Step-by-Step Implementation

### 1. Add Preference Key

**File:** `lib/data/local/prefs_store.dart`

```dart
abstract class PrefKeys {
  // ... existing keys
  static const String settingsDevicePreview = 'settings.devicePreview';
}
```

### 2. Update Settings Provider

**File:** `lib/providers/settings_provider.dart`

```dart
class SettingsProvider extends ChangeNotifier {
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _devicePreviewEnabled = false;  // Add this
  bool _loaded = false;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get devicePreviewEnabled => _devicePreviewEnabled;  // Add this
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final music = await PrefsStore.instance.readBool(PrefKeys.settingsMusic);
    final sfx = await PrefsStore.instance.readBool(PrefKeys.settingsSound);
    final devicePreview = await PrefsStore.instance.readBool(
      PrefKeys.settingsDevicePreview,
    );  // Add this
    _musicEnabled = music ?? true;
    _sfxEnabled = sfx ?? true;
    _devicePreviewEnabled = devicePreview ?? false;  // Add this
    _loaded = true;
    notifyListeners();
  }

  // Add this method
  Future<void> setDevicePreviewEnabled(bool value) async {
    if (_devicePreviewEnabled == value) return;
    _devicePreviewEnabled = value;
    notifyListeners();
    await PrefsStore.instance.saveBool(PrefKeys.settingsDevicePreview, value);
  }
}
```

### 3. Initialize DevicePreview in main.dart

**File:** `lib/main.dart`

```dart
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_quest/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    DevicePreview(
      enabled: kDebugMode,
      storage: DevicePreviewStorage.none(),  // Disable built-in persistence
      data: const DevicePreviewData(
        isToolbarVisible: false,
        isFrameVisible: false,
      ),
      builder: (context) => const App(),
    ),
  );
}
```

**Key points:**
- Use `enabled: kDebugMode` to enable only in debug builds
- Use `storage: DevicePreviewStorage.none()` to disable DevicePreview's own persistence
- Initialize with default state (disabled) - splash page will apply saved state

### 4. Apply Saved State in Splash Page

**File:** `lib/ui/pages/splash_page.dart`

```dart
import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ... other imports

class _SplashPageState extends State<SplashPage> {
  // ... existing code

  Future<void> _bootstrapAudioAndGo() async {
    // 1) Load settings if needed
    final settings = context.read<SettingsProvider>();
    if (!settings.isLoaded) {
      await settings.load();
    }

    // 2) Apply saved DevicePreview state (debug mode only)
    if (kDebugMode && mounted) {
      final store = context.read<DevicePreviewStore>();
      store.data = store.data.copyWith(
        isToolbarVisible: settings.devicePreviewEnabled,
        isFrameVisible: settings.devicePreviewEnabled,
        isEnabled: settings.devicePreviewEnabled,
      );
    }

    // 3) Continue with other initialization
    await AudioManager.instance.init();
    // ... rest of method
  }
}
```

**Key points:**
- Apply state AFTER loading SettingsProvider
- Apply BEFORE showing UI to user
- Guard with `kDebugMode && mounted`
- Use the SettingsProvider from ProvidersRoot (not a temporary instance)

### 5. Add Settings Toggle

**File:** `lib/ui/pages/settings_page.dart`

```dart
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ... other imports

class _SettingsPageState extends State<SettingsPage> {
  SettingsProvider? _sp;

  void _toggleDevicePreviewToolbar(bool value) {
    // Update DevicePreview immediately
    final store = context.read<DevicePreviewStore>();
    store.data = store.data.copyWith(
      isToolbarVisible: value,
      isFrameVisible: value,
      isEnabled: value,
    );
    // Persist to SharedPreferences
    _sp!.setDevicePreviewEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: Column(
        children: [
          GameToggleRow(
            label: 'Music',
            value: settings.musicEnabled,
            onChanged: settings.setMusicEnabled,
          ),
          GameToggleRow(
            label: 'Sound Effects',
            value: settings.sfxEnabled,
            onChanged: settings.setSfxEnabled,
          ),
          // Add this - only visible in debug builds
          if (kDebugMode) ...[
            GameToggleRow(
              label: 'Device Preview',
              value: settings.devicePreviewEnabled,
              onChanged: _toggleDevicePreviewToolbar,
            ),
          ],
        ],
      ),
    );
  }
}
```

**Key points:**
- Update both DevicePreviewStore (immediate) and SettingsProvider (persistent)
- Use `kDebugMode` to show toggle only in debug builds
- Read value from SettingsProvider, not local state

### 6. Update app.dart for DevicePreview Integration

**File:** `lib/app.dart`

```dart
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: ProvidersRoot.providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
        locale: DevicePreview.locale(context),      // Add this
        builder: DevicePreview.appBuilder,          // Add this
      ),
    );
  }
}
```

## Key Concepts

### Why Disable DevicePreview's Built-in Storage?

```dart
storage: DevicePreviewStorage.none()
```

DevicePreview has its own persistence system. We disable it because:
1. **Consistency** - All settings in one place (SettingsProvider)
2. **Control** - We manage when/how state is saved
3. **Architecture** - Follows the app's established settings pattern

### Why Apply State in Splash Page?

The timing is critical:
1. **Too early (main.dart)** - Provider not yet available
2. **Too late (settings page)** - User sees wrong state initially
3. **Just right (splash page)** - After providers created, before UI shown

### State Synchronization

Two separate states must be kept in sync:
1. **DevicePreviewStore** - Controls actual UI (toolbar, frame)
2. **SettingsProvider** - Stores preference for next session

When user toggles:
```dart
// Update DevicePreview (immediate visual feedback)
store.data = store.data.copyWith(...);

// Update SettingsProvider (persist for next session)
settings.setDevicePreviewEnabled(value);
```

## Common Pitfalls

### ❌ Creating Temporary SettingsProvider in main.dart

```dart
// DON'T DO THIS
Future<void> main() async {
  final settings = SettingsProvider();  // ❌ Temporary instance
  await settings.load();

  runApp(DevicePreview(
    data: DevicePreviewData(
      isEnabled: settings.devicePreviewEnabled,  // ❌ Won't sync with app instance
    ),
    ...
  ));
}
```

**Why it fails:** The app uses a different SettingsProvider instance from ProvidersRoot. Changes in Settings page won't sync with DevicePreview.

**Solution:** Apply state in splash page where you have access to the real SettingsProvider.

### ❌ Only Updating DevicePreviewStore

```dart
// DON'T DO THIS
void _toggleDevicePreviewToolbar(bool value) {
  final store = context.read<DevicePreviewStore>();
  store.data = store.data.copyWith(isEnabled: value);
  // ❌ Forgot to persist!
}
```

**Why it fails:** State not saved to SharedPreferences. Will be lost on app restart.

**Solution:** Always update both DevicePreviewStore AND SettingsProvider.

### ❌ Using DevicePreview's Default Storage

```dart
// DON'T DO THIS
DevicePreview(
  enabled: kDebugMode,
  // ❌ Default storage enabled - conflicts with our persistence
  builder: (context) => const App(),
)
```

**Why it fails:** DevicePreview will save its own state, overriding your saved preferences.

**Solution:** Always use `storage: DevicePreviewStorage.none()`.

### ❌ Forgetting kDebugMode Guards

```dart
// DON'T DO THIS - No kDebugMode guard
GameToggleRow(
  label: 'Device Preview',  // ❌ Will show in release builds
  value: settings.devicePreviewEnabled,
  onChanged: _toggleDevicePreviewToolbar,
)
```

**Why it fails:** Toggle visible in release builds where DevicePreview is disabled.

**Solution:** Always wrap debug-only UI with `if (kDebugMode) ...`.

## Testing Checklist

### Initial Setup
- [ ] Fresh install with cleared storage
- [ ] Device Preview toggle shows OFF
- [ ] DevicePreview UI is hidden

### Toggle ON
- [ ] Settings toggle turns ON
- [ ] Toolbar appears at bottom
- [ ] Device frame appears around app
- [ ] State persists after hot reload

### Toggle OFF
- [ ] Settings toggle turns OFF
- [ ] Toolbar disappears
- [ ] Device frame disappears
- [ ] Clean app view restored

### Persistence
- [ ] Enable Device Preview
- [ ] Restart app
- [ ] Device Preview still enabled
- [ ] Settings toggle shows ON

### Persistence (Disabled)
- [ ] Disable Device Preview
- [ ] Restart app
- [ ] Device Preview still disabled
- [ ] Settings toggle shows OFF

### Release Build
- [ ] Device Preview toggle not visible in Settings
- [ ] DevicePreview completely excluded from build
- [ ] No runtime errors in release mode

## Summary

This implementation provides a clean, maintainable approach to device preview with:

✅ **User control** - Toggle in Settings
✅ **Persistence** - State survives restarts
✅ **Debug-only** - No impact on release builds
✅ **Consistent** - Follows app's settings pattern
✅ **No conflicts** - Disables DevicePreview's own storage

Key takeaway: Apply saved state in splash page, not main.dart, to ensure synchronization with the app's actual SettingsProvider instance.
