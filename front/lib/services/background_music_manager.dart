import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'package:knife_hit/core/constants/asset_paths.dart';

/// Enumerates high-level background music tracks used across the app.
enum BackgroundTrack {
  menu,
  game,
  boss,
}

extension BackgroundTrackAsset on BackgroundTrack {
  /// Relative asset path resolved under `assets/audio/`.
  String get assetPath {
    switch (this) {
      case BackgroundTrack.menu:
        return AssetPaths.musicMenu;
      case BackgroundTrack.game:
        return AssetPaths.musicGame;
      case BackgroundTrack.boss:
        return AssetPaths.musicBoss;
    }
  }

  /// Default mixing volume for the track.
  double get defaultVolume {
    switch (this) {
      case BackgroundTrack.menu:
        return 0.6;
      case BackgroundTrack.game:
        return 0.7;
      case BackgroundTrack.boss:
        return 0.75;
    }
  }
}

/// Coordinates background music playback and transitions.
class BackgroundMusicManager {
  BackgroundMusicManager._();

  static final BackgroundMusicManager instance = BackgroundMusicManager._();

  bool _initialized = false;
  BackgroundTrack? _currentTrack;
  final _cacheFutures = <BackgroundTrack, Future<void>>{};

  Future<void> _ensureInitialized() async {
    // Flame recreates its AudioCache after hot reload, so restating the prefix
    // keeps our absolute asset paths valid.
    FlameAudio.updatePrefix('');
    if (_initialized) {
      return;
    }
    try {
      await FlameAudio.bgm.initialize();
      await Future.wait(BackgroundTrack.values.map(_ensureCached));
      _initialized = true;
    } on Object catch (error, stackTrace) {
      debugPrint('BackgroundMusicManager: init failed: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _ensureCached(
    BackgroundTrack track, {
    bool forceReload = false,
  }) {
    if (forceReload) {
      _cacheFutures.remove(track);
    } else {
      final pending = _cacheFutures[track];
      if (pending != null) {
        return pending;
      }
    }
    final future = () async {
      try {
        await FlameAudio.audioCache.load(track.assetPath);
      } on Object catch (error, stackTrace) {
        debugPrint(
          'BackgroundMusicManager: preload failed '
          '(${track.assetPath}): $error',
        );
        debugPrint('$stackTrace');
        rethrow;
      }
    }();
    _cacheFutures[track] = future;
    future.catchError((Object _) {
      if (identical(_cacheFutures[track], future)) {
        _cacheFutures.remove(track);
      }
    });
    return future;
  }

  /// Plays [track] on loop. Subsequent calls restart the new track.
  Future<void> play(BackgroundTrack track, {double? volume}) async {
    await _ensureInitialized();
    await _ensureCached(track);
    final resolvedVolume = volume ?? track.defaultVolume;
    if (await _startTrack(track, resolvedVolume)) {
      return;
    }
    await _ensureCached(track, forceReload: true);
    await _startTrack(track, resolvedVolume, retrying: true);
  }

  Future<bool> _startTrack(
    BackgroundTrack track,
    double volume, {
    bool retrying = false,
  }) async {
    try {
      if (FlameAudio.bgm.isPlaying) {
        try {
          await FlameAudio.bgm.stop();
        } on Object catch (error) {
          debugPrint('BackgroundMusicManager: stop-before-play failed: $error');
        }
      }
      await FlameAudio.bgm.play(track.assetPath, volume: volume);
      _currentTrack = track;
      return true;
    } on Object catch (error, stackTrace) {
      final phase = retrying ? 'retry play failed' : 'play failed';
      debugPrint(
        'BackgroundMusicManager: $phase '
        '(${track.assetPath}): $error',
      );
      debugPrint('$stackTrace');
      return false;
    }
  }

  /// Stops any currently playing music.
  Future<void> stop() async {
    if (!_initialized) {
      return;
    }
    try {
      try {
          await FlameAudio.bgm.stop();
      } on Object catch (error) {
        debugPrint('BackgroundMusicManager: stop failed before play: $error');
      }
    } on Object catch (error, stackTrace) {
      debugPrint('BackgroundMusicManager: stop failed: $error');
      debugPrint('$stackTrace');
    } finally {
      _currentTrack = null;
    }
  }

  /// Pauses the current track while keeping the player alive.
  Future<void> pause() async {
    if (!_initialized) {
      return;
    }
    try {
      await FlameAudio.bgm.pause();
    } on Object catch (error, stackTrace) {
      debugPrint('BackgroundMusicManager: pause failed: $error');
      debugPrint('$stackTrace');
    }
  }

  /// Resumes playback if a track is paused.
  Future<void> resume() async {
    if (!_initialized) {
      return;
    }
    try {
      await FlameAudio.bgm.resume();
    } on Object catch (error, stackTrace) {
      debugPrint('BackgroundMusicManager: resume failed: $error');
      debugPrint('$stackTrace');
    }
  }

  BackgroundTrack? get currentTrack => _currentTrack;
}
