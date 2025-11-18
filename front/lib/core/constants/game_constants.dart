/// Contains gameplay-related constants that power the core mechanics.
abstract class GameConstants {
  /// Prevent instantiation.
  const GameConstants._();

  /// Number of knives the player starts a level with.
  static const int startingKnives = 5;

  /// Milliseconds between allowed knife throws (cooldown).
  static const double knifeThrowCooldownMs = 350;
}
