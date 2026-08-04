import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/card_rental.dart';
import '../models/user_card.dart';
import 'game_state_provider.dart';

// クリエイター取り分（レンタル料の70%）
const int kRentalCreatorSharePercent = 70;

// ユーザーが所有するカード（貸し出し設定可能）
final userOwnedCardsProvider = StateProvider<List<PlayCard>>((ref) {
  // 本実装では Firestore から取得
  return [];
});

// ユーザーのカード公開設定
final userCardListingsProvider = StateProvider<List<CardListing>>((ref) {
  // 本実装では Firestore から取得
  return [];
});

// 人気度ランキング（TOP 100）
final popularCardsTOP100Provider = StateProvider<List<CardPopularityScore>>((ref) {
  // ダミーデータ
  return _generateDummyPopularCards();
});

// 現在レンタル中のカード
final activeRentalsProvider = StateProvider<List<RentalTransaction>>((ref) {
  // 本実装では Firestore から取得
  return [];
});

// ユーザーのレンタル収益
final userRentalEarningsProvider = StateProvider<int>((ref) {
  final listings = ref.watch(userCardListingsProvider);
  // 本実装では Firestore から集計
  return listings.length * 50; // ダミー
});

// 公開カードを ON/OFF
void toggleCardPublic(
  WidgetRef ref,
  String cardId,
  bool isPublic,
  String creatorName,
) {
  final listings = ref.read(userCardListingsProvider);
  final existing = listings.where((l) => l.cardId == cardId).firstOrNull;

  if (existing != null) {
    final updated = listings.map((l) {
      if (l.cardId == cardId) {
        return CardListing(
          cardId: l.cardId,
          userId: l.userId,
          creatorName: creatorName,
          isPublic: isPublic,
          rentalCostPerDay: l.rentalCostPerDay,
          creatorSharePercent: l.creatorSharePercent,
          createdAt: l.createdAt,
        );
      }
      return l;
    }).toList();
    ref.read(userCardListingsProvider.notifier).state = updated;
  } else {
    listings.add(CardListing(
      cardId: cardId,
      userId: 'user_placeholder',
      creatorName: creatorName,
      isPublic: isPublic,
      rentalCostPerDay: 50,
      creatorSharePercent: 70,
      createdAt: DateTime.now(),
    ));
    ref.read(userCardListingsProvider.notifier).state = [...listings];
  }
}

// カードをレンタル（借り手のコインを減算し、収益の70%をクリエイターに計上）
// totalCost はUIが提示した実際の表示価格（レンタル期間ごとの料金プラン）をそのまま渡す。
// card.cost（マナコスト）とは無関係 — ここで再計算すると表示価格と乖離するため注意。
// 残高不足の場合は何もせず false を返す
bool rentCard(
  WidgetRef ref,
  CardPopularityScore card,
  String renterId,
  int rentalDays,
  int totalCost,
) {
  final wallet = ref.read(walletProvider);

  if (wallet.coinBalance < totalCost) return false;

  final earnings = (totalCost * kRentalCreatorSharePercent) ~/ 100;

  final transaction = RentalTransaction(
    id: '${DateTime.now().millisecondsSinceEpoch}',
    cardId: card.cardId,
    cardName: card.cardName,
    renterId: renterId,
    creatorId: card.creatorId,
    costPerDay: (totalCost / rentalDays).round(),
    rentalDays: rentalDays,
    totalCost: totalCost,
    creatorEarnings: earnings,
    rentalStart: DateTime.now(),
    rentalEnd: DateTime.now().add(Duration(days: rentalDays)),
  );

  ref.read(walletProvider.notifier).state = wallet.copyWith(
    coinBalance: wallet.coinBalance - totalCost,
  );

  final rentals = ref.read(activeRentalsProvider);
  ref.read(activeRentalsProvider.notifier).state = [...rentals, transaction];

  // レンタル回数を加算 → 一定回数でオーナーのカードが進化（使い込み進化）
  final topCards = ref.read(popularCardsTOP100Provider);
  ref.read(popularCardsTOP100Provider.notifier).state = topCards.map((c) {
    if (c.cardId != card.cardId) return c;
    return c.copyWith(
      totalRentalCount: c.totalRentalCount + 1,
      totalEarnings: c.totalEarnings + earnings,
    );
  }).toList();

  return true;
}

List<CardPopularityScore> _generateDummyPopularCards() {
  final cards = [
    ('joy_c5_001', '太陽神', 'user_1', 'SunMaster', 'joy', 5, 250, 85, 120, 95),
    ('anger_c4_001', '火の帝王', 'user_2', 'FireKing', 'anger', 4, 180, 72, 95, 78),
    ('sadness_c3_001', '悲しみの王', 'user_3', 'SorrowLord', 'sadness', 3, 160, 65, 85, 55),
    ('joy_c4_001', '黄金の皇帝', 'user_4', 'GoldEmperor', 'joy', 4, 140, 60, 78, 48),
    ('anger_c3_001', '怒りの王', 'user_5', 'AngerKing', 'anger', 3, 120, 55, 68, 45),
  ];

  return cards.asMap().entries.map((e) {
    final (cardId, name, creatorId, creatorName, attr, cost, usage, rental, battles, wins) = e.value;
    final winRate = wins / battles;
    // 人気度スコア: 使用×勝率 + レンタル×1 + 収益×0.05
    final earnings = rental * 35;
    final score = (usage * winRate) + (rental * 1.0) + (earnings * 0.05);

    return CardPopularityScore(
      cardId: cardId,
      cardName: name,
      creatorId: creatorId,
      creatorName: creatorName,
      attribute: attr,
      cost: cost,
      totalUsageCount: usage,
      totalRentalCount: rental,
      totalBattlesWithCard: battles,
      totalWinsWithCard: wins,
      winRate: winRate,
      totalEarnings: earnings,
      popularityScore: score,
      rank: e.key + 1,
      lastUpdated: DateTime.now(),
    );
  }).toList();
}
