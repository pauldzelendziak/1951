import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knife_hit/data/models/player_stats.dart';

class PlayerStatsStorage {
  const PlayerStatsStorage();

  static const String _statsKey = 'player_stats';

  Future<PlayerStats> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_statsKey);
    if (raw == null || raw.isEmpty) {
      return PlayerStats.zero;
    }
    try {
      final Map<String, Object?> decoded =
          Map<String, Object?>.from(jsonDecode(raw) as Map);
      return PlayerStats.fromJson(decoded);
    } on FormatException catch (error) {
      debugPrint('Invalid player stats payload, clearing. Error: $error');
      await prefs.remove(_statsKey);
      return PlayerStats.zero;
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to read player stats: $error');
      debugPrint('$stackTrace');
      return PlayerStats.zero;
    }
  }

  Future<void> write(PlayerStats stats) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final PlayerStats normalized = stats.recalculateAccuracy();
    final String payload = jsonEncode(normalized.toJson());
    await prefs.setString(_statsKey, payload);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsKey);
  }

  Future<PlayerStats> update(PlayerStats Function(PlayerStats current) updater) async {
    final PlayerStats current = await read();
    final PlayerStats updated = updater(current).recalculateAccuracy();
    await write(updated);
    return updated;
  }
}
