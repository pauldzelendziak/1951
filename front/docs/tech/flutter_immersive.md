# Flutter Immersive Mode Implementation

**A simple, working solution for switching between immersive (no system bars) and normal mode in Flutter apps using built-in Flutter methods only.**

## Overview

This implementation provides reliable switching between:
- **Immersive Mode**: Complete fullscreen with hidden status bar and navigation bar
- **Normal Mode**: Standard view with visible system bars

## Android Configuration

### 1. Update `android/app/src/main/res/values/styles.xml`

```xml
<style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
    <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
</style>

<style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">?android:colorBackground</item>
    <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
</style>
```

**Key Points:**
- **Remove** `android:windowFullscreen="true"` (if present)
- **Add** `android:windowLayoutInDisplayCutoutMode="shortEdges"` for proper notch handling
- Keep both themes consistent

## Flutter Implementation

### 1. Display Mode Enum

```dart
enum DisplayMode { immersive, normal }
```

### 2. Mode Switching Function

```dart
Future<void> setDisplayMode(DisplayMode mode) async {
  if (mode == DisplayMode.immersive) {
    // Hide everything - complete fullscreen
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    // Keep bars transparent for rare re-appearances
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
  } else {
    // Show both status bar and navigation bar
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,   // Forces TOP + BOTTOM bars visible
    );

    // Set dark grey background for status and navigation bars to ensure proper contrast on custom ROMs such as EMUI, MUI etc.
    const darkGrey = Color(0x88232323);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: darkGrey,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: darkGrey,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}
```

### 3. Usage Example

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool _immersive = true;

  @override
  void initState() {
    super.initState();
    // Set initial mode
    setDisplayMode(DisplayMode.immersive);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(  // Protects content from notches
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _immersive = !_immersive;
                  setDisplayMode(_immersive ? DisplayMode.immersive
                                           : DisplayMode.normal);
                });
              },
              child: Text(_immersive ? 'Switch to normal' : 'Switch to immersive'),
            ),
            // Your content here
          ],
        ),
      ),
    );
  }
}
```

## Key Implementation Details

### System UI Modes Explained

| Mode | SystemUiMode | Overlays | Result |
|------|-------------|----------|--------|
| **Immersive** | `SystemUiMode.immersiveSticky` | None | Hidden bars, swipe to reveal temporarily |
| **Normal** | `SystemUiMode.manual` | `SystemUiOverlay.values` | Both status & nav bars visible |

### Why This Works

1. **`SystemUiMode.immersiveSticky`**: Provides true fullscreen with gesture-based temporary reveal
2. **`SystemUiMode.manual` + `SystemUiOverlay.values`**: Explicitly forces both system bars to appear
3. **`shortEdges` cutout mode**: Ensures proper handling of device notches and rounded corners

### SafeArea Usage

```dart
// For content that should avoid notches/system bars
SafeArea(
  child: YourContent(),
)

// For content that should extend edge-to-edge
Container(
  child: YourContent(), // Will go behind system bars when visible
)
```

## Testing

- **Immersive Mode**: System bars should be completely hidden
- **Normal Mode**: Both status bar and navigation bar should be visible
- **Transitions**: Switching should be immediate and reliable
- **Device Rotation**: Mode should persist through orientation changes
- **App Switching**: Mode should be maintained when returning to app

## Notes

- Uses **Flutter built-in methods only** - no native platform channels required
- Works reliably across different Android versions
- Handles device notches and rounded corners properly
- Maintains proper system bar transparency for visual consistency
