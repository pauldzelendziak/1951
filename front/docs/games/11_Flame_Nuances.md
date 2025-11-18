# Flame Nuances and Common Pitfalls

## Purpose

Flame integration with Flutter has several non-obvious behaviors and gotchas. This document covers common issues, solutions, and best practices for working with Flame game engine.

---

## 1. The Black Background Problem

### Problem
Flame's GameWidget renders a **black background by default** that covers Flutter's background, even when the game is transparent.

### Visual Issue
```
User sees:     Black screen (Flame's default background)
Expected:      Flutter background image
```

### Solution 1: Set Flame Background Color to Transparent

```dart
class MyGame extends FlameGame {
  @override
  Color backgroundColor() => Color(0x00000000); // Fully transparent

  // Alternative:
  @override
  Color backgroundColor() => Colors.transparent;
}
```

**When to use**: When you want Flutter backgrounds visible through Flame.

### Solution 2: Three-Layer Stack Architecture

```dart
MaterialApp(
  builder: (context, child) {
    return Stack(
      children: [
        // Layer 1: Background image (Flutter)
        BackgroundImage(),

        // Layer 2: Decorative Flame animations (blurred, non-interactive)
        IgnorePointer(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: GameWidget(game: decorativeGame),
          ),
        ),

        // Layer 3: Interactive content (Flutter or Flame)
        child!,
      ],
    );
  },
)
```

**When to use**: When you want persistent background across all screens.

### Solution 3: Flame Renders Own Background

```dart
class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Add background sprite
    add(SpriteComponent(
      sprite: await loadSprite('background.png'),
      size: size,
      priority: -1, // Behind everything
    ));
  }
}
```

**When to use**: When game should be self-contained.

---

## 2. Component Not Rendering

### Common Causes

#### Missing Size
```dart
// WRONG: Component won't render
class MyComponent extends PositionComponent {
  @override
  Future<void> onLoad() async {
    // size not set!
  }
}

// CORRECT
class MyComponent extends PositionComponent {
  @override
  Future<void> onLoad() async {
    size = Vector2(64, 64); // Set size!
  }
}
```

#### Position Off-Screen
```dart
// WRONG: Positioned outside visible area
position = Vector2(-100, -100);

// CORRECT: Position within game bounds
position = Vector2(100, 100);
```

#### No Sprite/Paint
```dart
// WRONG: Nothing to render
class MyComponent extends SpriteComponent {
  @override
  Future<void> onLoad() async {
    // No sprite loaded!
  }
}

// CORRECT
class MyComponent extends SpriteComponent {
  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('player.png');
  }
}
```

#### Wrong Priority
```dart
// WRONG: Behind other components
priority = -100;

// CORRECT: Set appropriate priority (higher = front)
priority = 10;
```

---

## 3. Collision Detection Issues

### Not Detecting Collisions

#### Missing Mixin
```dart
// WRONG: No collision detection
class MyGame extends FlameGame {
  // Collisions won't work!
}

// CORRECT
class MyGame extends FlameGame with HasCollisionDetection {
  // Collisions enabled
}
```

#### Missing Hitbox
```dart
// WRONG: No hitbox added
class Player extends PositionComponent with CollisionCallbacks {
  @override
  Future<void> onLoad() async {
    // No hitbox!
  }
}

// CORRECT
class Player extends PositionComponent with CollisionCallbacks {
  @override
  Future<void> onLoad() async {
    add(CircleHitbox()); // Add hitbox!
  }
}
```

#### Hitbox Wrong Size
```dart
// WRONG: Hitbox doesn't match sprite
add(CircleHitbox(radius: 1000)); // Huge hitbox

// CORRECT: Match sprite size
add(CircleHitbox(
  radius: size.x * 0.4, // 80% of sprite width
  position: size / 2,
  anchor: Anchor.center,
));
```

### False Collisions

#### Hitbox Too Large
```dart
// Problem: Collisions feel unfair
add(RectangleHitbox()); // Full sprite size

// Solution: Smaller hitbox for better feel
add(CircleHitbox(
  radius: size.x * 0.3, // 60% of sprite
));
```

---

## 4. Asset Loading Issues

### Assets Not Found

#### Wrong Path
```dart
// WRONG: Missing 'images/' prefix
sprite = await loadSprite('player.png');

// CORRECT: Flame expects images/ directory
sprite = await loadSprite('player.png');
// Looks for: assets/images/player.png
```

#### Not Declared in pubspec.yaml
```yaml
# WRONG: Assets not declared
flutter:
  # Nothing here

# CORRECT
flutter:
  assets:
    - assets/images/
    - assets/images/player/
    - assets/audio/
```

### Preloading Best Practices

```dart
// WRONG: Load during gameplay (causes lag)
void spawnEnemy() {
  final sprite = await loadSprite('enemy.png'); // Don't do this!
}

// CORRECT: Preload in onLoad
@override
Future<void> onLoad() async {
  await images.loadAll([
    'player.png',
    'enemy.png',
    'bullet.png',
  ]);
}

// Then use cached images:
sprite = Sprite(images.fromCache('enemy.png'));
```

---

## 5. Update vs onLoad Confusion

### When to Use Each

```dart
// onLoad: ONE-TIME initialization
@override
Future<void> onLoad() async {
  size = Vector2(64, 64);
  position = Vector2(100, 100);
  sprite = await loadSprite('player.png');
  add(CircleHitbox());
}

// update: EVERY FRAME logic
@override
void update(double dt) {
  super.update(dt);
  position.y += 100 * dt; // Move down at 100 pixels/second
}
```

### Common Mistakes

```dart
// WRONG: Loading sprites every frame
@override
void update(double dt) {
  sprite = await loadSprite('player.png'); // Don't!
}

// WRONG: One-time setup in update
@override
void update(double dt) {
  if (size == Vector2.zero()) {
    size = Vector2(64, 64); // Should be in onLoad
  }
}
```

---

## 6. Game Reference Issues

### Accessing Game Before Ready

```dart
// WRONG: gameRef not available yet
class Player extends PositionComponent {
  Player() {
    position = gameRef.size / 2; // ERROR: gameRef is null!
  }
}

// CORRECT: Access gameRef in onLoad
class Player extends PositionComponent with HasGameRef<MyGame> {
  @override
  Future<void> onLoad() async {
    position = gameRef.size / 2; // Safe: gameRef is set
  }
}
```

### Missing HasGameRef Mixin

```dart
// WRONG: Can't access gameRef
class Player extends PositionComponent {
  void something() {
    gameRef.doSomething(); // ERROR: No gameRef!
  }
}

// CORRECT: Add mixin
class Player extends PositionComponent with HasGameRef<MyGame> {
  void something() {
    gameRef.doSomething(); // Works!
  }
}
```

---

## 7. Component Lifecycle

### Proper Removal

```dart
// Add component
add(enemyComponent);

// Remove component
enemyComponent.removeFromParent();

// WRONG: Don't remove during collision
@override
void onCollision(...) {
  removeFromParent(); // Can cause issues
  other.removeFromParent(); // Can cause issues
}

// CORRECT: Remove after current update cycle
@override
void onCollision(...) {
  Future.microtask(() {
    removeFromParent();
    other.removeFromParent();
  });
}

// OR use RemoveEffect
@override
void onCollision(...) {
  add(RemoveEffect());
}
```

---

## 8. Input Handling

### Touch Events

```dart
// WRONG: Wrong mixin
class MyGame extends FlameGame {
  void onTap() {} // Won't be called!
}

// CORRECT: Add detector mixin
class MyGame extends FlameGame with TapDetector {
  @override
  void onTapDown(TapDownInfo info) {
    print('Tapped at: ${info.eventPosition.global}');
  }
}

// For dragging:
class MyGame extends FlameGame with PanDetector {
  @override
  void onPanUpdate(DragUpdateInfo info) {
    player.position = info.eventPosition.global;
  }
}
```

### Component-Level Input

```dart
class Button extends PositionComponent with TapCallbacks {
  @override
  void onTapDown(TapDownEvent event) {
    print('Button tapped!');
  }
}
```

---

## 9. Pause/Resume Game

### Proper Implementation

```dart
class MyGame extends FlameGame {
  void pauseGame() {
    pauseEngine(); // Flame built-in: stops update() calls
  }

  void resumeGame() {
    resumeEngine(); // Flame built-in: resumes update() calls
  }
}

// WRONG: Manual pause tracking
bool isPaused = false;

@override
void update(double dt) {
  if (isPaused) return; // Don't do this, use pauseEngine()
}
```

---

## 10. Anchor Points Confusion

### Understanding Anchors

```
Anchor.topLeft:     (0, 0) relative to component
Anchor.center:      (width/2, height/2)
Anchor.bottomRight: (width, height)
```

```dart
// WRONG: Unexpected positioning
component.position = Vector2(100, 100);
component.anchor = Anchor.topLeft;
// Component's top-left corner at (100, 100)

// CORRECT: Center component
component.position = Vector2(100, 100);
component.anchor = Anchor.center;
// Component's center at (100, 100)
```

**Rule of Thumb**: Use `Anchor.center` for most game entities (easier rotation and positioning).

---

## 11. Performance Issues

### Too Many Components

```dart
// WRONG: Creating hundreds of components every frame
void update(double dt) {
  for (int i = 0; i < 100; i++) {
    add(ParticleComponent()); // Memory leak!
  }
}

// CORRECT: Limit component count
void update(double dt) {
  if (children.length < 100) {
    add(ParticleComponent());
  }
}

// BETTER: Use object pooling (advanced)
```

### Inefficient Collision Detection

```dart
// WRONG: Checking every component
void update(double dt) {
  for (var enemy in children.whereType<Enemy>()) {
    for (var bullet in children.whereType<Bullet>()) {
      if (checkCollision(enemy, bullet)) {
        // ...
      }
    }
  }
}

// CORRECT: Use Flame's collision detection
class MyGame extends FlameGame with HasCollisionDetection {
  // Automatic collision detection
}

class Enemy extends PositionComponent with CollisionCallbacks {
  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (other is Bullet) {
      // Handle collision
    }
  }
}
```

---

## 12. Coordinate Systems

### Screen vs Game Coordinates

```dart
// Screen coordinates (from touch events)
void onTapDown(TapDownInfo info) {
  final screenPos = info.eventPosition.global; // Screen coordinates

  // Use directly if game matches screen size
  player.position = screenPos;
}

// For camera-based games:
void onTapDown(TapDownInfo info) {
  final worldPos = camera.screenToWorld(info.eventPosition.global);
  player.position = worldPos;
}
```

---

## 13. Timer Issues

### Using Flame Timers

```dart
// CORRECT: Use Flame's Timer component
class MyGame extends FlameGame {
  late Timer spawnTimer;

  @override
  Future<void> onLoad() async {
    spawnTimer = Timer(
      2.0,
      repeat: true,
      onTick: () => _spawnEnemy(),
    );

    add(spawnTimer); // Important: Add to game!
  }
}

// WRONG: Manual timer tracking
double _timeElapsed = 0;

@override
void update(double dt) {
  _timeElapsed += dt;
  if (_timeElapsed >= 2.0) {
    _spawnEnemy();
    _timeElapsed = 0;
  }
}
// This works but Flame's Timer is cleaner
```

---

## Quick Reference: Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| Black screen | Flame default background | Set `backgroundColor()` to transparent |
| Component invisible | No size/sprite | Set `size` and load `sprite` in `onLoad` |
| No collisions | Missing mixin/hitbox | Add `HasCollisionDetection` and `CircleHitbox` |
| Asset not found | Wrong path/not in pubspec | Check path and add to pubspec.yaml |
| gameRef is null | Accessed too early | Use `HasGameRef` mixin, access in `onLoad` |
| Tap not working | Missing detector | Add `TapDetector` or `TapCallbacks` mixin |
| Game won't pause | Using manual flag | Use `pauseEngine()` / `resumeEngine()` |
| Wrong position | Wrong anchor | Set `anchor = Anchor.center` |

---

## Debugging Tips

### Enable Flame Debug Mode

```dart
class MyGame extends FlameGame with HasCollisionDetection {
  @override
  Future<void> onLoad() async {
    debugMode = true; // Shows hitboxes and component bounds
  }
}
```

### Print Component Info

```dart
@override
void update(double dt) {
  print('Position: $position, Size: $size, Children: ${children.length}');
}
```

### Check Component Tree

```dart
void printComponentTree(Component component, [int indent = 0]) {
  print('${'  ' * indent}${component.runtimeType}');
  for (var child in component.children) {
    printComponentTree(child, indent + 1);
  }
}

// Usage:
printComponentTree(game);
```

---

## Next Steps

After understanding Flame nuances:
- Review **Flame Integration** (07) with this knowledge
- Build a simple test game to practice these patterns
- Consult Flame documentation for advanced features
