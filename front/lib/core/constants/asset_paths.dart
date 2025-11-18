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

  /// Boss target variants displayed on milestone levels.
  static const String targetBossCheese = 'targets/boss_cheese.webp';
  static const String targetBossTomato = 'targets/boss_tomato.webp';
   static const String targetBossLemon = 'targets/boss_lemon.webp';
  static const String targetBossSushi = 'targets/boss_sushi.webp';
  static const String targetBossDonut = 'targets/boss_donut.webp';
  static const String targetBossTire = 'targets/boss_tire.webp';
  static const String targetBossShield = 'targets/boss_shield.webp';
  static const String targetBossVynil = 'targets/boss_vynil.webp';
  static const String targetBossCompass = 'targets/boss_compass.webp';

  /// Default knife sprite (tanto) inside `assets/images/knives/`.
  static const String knifeTanto = 'knives/tanto_sword.webp';

  /// Knife skins unlocked after defeating milestone bosses.
  static const String knifeBossCheese = 'knives/br_cheese_sword.webp';
  static const String knifeBossTomato = 'knives/br_tomato_sword.webp';
  static const String knifeBossLemon = 'knives/br_lemon_sword.webp';
  static const String knifeBossSushi = 'knives/br_sushi_sword.webp';
  static const String knifeBossDonut = 'knives/br_donut_sword.webp';
  static const String knifeBossGear = 'knives/br_gear_sword.webp';
  static const String knifeBossShield = 'knives/br_vikings_sword.webp';
  static const String knifeBossVynil = 'knives/br_vinile_sword.webp';
  static const String knifeBossCompass = 'knives/br_compass_knife.webp';

  /// Whole apple sprite located in `assets/images/targets/`.
  static const String appleWhole = 'targets/apple_full.webp';

  /// Left half of the cut apple sprite.
  static const String appleCutLeft = 'targets/apple_cut_left.webp';

  /// Right half of the cut apple sprite.
  static const String appleCutRight = 'targets/apple_cut_right.webp';

  /// Sound effect triggered when an apple is sliced.
  static const String appleSliceSfx = 'audio/apple_hit.mp3';

  /// Sound for knife-on-knife clashes when a throw collides with a stuck blade.
  static const String knifeClashSfx = 'audio/knife_clash.mp3';
}
