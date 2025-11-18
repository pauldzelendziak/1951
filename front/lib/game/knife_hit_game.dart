import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
// No Flutter widgets are required directly here; Flame provides the game APIs.

/// Main Flame game instance hosting the playfield and game state.
import 'package:knife_hit/core/constants/asset_paths.dart';
import 'package:knife_hit/core/constants/game_constants.dart';

class KnifeHitGame extends FlameGame with HasCollisionDetection {
  /// The rotating target component (tree/log) positioned at the center.
  late TargetComponent target;

  /// Active knives that start on the playfield.
  final List<KnifeComponent> knives = [];

  /// Number of knives available at the start of a level.
  int knivesRemaining = 5;
  int _lastThrowAt = 0; // ms since epoch

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Додаємо дерево по центру
    // Debug: print the asset key we are about to load for the target
    print('DEBUG: loading target asset key: "${AssetPaths.targetDefaultWood}"');
    // Make the target smaller so the wood image appears reduced on screen.
    const double targetDiameter = 280; // px
    target = TargetComponent()
      ..sprite = await loadSprite(AssetPaths.targetDefaultWood)
      ..size = Vector2.all(targetDiameter)
      ..anchor = Anchor.center
      ..position = size / 2;
    add(target);

    // Додаємо ножі внизу
    for (int i = 0; i < knivesRemaining; i++) {
      // Debug: print the asset key we are about to load for the knife
      print('DEBUG: loading knife asset key: "${AssetPaths.knifeTanto}"');
      final knife = KnifeComponent()
        ..sprite = await loadSprite(AssetPaths.knifeTanto)
        ..size = Vector2(40, 120)
        ..anchor = Anchor.center
        ..position = Vector2(size.x / 2, size.y - 50);
      add(knife);
      knives.add(knife);
    }
  }

  /// Called by the containing widget when the user taps the play field.
  /// Throws the next available knife toward the target (straight-line).
  void onUserTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastThrowAt < GameConstants.knifeThrowCooldownMs) {
      return; // still in cooldown
    }

    // find next available knife
    KnifeComponent? next;
    for (final k in knives) {
      if (!k.isFlying && !k.isStuck) {
        next = k;
        break;
      }
    }
    if (next == null) return;

    // compute direction: from knife to target center
    final targetComp = target;
    final dir = (targetComp.absoluteCenter - next.absoluteCenter).normalized();

    next.throwKnife(dir);
    _lastThrowAt = now;
  }

  @override
  void update(double dt) {
    super.update(dt);
    target.update(dt);
  }
}

class TargetComponent extends SpriteComponent with CollisionCallbacks {
  /// Creates a static rotating target component (wooden log).
  TargetComponent() : super() {
    // Hitbox radius will be set according to component size (set in onMount)
    // Add a placeholder hitbox; it will be replaced in onMount when size is known.
    add(CircleHitbox(radius: 1, anchor: Anchor.center));
  }

  @override
  void onMount() {
    super.onMount();
    // Update hitbox radius to match half of the current size (radius of the circle)
    final circle = children.whereType<CircleHitbox>().firstOrNull;
    if (circle != null) {
      circle.radius = size.x / 2;
      circle.anchor = Anchor.center;
    }
  }

  final double _rotationSpeed = 60 * math.pi / 180; // 60°/сек
  bool clockwise = true;

  @override
  void update(double dt) {
    super.update(dt);
    angle += (clockwise ? _rotationSpeed : -_rotationSpeed) * dt;
  }

  void shake() {
    add(
      SequenceEffect([
        ScaleEffect.to(Vector2.all(0.98), EffectController(duration: 0.05)),
        ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.05)),
      ]),
    );
  }
}

class KnifeComponent extends SpriteComponent with CollisionCallbacks {
  /// Whether the knife is currently flying towards the target.
  bool isFlying = false;

  /// Whether the knife is currently stuck in the target.
  bool isStuck = false;

  /// Travel speed in pixels per second.
  double speed = 1200; // px/sec

  /// Direction vector for movement while flying.
  Vector2 direction = Vector2(0, -1);

  /// Sprite orientation correction (so the sprite image faces the travel
  /// direction correctly). Tweak if the art's forward direction differs.
  ///
  /// Set to +pi/2 so the blade (art) which points upwards will align with
  /// movement direction. Adjust if your sprite points a different way.
  final double orientationOffset = math.pi / 2;

  /// How deep the knife embeds into the target in pixels.
  double penetrationDepth = 1;

  // --- Tracer (trail) support ------------------------------------------------
  KnifeTrail? _trail;
  double _trailTimer = 0.0;
  final double _trailSpawnInterval = 0.02; // seconds between trail points
  // When >0, skip update logic for this many frames (prevents races during reparent)
  int _skipUpdates = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_skipUpdates > 0) {
      _skipUpdates -= 1;
      return;
    }
    if (isFlying && !isStuck) {
      // Emit trail points periodically while flying (in world coords)
      _trailTimer += dt;
      if (_trailTimer >= _trailSpawnInterval) {
        _trailTimer = 0.0;
        _trail?.addPoint(absoluteCenter);
      }
      // Predictive movement: compute next position and test segment-circle
      // intersection to avoid overshoot and flicker on stick.
      final displacement = direction * speed * dt;
      final nextPos = position + displacement;

      final target = parent!.children.whereType<TargetComponent>().firstOrNull;
      if (target != null) {
        // Use world (absolute) coordinates for the collision math to avoid
        // mixing local and global coordinates which caused inverted impact
        // vectors and wrong impact angles.
        final posWorld = absoluteCenter;
        final nextWorld = posWorld + displacement;
        final center = target.absoluteCenter;
        final double r = target.size.x / 2;

        // Solve |(posWorld + s*t) - center|^2 = r^2 for t in [0,1], where
        // s = nextWorld - posWorld.
        final s = nextWorld - posWorld;
        final v = posWorld - center;
        final a = s.dot(s);
        final b = 2 * s.dot(v);
        final c = v.dot(v) - r * r;

        double? tHit;
        if (a.abs() < 1e-8) {
          if (v.length <= r) tHit = 0.0;
        } else {
          final disc = b * b - 4 * a * c;
          if (disc >= 0) {
            final sqrtD = math.sqrt(disc);
            final t1 = (-b - sqrtD) / (2 * a);
            final t2 = (-b + sqrtD) / (2 * a);
            for (final t in [t1, t2]) {
              if (t >= 0 && t <= 1) {
                if (tHit == null || t < tHit) tHit = t;
              }
            }
          }
        }

        if (tHit != null) {
          final impactPoint = posWorld + s * tHit;
          _stickToTarget(target, impactPoint);
          return;
        }
      }

      // No collision this frame: apply local position update
      position = nextPos;
    }
  }

  void throwKnife([Vector2? dir]) {
    if (isFlying || isStuck) return;
    if (dir != null) {
      direction = dir.normalized();
      // Set visual angle so the sprite faces the direction of travel.
      final worldAngle = math.atan2(direction.y, direction.x) + orientationOffset;
      angle = worldAngle; // while attached to root, worldAngle == local angle
      // DEBUG
      // ignore: avoid_print
      print('THROW: pos=${absoluteCenter.toString()}, dir=${direction.toString()}, worldAngle=$worldAngle, speed=$speed');
    }
    // Create a trail component attached to the same parent (game root)
    if (parent != null) {
      _trail = KnifeTrail(lifeSpan: 0.28, color: ui.Color(0xFFFFD166));
      parent!.add(_trail!);
      _trail!.addPoint(absoluteCenter);
    }
    isFlying = true;
  }

  /// Attach the knife to the [target] at the impact position/angle.
  void _stickToTarget(TargetComponent target, [Vector2? impactGlobal]) {
    // FINAL FIX: Instead of reparenting the existing knife (which causes
    // visual glitches due to Flame's lifecycle), we will create a new,
    // simple, static "StuckKnife" component at the correct final position
    // and rotation, and then remove the current flying knife. This completely
    // avoids all reparenting race conditions.

    // 1. Calculate final properties for the stuck knife.
    final Vector2 hit = impactGlobal ?? absoluteCenter;
    final Vector2 impactVec = (hit - target.absoluteCenter).normalized();
    final double impactAngle =
        math.atan2(hit.y - target.absoluteCenter.y, hit.x - target.absoluteCenter.x);
    final double worldAngle = impactAngle + math.pi / 2;

    final double radius = target.size.x / 2;
    final Vector2 desiredWorldCenter =
        target.absoluteCenter + impactVec * (radius - penetrationDepth);

    // Convert world coordinates to the target's local space.
    final Vector2 v = desiredWorldCenter - target.absoluteCenter;
    final double ca = math.cos(target.angle);
    final double sa = math.sin(target.angle);
    final Vector2 vLocal = Vector2(ca * v.x + sa * v.y, -sa * v.x + ca * v.y);
    final Vector2 localPos = target.size / 2 + vLocal;
    final double localAngle = worldAngle - target.angle + math.pi;

    // 2. Create and add the new StuckKnifeComponent to the target.
    final stuckKnife = StuckKnifeComponent()
      ..sprite = sprite
      ..size = size
      ..anchor = anchor
      ..position = localPos
      ..angle = localAngle
      ..priority = -1;
    target.add(stuckKnife);

    // 3. Shake the target and remove the original flying knife.
    target.shake();
    removeFromParent(); // The flying knife's life is over.
  }
}

/// A simple, static component representing a knife stuck in the target.
/// It has no update logic and is purely visual.
class StuckKnifeComponent extends SpriteComponent {}

/// Simple fading trail component. Stores recent positions (in parent
/// coordinates) and renders small circles that fade out over `lifeSpan`.
class KnifeTrail extends Component {
  KnifeTrail({this.lifeSpan = 0.28, required this.color});

  final double lifeSpan;
  final ui.Color color;

  final List<_TrailPoint> _points = [];

  void addPoint(Vector2 worldPos) {
    _points.add(_TrailPoint(worldPos.clone(), lifeSpan));
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final p in _points) {
      p.life -= dt;
    }
    _points.removeWhere((p) => p.life <= 0);
    if (_points.isEmpty) {
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final paint = ui.Paint()..style = ui.PaintingStyle.fill;
    for (final p in _points) {
      final t = (p.life / lifeSpan).clamp(0.0, 1.0);
      final alpha = (t * 255).toInt().clamp(0, 255);
      paint.color = ui.Color.fromARGB(alpha, color.red, color.green, color.blue);
      final radius = 6.0 * t + 1.0;
      final off = p.pos.toOffset();
      canvas.drawCircle(off, radius, paint);
    }
  }
}

class _TrailPoint {
  _TrailPoint(this.pos, this.life);
  Vector2 pos;
  double life;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Small transient marker to visualize hit points (in world coordinates).
class DebugDot extends PositionComponent {
  DebugDot(Vector2 worldPos, {this.lifeSpan = 2.0}) {
    position = worldPos;
    anchor = Anchor.center;
    size = Vector2.all(18);
  }

  double lifeSpan;
  double _life = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _life = lifeSpan;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final t = (_life / lifeSpan).clamp(0.0, 1.0);
    final paint = ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..color = ui.Color.fromARGB((t * 200).toInt().clamp(0, 200), 255, 0, 0);
    final r = size.x / 2 * (0.6 + 0.4 * t);
    canvas.drawCircle(ui.Offset(size.x / 2, size.y / 2), r, paint);
    final stroke = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..color = ui.Color.fromARGB((t * 255).toInt().clamp(0, 255), 255, 200, 0)
      ..strokeWidth = 2.0;
    canvas.drawCircle(ui.Offset(size.x / 2, size.y / 2), r + 2.0, stroke);
  }
}

/// Debug line: draws a fading line between two world coordinates.
class DebugLine extends Component {
  DebugLine(this.start, this.end, {this.lifeSpan = 2.0});

  final Vector2 start;
  final Vector2 end;
  double lifeSpan;
  double _life = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _life = lifeSpan;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final t = (_life / lifeSpan).clamp(0.0, 1.0);
    final paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = ui.Color.fromARGB((t * 200).toInt().clamp(0, 200), 255, 150, 0);
    canvas.drawLine(ui.Offset(start.x, start.y), ui.Offset(end.x, end.y), paint);
  }
}

/// Debug spawn circle: draws a fading ring at the specified center+radius.
class DebugSpawnCircle extends Component {
  DebugSpawnCircle(this.center, this.radius, {this.lifeSpan = 2.0});

  final Vector2 center;
  final double radius;
  double lifeSpan;
  double _life = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _life = lifeSpan;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final t = (_life / lifeSpan).clamp(0.0, 1.0);
    final paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = ui.Color.fromARGB((t * 200).toInt().clamp(0, 200), 100, 220, 255);
    canvas.drawCircle(ui.Offset(center.x, center.y), radius, paint);
  }
}
