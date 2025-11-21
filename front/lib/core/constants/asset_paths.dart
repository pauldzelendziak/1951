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
  static const String knifeKitchen = 'knives/kitchen_sword.webp';
  static const String knifeCombat = 'knives/combat_sword.webp';
  static const String knifeStiletto = 'knives/stiletto_sword.webp';
  static const String knifeBowie = 'knives/browie_sword.webp';
  static const String knifeRainbow = 'knives/sp_rainbow_sword.webp';
  static const String knifeGolden = 'knives/sp_golden_sword.webp';
  static const String knifeCrystal = 'knives/sp_crystal_sword.webp';
  static const String knifeDiamond = 'knives/sp_diamond_sword.webp';
  static const String knifeCarrot = 'knives/zb_carrot_sword.webp';
  static const String knifeFish = 'knives/zb_fish_sword.webp';
  static const String knifePencil = 'knives/zb_pencil_sword.webp';
  static const String knifeFork = 'knives/zb_fork_sword.webp';
  static const String knifeArrow = 'knives/zb_arrow_sword.webp';
  static const String knifeScrewdriver = 'knives/zb_screwdriver_sword.webp';
  static const String knifePlasma = 'knives/hp_plasma_blade.webp';
  static const String knifeShadow = 'knives/hp_shadow_dagger.webp';
  static const String knifeIce = 'knives/hp_ice_sword.webp';
  static const String knifeFire = 'knives/hp_fire_sword.webp';
  static const String knifeGalaxy = 'knives/ep_galactic_knife.webp';

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
  static const String knifeBossTire = 'knives/br_tire_knife.webp';

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

  /// Achievement badge icons located under `assets/images/buttons/`.
  static const String achievementFirstBlood = 'assets/images/buttons/first_blood.webp';
  static const String achievementAppleSlayer = 'assets/images/buttons/apple_slayer.webp';
  static const String achievementApprentice = 'assets/images/buttons/apprentice.webp';
  static const String achievementAccurate = 'assets/images/buttons/accurate.webp';
  static const String achievementBossHunter = 'assets/images/buttons/boss_hunter.webp';
  static const String achievementCollector = 'assets/images/buttons/collector.webp';
  static const String achievementAppleManiac = 'assets/images/buttons/apple_maniac.webp';
  static const String achievementSkilledThrower = 'assets/images/buttons/skilled_thrower.webp';
  static const String achievementLevel25 = 'assets/images/buttons/level_25.webp';
  static const String achievementMasterThrower = 'assets/images/buttons/master_thrower.webp';
  static const String achievementPerfectAim = 'assets/images/buttons/perfect_aim.webp';
  static const String achievementAppleKing = 'assets/images/buttons/apple_king.webp';
  static const String achievementBossMaster = 'assets/images/buttons/boss_master.webp';
  static const String achievementFullCollection = 'assets/images/buttons/full_collection.webp';
  static const String achievementLevel50 = 'assets/images/buttons/lvl_50.webp';
  static const String achievementLegend = 'assets/images/buttons/legend.webp';
  static const String achievementUltimateBoss = 'assets/images/buttons/ultimate_boss.webp';
  static const String achievementKnifeGod = 'assets/images/buttons/knife_god.webp';
  static const String achievementAppleLegend = 'assets/images/buttons/apple_legend.webp';
}
