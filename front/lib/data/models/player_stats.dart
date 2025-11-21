class PlayerStats {
  const PlayerStats({
    required this.totalScore,
    required this.highScore,
    required this.totalKnivesThrown,
    required this.successfulHits,
    required this.accuracy,
    required this.totalApplesHit,
    required this.maxLevelReached,
    required this.bossFightsWon,
    required this.totalPlaytimeMinutes,
    required this.gamesPlayed,
    required this.knivesUnlocked,
  });

  final int totalScore;
  final int highScore;
  final int totalKnivesThrown;
  final int successfulHits;
  final double accuracy;
  final int totalApplesHit;
  final int maxLevelReached;
  final int bossFightsWon;
  final int totalPlaytimeMinutes;
  final int gamesPlayed;
  final int knivesUnlocked;

  double get computedAccuracy {
    if (totalKnivesThrown <= 0 || successfulHits <= 0) {
      return 0;
    }
    final double ratio = successfulHits / totalKnivesThrown;
    final double percentage = ratio * 100;
    return percentage.clamp(0, 100).toDouble();
  }

  PlayerStats recalculateAccuracy() {
    return copyWith(accuracy: computedAccuracy);
  }

  static const PlayerStats zero = PlayerStats(
    totalScore: 0,
    highScore: 0,
    totalKnivesThrown: 0,
    successfulHits: 0,
    accuracy: 0,
    totalApplesHit: 0,
    maxLevelReached: 0,
    bossFightsWon: 0,
    totalPlaytimeMinutes: 0,
    gamesPlayed: 0,
    knivesUnlocked: 0,
  );

  PlayerStats copyWith({
    int? totalScore,
    int? highScore,
    int? totalKnivesThrown,
    int? successfulHits,
    double? accuracy,
    int? totalApplesHit,
    int? maxLevelReached,
    int? bossFightsWon,
    int? totalPlaytimeMinutes,
    int? gamesPlayed,
    int? knivesUnlocked,
  }) {
    return PlayerStats(
      totalScore: totalScore ?? this.totalScore,
      highScore: highScore ?? this.highScore,
      totalKnivesThrown: totalKnivesThrown ?? this.totalKnivesThrown,
      successfulHits: successfulHits ?? this.successfulHits,
      accuracy: accuracy ?? this.accuracy,
      totalApplesHit: totalApplesHit ?? this.totalApplesHit,
      maxLevelReached: maxLevelReached ?? this.maxLevelReached,
      bossFightsWon: bossFightsWon ?? this.bossFightsWon,
      totalPlaytimeMinutes: totalPlaytimeMinutes ?? this.totalPlaytimeMinutes,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      knivesUnlocked: knivesUnlocked ?? this.knivesUnlocked,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'totalScore': totalScore,
      'highScore': highScore,
      'totalKnivesThrown': totalKnivesThrown,
      'successfulHits': successfulHits,
      'accuracy': accuracy,
      'totalApplesHit': totalApplesHit,
      'maxLevelReached': maxLevelReached,
      'bossFightsWon': bossFightsWon,
      'totalPlaytimeMinutes': totalPlaytimeMinutes,
      'gamesPlayed': gamesPlayed,
      'knivesUnlocked': knivesUnlocked,
    };
  }

  factory PlayerStats.fromJson(Map<String, Object?> json) {
    double parseAccuracy(Object? value) {
      if (value is int) {
        return value.toDouble();
      }
      if (value is double) {
        return value;
      }
      return 0;
    }

    return PlayerStats(
      totalScore: (json['totalScore'] as int?) ?? 0,
      highScore: (json['highScore'] as int?) ?? 0,
      totalKnivesThrown: (json['totalKnivesThrown'] as int?) ?? 0,
      successfulHits: (json['successfulHits'] as int?) ?? 0,
      accuracy: parseAccuracy(json['accuracy']),
      totalApplesHit: (json['totalApplesHit'] as int?) ?? 0,
      maxLevelReached: (json['maxLevelReached'] as int?) ?? 0,
      bossFightsWon: (json['bossFightsWon'] as int?) ?? 0,
      totalPlaytimeMinutes: (json['totalPlaytimeMinutes'] as int?) ?? 0,
      gamesPlayed: (json['gamesPlayed'] as int?) ?? 0,
      knivesUnlocked: (json['knivesUnlocked'] as int?) ?? 0,
    );
  }
}
