# Navigation System

## Purpose

A well-designed navigation system provides smooth transitions between screens while maintaining visual continuity through persistent background layers and animations. This creates a cohesive user experience across your entire game.

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
```

No additional packages required - uses Flutter's built-in navigation.

## Architecture Overview

### Three-Layer Rendering Stack

The navigation system uses a layered approach in `main.dart`'s `MaterialApp.builder`:

```
┌─────────────────────────────────┐
│  Layer 3: Navigation Stack      │ ← Interactive screens
│  (Navigator with routes)        │
├─────────────────────────────────┤
│  Layer 2: Background Animations │ ← Decorative (blurred)
│  (IgnorePointer)                │
├─────────────────────────────────┤
│  Layer 1: Background Image      │ ← Static/dynamic background
│  (ValueNotifier-driven)         │
└─────────────────────────────────┘
```

**Benefits**:
- Background persists across navigation
- Smooth transitions without background flicker
- Animated decorations add visual interest
- Clear separation of concerns

---

## Implementation

### Main App Structure

**Architecture**:
```dart
class MyApp extends StatefulWidget {
  final BackgroundManager backgroundManager;
  final SpaceshipAnimationService animationService;
  // ... other services
}

class _MyAppState extends State<MyApp> {
  late ValueNotifier<String> _backgroundNotifier;

  @override
  void initState() {
    _backgroundNotifier = ValueNotifier(backgroundManager.currentBackground);

    // Listen for background changes
    settingsService.addListener(() {
      _backgroundNotifier.value = backgroundManager.randomBackground;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return Stack(
          children: [
            // Layer 1: Background
            ValueListenableBuilder<String>(
              valueListenable: _backgroundNotifier,
              builder: (_, bg, __) => BackgroundImage(imagePath: bg),
            ),

            // Layer 2: Decorative animations
            IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: GameWidget(
                  game: animationService.game,
                ),
              ),
            ),

            // Layer 3: Interactive content
            child!,
          ],
        );
      },
      home: MenuScreen(),
    );
  }
}
```

**Setup Checklist**:
- [ ] Create BackgroundManager service
- [ ] Set up ValueNotifier for background state
- [ ] Implement three-layer Stack in MaterialApp.builder
- [ ] Add background image listener
- [ ] Configure IgnorePointer for decorative layer
- [ ] Set up initial route (usually MenuScreen)

---

## Screen Navigation Patterns

### 1. Push Navigation (Standard Flow)

**Use Case**: Navigate to a new screen (Menu → Settings, Menu → Game)

```dart
Navigator.push(
  context,
  FadePageRoute(
    builder: (context) => SettingsScreen(
      settingsService: widget.settingsService,
      audioService: widget.audioService,
    ),
  ),
);
```

**Setup Checklist**:
- [ ] Create FadePageRoute class
- [ ] Implement PageRouteBuilder with fade transition
- [ ] Pass required services via constructor
- [ ] Set transition duration (typically 300ms)

---

### 2. Pop Navigation (Back/Cancel)

**Use Case**: Return to previous screen

```dart
Navigator.pop(context);

// With result:
Navigator.pop(context, resultValue);
```

**Setup Checklist**:
- [ ] Add back buttons to all secondary screens (ScreenHeader)
- [ ] Handle WillPopScope for custom back behavior
- [ ] Support Android back button
- [ ] Clean up resources on pop (dispose controllers)

---

### 3. Replace Navigation (Screen Swap)

**Use Case**: Replace current screen without adding to stack (Game Over → Menu)

```dart
Navigator.pushReplacement(
  context,
  FadePageRoute(builder: (context) => MenuScreen()),
);
```

---

### 4. Modal Dialogs

**Use Case**: Temporary overlays (Pause, Game Over, Confirmations)

```dart
await GameDialog.show(
  context: context,
  title: 'Paused',
  child: PauseDialogContent(),
  dismissible: true,
);
```

**Setup Checklist**:
- [ ] Implement GameDialog.show() static method
- [ ] Use showDialog with custom dialog builder
- [ ] Add barrier dismissible option
- [ ] Handle result returns
- [ ] Animate dialog entrance/exit

---

## Custom Page Transitions

### FadePageRoute

**Purpose**: Smooth crossfade between screens

**Architecture**:
```dart
class FadePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Duration duration;

  @override
  Widget buildPage(...) => builder(context);

  @override
  Widget buildTransitions(context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  @override
  Duration get transitionDuration => duration ?? Duration(milliseconds: 300);

  @override
  bool get opaque => false; // Allow background visibility during transition

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;
}
```

**Setup Checklist**:
- [ ] Extend PageRoute<T>
- [ ] Implement buildPage and buildTransitions
- [ ] Set transitionDuration (300ms recommended)
- [ ] Configure opaque = false for background visibility
- [ ] Add optional duration parameter

---

### DirectionalPageRoute (Optional)

**Purpose**: Slide transitions from specific directions

**Architecture**:
```dart
enum SlideDirection { left, right, up, down }

class DirectionalPageRoute<T> extends PageRoute<T> {
  final SlideDirection direction;

  @override
  Widget buildTransitions(...) {
    Offset begin = _getBeginOffset(direction);
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    );
  }

  Offset _getBeginOffset(SlideDirection dir) {
    switch (dir) {
      case SlideDirection.left: return Offset(-1, 0);
      case SlideDirection.right: return Offset(1, 0);
      case SlideDirection.up: return Offset(0, -1);
      case SlideDirection.down: return Offset(0, 1);
    }
  }
}
```

**Use Cases**:
- Hierarchical navigation (Settings → subsections)
- Modal sheets (slide from bottom)
- Horizontal swiping (carousels)

---

## Background Management

### BackgroundManager Service

**Purpose**: Centralized control of background images with random selection

**Architecture**:
```dart
class BackgroundManager {
  final List<String> _backgrounds = [
    'assets/images/backgrounds/background_1.jpg',
    'assets/images/backgrounds/background_2.jpg',
    'assets/images/backgrounds/background_3.jpg',
    'assets/images/backgrounds/background_4.jpg',
  ];

  String get currentBackground => _current;

  String get randomBackground {
    _current = _backgrounds[Random().nextInt(_backgrounds.length)];
    return _current;
  }

  void setBackground(String bg) {
    if (_backgrounds.contains(bg)) {
      _current = bg;
    }
  }
}
```

**Setup Checklist**:
- [ ] Create BackgroundManager class
- [ ] Add list of background asset paths
- [ ] Implement random selection logic
- [ ] Add current background getter
- [ ] Optionally save selection to SettingsService

**Integration**:
- Initialize in `main.dart`
- Connect to ValueNotifier for reactive updates
- Trigger changes on screen transitions or settings updates

---

## Screen Organization

### Primary Screens

**MenuScreen** (Home)
- Entry point of the app
- Navigation hub to all other screens
- Should be lightweight and fast to render

**GameScreen** (Full-screen Flame game)
- Wraps GameWidget
- Minimal Flutter UI (HUD overlays only)
- Handles game lifecycle (start, pause, resume)

### Secondary Screens (Modal Overlays)

**AchievementsScreen**
- Shows unlocked and locked achievements
- Displays progress for incomplete achievements
- Uses ScreenHeader for consistent layout

**SettingsScreen**
- Audio toggles (music, sound effects)
- Data reset option
- Privacy policy access
- Uses ScreenHeader for consistent layout

**ShopScreen** (Optional)
- In-game purchases (skins, power-ups)
- Currency display
- Purchase confirmation dialogs

**StatisticsScreen**
- Best scores, levels
- Cumulative stats (total games, deaths, etc.)
- Achievement completion percentage

---

## Navigation Flow Diagram

```
┌─────────────┐
│ MenuScreen  │ ← Initial route, home base
└──────┬──────┘
       │
       ├──→ [Play] ──→ GameScreen ──→ GameOverDialog ──→ MenuScreen
       │                    ↓
       │                 PauseDialog ──→ Resume / Quit
       │
       ├──→ [Achievements] ──→ AchievementsScreen ──→ [Back]
       │
       ├──→ [Shop] ──→ ShopScreen ──→ [Back]
       │
       ├──→ [Settings] ──→ SettingsScreen ──→ ResetDataDialog
       │                          │
       │                          └──→ [Back]
       │
       └──→ [Statistics] ──→ StatisticsScreen ──→ [Back]
```

---

## Service Integration

### Background Updates

When user changes settings or triggers background change:

```dart
// In SettingsScreen or elsewhere:
widget.settingsService.setRandomBackground();

// This triggers listener in MyApp:
settingsService.addListener(() {
  _backgroundNotifier.value = backgroundManager.randomBackground;
});
```

### Persistent Animations

The middle animation layer (Layer 2) remains active across all screens:

```dart
// In main.dart builder:
IgnorePointer(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
    child: GameWidget(
      game: spaceshipAnimationService.game,
    ),
  ),
)
```

This creates a continuous animated background visible behind all screens.

---

## Best Practices

### 1. Service Passing
Pass services explicitly via constructors to screens:
```dart
SettingsScreen(
  settingsService: widget.settingsService,
  audioService: widget.audioService,
)
```
This makes dependencies clear and testable.

### 2. Navigation Guards
Prevent navigation during critical operations:
```dart
if (_gameInProgress) {
  // Show pause dialog instead of popping
  return false;
}
```

### 3. Resource Cleanup
Always dispose controllers when popping:
```dart
@override
void dispose() {
  _animationController.dispose();
  super.dispose();
}
```

### 4. Transition Consistency
Use the same transition type for related screens:
- All secondary screens use FadePageRoute
- Game start/end can use different transitions for emphasis

### 5. Back Button Handling
Provide explicit back buttons on all screens:
```dart
ScreenHeader(
  title: 'Settings',
  onBackPressed: () => Navigator.pop(context),
)
```

---

## Common Pitfalls

1. **Background Flicker**: Not using layered stack causes background to reload
   - **Solution**: Use three-layer architecture with persistent background

2. **Memory Leaks**: Not disposing page routes or controllers
   - **Solution**: Implement proper dispose methods

3. **Service Access**: Trying to access services after pop
   - **Solution**: Pass services to screens, don't rely on global state

4. **Animation Conflicts**: Multiple animations fighting for same widget
   - **Solution**: Use Hero widgets or coordinate animation timing

5. **Navigation Stack Bloat**: Pushing too many screens without clearing
   - **Solution**: Use pushReplacement or popUntil when appropriate

6. **Inconsistent Transitions**: Different transition styles across app
   - **Solution**: Define standard transitions and use consistently

---

## Testing Recommendations

1. **Navigation Flow**: Test all paths from menu to game and back
2. **Back Button**: Verify Android back button works on all screens
3. **Dialog Dismissal**: Test barrier dismissible and non-dismissible dialogs
4. **Background Persistence**: Verify background doesn't flicker during navigation
5. **Service Availability**: Ensure services are accessible on all screens
6. **Memory**: Use DevTools to check for navigation-related memory leaks

---

## Customization Options

### Alternative Transitions
- **Scale Transition**: Grow/shrink effect
- **Rotation Transition**: Spin effect (use sparingly)
- **Custom Curves**: Elastic, bounce, spring physics
- **Combined Transitions**: Fade + slide, scale + rotate

### Advanced Patterns
- **Named Routes**: For complex navigation graphs
- **Deep Linking**: Handle external URLs
- **Route Guards**: Authentication/authorization checks
- **Nested Navigation**: TabBar or BottomNavigationBar
- **Hero Animations**: Shared element transitions

---

## Next Steps

After implementing navigation:
- Set up **Audio System** (03_Audio_System.md) for background music continuity
- Configure **Theme & Styling** (08_Theme_And_Styling.md) for consistent appearance
- Implement **Animation Systems** (10_Animation_Systems.md) for transition effects
