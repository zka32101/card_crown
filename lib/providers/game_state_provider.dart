import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_card.dart';
import '../data/seed_cards_data.dart';
import 'auth_provider.dart';

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
    imageUrl: sc.imageUrl,
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

// 連勝/PvPボーナスの1日あたり合計獲得上限（コイン）
// UI文言「1日上限🪙20」に対応する、実際に強制する側の定数
const int kDailyBonusCoinCap = 20;

// ジェムの使い道（機能ブースト）
// 連勝シールド: 敗北時に1個消費して連勝数のリセットを防ぐ
const int kStreakShieldGemCost = 3;
// 本日のデイリーボーナス上限を+20拡張する（1日に購入できる回数の上限あり）
const int kDailyBonusCapExtensionGemCost = 5;
const int kDailyBonusCapExtensionAmount = 20;
const int kDailyBonusCapExtensionMaxPerDay = 2;
// 本日のミッションセットを引き直す（未クレームの進捗は失われる）
const int kMissionRerollGemCost = 2;

// JST（UTC+9）基準の「今日」を yyyy-MM-dd 文字列で返す
// 端末のタイムゾーン設定に依存せず日次リセットの境界を揃えるため
String todayKeyJst() {
  final jstNow = DateTime.now().toUtc().add(const Duration(hours: 9));
  return '${jstNow.year.toString().padLeft(4, '0')}-'
      '${jstNow.month.toString().padLeft(2, '0')}-'
      '${jstNow.day.toString().padLeft(2, '0')}';
}

// ユーザーウォレット
class WalletState {
  final int totalPoints;
  final int todayPoints;
  final int todayWins;
  final int coinBalance;
  final int gemBalance;
  final int winStreak; // 連勝数
  final int dailyBonusCoinsEarned; // dailyBonusDate内で連勝/PvPボーナスにより獲得した累計コイン
  final String dailyBonusDate; // dailyBonusCoinsEarned が対応する日付（JST, yyyy-MM-dd）
  final int streakShieldCount; // 連勝シールドの所持数（ジェムで購入、敗北時に自動消費）
  final int dailyBonusCapExtra; // dailyBonusCapExtraDate内でジェム購入により拡張された当日の追加上限
  final String dailyBonusCapExtraDate; // dailyBonusCapExtra が対応する日付（JST, yyyy-MM-dd）

  const WalletState({
    this.totalPoints = 0,
    this.todayPoints = 0,
    this.todayWins = 0,
    this.coinBalance = 100,
    this.gemBalance = 0,
    this.winStreak = 0,
    this.dailyBonusCoinsEarned = 0,
    this.dailyBonusDate = '',
    this.streakShieldCount = 0,
    this.dailyBonusCapExtra = 0,
    this.dailyBonusCapExtraDate = '',
  });

  WalletState copyWith({
    int? totalPoints,
    int? todayPoints,
    int? todayWins,
    int? coinBalance,
    int? gemBalance,
    int? winStreak,
    int? dailyBonusCoinsEarned,
    String? dailyBonusDate,
    int? streakShieldCount,
    int? dailyBonusCapExtra,
    String? dailyBonusCapExtraDate,
  }) =>
    WalletState(
      totalPoints: totalPoints ?? this.totalPoints,
      todayPoints: todayPoints ?? this.todayPoints,
      todayWins: todayWins ?? this.todayWins,
      coinBalance: coinBalance ?? this.coinBalance,
      gemBalance: gemBalance ?? this.gemBalance,
      winStreak: winStreak ?? this.winStreak,
      dailyBonusCoinsEarned: dailyBonusCoinsEarned ?? this.dailyBonusCoinsEarned,
      dailyBonusDate: dailyBonusDate ?? this.dailyBonusDate,
      streakShieldCount: streakShieldCount ?? this.streakShieldCount,
      dailyBonusCapExtra: dailyBonusCapExtra ?? this.dailyBonusCapExtra,
      dailyBonusCapExtraDate: dailyBonusCapExtraDate ?? this.dailyBonusCapExtraDate,
    );

  /// 連勝ボーナス: 3連勝=+5, 5連勝=+10, 7連勝+=+15
  int get streakBonus {
    if (winStreak >= 7) return 15;
    if (winStreak >= 5) return 10;
    if (winStreak >= 3) return 5;
    return 0;
  }

  // 今日のジェム購入による拡張分（他の日の値は無視する）
  int get _todayCapExtra => dailyBonusCapExtraDate == todayKeyJst() ? dailyBonusCapExtra : 0;

  // 今日すでに使った分を差し引いた、残りの1日ボーナス上限（ジェム拡張分を含む）
  int get remainingDailyBonusCap {
    final earnedToday = dailyBonusDate == todayKeyJst() ? dailyBonusCoinsEarned : 0;
    final remaining = (kDailyBonusCoinCap + _todayCapExtra) - earnedToday;
    return remaining < 0 ? 0 : remaining;
  }

  // 本日すでにジェムで購入した上限拡張の回数（kDailyBonusCapExtensionMaxPerDayとの比較用）
  int get dailyBonusCapExtensionsUsedToday => _todayCapExtra ~/ kDailyBonusCapExtensionAmount;

  // 1日上限を考慮した上で、実際に獲得した後のウォレット状態を返す
  // 戻り値: (更新後のWalletState, 実際に加算されたコイン額)
  (WalletState, int) grantDailyBonus(int rawAmount) {
    if (rawAmount <= 0) return (this, 0);
    final today = todayKeyJst();
    final earnedToday = dailyBonusDate == today ? dailyBonusCoinsEarned : 0;
    final remaining = (kDailyBonusCoinCap + _todayCapExtra) - earnedToday;
    final granted = rawAmount > remaining ? (remaining < 0 ? 0 : remaining) : rawAmount;
    if (granted <= 0) return (this, 0);
    return (
      copyWith(
        coinBalance: coinBalance + granted,
        dailyBonusCoinsEarned: earnedToday + granted,
        dailyBonusDate: today,
      ),
      granted,
    );
  }

  // ジェムで本日のデイリーボーナス上限を+kDailyBonusCapExtensionAmountする。
  // 呼び出し側でgemBalance/dailyBonusCapExtensionsUsedTodayの上限チェック済みであること。
  WalletState extendDailyBonusCap() {
    final today = todayKeyJst();
    return copyWith(
      gemBalance: gemBalance - kDailyBonusCapExtensionGemCost,
      dailyBonusCapExtra: _todayCapExtra + kDailyBonusCapExtensionAmount,
      dailyBonusCapExtraDate: today,
    );
  }

  // ジェムで連勝シールドを1個購入する。呼び出し側でgemBalanceの上限チェック済みであること。
  WalletState buyStreakShield() => copyWith(
        gemBalance: gemBalance - kStreakShieldGemCost,
        streakShieldCount: streakShieldCount + 1,
      );

  Map<String, dynamic> toMap() => {
    'totalPoints': totalPoints,
    'todayPoints': todayPoints,
    'todayWins': todayWins,
    'coinBalance': coinBalance,
    'gemBalance': gemBalance,
    'winStreak': winStreak,
    'dailyBonusCoinsEarned': dailyBonusCoinsEarned,
    'dailyBonusDate': dailyBonusDate,
    'streakShieldCount': streakShieldCount,
    'dailyBonusCapExtra': dailyBonusCapExtra,
    'dailyBonusCapExtraDate': dailyBonusCapExtraDate,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory WalletState.fromMap(Map<String, dynamic> map) {
    return WalletState(
      totalPoints: map['totalPoints'] ?? 0,
      todayPoints: map['todayPoints'] ?? 0,
      todayWins: map['todayWins'] ?? 0,
      coinBalance: map['coinBalance'] ?? 100,
      gemBalance: map['gemBalance'] ?? 0,
      winStreak: map['winStreak'] ?? 0,
      dailyBonusCoinsEarned: map['dailyBonusCoinsEarned'] ?? 0,
      dailyBonusDate: map['dailyBonusDate'] ?? '',
      streakShieldCount: map['streakShieldCount'] ?? 0,
      dailyBonusCapExtra: map['dailyBonusCapExtra'] ?? 0,
      dailyBonusCapExtraDate: map['dailyBonusCapExtraDate'] ?? '',
    );
  }
}

// ローカル状態管理用（既存）
final walletProvider = StateProvider<WalletState>((ref) => const WalletState());

// Firestore統合版：ユーザーのウォレット
final userWalletProvider = FutureProvider<WalletState>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const WalletState();
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wallet')
        .doc('balance')
        .get();

    if (doc.exists) {
      return WalletState.fromMap(doc.data() ?? {});
    } else {
      // 初回作成
      final initialWallet = const WalletState();
      await doc.reference.set(initialWallet.toMap());
      return initialWallet;
    }
  } catch (e) {
    debugPrint('Error loading wallet: $e');
    return const WalletState();
  }
});

// 自分のPvPレーティング（pvpBattle Cloud Functionがusers/{uid}/rating/currentを更新する）
final myRatingProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 1000;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('rating')
        .doc('current')
        .get();
    return (doc.data()?['rating'] as int?) ?? 1000;
  } catch (e) {
    debugPrint('Error loading rating: $e');
    return 1000;
  }
});

// カード作成1回あたりのコイン消費量
const int kCardCreationCoinCost = 100;

// ウォレット更新関数
Future<void> updateWallet(String userId, WalletState wallet) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wallet')
        .doc('balance')
        .set(wallet.toMap(), SetOptions(merge: true));
  } catch (e) {
    debugPrint('Error updating wallet: $e');
  }
}

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
