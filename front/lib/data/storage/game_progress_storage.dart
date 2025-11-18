import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knife_hit/data/models/game_progress.dart';

class GameProgressStorage {
  const GameProgressStorage();

  static const String _progressKey = 'game_progress';

  Future<GameProgress?> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_progressKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Map<String, Object?> decoded =
          Map<String, Object?>.from(jsonDecode(raw) as Map);
      return GameProgress.fromJson(decoded);
    } on FormatException catch (error) {
      debugPrint('Invalid game progress payload, clearing. Error: $error');
      await prefs.remove(_progressKey);
      return null;
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to read game progress: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  Future<void> write(GameProgress progress) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String payload = jsonEncode(progress.toJson());
    await prefs.setString(_progressKey, payload);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
  }
}
