import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_card.dart';
import '../data/seed_cards_data.dart';

// 全カード（シードカード→PlayCard変換）プロバイダー
final allPlayCardsProvider = Provider<List<PlayCard>>((ref) {
  return seedCardsData.map((sc) => PlayCard(
    cardId: sc.cardId,
    attribute: sc.attribute,
    cost: sc.cost,
    attackPower: sc.attackPower,
    defensePower: sc.defensePower,
    speed: sc.speed,
    nameJp: sc.nameJp,
    imageUrl: '',
    isSeedCard: true,
  )).toList();
});

// 防衛デッキ（5枚）
final defenseDeckProvider = StateProvider<List<PlayCard>>((ref) {
  // デフォルト：シードカードの最初の5枚
  final allCards = ref.read(allPlayCardsProvider);
  return allCards.take(5).toList();
});

// 攻撃デッキ選択中
final selectedAttackDeckProvider = StateProvider<List<PlayCard>>((ref) => []);

// ユーザーウォレット
class WalletState {
  final int totalPoints;
  final int todayPoints;
  final int todayWins;
  final int coinBalance;
  final int winStreak; // 連勝数

  const WalletState({
    this.totalPoints = 0,
    this.todayPoints = 0,
    this.todayWins = 0,
    this.coinBalance = 100,
    this.winStreak = 0,
  });

  WalletState copyWith({int? totalPoints, int? todayPoints, int? todayWins, int? coinBalance, int? winStreak}) =>
    WalletState(
      totalPoints: totalPoints ?? this.totalPoints,
      todayPoints: todayPoints ?? this.todayPoints,
      todayWins: todayWins ?? this.todayWins,
      coinBalance: coinBalance ?? this.coinBalance,
      winStreak: winStreak ?? this.winStreak,
    );

  /// 連勝ボーナス: 3連勝=+5, 5連勝=+10, 7連勝+=+15
  int get streakBonus {
    if (winStreak >= 7) return 15;
    if (winStreak >= 5) return 10;
    if (winStreak >= 3) return 5;
    return 0;
  }
}

final walletProvider = StateProvider<WalletState>((ref) => const WalletState());

// 連続ログイン日数（1-7 でローテーション。本実装では Firebase で日付管理予定）
final loginStreakProvider = StateProvider<int>((ref) => 1);

// プレイヤーランク
class PlayerRank {
  final int rating;
  final String tier;
  final int wins;
  final int losses;

  const PlayerRank({
    this.rating = 1000,
    this.tier = 'bronze',
    this.wins = 0,
    this.losses = 0,
  });

  String get tierLabel {
    switch (tier) {
      case 'bronze': return 'ブロンズ';
      case 'silver': return 'シルバー';
      case 'gold': return 'ゴールド';
      case 'platinum': return 'プラチナ';
      case 'diamond': return 'ダイヤモンド';
      default: return 'ブロンズ';
    }
  }

  String get tierEmoji {
    switch (tier) {
      case 'bronze': return '🥉';
      case 'silver': return '🥈';
      case 'gold': return '🥇';
      case 'platinum': return '💎';
      case 'diamond': return '👑';
      default: return '🥉';
    }
  }

  PlayerRank addWin() {
    final newRating = rating + 20;
    return PlayerRank(
      rating: newRating,
      tier: _calcTier(newRating),
      wins: wins + 1,
      losses: losses,
    );
  }

  PlayerRank addLoss() {
    final newRating = (rating - 15).clamp(0, 99999);
    return PlayerRank(
      rating: newRating,
      tier: _calcTier(newRating),
      wins: wins,
      losses: losses + 1,
    );
  }

  static String _calcTier(int r) {
    if (r >= 2100) return 'diamond';
    if (r >= 1800) return 'platinum';
    if (r >= 1500) return 'gold';
    if (r >= 1200) return 'silver';
    return 'bronze';
  }
}

final playerRankProvider = StateProvider<PlayerRank>((ref) => const PlayerRank());

// シードカード属性フィルター
final attributeFilterProvider = StateProvider<String?>((ref) => null);
