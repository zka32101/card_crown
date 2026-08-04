import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/game_state_provider.dart';
import '../services/purchase_service.dart';
import '../theme/kingdom_theme.dart';
import '../l10n/app_localizations.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  // 購入処理中のパッケージID（多重タップ防止・ボタンにローディング表示するため）
  String? _processingPackageId;

  Future<void> _buy(CurrencyPackageDef pkg) async {
    if (_processingPackageId != null) return;
    setState(() => _processingPackageId = pkg.packageId);

    final result = await PurchaseService.purchaseCurrencyPackage(pkg.packageId);
    if (!mounted) return;
    setState(() => _processingPackageId = null);

    final t = AppLocalizations.of(context)!;
    switch (result) {
      case PurchaseResult.success:
        _grantCurrency(pkg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.shop_receivedPackage(pkg.label))),
        );
      case PurchaseResult.cancelled:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.shop_purchaseCancelled)),
        );
      case PurchaseResult.noProduct:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.shop_productComingSoon)),
        );
      case PurchaseResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.shop_purchaseError), backgroundColor: Colors.red),
        );
    }
  }

  void _grantCurrency(CurrencyPackageDef pkg) {
    final wallet = ref.read(walletProvider);
    final updated = pkg.isGem
        ? wallet.copyWith(gemBalance: wallet.gemBalance + pkg.amount)
        : wallet.copyWith(coinBalance: wallet.coinBalance + pkg.amount);
    ref.read(walletProvider.notifier).state = updated;

    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      updateWallet(userId, updated);
    }
  }

  void _buyStreakShield() {
    final t = AppLocalizations.of(context)!;
    final wallet = ref.read(walletProvider);
    if (wallet.gemBalance < kStreakShieldGemCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.shop_insufficientGems), backgroundColor: Kingdom.angerCrimson),
      );
      return;
    }
    final updated = wallet.buyStreakShield();
    ref.read(walletProvider.notifier).state = updated;
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) updateWallet(userId, updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.shop_exchangeSuccess)),
    );
  }

  void _extendDailyBonusCap() {
    final t = AppLocalizations.of(context)!;
    final wallet = ref.read(walletProvider);
    if (wallet.dailyBonusCapExtensionsUsedToday >= kDailyBonusCapExtensionMaxPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.shop_dailyBonusCapExtMaxReached), backgroundColor: Kingdom.angerCrimson),
      );
      return;
    }
    if (wallet.gemBalance < kDailyBonusCapExtensionGemCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.shop_insufficientGems), backgroundColor: Kingdom.angerCrimson),
      );
      return;
    }
    final updated = wallet.extendDailyBonusCap();
    ref.read(walletProvider.notifier).state = updated;
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) updateWallet(userId, updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.shop_exchangeSuccess)),
    );
  }

  Future<void> _restore() async {
    final ok = await PurchaseService.restorePurchases();
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? t.shop_restoreSuccess : t.shop_restoreNotFound)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Kingdom.night,
      appBar: AppBar(
        title: Text(t.shop_title, style: Kingdom.title(size: 17)),
        backgroundColor: Kingdom.nightDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Kingdom.gilt),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _restore,
            child: Text(t.shop_restorePurchases, style: TextStyle(color: Kingdom.parchment.withValues(alpha: 0.7))),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: EmotionMoteField(count: 10)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(Kingdom.spaceLg),
              children: [
                // 現在の残高表示
                OrnateFrame(
                  accent: Kingdom.gilt,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _BalanceDisplay(emoji: '🪙', label: t.shop_coinLabel, value: wallet.coinBalance),
                      Container(width: 1, height: 40, color: Kingdom.parchment.withValues(alpha: 0.15)),
                      _BalanceDisplay(emoji: '💎', label: t.shop_gemLabel, value: wallet.gemBalance),
                    ],
                  ),
                ),
                const SizedBox(height: Kingdom.spaceXxl),

                Text(t.shop_coinPackagesHeader, style: Kingdom.label(size: 15, color: Kingdom.gilt)),
                const SizedBox(height: Kingdom.spaceMd),
                for (final pkg in kCoinPackages) ...[
                  _PackageTile(
                    pkg: pkg,
                    accent: Kingdom.gilt,
                    isProcessing: _processingPackageId == pkg.packageId,
                    onTap: () => _buy(pkg),
                  ),
                  const SizedBox(height: Kingdom.spaceMd),
                ],
                const SizedBox(height: Kingdom.spaceLg),

                Text(t.shop_gemPackagesHeader, style: Kingdom.label(size: 15, color: Kingdom.sadnessIndigo)),
                const SizedBox(height: Kingdom.spaceMd),
                for (final pkg in kGemPackages) ...[
                  _PackageTile(
                    pkg: pkg,
                    accent: Kingdom.sadnessIndigo,
                    isProcessing: _processingPackageId == pkg.packageId,
                    onTap: () => _buy(pkg),
                  ),
                  const SizedBox(height: Kingdom.spaceMd),
                ],
                const SizedBox(height: Kingdom.spaceLg),

                Text(t.shop_gemExchangeHeader, style: Kingdom.label(size: 15, color: Kingdom.sadnessIndigo)),
                const SizedBox(height: Kingdom.spaceMd),
                _ExchangeTile(
                  emoji: '🛡️',
                  label: t.shop_streakShieldLabel(wallet.streakShieldCount),
                  description: t.shop_streakShieldDesc,
                  costLabel: '💎$kStreakShieldGemCost',
                  accent: Kingdom.sadnessIndigo,
                  onTap: _buyStreakShield,
                ),
                const SizedBox(height: Kingdom.spaceMd),
                _ExchangeTile(
                  emoji: '⏫',
                  label: t.shop_dailyBonusCapExtLabel(kDailyBonusCapExtensionAmount),
                  description: t.shop_dailyBonusCapExtDesc(
                      wallet.dailyBonusCapExtensionsUsedToday, kDailyBonusCapExtensionMaxPerDay),
                  costLabel: '💎$kDailyBonusCapExtensionGemCost',
                  accent: Kingdom.sadnessIndigo,
                  onTap: _extendDailyBonusCap,
                ),
                const SizedBox(height: Kingdom.spaceXl),

                Text(
                  t.shop_storeNote,
                  style: TextStyle(color: Kingdom.parchment.withValues(alpha: 0.5), fontSize: 11),
                ),
                SizedBox(height: Kingdom.spaceXl + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceDisplay extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;

  const _BalanceDisplay({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$emoji $value',
            style: TextStyle(
                fontFamily: Kingdom.displayFont,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Kingdom.parchment)),
        const SizedBox(height: Kingdom.spaceXs),
        Text(label, style: TextStyle(fontSize: 11, color: Kingdom.parchment.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _ExchangeTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final String costLabel;
  final Color accent;
  final VoidCallback onTap;

  const _ExchangeTile({
    required this.emoji,
    required this.label,
    required this.description,
    required this.costLabel,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OrnateFrame(
      accent: accent,
      showCorners: false,
      padding: const EdgeInsets.symmetric(horizontal: Kingdom.spaceLg, vertical: Kingdom.spaceMd),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: Kingdom.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Kingdom.parchment, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(description, style: TextStyle(color: Kingdom.parchment.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            height: Kingdom.minTapTarget,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Kingdom.night,
                minimumSize: const Size(70, Kingdom.minTapTarget),
              ),
              child: Text(costLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final CurrencyPackageDef pkg;
  final Color accent;
  final bool isProcessing;
  final VoidCallback onTap;

  const _PackageTile({
    required this.pkg,
    required this.accent,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OrnateFrame(
      accent: accent,
      showCorners: false,
      padding: const EdgeInsets.symmetric(horizontal: Kingdom.spaceLg, vertical: Kingdom.spaceMd),
      child: Row(
        children: [
          Text(pkg.isGem ? '💎' : '🪙', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: Kingdom.spaceMd),
          Expanded(
            child: Text(pkg.label,
                style: TextStyle(color: Kingdom.parchment, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          SizedBox(
            height: Kingdom.minTapTarget,
            child: ElevatedButton(
              onPressed: isProcessing ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Kingdom.night,
                minimumSize: const Size(84, Kingdom.minTapTarget),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Kingdom.night))
                  : Text(pkg.fallbackPriceLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
