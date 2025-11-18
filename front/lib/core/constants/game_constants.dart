/// Contains gameplay-related constants that power the core mechanics.
abstract class GameConstants {
  /// Prevent instantiation.
  const GameConstants._();

  /// Number of knives the player starts a level with.
  static const int startingKnives = 5;

  /// Milliseconds between allowed knife throws (cooldown).
  static const double knifeThrowCooldownMs = 350;

  /// Chance (0-1) that a level spawns apples on the target.
  static const double appleSpawnChance = 0.4;

  /// Maximum number of apples that may appear simultaneously on a target.
  static const int maxApplesOnTarget = 2;
}
