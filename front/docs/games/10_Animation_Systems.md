# Animation Systems

## Purpose

Animations bring your game to life, providing visual feedback, enhancing transitions, and creating an engaging user experience. This document covers both UI animations (Flutter) and game animations (Flame).

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flame: ^1.33.0
```

---

## Animation Categories

### 1. UI Animations (Flutter)
- Button press feedback
- Dialog entrance/exit
- Screen transitions
- Shimmer effects
- Menu animations

### 2. Game Animations (Flame)
- Particle effects
- Sprite animations
- Movement patterns
- Effects (scale, rotation, opacity)

### 3. Background Animations
- Persistent decorative animations
- Parallax backgrounds
- Ambient effects

---

## 1. UI Animations (Flutter)

### Button Press Animation

```dart
class GameButton extends StatefulWidget {
  final VoidCallback onPressed;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });

    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          // Button content
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Key Points**:
- Duration: 100-200ms for snappy feedback
- Curve: easeInOut for smooth feel
- Scale: 0.95 (5% reduction)
- Always dispose controller

---

### Dialog Animation

```dart
class GameDialog extends StatefulWidget {
  final Widget child;
  final String? title;

  @override
  State<GameDialog> createState() => _GameDialogState();
}

class _GameDialogState extends State<GameDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0, 0.5, curve: Curves.easeIn),
    ));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          // Dialog content
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => GameDialog(child: child, title: title),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Key Points**:
- Elastic curve for bounce effect
- Combined scale and fade
- Fade duration: first 50% of animation
- Total duration: 600ms

---

### Pulse Animation (Repeating)

```dart
class PulsingButton extends StatefulWidget {
  final Widget child;

  @override
  State<PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

### Shimmer Effect

```dart
class ShimmerButtonWrapper extends StatelessWidget {
  final Widget child;
  final AnimationController controller;

  const ShimmerButtonWrapper({
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(
                    -200 + (controller.value * 400),
                    -200 + (controller.value * 400),
                  ),
                  child: Container(
                    width: 100,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## 2. Game Animations (Flame)

### Particle Effects

```dart
ParticleSystemComponent createExplosion(Vector2 position) {
  return ParticleSystemComponent(
    position: position,
    particle: Particle.generate(
      count: 30,
      lifespan: 1.0,
      generator: (i) {
        final angle = (i / 30) * 2 * pi;
        final speed = 100 + Random().nextDouble() * 100;

        return AcceleratedParticle(
          acceleration: Vector2(0, 200), // Gravity
          speed: Vector2(
            cos(angle) * speed,
            sin(angle) * speed,
          ),
          child: CircleParticle(
            radius: 2 + Random().nextDouble() * 3,
            paint: Paint()
              ..color = Colors.orange.withOpacity(0.8),
          ),
        );
      },
    ),
  );
}

// Usage:
add(createExplosion(position));
```

### Sprite Trail Effect

```dart
class PlayerTrail extends ParticleSystemComponent {
  PlayerTrail()
      : super(
          particle: Particle.generate(
            count: 30,
            lifespan: 0.8,
            generator: (i) {
              return AcceleratedParticle(
                acceleration: Vector2(0, 100),
                speed: Vector2.zero(),
                child: CircleParticle(
                  radius: 2,
                  paint: Paint()
                    ..color = Colors.cyan.withOpacity(0.5),
                ),
              );
            },
          ),
        );
}
```

### Flame Effects (Built-in)

```dart
// Scale effect
add(
  ScaleEffect.to(
    Vector2.all(1.2),
    EffectController(
      duration: 0.5,
      curve: Curves.easeInOut,
      reverseDuration: 0.5,
      infinite: true,
    ),
  ),
);

// Rotation effect
add(
  RotateEffect.by(
    2 * pi,
    EffectController(duration: 2.0, infinite: true),
  ),
);

// Opacity effect (blinking)
add(
  OpacityEffect.to(
    0.3,
    EffectController(
      duration: 0.3,
      reverseDuration: 0.3,
      infinite: true,
    ),
  ),
);

// Move effect
add(
  MoveEffect.to(
    Vector2(100, 200),
    EffectController(duration: 1.0, curve: Curves.easeInOut),
  ),
);

// Sequence of effects
add(
  SequenceEffect([
    ScaleEffect.to(Vector2.all(1.5), EffectController(duration: 0.2)),
    ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.2)),
    RemoveEffect(),
  ]),
);
```

---

## 3. Background Animations

### Persistent Game Widget

```dart
// In main.dart MaterialApp.builder:
Stack(
  children: [
    // Background image
    BackgroundImage(),

    // Persistent animation layer
    IgnorePointer(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: GameWidget(
          game: spaceshipAnimationService.game,
        ),
      ),
    ),

    // Interactive content
    child!,
  ],
)
```

### Floating Stars Component

```dart
class FloatingStarComponent extends SpriteComponent
    with HasGameRef {

  late Vector2 velocity;
  double rotationSpeed;

  FloatingStarComponent()
      : rotationSpeed = (Random().nextDouble() - 0.5) * 2;

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('star.png');
    size = Vector2.all(20 + Random().nextDouble() * 30);
    position = Vector2(
      Random().nextDouble() * gameRef.size.x,
      Random().nextDouble() * gameRef.size.y,
    );

    velocity = Vector2(
      (Random().nextDouble() - 0.5) * 50,
      (Random().nextDouble() - 0.5) * 50,
    );

    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += velocity * dt;
    angle += rotationSpeed * dt;

    // Wrap around screen
    if (position.x < -size.x) position.x = gameRef.size.x + size.x;
    if (position.x > gameRef.size.x + size.x) position.x = -size.x;
    if (position.y < -size.y) position.y = gameRef.size.y + size.y;
    if (position.y > gameRef.size.y + size.y) position.y = -size.y;
  }
}
```

---

## Animation Timing Guidelines

### UI Animations
- **Button press**: 100-150ms
- **Screen transition**: 250-350ms
- **Dialog enter**: 400-600ms
- **Toast notification**: 300ms enter, 300ms exit
- **Shimmer sweep**: 1500-2000ms

### Game Animations
- **Particle lifespan**: 0.5-2.0 seconds
- **Effect duration**: 0.2-1.0 seconds
- **Rotation speed**: 1-3 rad/s
- **Movement speed**: Based on game difficulty

---

## Animation Curves

```dart
// Standard Flutter curves
Curves.easeIn        // Slow start
Curves.easeOut       // Slow end
Curves.easeInOut     // Slow start and end
Curves.linear        // Constant speed
Curves.bounceOut     // Bouncy ending
Curves.elasticOut    // Elastic bounce
Curves.decelerate    // Fast then slow

// Custom curve
Cubic(0.4, 0.0, 0.2, 1.0)
```

---

## Best Practices

1. **Dispose controllers**: Always in dispose()
2. **Use vsync**: Required for animation controllers
3. **Appropriate duration**: Not too slow (boring) or fast (jarring)
4. **Consistent timing**: Similar actions have similar durations
5. **Performance**: Limit simultaneous animations
6. **Accessibility**: Respect reduced motion preferences
7. **Subtle effects**: Animations should enhance, not distract

---

## Performance Optimization

### Reduce Overdraw
```dart
// Bad: Rebuilds entire widget tree
AnimatedBuilder(
  animation: controller,
  builder: (context, child) => EntireScreen(...),
)

// Good: Only rebuilds animated widget
AnimatedBuilder(
  animation: controller,
  builder: (context, child) => Transform.scale(...),
  child: ExpensiveWidget(), // Built once
)
```

### Limit Particle Count
```dart
// Adjust based on device performance
final maxParticles = Platform.isAndroid ? 20 : 30;
```

### Cache Animations
```dart
// Reuse animation controllers where possible
class _MyState extends State<MyWidget> {
  static AnimationController? _sharedController;

  @override
  void initState() {
    _sharedController ??= AnimationController(...);
  }
}
```

---

## Common Pitfalls

1. **Memory leaks**: Not disposing controllers
2. **Janky animations**: Too complex widget trees
3. **Overlapping animations**: Conflicting transforms
4. **Wrong vsync**: Using wrong TickerProvider
5. **No null checks**: Controllers accessed after dispose

---

## Testing Checklist

- [ ] Button animations feel responsive
- [ ] Dialogs animate smoothly
- [ ] Screen transitions don't lag
- [ ] Particle effects don't cause frame drops
- [ ] Background animations don't interfere with gameplay
- [ ] All controllers disposed properly
- [ ] Animations respect reduced motion settings

---

## Next Steps

After implementing animations:
- Apply to **Shared UI Components** (01)
- Use in **Navigation System** (02) for transitions
- Add to **Flame game components** (07) for effects
