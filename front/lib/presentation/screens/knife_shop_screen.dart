import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:knife_hit/core/constants/colors.dart';
import 'package:knife_hit/data/models/game_progress.dart';
import 'package:knife_hit/data/models/knife_catalog.dart';

class KnifeShopScreen extends StatefulWidget {
  const KnifeShopScreen({required this.initialProgress, super.key});

  final GameProgress initialProgress;

  @override
  State<KnifeShopScreen> createState() => _KnifeShopScreenState();
}

class _KnifeShopScreenState extends State<KnifeShopScreen> {
  late int _coins;
  late Set<String> _ownedKnifeIds;
  late String _equippedKnifeId;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _coins = widget.initialProgress.appleCoins;
    _ownedKnifeIds = _deriveOwnedIds();
    _equippedKnifeId =
        KnifeCatalog.findByAsset(widget.initialProgress.equippedKnifeAsset)?.id ??
            'kitchen';
  }

  Set<String> _deriveOwnedIds() {
    final Set<String> ids = {'kitchen'};
    for (final KnifeSkinInfo knife in KnifeCatalog.all) {
      if (knife.price == 0) {
        ids.add(knife.id);
      }
    }
    for (final String asset in widget.initialProgress.unlockedKnifeAssets) {
      final KnifeSkinInfo? info = KnifeCatalog.findByAsset(asset);
      if (info != null) {
        ids.add(info.id);
      }
    }
    return ids;
  }

  void _handlePurchase(KnifeSkinInfo knife) {
    final int? price = knife.price;
    if (price == null) {
      return;
    }
    if (_coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins for this knife.')),
      );
      return;
    }
    setState(() {
      _coins -= price;
      _ownedKnifeIds.add(knife.id);
      _equippedKnifeId = knife.id;
    });
  }

  void _handleEquip(KnifeSkinInfo knife) {
    setState(() {
      _equippedKnifeId = knife.id;
    });
  }

  Future<void> _finishAndPop() async {
    if (_closing) {
      return;
    }
    _closing = true;
    final Set<String> unlocked = {...widget.initialProgress.unlockedKnifeAssets};
    for (final String id in _ownedKnifeIds) {
      final String? asset = KnifeCatalog.findById(id)?.asset;
      if (asset != null) {
        unlocked.add(asset);
      }
    }
    final String equippedAsset =
        KnifeCatalog.findById(_equippedKnifeId)?.asset ??
        widget.initialProgress.equippedKnifeAsset;
    final GameProgress updated = widget.initialProgress.copyWith(
      appleCoins: _coins,
      unlockedKnifeAssets: unlocked,
      equippedKnifeAsset: equippedAsset,
    );
    Navigator.of(context).pop(updated);
  }

  Future<bool> _onWillPop() async {
    await _finishAndPop();
    return false;
  }

  Future<void> _promptCoinDebug() async {
    final TextEditingController controller =
        TextEditingController(text: _coins.toString());
    final int? value = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set coins'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Coins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final int? parsed = int.tryParse(controller.text.trim());
                Navigator.of(dialogContext).pop(parsed);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (value != null) {
      setState(() {
        _coins = value.clamp(0, 999999).toInt();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.homeGradientStart, AppColors.homeGradientEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _finishAndPop,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Knife Shop',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _CoinBadge(
                        coins: _coins,
                        onTap: kDebugMode ? _promptCoinDebug : null,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Collect blades across every rarity tier. Prices are placeholders — specify live costs later.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: KnifeCatalog.all.length,
                    itemBuilder: (context, index) {
                      final KnifeSkinInfo knife = KnifeCatalog.all[index];
                      final bool owned = _ownedKnifeIds.contains(knife.id) || knife.price == 0;
                      final bool equipped = _equippedKnifeId == knife.id;
                      final bool locked = !owned;
                      final bool canAfford = knife.price != null && _coins >= (knife.price ?? 0);
                      return _KnifeCard(
                        info: knife,
                        owned: owned,
                        locked: locked,
                        equipped: equipped,
                        canAfford: canAfford,
                        onBuy: knife.isPurchasable ? () => _handlePurchase(knife) : null,
                        onSelect: owned ? () => _handleEquip(knife) : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coins, this.onTap});

  final int coins;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                coins.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.tune, size: 16, color: Colors.white54),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KnifeCard extends StatelessWidget {
  const _KnifeCard({
    required this.info,
    required this.owned,
    required this.locked,
    required this.equipped,
    required this.canAfford,
    required this.onBuy,
    required this.onSelect,
  });

  final KnifeSkinInfo info;
  final bool owned;
  final bool locked;
  final bool equipped;
  final bool canAfford;
  final VoidCallback? onBuy;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3B251A), Color(0xFF1F120D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white10),
      boxShadow: const [
        BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 8)),
      ],
    );

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        'assets/images/${info.asset}',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                if (info.isPurchasable)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _PriceChip(label: '${info.price} coins'),
                  )
                else if (info.isBossReward)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _PriceChip(label: 'Boss ${info.bossLevel}', showCoin: false),
                  ),
                if (equipped)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _BadgeIcon(
                      icon: Icons.check_circle,
                      color: Colors.lightGreenAccent,
                    ),
                  ),
                if (locked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                      child: const Center(
                        child: Icon(Icons.lock, color: Colors.white70, size: 32),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(theme),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    if (equipped) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Equipped',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      );
    }
    if (owned && onSelect != null) {
      return ElevatedButton(
        onPressed: onSelect,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.dark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Equip'),
      );
    }
    if (info.isBossReward) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: Text(
          info.unlockDescription ?? 'Defeat boss',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ElevatedButton(
      onPressed: canAfford ? onBuy : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Buy'),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label, this.showCoin = true});

  final String label;
  final bool showCoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCoin) ...[
            const Icon(Icons.monetization_on, size: 14, color: Colors.amberAccent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
