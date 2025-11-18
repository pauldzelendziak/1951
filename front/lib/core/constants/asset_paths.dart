/// Central registry for frequently accessed asset locations.
abstract class AssetPaths {
  /// Prevent instantiation.
  const AssetPaths._();

  /// Path to the placeholder logo image used on the home screen.
  static const String logoPlaceholder = 'assets/images/ui/logo_placeholder.png';

  /// Path to the play icon image (fallback if using image button).
  static const String iconPlay = 'assets/images/buttons/play.png';

  /// Default target (wood) sprite inside `assets/images/targets/`.
  ///
  /// Flame's loader expects asset keys without a leading `assets/` prefix,
  /// so use `images/targets/...` here to avoid `assets/assets/...` duplication.
  static const String targetDefaultWood = 'targets/default_wood.webp';

  /// Default knife sprite (tanto) inside `assets/images/knives/`.
  static const String knifeTanto = 'knives/tanto_sword.webp';
}
