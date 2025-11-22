import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/foundation.dart';
// No Flutter widgets are required directly here; Flame provides the game APIs.

import 'package:knife_hit/core/constants/asset_paths.dart';
import 'package:knife_hit/core/constants/game_constants.dart';
import 'package:knife_hit/data/models/game_progress.dart';
import 'package:knife_hit/data/models/level_state_snapshot.dart';
import 'package:knife_hit/game/boss_levels.dart';
import 'package:knife_hit/game/level_settings.dart';
import 'package:knife_hit/services/sound_manager.dart';

/// Main Flame game instance hosting the playfield and game state.
class KnifeHitGame extends FlameGame with HasCollisionDetection {
  /// The rotating target component (tree/log) positioned at the center.
  late TargetComponent target;

  /// Active knives that start on the playfield.
  final List<KnifeComponent> knives = [];

  /// Number of knives available at the start of a level.
  late int knivesRemaining;
  int _lastThrowAt = 0; // ms since epoch
  final math.Random _rng = math.Random();
  final ValueNotifier<int> appleCoins = ValueNotifier<int>(0);
  final ValueNotifier<int> knivesLeft = ValueNotifier<int>(0);
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<bool> isBossLevel = ValueNotifier<bool>(false);
  final ValueNotifier<Set<String>> unlockedKnifeSkins =
      ValueNotifier<Set<String>>({AssetPaths.knifeTanto});
  int _lastStickAt = 0; // ms
  int _comboCount = 0;
  int _initialKnifeCount = 0;
  int _successfulSticks = 0;
  int _appleCoinsAtLevelStart = 0;
  int _sessionKnivesThrown = 0;
  int _sessionSuccessfulHits = 0;
  int _sessionApplesHit = 0;
  int _sessionBossWins = 0;
  int _sessionHighestLevelReached = 1;
  int _sessionScoreEarned = 0;
  bool _levelCompleteTriggered = false;
  bool _levelFailedTriggered = false;
  int lastLevelScore = 0;
  final ValueNotifier<bool> levelCompleted = ValueNotifier<bool>(false);
  final ValueNotifier<bool> levelFailed = ValueNotifier<bool>(false);
  double _timeScale = 1.0;
  double _slowMoTimer = 0.0;
  int levelIndex = 1;
  late LevelSettings _currentLevelSettings;
  final BossProgressTracker bossProgress = BossProgressTracker();
  String _equippedKnifeSprite = AssetPaths.knifeTanto;
  String get equippedKnifeAsset => _equippedKnifeSprite;
  int get sessionKnivesThrown => _sessionKnivesThrown;
  int get sessionSuccessfulHits => _sessionSuccessfulHits;
  int get sessionApplesHit => _sessionApplesHit;
  int get sessionBossWins => _sessionBossWins;
  int get sessionHighestLevelReached => _sessionHighestLevelReached;
  int get sessionScoreEarned => _sessionScoreEarned;
  BossSpotlightOverlay? _bossOverlay;
  final GameProgress? _initialProgress;
  final LevelStateSnapshot? _initialLevelSnapshot;

  KnifeHitGame({GameProgress? initialProgress})
      : _initialProgress = initialProgress,
        _initialLevelSnapshot = initialProgress?.activeLevel,
        _currentLevelSettings = LevelSettings.forLevel(
          initialProgress?.activeLevel?.levelIndex ??
              initialProgress?.levelIndex ??
              1,
        ) {
    levelIndex = initialProgress?.activeLevel?.levelIndex ??
        initialProgress?.levelIndex ??
        1;
    _sessionHighestLevelReached = levelIndex;
    final int inferredInitialKnives =
      _initialLevelSnapshot?.initialKnifeCount ??
        _currentLevelSettings.knifeCount;
    _initialKnifeCount = inferredInitialKnives;
    final int inferredRemaining =
      _initialLevelSnapshot?.knivesRemaining ?? inferredInitialKnives;
    final int normalizedRemaining = inferredRemaining.clamp(0, inferredInitialKnives).toInt();
    knivesRemaining = normalizedRemaining;
    knivesLeft.value = knivesRemaining;
    levelCompleted.value = false;
    levelFailed.value = false;
    _appleCoinsAtLevelStart = appleCoins.value;
    if (initialProgress != null) {
      appleCoins.value = initialProgress.appleCoins;
      score.value = initialProgress.score;
      unlockedKnifeSkins.value = {
        ...initialProgress.unlockedKnifeAssets,
      };
      _equippedKnifeSprite = initialProgress.equippedKnifeAsset;
      bossProgress.applyDefeatedLevels(initialProgress.defeatedBossLevels);
      _appleCoinsAtLevelStart = appleCoins.value;
    }
  }

  @override
  ui.Color backgroundColor() => const ui.Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await SoundManager.instance.init();

    // Додаємо дерево по центру
    // Debug: print the asset key we are about to load for the target
    print('DEBUG: loading target asset key: "${AssetPaths.targetDefaultWood}"');
    // Make the target smaller so the wood image appears reduced on screen.
    const double targetDiameter = 280; // px
    final woodSprite = await loadSprite(AssetPaths.targetDefaultWood);
    target = TargetComponent(sprite: woodSprite)
      ..size = Vector2.all(targetDiameter)
      ..anchor = Anchor.center
      ..position = size / 2
      ..priority = 1;
    await add(target);
    await _initializeLevel(
      resetScore: _initialProgress == null,
      settingsOverride: _currentLevelSettings,
      levelSnapshot: _initialLevelSnapshot,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _bossOverlay?.updateSize(size);
  }

  /// Called by the containing widget when the user taps the play field.
  /// Throws the next available knife toward the target (straight-line).
  void onUserTap() {
    if (_levelCompleteTriggered || _levelFailedTriggered) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastThrowAt < GameConstants.knifeThrowCooldownMs) {
      return; // still in cooldown
    }

    // find next available knife
    KnifeComponent? next;
    int nextIndex = -1;
    for (int i = 0; i < knives.length; i++) {
      if (!knives[i].isFlying && !knives[i].isStuck) {
        next = knives[i];
        nextIndex = i;
        break;
      }
    }
    if (next == null) return;

    // Remove idle animation from thrown knife
    next.removeIdleAnimation();

    // Show and add idle animation to the next waiting knife
    if (nextIndex + 1 < knives.length) {
      final nextWaitingKnife = knives[nextIndex + 1];
      if (!nextWaitingKnife.isFlying && !nextWaitingKnife.isStuck) {
        nextWaitingKnife.opacity = 1.0; // Показуємо наступний ніж
        _addIdleKnifeAnimation(nextWaitingKnife, nextWaitingKnife.position.y);
      }
    }

    // compute direction: from knife to target center
    final targetComp = target;
    final dir = (targetComp.absoluteCenter - next.absoluteCenter).normalized();

    next.throwKnife(dir);
    unawaited(SoundManager.instance.play(SoundEffect.knifeThrow));
    _sessionKnivesThrown += 1;
    knivesRemaining = math.max(0, knivesRemaining - 1);
    knivesLeft.value = knivesRemaining;
    _lastThrowAt = now;
  }
  @override
  void update(double dt) {
    if (_slowMoTimer > 0) {
      _slowMoTimer -= dt;
      if (_slowMoTimer <= 0) {
        _timeScale = 1.0;
      }
    }
    final double scaledDt = dt * _timeScale;
    super.update(scaledDt);
    target.update(scaledDt);
  }

  void addAppleCoin() {
    appleCoins.value += 1;
    _sessionApplesHit += 1;
  }

  void triggerSlowMotion({double scale = 0.3, double duration = 0.5}) {
    _timeScale = scale;
    _slowMoTimer = duration;
  }

  /// Called when a knife successfully sticks into the target.
  /// If [hitApple] is true, an apple was hit as part of the same impact.
  void onKnifeStuck({required bool hitApple}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastStickAt <= 2000) {
      _comboCount += 1;
    } else {
      _comboCount = 1;
    }
    _lastStickAt = now;
    unawaited(SoundManager.instance.play(SoundEffect.knifeHit));

    double multiplier = _comboCount >= 3 ? 1.5 : 1.0;
    int base = 10;
    int bonusApple = hitApple ? 20 : 0;
    final int delta = ((base + bonusApple) * multiplier).round();
    score.value += delta;
    _sessionScoreEarned += delta;

    _successfulSticks += 1;
    _sessionSuccessfulHits += 1;
    
    // Add screen shake effect on successful hit
    _addScreenShake(intensity: hitApple ? 6.0 : 3.0);
    
    if (!_levelCompleteTriggered && _successfulSticks >= _initialKnifeCount) {
      _handleLevelComplete(boss: _currentLevelSettings.isBossLevel);
    }
  }
  
  /// Adds a camera shake effect to the entire game view
  void _addScreenShake({double intensity = 3.0}) {
    camera.viewport.add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(intensity, 0),
          EffectController(duration: 0.03),
        ),
        MoveEffect.by(
          Vector2(-intensity * 2, intensity),
          EffectController(duration: 0.03),
        ),
        MoveEffect.by(
          Vector2(intensity, -intensity * 2),
          EffectController(duration: 0.03),
        ),
        MoveEffect.by(
          Vector2(0, intensity),
          EffectController(duration: 0.03),
        ),
      ]),
    );
  }

  /// Award points for completing a level. If [boss] is true, award boss points.
  void awardLevelComplete({bool boss = false}) {
    final int award = boss ? 200 : 50;
    score.value += award;
    _sessionScoreEarned += award;
  }

  Future<void> startNextLevel({int? knifeCountOverride}) async {
    lastLevelScore = score.value;
    levelIndex += 1;
    await _initializeLevel(
      resetScore: true,
      knifeCountOverride: knifeCountOverride,
    );
    resumeEngine();
  }

  Future<void> jumpToBossLevel(int level) async {
    final BossLevelDefinition? bossDefinition =
        BossLevels.definitionForLevel(level);
    if (bossDefinition == null) {
      throw ArgumentError('Level $level does not map to a boss encounter');
    }
    await jumpToLevel(level);
  }

  Future<void> jumpToLevel(int level) async {
    final int targetLevel = level < 1 ? 1 : level;
    levelIndex = targetLevel;
    lastLevelScore = 0;
    await _initializeLevel(
      resetScore: true,
      settingsOverride: LevelSettings.forLevel(targetLevel),
    );
    resumeEngine();
  }

  Future<void> retryCurrentLevel() async {
    await _initializeLevel(
      resetScore: true,
      settingsOverride: _currentLevelSettings,
      levelSnapshot: null,
      restoreKnifeState: false,
    );
    resumeEngine();
  }

  Future<void> _initializeLevel({
    bool resetScore = false,
    LevelSettings? settingsOverride,
    int? knifeCountOverride,
    LevelStateSnapshot? levelSnapshot,
    bool restoreKnifeState = true,
  }) async {
    await SoundManager.instance.stopAll();
    _currentLevelSettings =
        settingsOverride ?? LevelSettings.forLevel(levelIndex);
    _sessionHighestLevelReached =
        math.max(_sessionHighestLevelReached, levelIndex);
    _appleCoinsAtLevelStart = appleCoins.value;
    isBossLevel.value = _currentLevelSettings.isBossLevel;
    _applyBossVisuals();
    final LevelStateSnapshot? snapshotForLevel = levelSnapshot;
    final int count = knifeCountOverride ??
      snapshotForLevel?.initialKnifeCount ??
      _currentLevelSettings.knifeCount;
    _initialKnifeCount = count;
    final int remaining = restoreKnifeState
      ? (snapshotForLevel?.knivesRemaining ?? count)
      : count;
    knivesRemaining = remaining.clamp(0, count).toInt();
    knivesLeft.value = knivesRemaining;
    _successfulSticks = 0;
    _comboCount = 0;
    _lastStickAt = 0;
    _levelCompleteTriggered = false;
    _levelFailedTriggered = false;
    levelCompleted.value = false;
    levelFailed.value = false;
    if (resetScore) {
      score.value = 0;
    }
    final Sprite targetSprite =
      await loadSprite(_currentLevelSettings.targetSpriteAsset);
    target.setSprite(targetSprite);
    await target.resetForLevel(
      random: _rng,
      settings: _currentLevelSettings,
      snapshot: snapshotForLevel?.targetState,
    );
    _successfulSticks =
      (count - knivesRemaining).clamp(0, count).toInt();
    await _respawnPlayerKnives(count);
    _markUsedKnives(count - knivesRemaining);

    if (snapshotForLevel != null && kDebugMode) {
      debugPrint('[LevelInit] adopted snapshot knives=${snapshotForLevel.targetState.stuckKnives.length} apples=${snapshotForLevel.targetState.appleSnapshots.length}');
    }
  }

  Future<void> _respawnPlayerKnives(int count) async {
    for (final knife in knives) {
      knife.removeFromParent();
    }
    knives.clear();

    const double knifeBaselineOffset = 110;
    final Sprite knifeSprite = await loadSprite(_equippedKnifeSprite);
    for (int i = 0; i < count; i++) {
      final baseY = size.y - knifeBaselineOffset;
      final knife = KnifeComponent()
        ..sprite = knifeSprite
        ..assetKey = _equippedKnifeSprite
        ..size = Vector2(40, 120)
        ..anchor = Anchor.center
        ..position = Vector2(size.x / 2, baseY);
      knives.add(knife);
      await add(knife);
      
      // Тільки перший ніж видимий і анімується
      if (i == 0) {
        _addIdleKnifeAnimation(knife, baseY);
        knife.opacity = 1.0;
      } else {
        knife.opacity = 0.0; // Приховуємо всі інші ножі
      }
    }
  }
  
  /// Adds a gentle up-down floating animation to the waiting knife
  void _addIdleKnifeAnimation(KnifeComponent knife, double baseY) {
    const floatDistance = 8.0; // pixels to float up/down
    const floatDuration = 0.8; // seconds for one cycle
    
    final effect = MoveEffect.by(
      Vector2(0, -floatDistance),
      EffectController(
        duration: floatDuration,
        curve: Curves.easeInOut,
        infinite: true,
        alternate: true,
      ),
    );
    
    knife.add(effect);
    knife.setIdleEffect(effect);
  }

  void _markUsedKnives(int usedCount) {
    if (usedCount <= 0) {
      return;
    }
    for (int i = 0; i < usedCount && i < knives.length; i++) {
      final knife = knives[i];
      knife.isFlying = true;
      knife.isStuck = true;
      knife.removeFromParent();
    }
  }

  void _handleLevelComplete({bool boss = false}) {
    if (_levelCompleteTriggered || _levelFailedTriggered) {
      return;
    }
    _levelCompleteTriggered = true;
    unawaited(() async {
      await SoundManager.instance.stopAll();
      await SoundManager.instance
          .play(boss ? SoundEffect.bossDefeat : SoundEffect.levelComplete);
    }());
    awardLevelComplete(boss: boss);
    lastLevelScore = score.value;
    levelCompleted.value = true;
    if (boss) {
      _sessionBossWins += 1;
      final BossLevelDefinition? definition =
          _currentLevelSettings.bossDefinition;
      if (definition != null) {
        appleCoins.value += definition.appleCoinReward;
        bossProgress.markBossDefeated(levelIndex);
        if (!unlockedKnifeSkins.value.contains(definition.rewardKnifeAsset)) {
          unlockedKnifeSkins.value = {
            ...unlockedKnifeSkins.value,
            definition.rewardKnifeAsset,
          };
        }
      }
    }
    pauseEngine();
  }

  void handlePlayerFailure() {
    _handleLevelFailed();
  }

  /// Debug helper: instantly trigger level completion.
  void debugForceWin() {
    if (kDebugMode) {
      _handleLevelComplete(boss: _currentLevelSettings.isBossLevel);
    }
  }

  void _handleLevelFailed() {
    if (_levelFailedTriggered || _levelCompleteTriggered) {
      return;
    }
    _levelFailedTriggered = true;
    unawaited(() async {
      await SoundManager.instance.stopAll();
      await SoundManager.instance.play(SoundEffect.gameOver);
    }());
    appleCoins.value = _appleCoinsAtLevelStart;
    levelFailed.value = true;
    pauseEngine();
  }

  void equipKnifeSkin(String assetKey) {
    if (!unlockedKnifeSkins.value.contains(assetKey)) {
      throw ArgumentError('Attempted to equip locked knife skin: $assetKey');
    }
    _equippedKnifeSprite = assetKey;
  }

  int get initialKnifeCount => _initialKnifeCount;

    BossLevelDefinition? get currentBossDefinition =>
      _currentLevelSettings.bossDefinition;

    String? get currentBossRewardAsset =>
      _currentLevelSettings.bossDefinition?.rewardKnifeAsset;

  LevelStateSnapshot? _captureLevelSnapshot() {
    if (_levelCompleteTriggered || _levelFailedTriggered) {
      return null;
    }
    if (!target.isLoaded) {
      return null;
    }
    final LevelStateSnapshot snapshot = LevelStateSnapshot(
      levelIndex: levelIndex,
      knivesRemaining: knivesRemaining,
      initialKnifeCount: _initialKnifeCount,
      targetState: target.snapshotState(),
    );
    if (kDebugMode) {
      debugPrint('[LevelCapture] knives=${snapshot.targetState.stuckKnives.length} apples=${snapshot.targetState.appleSnapshots.length} remaining=$knivesRemaining');
    }
    return snapshot;
  }

  GameProgress snapshotProgress() {
    final LevelStateSnapshot? levelState = _captureLevelSnapshot();
    return GameProgress(
      levelIndex: levelIndex,
      score: score.value,
      appleCoins: appleCoins.value,
      equippedKnifeAsset: _equippedKnifeSprite,
      unlockedKnifeAssets: Set.unmodifiable(unlockedKnifeSkins.value),
      defeatedBossLevels: Set.unmodifiable(bossProgress.defeatedLevelIds()),
      activeLevel: levelState,
    );
  }

  void _applyBossVisuals() {
    final bool bossActive = _currentLevelSettings.isBossLevel;
    if (bossActive) {
      final overlay = _bossOverlay ?? BossSpotlightOverlay();
      overlay.priority = 50;
      overlay.updateSize(size);
      if (!overlay.isMounted) {
        add(overlay);
      }
      _bossOverlay = overlay;
    } else {
      _bossOverlay?.removeFromParent();
      _bossOverlay = null;
    }
  }
}

class TargetComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<KnifeHitGame> {
  TargetComponent({required Sprite sprite}) : _woodSprite = sprite;

  static const double _arcPadding = 0.08; // small global buffer between arcs
  static const double _appleArcInflation = 0.12; // widen apple reservation footprint
  static const double _knifeArcInflation = 0.08; // widen knife reservation footprint

  Sprite _woodSprite;
  late final SpriteComponent _woodLayer;
  late final CircleHitbox _hitbox;
  math.Random? _randomSource;
  double _rotationSpeed = 60 * math.pi / 180;
  double? _directionChangeIntervalMin;
  double? _directionChangeIntervalMax;
  double _timeUntilDirectionFlip = double.infinity;
  BossRotationPattern? _bossRotationPattern;
  double _bossCurrentSpeed = 0;
  double _bossTargetSpeed = 0;
  double _bossSpeedTimer = 0;
  List<AppleSnapshot>? _pendingAppleSnapshots;
  bool _awaitingAppleMount = false;
  List<StuckKnifeSnapshot>? _pendingStuckSnapshots;
  bool _awaitingStuckMount = false;

  void _logSpawn(String message) {
    if (kDebugMode) {
      debugPrint('[TargetSpawn] $message');
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _woodLayer = SpriteComponent(sprite: _woodSprite)
      ..size = size.clone()
      ..anchor = Anchor.center
      ..position = size / 2
      ..priority = 1;
    add(_woodLayer);

    _hitbox = CircleHitbox(
      radius: size.x / 2,
      anchor: Anchor.center,
    )
      ..position = size / 2;
    add(_hitbox);
  }

  void _applyLayout() {
    if (!isLoaded) return;
    _woodLayer
      ..size = size.clone()
      ..position = size / 2;
    _hitbox
      ..radius = size.x / 2
      ..position = size / 2;
  }

  void setSprite(Sprite sprite) {
    _woodSprite = sprite;
    if (_woodLayer.isMounted) {
      _woodLayer.sprite = sprite;
    }
  }

  Future<void> _seedApples({
    required math.Random random,
    required int count,
    required List<_AngleReservation> reservedAngles,
  }) async {
    _logSpawn('seedApples count=$count (boss=${gameRef._currentLevelSettings.isBossLevel})');
    if (count <= 0) {
      _pendingAppleSnapshots = null;
      _awaitingAppleMount = false;
      return;
    }

    const double topAngle = -math.pi / 2;
    const double halfSpread = math.pi / 12;
    final double appleHalfWidth =
        _computeArcHalfWidth(AppleComponent._appleDiameter) +
            _appleArcInflation;
    final List<AppleSnapshot> seeded = [];

    for (int i = 0; i < count; i++) {
      double angle = _normalizeAngle(
        topAngle + (random.nextDouble() - 0.5) * (halfSpread * 2),
      );
      int guard = 0;
      while (_isAngleReserved(angle, appleHalfWidth, reservedAngles) &&
          guard < 12) {
        angle = _normalizeAngle(
          topAngle + (random.nextDouble() - 0.5) * (halfSpread * 2),
        );
        guard += 1;
      }
      if (_isAngleReserved(angle, appleHalfWidth, reservedAngles)) {
        continue;
      }
      reservedAngles.add(_AngleReservation(angle, appleHalfWidth));
      await add(AppleComponent(
        angleRadians: angle,
        margin: -0.1,
      ));
      _logSpawn('  apple index=$i angle=${angle.toStringAsFixed(3)} guard=$guard');
      seeded.add(AppleSnapshot(angle: angle, margin: -0.1));
    }
    if (seeded.isNotEmpty) {
      _pendingAppleSnapshots = List<AppleSnapshot>.from(seeded);
      _awaitingAppleMount = true;
    } else {
      _pendingAppleSnapshots = null;
      _awaitingAppleMount = false;
    }
    final totalApples = children.whereType<AppleComponent>().length;
    _logSpawn('seedApples total components=$totalApples');
  }

  Future<void> resetForLevel({
    required math.Random random,
    required LevelSettings settings,
    TargetStateSnapshot? snapshot,
  }) async {
    _logSpawn('resetForLevel level=${gameRef.levelIndex} boss=${settings.isBossLevel} snapshot=${snapshot != null}');
    _randomSource = random;
    for (final apple in children.whereType<AppleComponent>().toList()) {
      apple.removeFromParent();
    }
    _pendingAppleSnapshots = null;
    _awaitingAppleMount = false;
    final stuckBeforeClear =
        children.whereType<StuckKnifeComponent>().length;
    _logSpawn('resetForLevel clearing stuck knives count=$stuckBeforeClear');
    _pendingStuckSnapshots = null;
    _awaitingStuckMount = false;
    for (final stuck in children.whereType<StuckKnifeComponent>().toList()) {
      stuck.removeFromParent();
    }
    await Future<void>.delayed(Duration.zero);
    final stuckAfterClear =
        children.whereType<StuckKnifeComponent>().length;
    _logSpawn('resetForLevel cleared stuck knives remaining=$stuckAfterClear');
    final bool restoring = snapshot != null;
    if (!restoring && !settings.isBossLevel) {
      final List<_AngleReservation> reservedAngles = [];
      final int applesToSpawn = settings.randomAppleCount(random);
      await _seedApples(
        random: random,
        count: applesToSpawn,
        reservedAngles: reservedAngles,
      );
      await _seedInitialStuckKnives(
        random: random,
        reservedAngles: reservedAngles,
      );
    }
    _applyLevelSettings(settings, random);
    if (snapshot != null) {
      await _applySnapshot(snapshot);
    }
  }

  TargetStateSnapshot snapshotState() {
    _logSpawn('snapshotState start');
    final Iterable<AppleComponent> appleComponents =
        children.whereType<AppleComponent>();
    late final List<AppleSnapshot> appleStates;
    if (appleComponents.isEmpty) {
      if (_awaitingAppleMount && _pendingAppleSnapshots != null) {
        appleStates = List<AppleSnapshot>.from(_pendingAppleSnapshots!);
        _logSpawn('  apples pending fallback count=${appleStates.length}');
      } else {
        appleStates = <AppleSnapshot>[];
      }
    } else {
      appleStates = [
        for (final apple in appleComponents)
          AppleSnapshot(angle: apple.angleRadians, margin: apple.margin),
      ];
      _logSpawn('  apples from components count=${appleStates.length}');
      _awaitingAppleMount = false;
      _pendingAppleSnapshots = null;
    }
    final Iterable<StuckKnifeComponent> stuckComponents =
        children.whereType<StuckKnifeComponent>();
    List<StuckKnifeSnapshot> stuckStates;
    final bool hasPending = _pendingStuckSnapshots != null;
    if (_awaitingStuckMount && hasPending) {
      stuckStates = List<StuckKnifeSnapshot>.from(_pendingStuckSnapshots!);
      _logSpawn(
        '  stuck pending fallback count=${stuckStates.length} actual=${stuckComponents.length}',
      );
      _awaitingStuckMount = false;
      _pendingStuckSnapshots = null;
    } else {
      stuckStates = [
        for (final stuck in stuckComponents)
          StuckKnifeSnapshot(
            assetKey: stuck.assetKey,
            localX: stuck.position.x,
            localY: stuck.position.y,
            angle: stuck.angle,
          ),
      ];
      _logSpawn('  stuck from components count=${stuckStates.length}');
    }
    final double? directionTimer =
        _timeUntilDirectionFlip.isFinite ? _timeUntilDirectionFlip : null;
    _logSpawn('snapshotState done apples=${appleStates.length} stuck=${stuckStates.length}');
    return TargetStateSnapshot(
      angle: angle,
      clockwise: clockwise,
      rotationSpeed: _rotationSpeed,
      timeUntilDirectionFlip: directionTimer,
      appleSnapshots: appleStates,
      stuckKnives: stuckStates,
      bossCurrentSpeed: _bossRotationPattern != null ? _bossCurrentSpeed : null,
      bossTargetSpeed: _bossRotationPattern != null ? _bossTargetSpeed : null,
      bossSpeedTimer: _bossRotationPattern != null ? _bossSpeedTimer : null,
    );
  }

  Future<void> _applySnapshot(TargetStateSnapshot snapshot) async {
    _logSpawn('applySnapshot apples=${snapshot.appleSnapshots.length} stuck=${snapshot.stuckKnives.length}');
    angle = snapshot.angle;
    clockwise = snapshot.clockwise;
    _rotationSpeed = snapshot.rotationSpeed;
    _timeUntilDirectionFlip =
        snapshot.timeUntilDirectionFlip ?? double.infinity;
    if (snapshot.bossCurrentSpeed != null) {
      _bossCurrentSpeed = snapshot.bossCurrentSpeed!;
    }
    if (snapshot.bossTargetSpeed != null) {
      _bossTargetSpeed = snapshot.bossTargetSpeed!;
    }
    if (snapshot.bossSpeedTimer != null) {
      _bossSpeedTimer = snapshot.bossSpeedTimer!;
    }

    final Map<String, Sprite> spriteCache = {};
    if (!gameRef._currentLevelSettings.isBossLevel) {
      if (snapshot.appleSnapshots.isNotEmpty) {
        _pendingAppleSnapshots = List<AppleSnapshot>.from(snapshot.appleSnapshots);
        _awaitingAppleMount = true;
      } else {
        _pendingAppleSnapshots = null;
        _awaitingAppleMount = false;
      }
      if (snapshot.stuckKnives.isNotEmpty) {
        _pendingStuckSnapshots = List<StuckKnifeSnapshot>.from(snapshot.stuckKnives);
        _awaitingStuckMount = true;
      } else {
        _pendingStuckSnapshots = null;
        _awaitingStuckMount = false;
      }
      for (final AppleSnapshot apple in snapshot.appleSnapshots) {
        await add(AppleComponent(
          angleRadians: apple.angle,
          margin: apple.margin,
        ));
        _logSpawn('  restored apple angle=${apple.angle.toStringAsFixed(3)}');
      }

      for (final StuckKnifeSnapshot stuck in snapshot.stuckKnives) {
        if (stuck.assetKey.isEmpty) {
          continue;
        }
        if (!spriteCache.containsKey(stuck.assetKey)) {
          spriteCache[stuck.assetKey] =
              await gameRef.loadSprite(stuck.assetKey);
        }
        final Sprite? sprite = spriteCache[stuck.assetKey];
        if (sprite == null) {
          continue;
        }
        final stuckComponent = StuckKnifeComponent(assetKey: stuck.assetKey)
          ..sprite = sprite
          ..size = Vector2(40, 120)
          ..anchor = Anchor.center
          ..position = Vector2(stuck.localX, stuck.localY)
          ..angle = stuck.angle
          ..priority = 0;
        await add(stuckComponent);
        _logSpawn('  restored stuck asset=${stuck.assetKey} pos=(${stuck.localX.toStringAsFixed(1)}, ${stuck.localY.toStringAsFixed(1)}) angle=${stuck.angle.toStringAsFixed(3)}');
      }
      _logSpawn('applySnapshot restored apples=${snapshot.appleSnapshots.length} stuck=${snapshot.stuckKnives.length}');
    }

    _applyLayout();
  }

  Future<void> _seedInitialStuckKnives({
    required math.Random random,
    required List<_AngleReservation> reservedAngles,
  }) async {
    _logSpawn('seedInitialStuckKnives start');
    final int count = 1 + random.nextInt(2);
    final String assetKey = gameRef.equippedKnifeAsset;
    final Sprite knifeSprite = await gameRef.loadSprite(assetKey);
    final double radius = size.x / 2;
    const double penetration = 1;
    const double knifeVisualWidth = 40;
    final double knifeHalfWidth =
        _computeArcHalfWidth(knifeVisualWidth) + _knifeArcInflation;
    final List<StuckKnifeSnapshot> seeded = [];

    for (int i = 0; i < count; i++) {
      double angle = _normalizeAngle(random.nextDouble() * math.pi * 2);
      int guard = 0;
      while (_isAngleReserved(angle, knifeHalfWidth, reservedAngles) &&
          guard < 16) {
        angle = _normalizeAngle(random.nextDouble() * math.pi * 2);
        guard += 1;
      }
      if (_isAngleReserved(angle, knifeHalfWidth, reservedAngles)) {
        continue;
      }
      reservedAngles.add(_AngleReservation(angle, knifeHalfWidth));

      final Vector2 offset =
          Vector2(math.cos(angle), math.sin(angle)) * (radius - penetration);
      final Vector2 localPosition = size / 2 + offset;
      final double localAngle = angle + math.pi / 2 + math.pi;
      final stuck = StuckKnifeComponent(assetKey: assetKey)
        ..sprite = knifeSprite
        ..size = Vector2(40, 120)
        ..anchor = Anchor.center
        ..position = localPosition
        ..angle = localAngle
        ..priority = 0;
      await add(stuck);
      _logSpawn('  stuck seed index=$i pos=(${localPosition.x.toStringAsFixed(1)}, ${localPosition.y.toStringAsFixed(1)}) angle=${localAngle.toStringAsFixed(3)} guard=$guard');
      seeded.add(
        StuckKnifeSnapshot(
          assetKey: assetKey,
          localX: localPosition.x,
          localY: localPosition.y,
          angle: localAngle,
        ),
      );
    }
    if (seeded.isNotEmpty) {
      _pendingStuckSnapshots = List<StuckKnifeSnapshot>.from(seeded);
      _awaitingStuckMount = true;
      _logSpawn('seedInitialStuckKnives pending cached=${seeded.length}');
    } else {
      _pendingStuckSnapshots = null;
      _awaitingStuckMount = false;
      _logSpawn('seedInitialStuckKnives produced none');
    }
    final totalAfterSeed =
        children.whereType<StuckKnifeComponent>().length;
    _logSpawn('seedInitialStuckKnives total children count=$totalAfterSeed');
  }

  void _applyLevelSettings(LevelSettings settings, math.Random random) {
    final double speedDeg = settings.randomRotationSpeed(random);
    _rotationSpeed = speedDeg * math.pi / 180;
    _bossRotationPattern = settings.bossDefinition?.rotationPattern;
    if (_bossRotationPattern != null) {
      final BossRotationPattern pattern = _bossRotationPattern!;
      final double initialSpeedDeg = pattern.randomSpeed(random);
      _bossCurrentSpeed = initialSpeedDeg * math.pi / 180;
      _bossTargetSpeed = _bossCurrentSpeed;
      _bossSpeedTimer = pattern.randomHoldDuration(random);
      _rotationSpeed = _bossCurrentSpeed.abs();
    }
    if (settings.hasDirectionChanges) {
      _directionChangeIntervalMin = settings.directionChangeIntervalMinSec;
      _directionChangeIntervalMax = settings.directionChangeIntervalMaxSec;
      clockwise = random.nextBool();
      _scheduleNextDirectionFlip();
    } else {
      _directionChangeIntervalMin = null;
      _directionChangeIntervalMax = null;
      _timeUntilDirectionFlip = double.infinity;
      clockwise = true;
    }
  }

  void _scheduleNextDirectionFlip() {
    if (_directionChangeIntervalMin == null ||
        _directionChangeIntervalMax == null) {
      _timeUntilDirectionFlip = double.infinity;
      return;
    }
    final double min = _directionChangeIntervalMin!;
    final double max = _directionChangeIntervalMax!;
    if ((max - min).abs() < 1e-6) {
      _timeUntilDirectionFlip = min;
      return;
    }
    final math.Random? random = _randomSource;
    if (random == null) {
      _timeUntilDirectionFlip = max;
      return;
    }
    _timeUntilDirectionFlip = min + random.nextDouble() * (max - min);
  }

  void _tickDirectionChange(double dt) {
    if (_directionChangeIntervalMin == null ||
        _directionChangeIntervalMax == null) {
      return;
    }
    _timeUntilDirectionFlip -= dt;
    if (_timeUntilDirectionFlip <= 0) {
      clockwise = !clockwise;
      _scheduleNextDirectionFlip();
    }
  }

  AppleComponent? trySliceApple(Vector2 worldPoint) {
    final targetCenter = absoluteCenter;
    final impactVector = worldPoint - targetCenter;
    if (impactVector.length2 < 1e-6) {
      return null;
    }
    final impactDir = impactVector.normalized();
    // Compare the knife impact direction and distance against each apple's
    // current offset from the target so we can tolerate slight rim errors.
    for (final apple in children.whereType<AppleComponent>()) {
      if (!apple.isSliceable) {
        continue;
      }
      final appleOffset = apple.absoluteCenter - targetCenter;
      if (appleOffset.length2 < 1e-6) {
        continue;
      }
      final appleDir = appleOffset.normalized();
      final double angleDiff = math.acos(
        appleDir.dot(impactDir).clamp(-1.0, 1.0),
      );
      const double angleTolerance = 0.35; // ~20 degrees
      if (angleDiff > angleTolerance) {
        continue;
      }
      final double radialDiff = (appleOffset.length - impactVector.length).abs();
      final double radialTolerance = apple.margin + apple.size.x * 0.4;
      if (radialDiff > radialTolerance) {
        continue;
      }
      apple.slice();
      return apple;
    }
    return null;
  }

  bool _isAngleReserved(
    double angle,
    double halfWidth,
    List<_AngleReservation> reservations,
  ) {
    final double normalized = _normalizeAngle(angle);
    for (final reservation in reservations) {
      final double combinedHalfWidth =
          reservation.halfWidth + halfWidth + _arcPadding;
      if (_angularDistance(reservation.angle, normalized) < combinedHalfWidth) {
        return true;
      }
    }
    return false;
  }

  double _angularDistance(double a, double b) {
    final double diff = (_normalizeAngle(a) - _normalizeAngle(b)).abs();
    return diff > math.pi ? (2 * math.pi) - diff : diff;
  }

  double _computeArcHalfWidth(double itemWidth) {
    final double radius = size.x / 2;
    if (radius <= 0) {
      return 0;
    }
    return math.atan((itemWidth / 2) / radius);
  }

  double _normalizeAngle(double angle) {
    final double twoPi = 2 * math.pi;
    double normalized = angle % twoPi;
    if (normalized < 0) {
      normalized += twoPi;
    }
    return normalized;
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    _applyLayout();
  }

  bool clockwise = true;

  @override
  void update(double dt) {
    super.update(dt);
    _applyLayout();
    _tickBossRotation(dt);
    angle += (clockwise ? _rotationSpeed : -_rotationSpeed) * dt;
    _tickDirectionChange(dt);
  }

  void shake() {
    // Enhanced shake with rotation wobble
    add(
      SequenceEffect([
        ScaleEffect.to(Vector2.all(0.96), EffectController(duration: 0.04)),
        ScaleEffect.to(Vector2.all(1.02), EffectController(duration: 0.04)),
        ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.04)),
      ]),
    );
    
    // Add white flash overlay effect
    _addWhiteFlash();
    
    // Spawn impact particles
    _spawnImpactParticles();
  }
  
  /// Creates a white flash overlay that fades quickly
  void _addWhiteFlash() {
    final flashPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    final flashOverlay = CircleComponent(
      radius: size.x / 2,
      paint: flashPaint,
      anchor: Anchor.center,
      position: size / 2,
      priority: 10,
    );
    
    flashOverlay.add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.15, curve: Curves.easeOut),
        onComplete: () => flashOverlay.removeFromParent(),
      ),
    );
    
    add(flashOverlay);
  }
  
  /// Spawns particle effects around the impact point
  void _spawnImpactParticles() {
    final random = math.Random();
    final particleCount = 8;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final velocity = Vector2(
        math.cos(angle) * (50 + random.nextDouble() * 30),
        math.sin(angle) * (50 + random.nextDouble() * 30),
      );
      
      final particlePaint = ui.Paint()..color = ui.Color.lerp(
        const ui.Color(0xFFFFD700),
        const ui.Color(0xFFFFFFFF),
        random.nextDouble(),
      )!;
      
      final particle = ParticleSystemComponent(
        particle: AcceleratedParticle(
          lifespan: 0.3 + random.nextDouble() * 0.2,
          speed: velocity,
          acceleration: velocity * -2, // decelerate
          child: CircleParticle(
            radius: 2 + random.nextDouble() * 2,
            paint: particlePaint,
          ),
        ),
        position: size / 2,
        priority: 5,
      );
      
      add(particle);
    }
  }

  void _tickBossRotation(double dt) {
    final BossRotationPattern? pattern = _bossRotationPattern;
    if (pattern == null) {
      return;
    }
    final math.Random random = _randomSource ?? math.Random();
    _bossSpeedTimer -= dt;
    if (_bossSpeedTimer <= 0) {
      final double nextSpeedDeg = pattern.randomSpeed(random);
      _bossTargetSpeed = nextSpeedDeg * math.pi / 180;
      _bossSpeedTimer = pattern.randomHoldDuration(random);
      if (random.nextDouble() < pattern.directionFlipProbability) {
        clockwise = !clockwise;
      }
    }
    final double accelerationRadPerSec2 =
        pattern.accelerationDegPerSec2 * math.pi / 180;
    final double delta = _bossTargetSpeed - _bossCurrentSpeed;
    if (accelerationRadPerSec2 <= 0 || delta.abs() <= 1e-6) {
      _bossCurrentSpeed = _bossTargetSpeed;
      _rotationSpeed = _bossCurrentSpeed.abs();
      return;
    }
    final double maxStep = accelerationRadPerSec2 * dt;
    if (delta.abs() <= maxStep) {
      _bossCurrentSpeed = _bossTargetSpeed;
    } else {
      _bossCurrentSpeed += maxStep * delta.sign;
    }
    _rotationSpeed = _bossCurrentSpeed.abs();
  }
}

class BossSpotlightOverlay extends PositionComponent {
  BossSpotlightOverlay() {
    anchor = Anchor.topLeft;
  }

  void updateSize(Vector2 canvasSize) {
    size = canvasSize.clone();
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    final ui.Offset center = ui.Offset(size.x / 2, size.y / 2);
    final double radius = math.max(size.x, size.y) * 0.7;
    final ui.Paint paint = ui.Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        const [
          ui.Color.fromRGBO(0, 0, 0, 0.1),
          ui.Color.fromRGBO(0, 0, 0, 0.85),
        ],
        const [0.0, 1.0],
      );
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

class _AngleReservation {
  const _AngleReservation(this.angle, this.halfWidth);

  final double angle;
  final double halfWidth;
}

class KnifeComponent extends SpriteComponent
  with HasGameRef<KnifeHitGame>, CollisionCallbacks {
  /// Asset key used for this knife's sprite, persisted for stuck snapshots.
  String assetKey = AssetPaths.knifeTanto;

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
  bool _collisionHandled = false;
  
  // --- Idle animation support ------------------------------------------------
  Effect? _idleEffect;
  
  /// Removes the idle floating animation if present
  void removeIdleAnimation() {
    if (_idleEffect != null) {
      _idleEffect!.removeFromParent();
      _idleEffect = null;
    }
  }
  
  /// Sets the idle animation effect
  void setIdleEffect(Effect effect) {
    removeIdleAnimation();
    _idleEffect = effect;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collisionHandled) {
      return;
    }
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
        final stuckCollision =
            _detectStuckKnifeCollision(target, posWorld, nextWorld);
        if (stuckCollision != null) {
          _handleKnifeCollision(stuckCollision);
          return;
        }
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
          final apple = target.trySliceApple(impactPoint);
          _stickToTarget(target, impactPoint, hitApple: apple != null);
          return;
        }
      }

      // No collision this frame: apply local position update
      position = nextPos;
    }
  }

  Vector2? _detectStuckKnifeCollision(
    TargetComponent target,
    Vector2 start,
    Vector2 end,
  ) {
    final segment = end - start;
    final double segmentLength2 = segment.length2;
    if (segmentLength2 <= 1e-6) {
      return null;
    }
    for (final stuck in target.children.whereType<StuckKnifeComponent>()) {
      final center = stuck.absoluteCenter;
      final double t = ((center - start).dot(segment) / segmentLength2)
          .clamp(0.0, 1.0);
      final Vector2 closest = start + segment * t;
      final double collisionRadius =
          math.max(stuck.size.x, stuck.size.y) * 0.25;
      if (center.distanceTo(closest) <= collisionRadius) {
        return closest;
      }
    }
    return null;
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
  void _stickToTarget(TargetComponent target, Vector2? impactGlobal, {bool hitApple = false}) {
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
    final stuckKnife = StuckKnifeComponent(assetKey: assetKey)
      ..sprite = sprite
      ..size = size
      ..anchor = anchor
      ..position = localPos
      ..angle = localAngle
      ..priority = 0;
    target.add(stuckKnife);

    // 3. Shake the target and remove the original flying knife.
    target.shake();
    // Award base + apple bonus via the game's scoring logic.
    gameRef.onKnifeStuck(hitApple: hitApple);
    removeFromParent(); // The flying knife's life is over.
  }

  void _handleKnifeCollision(Vector2 collisionPoint) {
    if (_collisionHandled) {
      return;
    }
    _collisionHandled = true;
    isFlying = false;
    _trail?.removeFromParent();
    _trail = null;
    final Vector2 retreatDir =
        direction.length2 < 1e-6 ? Vector2(0, -1) : -direction.normalized();
    direction = Vector2.zero();
    gameRef.triggerSlowMotion(scale: 0.3, duration: 0.5);
    unawaited(SoundManager.instance.play(SoundEffect.knifeMiss));
    // Collision with an already-stuck knife is not a successful stick,
    // so reset combo tracking to avoid rewarding a follow-up combo.
    gameRef._comboCount = 0;

    // Enhanced bounce animation with parabolic trajectory and rotation
    final random = math.Random();
    final horizontalBounce = (random.nextDouble() - 0.5) * 150; // Random left/right
    final initialRetreat = retreatDir * 80;
    
    // Add spinning rotation effect
    add(
      RotateEffect.by(
        math.pi * 4 * (random.nextBool() ? 1 : -1), // 4 full rotations, random direction
        EffectController(duration: 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Parabolic bounce trajectory
    add(
      SequenceEffect([
        // Initial retreat (fast)
        MoveEffect.by(
          initialRetreat,
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        // Arc to the side with parabolic curve
        MoveEffect.by(
          Vector2(horizontalBounce, -40),
          EffectController(duration: 0.25, curve: Curves.easeOutCubic),
        ),
        // Fall down with gravity effect (parabolic)
        MoveEffect.by(
          Vector2(horizontalBounce * 0.3, 900),
          EffectController(duration: 0.5, curve: Curves.easeIn),
        ),
      ]),
    );
    
    // Fade out during fall
    add(
      OpacityEffect.fadeOut(
        EffectController(
          duration: 0.6,
          startDelay: 0.2,
          curve: Curves.easeIn,
        ),
      ),
    );
    
    unawaited(Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!isMounted) {
        return;
      }
      removeFromParent();
    }));
    unawaited(Future<void>.delayed(const Duration(milliseconds: 420), () {
      gameRef.handlePlayerFailure();
    }));
  }

}

/// A simple, static component representing a knife stuck in the target.
/// It has no update logic and is purely visual.
class StuckKnifeComponent extends SpriteComponent {
  StuckKnifeComponent({required this.assetKey});

  final String assetKey;
}

// ignore: deprecated_member_use, awaiting game-wide migration to HasGameReference
class AppleComponent extends PositionComponent with HasGameRef<KnifeHitGame> {
  AppleComponent({
    required this.angleRadians,
    this.margin = 28,
  })  : _random = math.Random(),
        super(
          size: Vector2.all(_appleDiameter),
          anchor: Anchor.center,
          priority: 2,
        );

  static const double _appleDiameter = 50;
  final double angleRadians;
  final double margin;
  final math.Random _random;
  bool _isSliced = false;

  late final Sprite _wholeSprite;
  late final Sprite _cutLeftSprite;
  late final Sprite _cutRightSprite;
  late final SpriteComponent _wholeSpriteComponent;

  bool get isSliceable => !_isSliced;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _wholeSprite = await gameRef.loadSprite(AssetPaths.appleWhole);
    _cutLeftSprite = await gameRef.loadSprite(AssetPaths.appleCutLeft);
    _cutRightSprite = await gameRef.loadSprite(AssetPaths.appleCutRight);
    _wholeSpriteComponent = SpriteComponent(
      sprite: _wholeSprite,
      size: size.clone(),
      anchor: Anchor.center,
    );
    add(_wholeSpriteComponent);
    _syncTransform();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isSliced) {
      _syncTransform();
    }
  }

  void _syncTransform() {
    final parentTarget = parent;
    if (parentTarget is TargetComponent) {
      final radius = parentTarget.size.x / 2 - margin;
      final offset =
          Vector2(math.cos(angleRadians), math.sin(angleRadians)) * radius;
      position = parentTarget.size / 2 + offset;
      angle = angleRadians + math.pi / 2;
    }
  }

  void slice() {
    if (_isSliced) return;
    _isSliced = true;
    _wholeSpriteComponent.opacity = 0;
    _spawnSlices();
    _spawnJuice();
    unawaited(SoundManager.instance.play(SoundEffect.appleHit));
    gameRef.addAppleCoin();
    removeFromParent();
  }

  void _spawnSlices() {
    final worldPos = absoluteCenter;
    final leftPiece = AppleSlicePiece(
      sprite: _cutLeftSprite,
      startPosition: worldPos,
      initialVelocity: Vector2(-150, -160),
      gravity: Vector2(0, 680),
      angularVelocity: -3.5,
    );
    final rightPiece = AppleSlicePiece(
      sprite: _cutRightSprite,
      startPosition: worldPos,
      initialVelocity: Vector2(150, -160),
      gravity: Vector2(0, 680),
      angularVelocity: 3.5,
    );
    gameRef
      ..add(leftPiece)
      ..add(rightPiece);
  }

  void _spawnJuice() {
    final worldPos = absoluteCenter;
    final particle = Particle.generate(
      count: 14,
      lifespan: 0.6,
      generator: (_) {
        final velocity = Vector2(
          (_random.nextDouble() - 0.5) * 220,
          -(_random.nextDouble() * 160 + 80),
        );
        return AcceleratedParticle(
          acceleration: Vector2(0, 720),
          speed: velocity,
          position: Vector2.zero(),
          child: CircleParticle(
            paint: ui.Paint()
              ..color = _juicePalette[_random.nextInt(_juicePalette.length)],
            radius: 2 + _random.nextDouble() * 3,
          ),
        );
      },
    );
    gameRef.add(
      ParticleSystemComponent(
        particle: particle,
        position: worldPos.clone(),
        priority: 4,
      ),
    );
  }

  static const List<ui.Color> _juicePalette = [
    ui.Color(0xFFFF6B6B),
    ui.Color(0xFFFF8E53),
    ui.Color(0xFFFFC857),
  ];
}

class AppleSlicePiece extends SpriteComponent {
  AppleSlicePiece({
    required Sprite sprite,
    required Vector2 startPosition,
    required Vector2 initialVelocity,
    required Vector2 gravity,
    required double angularVelocity,
    this.lifeSpan = 1.2,
  })  : _velocity = initialVelocity.clone(),
        _gravity = gravity,
        _angularVelocity = angularVelocity,
        super(
          sprite: sprite,
          position: startPosition.clone(),
          size: Vector2.all(36),
          anchor: Anchor.center,
          priority: 4,
        );

  final double lifeSpan;
  final Vector2 _gravity;
  final double _angularVelocity;
  Vector2 _velocity;
  double _life = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _life = lifeSpan;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _velocity += _gravity * dt;
    position += _velocity * dt;
    angle += _angularVelocity * dt;
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
    }
  }
}

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
