// Simple audio helper; style/documentation lints are ignored to keep it focused.
// ignore_for_file: public_member_api_docs, omit_local_variable_types
// ignore_for_file: cascade_invocations, avoid_redundant_argument_values

import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'package:knife_hit/core/constants/asset_paths.dart';

/// Enumerates the short sound cues used across the game.
enum SoundEffect {
  knifeThrow,
  knifeHit,
  knifeMiss,
  appleHit,
  levelComplete,
  bossAppear,
  bossDefeat,
  gameOver,
  achievementUnlock,
}

extension SoundEffectAsset on SoundEffect {
  /// Relative asset key looked up under `assets/audio/`.
  String get assetPath {
    switch (this) {
      case SoundEffect.knifeThrow:
        return AssetPaths.sfxKnifeThrow;
      case SoundEffect.knifeHit:
        return AssetPaths.sfxKnifeHit;
      case SoundEffect.knifeMiss:
        return AssetPaths.sfxKnifeMiss;
      case SoundEffect.appleHit:
        return AssetPaths.sfxAppleHit;
      case SoundEffect.levelComplete:
        return AssetPaths.sfxLevelComplete;
      case SoundEffect.bossAppear:
        return AssetPaths.sfxBossAppear;
      case SoundEffect.bossDefeat:
        return AssetPaths.sfxBossDefeat;
      case SoundEffect.gameOver:
        return AssetPaths.sfxGameOver;
      case SoundEffect.achievementUnlock:
        return AssetPaths.sfxAchievementUnlock;
    }
  }

  /// Allows tuning the pool size per effect to avoid clipping.
  int get maxPlayers {
    switch (this) {
      case SoundEffect.knifeThrow:
      case SoundEffect.knifeHit:
      case SoundEffect.knifeMiss:
        return 4;
      case SoundEffect.appleHit:
        return 3;
      case SoundEffect.levelComplete:
      case SoundEffect.bossAppear:
      case SoundEffect.bossDefeat:
      case SoundEffect.gameOver:
      case SoundEffect.achievementUnlock:
        return 2;
    }
  }
}

typedef _StopHandle = Future<void> Function();

class _TrackedPlayback {
  _TrackedPlayback(this.stopHandle, this.cleanupTimer);

  final _StopHandle stopHandle;
  final Timer cleanupTimer;
}

/// Preloads short SFX via [AudioPool] to minimize playback latency.
class SoundManager {
  SoundManager._();

  static final SoundManager instance = SoundManager._();

  bool _initialized = false;
  Future<void>? _warmUpFuture;
  final Map<SoundEffect, AudioPool?> _pools = <SoundEffect, AudioPool?>{};
  final Map<SoundEffect, List<_TrackedPlayback>> _activePlaybacks =
      <SoundEffect, List<_TrackedPlayback>>{};

  /// Sets up audio routing and must be called before playing sounds.
  Future<void> init() async {
    // Hot reload recreates Flame's internal AudioCache, so always restate the
    // prefix before we touch any assets.
    FlameAudio.updatePrefix('');
    if (_initialized) {
      return;
    }
    _initialized = true;
  }

  /// Preloads every sound in the background. Safe to call multiple times.
  Future<void> warmUpAll() {
    if (_warmUpFuture != null) {
      return _warmUpFuture!;
    }
    _warmUpFuture = () async {
      await init();
      for (final SoundEffect effect in SoundEffect.values) {
        await _ensurePool(effect);
        // Yield to the event loop so we do not block the first frame.
        await Future<void>.delayed(Duration.zero);
      }
    }();
    return _warmUpFuture!;
  }

  Future<AudioPool?> _ensurePool(SoundEffect effect) async {
    if (_pools.containsKey(effect)) {
      return _pools[effect];
    }
    try {
      final AudioPool pool = await FlameAudio.createPool(
        effect.assetPath,
        minPlayers: 1,
        maxPlayers: effect.maxPlayers,
      );
      _pools[effect] = pool;
      return pool;
    } on Object catch (error, stackTrace) {
      debugPrint('SoundManager: failed to load ${effect.assetPath}: $error');
      debugPrint('$stackTrace');
      _pools[effect] = null;
      return null;
    }
  }

  /// Plays [effect] once. When [restart] is true, any current stream stops.
  Future<void> play(
    SoundEffect effect, {
    bool restart = false,
  }) async {
    await init();
    if (restart) {
      await stopEffect(effect);
    }
    final AudioPool? pool = await _ensurePool(effect);
    if (pool == null) {
      return;
    }
    try {
      final _StopHandle stop = await pool.start();
      _registerPlayback(effect, stop);
    } on Object catch (error, stackTrace) {
      debugPrint('SoundManager: failed to start ${effect.assetPath}: $error');
      debugPrint('$stackTrace');
    }
  }

  void _registerPlayback(SoundEffect effect, _StopHandle stop) {
    final Timer cleanup = Timer(const Duration(seconds: 5), () {
      final List<_TrackedPlayback>? entries = _activePlaybacks[effect];
      entries?.removeWhere((entry) => entry.stopHandle == stop);
      if (entries != null && entries.isEmpty) {
        _activePlaybacks.remove(effect);
      }
    });
    final record = _TrackedPlayback(stop, cleanup);
    final List<_TrackedPlayback> entries =
      _activePlaybacks.putIfAbsent(effect, () => <_TrackedPlayback>[]);
    entries.add(record);
  }

  /// Stops any currently tracked streams for [effect].
  Future<void> stopEffect(SoundEffect effect) async {
    final List<_TrackedPlayback>? entries = _activePlaybacks.remove(effect);
    if (entries == null || entries.isEmpty) {
      return;
    }
    for (final _TrackedPlayback entry in entries) {
      entry.cleanupTimer.cancel();
      await entry.stopHandle();
    }
  }

  /// Stops every effect that is currently playing.
  Future<void> stopAll() async {
    final List<SoundEffect> effects = _activePlaybacks.keys.toList();
    for (final SoundEffect effect in effects) {
      await stopEffect(effect);
    }
  }

  /// Releases every created [AudioPool]. Call from `dispose`.
  Future<void> dispose() async {
    await stopAll();
    for (final AudioPool? pool in _pools.values) {
      await pool?.dispose();
    }
    _pools.clear();
    _warmUpFuture = null;
    _initialized = false;
  }
}
