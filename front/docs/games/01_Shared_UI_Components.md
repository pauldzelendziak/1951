# Shared UI Components

## Purpose

Shared UI components establish a consistent visual language across your game. They provide reusable, themeable widgets that maintain design consistency while reducing code duplication.

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
```

No additional packages required - pure Flutter widgets.

## Core Components

### 1. GameLabel - Styled Text Display

**Purpose**: Display text with outline and shadow effects for readability over game backgrounds.

**Architecture**:
```dart
enum GameLabelSize { small, medium, large, title }

class GameLabel extends StatelessWidget {
  final String text;
  final GameLabelSize size;
  final Color color;
  final TextAlign textAlign;

  // Size-specific properties:
  // - fontSize: 18, 24, 36, 48
  // - outlineWidth: 1.5, 2.0, 2.5, 3.0
  // - shadowBlur: 4, 6, 8, 10
}
```

**Key Features**:
- Enum-based size system with computed properties
- Layered text rendering (outline + shadow + fill)
- Custom font support via theme
- High contrast for game backgrounds

**Setup Checklist**:
- [ ] Define GameLabelSize enum
- [ ] Implement size-to-property mapping
- [ ] Add custom font to assets and theme
- [ ] Create text shadow/outline rendering logic
- [ ] Set default colors from theme

**Customization**:
- Add more size variants (extraSmall, extraLarge)
- Support gradient text fills
- Add animation parameter for pulsing/glowing effects
- Include icon support for inline images

**Usage Pattern**:
```dart
GameLabel(
  text: 'Score: 1000',
  size: GameLabelSize.medium,
  color: AppColors.neonCyan,
)
```

---

### 2. GameButton - Interactive Button with Animations

**Purpose**: Provide tactile feedback with scale animations and audio on tap.

**Architecture**:
```dart
class GameButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double width;
  final double height;
  final bool isCircular; // Circle vs rounded rectangle

  // Uses AnimationController for scale animation
  // 100ms easeInOut curve, scales to 0.95 on tap
}
```

**Key Features**:
- Scale-down animation on tap (0.95x)
- Automatic button sound playback via ServiceLocator
- Support for icon-only or icon+label layouts
- Circular or rectangular shapes
- Dispose-safe animation controllers

**Setup Checklist**:
- [ ] Create StatefulWidget with AnimationController
- [ ] Implement tap gesture detection
- [ ] Add scale transform wrapper
- [ ] Integrate with AudioService for button sounds
- [ ] Support both circular and rectangular variants
- [ ] Handle proper disposal of animation controller

**Customization**:
- Add haptic feedback on tap
- Support disabled state with opacity
- Add loading state with spinner
- Support gradient backgrounds
- Add badge/notification indicator overlay

**Integration Points**:
- **AudioService** - Plays button sound on tap
- **Theme** - Colors from AppColors
- **Navigation** - Often triggers screen transitions

**Common Patterns**:
```dart
// Icon-only button
GameButton(
  icon: Icons.play_arrow,
  onPressed: () => _startGame(),
  isCircular: true,
)

// Button with label
GameButton(
  icon: Icons.settings,
  label: 'Settings',
  onPressed: () => _navigateToSettings(),
  width: 200,
  height: 60,
)
```

---

### 3. GameIconButton - Compact Icon Button

**Purpose**: Small, circular buttons for navigation and controls (back buttons, HUD controls).

**Architecture**:
```dart
class GameIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size; // Button diameter
}
```

**Key Features**:
- Fixed circular shape
- Simpler than GameButton (no animation by default)
- Consistent sizing across app
- Transparent backgrounds with borders

**Setup Checklist**:
- [ ] Create StatelessWidget (or StatefulWidget for animations)
- [ ] Add IconButton or custom GestureDetector
- [ ] Apply circular container decoration
- [ ] Integrate button sound playback
- [ ] Set default size and colors

**Usage Pattern**:
```dart
GameIconButton(
  icon: Icons.arrow_back,
  onPressed: () => Navigator.pop(context),
  backgroundColor: Colors.black54,
)
```

---

### 4. GameDialog - Animated Modal Container

**Purpose**: Unified dialog presentation with consistent animations and styling.

**Architecture**:
```dart
class GameDialog extends StatefulWidget {
  final String? title;
  final Widget child;
  final double width;
  final bool dismissible;

  // Animation sequence:
  // 1. Fade in overlay (300ms)
  // 2. Elastic bounce scale (600ms, ElasticOut curve)

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool dismissible = true,
  })
}
```

**Key Features**:
- Static `.show()` method for easy presentation
- Elastic bounce-in animation
- Fade-in overlay
- Optional title with decorative separator
- Configurable dismissibility
- Reverse animation on dismiss

**Setup Checklist**:
- [ ] Create StatefulWidget with AnimationController
- [ ] Implement fade and scale animations (parallel)
- [ ] Add showDialog wrapper in static method
- [ ] Create title section with optional separator
- [ ] Handle WillPopScope for dismissibility
- [ ] Implement proper animation disposal

**Customization**:
- Add background blur effect
- Support different animation curves (bounce, spring, etc.)
- Add swipe-to-dismiss gesture
- Include close button option
- Support full-screen variant

**Animation Details**:
```
Fade:  0 → 1 (0-300ms, easeIn)
Scale: 0 → 1 (0-600ms, ElasticOut)
```

**Usage Pattern**:
```dart
await GameDialog.show(
  context: context,
  title: 'Game Over',
  child: GameOverContent(),
  dismissible: false,
);
```

---

### 5. ScreenHeader - Standard Page Header

**Purpose**: Consistent header across all secondary screens with back navigation.

**Architecture**:
```dart
class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed; // Optional custom back action

  // Layout: [Back Button] [Title] [Spacer]
}
```

**Key Features**:
- Left-aligned back button
- Centered or left-aligned title
- Consistent height and padding
- Optional custom back action

**Setup Checklist**:
- [ ] Create horizontal Row layout
- [ ] Add GameIconButton for back navigation
- [ ] Add GameLabel for title
- [ ] Set consistent height constraint
- [ ] Handle default Navigator.pop

**Usage Pattern**:
```dart
Column(
  children: [
    ScreenHeader(title: 'Achievements'),
    Expanded(child: AchievementList()),
  ],
)
```

---

### 6. GameBackground - Consistent Backgrounds

**Purpose**: Provide uniform background styling across screens.

**Architecture**:
```dart
class GameBackground extends StatelessWidget {
  final Widget child;
  final String? imageAsset;
  final Color? backgroundColor;
  final BoxFit fit;

  // Renders: Background (image/color) + Overlay gradient + Child
}
```

**Key Features**:
- Support image or solid color backgrounds
- Optional gradient overlay for depth
- Consistent BoxFit handling
- Centers child content

**Setup Checklist**:
- [ ] Create Stack-based layout
- [ ] Add background layer (DecorationImage or Container)
- [ ] Add optional gradient overlay
- [ ] Position child content
- [ ] Handle asset loading errors

**Customization**:
- Add parallax scrolling effect
- Support animated background transitions
- Include blur option
- Add particle overlay system

---

### 7. HudStatIndicator - In-Game HUD Elements

**Purpose**: Display game statistics (score, lives, level) during gameplay.

**Architecture**:
```dart
class HudStatIndicator extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final String? imageAsset; // Alternative to icon

  // Layout: [Icon/Image] [Label: Value]
  // Style: Semi-transparent dark background
}
```

**Key Features**:
- Compact horizontal layout
- Semi-transparent background for visibility
- Support icon or image
- Consistent text styling

**Setup Checklist**:
- [ ] Create Container with rounded decoration
- [ ] Add icon/image slot
- [ ] Add label and value text fields
- [ ] Apply semi-transparent background
- [ ] Set padding and spacing

**Usage Pattern**:
```dart
Row(
  children: [
    HudStatIndicator(
      icon: Icons.star,
      label: 'Score',
      value: '1000',
    ),
    HudStatIndicator(
      imageAsset: 'assets/images/ui/heart.png',
      label: 'Lives',
      value: '3',
    ),
  ],
)
```

---

## Additional Specialized Dialogs

### PauseDialog
- Extends GameDialog
- Shows "Resume" and "Quit" options
- Optional settings access

### GameOverDialog
- Extends GameDialog
- Displays final score, level
- "New Best!" badge for high scores
- Replay and menu buttons

### TutorialDialog
- Extends GameDialog
- Shows on first launch only
- Explains controls and objectives
- Sets flag in settings to not show again

### ConfirmationDialog (e.g., ResetDataDialog)
- Extends GameDialog
- Shows warning message
- "Cancel" and "Confirm" buttons
- Different button colors for emphasis

---

## Component Hierarchy

```
Base Components (used everywhere):
├── GameLabel (text rendering)
├── GameButton (primary interactions)
└── GameIconButton (secondary actions)

Container Components (wrap content):
├── GameDialog (modal overlays)
├── GameBackground (full-screen backgrounds)
└── ScreenHeader (page headers)

Specialized Components (specific use cases):
├── HudStatIndicator (in-game HUD)
├── PauseDialog (game pause state)
├── GameOverDialog (game end state)
├── TutorialDialog (first-launch help)
└── ConfirmationDialog (destructive actions)
```

---

## Styling Consistency

All components should:
1. **Use theme colors** - Reference AppColors, never hardcode
2. **Follow size system** - Consistent padding, margins, border radius
3. **Support accessibility** - Minimum touch targets (48x48)
4. **Handle states** - Disabled, loading, error states
5. **Dispose properly** - Clean up controllers and listeners
6. **Play audio feedback** - Button taps, important events
7. **Respect theme mode** - Work in light/dark themes

## Implementation Order

1. **GameLabel** - Foundation for all text
2. **GameButton** - Primary interaction element
3. **GameIconButton** - Navigation and controls
4. **GameDialog** - Container for all modals
5. **ScreenHeader** - Standard page layout
6. **GameBackground** - Screen backgrounds
7. **HudStatIndicator** - Game HUD
8. **Specialized Dialogs** - Build on GameDialog

---

## Integration with Other Systems

| Component | Integrates With | Purpose |
|-----------|-----------------|---------|
| GameButton | AudioService | Button sound playback |
| GameDialog | Navigation | Modal presentation |
| ScreenHeader | Navigation | Back button functionality |
| HudStatIndicator | GameLoopManager | Real-time stat updates |
| GameBackground | BackgroundManager | Dynamic background switching |

---

## Testing Recommendations

1. **Visual consistency** - Create a demo screen showing all components
2. **Animation testing** - Verify smooth 60fps animations
3. **Responsiveness** - Test on different screen sizes
4. **Accessibility** - Test with TalkBack/VoiceOver
5. **Theme switching** - Verify appearance in light/dark modes
6. **Edge cases** - Long text, missing assets, null values

---

## Next Steps

After implementing shared UI components:
- Configure **Theme & Styling** (08_Theme_And_Styling.md) for consistent colors
- Set up **Navigation System** (02_Navigation_System.md) to use these components
- Integrate **Audio Service** (03_Audio_System.md) for button sounds
