# Theme and Styling

## Purpose

A consistent theme system establishes your game's visual identity and ensures uniform appearance across all screens and components. It centralizes colors, typography, and styling patterns for easy maintenance and updates.

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

flutter:
  fonts:
    - family: ConcertOne  # Example custom font
      fonts:
        - asset: assets/fonts/ConcertOne-Regular.ttf
```

---

## Architecture Overview

### Three-Layer Theme System

```
┌────────────────────────────────┐
│  1. AppColors (Constants)      │  ← Color palette
│     - Primary, accent, text    │
└────────────────────────────────┘
              ↓
┌────────────────────────────────┐
│  2. AppTheme (Material Theme)  │  ← Theme configuration
│     - Typography, shapes       │
└────────────────────────────────┘
              ↓
┌────────────────────────────────┐
│  3. Component Styles           │  ← Widget-specific
│     - Button styles, etc.      │
└────────────────────────────────┘
```

---

## 1. Color Palette

### AppColors Class

```dart
class AppColors {
  // Primary colors (neon/vibrant theme)
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonPink = Color(0xFFFF10F0);
  static const Color neonAmber = Color(0xFFFFBF00);
  static const Color neonBlue = Color(0xFF1E90FF);
  static const Color neonPurple = Color(0xFFBF00FF);

  // Text colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textWhite70 = Color(0xB3FFFFFF); // 70% opacity
  static const Color textWhite54 = Color(0x8AFFFFFF); // 54% opacity
  static const Color textBlack = Color(0xFF000000);

  // Background colors
  static const Color darkNavy = Color(0xFF0A0E27);
  static const Color deepSpace = Color(0xFF0D1117);
  static const Color pureBlack = Color(0xFF000000);

  // Overlay colors
  static const Color overlayDark = Color(0xCC000000); // 80% black
  static const Color overlayLight = Color(0x33FFFFFF); // 20% white

  // UI element colors
  static const Color dialogBackground = Color(0xFF1a237e); // Deep blue
  static const Color buttonBackground = Color(0xFF283593); // Medium blue
  static const Color buttonBackgroundHover = Color(0xFF3949ab);
  static const Color cardBackground = Color(0xFF212121);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Game-specific
  static const Color crystal = Color(0xFF00E5FF);
  static const Color heart = Color(0xFFE91E63);
  static const Color shield = Color(0xFF03A9F4);

  // Prevent instantiation
  AppColors._();
}
```

**Setup Checklist**:
- [ ] Create AppColors class with private constructor
- [ ] Define primary color palette (3-6 colors)
- [ ] Define text colors (white, black, variants)
- [ ] Define background colors (dark, darker, darkest)
- [ ] Define overlay colors for modals
- [ ] Define UI element colors (buttons, cards, dialogs)
- [ ] Define status colors (success, error, warning)
- [ ] Add game-specific colors (collectibles, power-ups)

**Color Naming Conventions**:
- Descriptive names: `neonCyan` not `color1`
- Purpose-based: `buttonBackground` not `blue2`
- Include opacity in name: `textWhite70` for 70% opacity

---

## 2. Material Theme

### AppTheme Class

```dart
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      // Use Material Design 3
      useMaterial3: true,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.neonCyan,
        secondary: AppColors.neonPink,
        surface: AppColors.darkNavy,
        background: AppColors.pureBlack,
        error: AppColors.error,
        onPrimary: AppColors.textBlack,
        onSecondary: AppColors.textWhite,
        onSurface: AppColors.textWhite,
        onBackground: AppColors.textWhite,
        onError: AppColors.textWhite,
      ),

      // Brightness
      brightness: Brightness.dark,

      // Typography
      fontFamily: 'ConcertOne',
      textTheme: _buildTextTheme(),

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textWhite),
        titleTextStyle: TextStyle(
          fontFamily: 'ConcertOne',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textWhite,
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBackground,
          foregroundColor: AppColors.textWhite,
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: AppColors.textWhite,
        size: 24,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: AppColors.textWhite54,
        thickness: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Display (largest)
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
        shadows: createTextGlow(AppColors.neonCyan, 10),
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
        shadows: createTextGlow(AppColors.neonCyan, 8),
      ),
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
        shadows: createTextGlow(AppColors.neonCyan, 6),
      ),

      // Headings
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
      ),

      // Titles
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),

      // Body text
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textWhite70,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textWhite70,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textWhite54,
      ),

      // Labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textWhite,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textWhite,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textWhite70,
      ),
    );
  }

  // Text glow effect helper
  static List<Shadow> createTextGlow(Color color, double blurRadius) {
    return [
      Shadow(
        color: color.withOpacity(0.8),
        blurRadius: blurRadius,
        offset: Offset.zero,
      ),
      Shadow(
        color: color.withOpacity(0.5),
        blurRadius: blurRadius * 2,
        offset: Offset.zero,
      ),
    ];
  }

  // Text stroke effect helper
  static List<Shadow> createTextStroke(Color color, double strokeWidth) {
    return [
      for (double i = -strokeWidth; i <= strokeWidth; i += 0.5)
        for (double j = -strokeWidth; j <= strokeWidth; j += 0.5)
          Shadow(
            color: color,
            offset: Offset(i, j),
            blurRadius: 0,
          ),
    ];
  }

  // Prevent instantiation
  AppTheme._();
}
```

**Setup Checklist**:
- [ ] Create AppTheme class with private constructor
- [ ] Define Material theme with useMaterial3: true
- [ ] Configure ColorScheme
- [ ] Set custom font family
- [ ] Build TextTheme with all text styles
- [ ] Configure component themes (AppBar, Card, Button)
- [ ] Add helper methods for effects (glow, stroke)

---

## 3. Applying Theme

### In main.dart

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Avoider',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme, // Same theme for consistency
      themeMode: ThemeMode.dark,
      home: MenuScreen(),
    );
  }
}
```

---

## 4. Using Theme in Widgets

### Accessing Theme Values

```dart
// Get theme
final theme = Theme.of(context);

// Use color scheme
Container(
  color: theme.colorScheme.primary,
)

// Use text styles
Text(
  'Title',
  style: theme.textTheme.displayLarge,
)

// Use custom colors
Container(
  decoration: BoxDecoration(
    color: AppColors.dialogBackground,
    border: Border.all(color: AppColors.neonCyan),
  ),
)
```

### Custom Text Styles

```dart
// Base style from theme
Text(
  'Custom Text',
  style: theme.textTheme.bodyLarge?.copyWith(
    color: AppColors.neonPink,
    fontSize: 20,
  ),
)

// Completely custom with glow
Text(
  'Glowing Text',
  style: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
    shadows: AppTheme.createTextGlow(AppColors.neonCyan, 8),
  ),
)
```

---

## 5. Component Styling Patterns

### GameButton Style

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.buttonBackground,
        AppColors.buttonBackgroundHover,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppColors.neonCyan,
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.neonCyan.withOpacity(0.5),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ],
  ),
)
```

### GameDialog Style

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.dialogBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppColors.neonCyan,
      width: 3,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.7),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  ),
)
```

### Card/Panel Style

```dart
Container(
  margin: EdgeInsets.all(16),
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: AppColors.cardBackground.withOpacity(0.8),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppColors.textWhite54,
      width: 1,
    ),
  ),
)
```

---

## 6. Custom Font Setup

### Adding Font Assets

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: ConcertOne
      fonts:
        - asset: assets/fonts/ConcertOne-Regular.ttf
          weight: 400
    - family: Orbitron
      fonts:
        - asset: assets/fonts/Orbitron-Regular.ttf
          weight: 400
        - asset: assets/fonts/Orbitron-Bold.ttf
          weight: 700
```

### File Structure

```
assets/
└── fonts/
    ├── ConcertOne-Regular.ttf
    ├── Orbitron-Regular.ttf
    └── Orbitron-Bold.ttf
```

### Using Custom Fonts

```dart
// Via theme (affects entire app)
fontFamily: 'ConcertOne'

// Per widget
Text(
  'Custom Font',
  style: TextStyle(fontFamily: 'Orbitron'),
)
```

---

## 7. Responsive Styling

### Size Helpers

```dart
class AppSizes {
  static double padding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 600 ? 24 : 16;
  }

  static double buttonHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return height > 800 ? 60 : 48;
  }

  static double fontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    return baseSize * (width > 600 ? 1.2 : 1.0);
  }
}
```

---

## 8. Animation Curves

### Common Curves

```dart
class AppCurves {
  static const Curve buttonPress = Curves.easeInOut;
  static const Curve dialogBounce = Curves.elasticOut;
  static const Curve pageTransition = Curves.easeInOutCubic;
  static const Curve shimmer = Curves.linear;
}
```

---

## Best Practices

1. **Centralize colors**: Never hardcode colors in widgets
2. **Use theme where possible**: Leverage Material theme system
3. **Consistent naming**: Use descriptive, purpose-based names
4. **Test accessibility**: Ensure sufficient contrast ratios
5. **Support dark mode**: Even if you only use dark theme
6. **Document custom styles**: Comment complex decorations
7. **Optimize fonts**: Only include weights you use

---

## Common Pitfalls

1. **Hardcoded colors**
   - Problem: Difficult to change theme
   - Solution: Always use AppColors constants

2. **Inconsistent spacing**
   - Problem: Misaligned UI elements
   - Solution: Define spacing constants (8, 16, 24, 32)

3. **Too many font sizes**
   - Problem: Inconsistent typography
   - Solution: Use theme text styles

4. **Ignoring contrast**
   - Problem: Unreadable text
   - Solution: Test with accessibility tools

5. **Large font files**
   - Problem: Increased app size
   - Solution: Only include necessary weights

---

## Testing Checklist

- [ ] All colors defined in AppColors
- [ ] Custom font loads correctly
- [ ] Text styles consistent across app
- [ ] Sufficient contrast for readability
- [ ] Button styles uniform
- [ ] Dialog styles consistent
- [ ] No hardcoded colors in widgets
- [ ] Theme changes reflect throughout app

---

## Next Steps

After setting up theme:
- Apply to **Shared UI Components** (01)
- Use in **Navigation System** (02) for transitions
- Integrate with **Animation Systems** (10) for effects
