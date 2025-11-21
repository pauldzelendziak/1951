import 'package:flutter/foundation.dart';

import 'package:knife_hit/core/constants/asset_paths.dart';

@immutable
class KnifeSkinInfo {
  const KnifeSkinInfo({
    required this.id,
    required this.name,
    required this.asset,
    required this.category,
    this.price,
    this.unlockDescription,
    this.bossLevel,
  });

  final String id;
  final String name;
  final String asset;
  final KnifeCategory category;
  final int? price;
  final String? unlockDescription;
  final int? bossLevel;

  bool get isBossReward => bossLevel != null;
  bool get isPurchasable => price != null && !isBossReward;
}

enum KnifeCategory {
  classic,
  special,
  fun,
  epic,
  legendary,
}

class KnifeCatalog {
  static const List<KnifeSkinInfo> all = [
    KnifeSkinInfo(
      id: 'kitchen',
      name: 'Kitchen Knife',
      asset: AssetPaths.knifeKitchen,
      category: KnifeCategory.classic,
      price: 0,
    ),
    KnifeSkinInfo(
      id: 'combat',
      name: 'Combat Knife',
      asset: AssetPaths.knifeCombat,
      category: KnifeCategory.classic,
      price: 20,
    ),
    KnifeSkinInfo(
      id: 'tanto',
      name: 'Tanto',
      asset: AssetPaths.knifeTanto,
      category: KnifeCategory.classic,
      price: 30,
    ),
    KnifeSkinInfo(
      id: 'stiletto',
      name: 'Stiletto',
      asset: AssetPaths.knifeStiletto,
      category: KnifeCategory.classic,
      price: 40,
    ),
    KnifeSkinInfo(
      id: 'bowie',
      name: 'Bowie Knife',
      asset: AssetPaths.knifeBowie,
      category: KnifeCategory.classic,
      price: 50,
    ),
    KnifeSkinInfo(
      id: 'rainbow',
      name: 'Rainbow Knife',
      asset: AssetPaths.knifeRainbow,
      category: KnifeCategory.special,
      price: 60,
    ),
    KnifeSkinInfo(
      id: 'golden',
      name: 'Golden Knife',
      asset: AssetPaths.knifeGolden,
      category: KnifeCategory.special,
      price: 80,
    ),
    KnifeSkinInfo(
      id: 'crystal',
      name: 'Crystal Knife',
      asset: AssetPaths.knifeCrystal,
      category: KnifeCategory.special,
      price: 90,
    ),
    KnifeSkinInfo(
      id: 'diamond',
      name: 'Diamond Knife',
      asset: AssetPaths.knifeDiamond,
      category: KnifeCategory.special,
      price: 100,
    ),
    KnifeSkinInfo(
      id: 'carrot',
      name: 'Carrot',
      asset: AssetPaths.knifeCarrot,
      category: KnifeCategory.fun,
      price: 50,
    ),
    KnifeSkinInfo(
      id: 'fish',
      name: 'Fish',
      asset: AssetPaths.knifeFish,
      category: KnifeCategory.fun,
      price: 55,
    ),
    KnifeSkinInfo(
      id: 'pencil',
      name: 'Pencil',
      asset: AssetPaths.knifePencil,
      category: KnifeCategory.fun,
      price: 60,
    ),
    KnifeSkinInfo(
      id: 'fork',
      name: 'Fork',
      asset: AssetPaths.knifeFork,
      category: KnifeCategory.fun,
      price: 65,
    ),
    KnifeSkinInfo(
      id: 'arrow',
      name: 'Arrow',
      asset: AssetPaths.knifeArrow,
      category: KnifeCategory.fun,
      price: 70,
    ),
    KnifeSkinInfo(
      id: 'screwdriver',
      name: 'Screwdriver',
      asset: AssetPaths.knifeScrewdriver,
      category: KnifeCategory.fun,
      price: 75,
    ),
    KnifeSkinInfo(
      id: 'boss_cheese',
      name: 'Cheese Knife',
      asset: AssetPaths.knifeBossCheese,
      category: KnifeCategory.epic,
      bossLevel: 5,
      unlockDescription: 'Boss 5 reward',
    ),
    KnifeSkinInfo(
      id: 'boss_tomato',
      name: 'Tomato Knife',
      asset: AssetPaths.knifeBossTomato,
      category: KnifeCategory.epic,
      bossLevel: 10,
      unlockDescription: 'Boss 10 reward',
    ),
    KnifeSkinInfo(
      id: 'boss_lemon',
      name: 'Lemon Knife',
      asset: AssetPaths.knifeBossLemon,
      category: KnifeCategory.epic,
      bossLevel: 15,
      unlockDescription: 'Boss 15 reward',
    ),
    KnifeSkinInfo(
      id: 'boss_sushi',
      name: 'Sushi Knife',
      asset: AssetPaths.knifeBossSushi,
      category: KnifeCategory.epic,
      bossLevel: 20,
      unlockDescription: 'Boss 20 reward',
    ),
    KnifeSkinInfo(
      id: 'boss_donut',
      name: 'Donut Knife',
      asset: AssetPaths.knifeBossDonut,
      category: KnifeCategory.epic,
      bossLevel: 25,
      unlockDescription: 'Boss 25 reward',
    ),
    KnifeSkinInfo(
      id: 'boss_tire',
      name: 'Tire Iron',
      asset: AssetPaths.knifeBossTire,
      category: KnifeCategory.epic,
      bossLevel: 30,
      unlockDescription: 'Boss 30 reward',
    ),
    KnifeSkinInfo(
      id: 'boss_viking',
      name: 'Viking Blade',
      asset: AssetPaths.knifeBossShield,
      category: KnifeCategory.epic,
      bossLevel: 35,
      unlockDescription: 'Boss 35 reward',
    ),
    KnifeSkinInfo(
      id: 'boss_vinyl',
      name: 'Vinyl Blade',
      asset: AssetPaths.knifeBossVynil,
      category: KnifeCategory.epic,
      bossLevel: 40,
      unlockDescription: 'Boss 40 reward',
    ),
    KnifeSkinInfo(
      id: 'boss_gear',
      name: 'Gear Knife',
      asset: AssetPaths.knifeBossGear,
      category: KnifeCategory.epic,
      bossLevel: 45,
      unlockDescription: 'Boss 45 reward',
    ),
    KnifeSkinInfo(
      id: 'boss_compass',
      name: 'Compass Knife',
      asset: AssetPaths.knifeBossCompass,
      category: KnifeCategory.epic,
      bossLevel: 50,
      unlockDescription: 'Boss 50 reward',
    ),
    KnifeSkinInfo(
      id: 'plasma',
      name: 'Plasma Blade',
      asset: AssetPaths.knifePlasma,
      category: KnifeCategory.legendary,
      price: 120,
    ),
    KnifeSkinInfo(
      id: 'shadow',
      name: 'Shadow Dagger',
      asset: AssetPaths.knifeShadow,
      category: KnifeCategory.legendary,
      price: 140,
    ),
    KnifeSkinInfo(
      id: 'ice',
      name: 'Ice Sword',
      asset: AssetPaths.knifeIce,
      category: KnifeCategory.legendary,
      price: 160,
    ),
    KnifeSkinInfo(
      id: 'fire',
      name: 'Fire Blade',
      asset: AssetPaths.knifeFire,
      category: KnifeCategory.legendary,
      price: 180,
    ),
    KnifeSkinInfo(
      id: 'galaxy',
      name: 'Galaxy Knife',
      asset: AssetPaths.knifeGalaxy,
      category: KnifeCategory.legendary,
      price: 200,
    ),
  ];

  static KnifeSkinInfo? findByAsset(String? asset) {
    if (asset == null || asset.isEmpty) {
      return null;
    }
    for (final KnifeSkinInfo info in all) {
      if (info.asset == asset) {
        return info;
      }
    }
    return null;
  }

  static KnifeSkinInfo? findById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final KnifeSkinInfo info in all) {
      if (info.id == id) {
        return info;
      }
    }
    return null;
  }
}
