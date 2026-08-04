import 'package:cloud_firestore/cloud_firestore.dart';

class CardListing {
  final String cardId;
  final String userId;
  final String creatorName;
  final bool isPublic;
  final int rentalCostPerDay;
  final int creatorSharePercent; // 70% 固定
  final DateTime createdAt;
  final Timestamp updatedAt;

  CardListing({
    required this.cardId,
    required this.userId,
    required this.creatorName,
    this.isPublic = false,
    this.rentalCostPerDay = 50,
    this.creatorSharePercent = 70,
    required this.createdAt,
    Timestamp? updatedAt,
  }) : updatedAt = updatedAt ?? Timestamp.now();

  Map<String, dynamic> toMap() => {
    'cardId': cardId,
    'userId': userId,
    'creatorName': creatorName,
    'isPublic': isPublic,
    'rentalCostPerDay': rentalCostPerDay,
    'creatorSharePercent': creatorSharePercent,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt,
  };

  factory CardListing.fromMap(Map<String, dynamic> map) {
    return CardListing(
      cardId: map['cardId'] ?? '',
      userId: map['userId'] ?? '',
      creatorName: map['creatorName'] ?? 'Unknown',
      isPublic: map['isPublic'] ?? false,
      rentalCostPerDay: map['rentalCostPerDay'] ?? 50,
      creatorSharePercent: map['creatorSharePercent'] ?? 70,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }
}

class RentalTransaction {
  final String id;
  final String cardId;
  final String cardName;
  final String renterId;
  final String creatorId;
  final int costPerDay;
  final int rentalDays;
  final int totalCost;
  final int creatorEarnings;
  final DateTime rentalStart;
  final DateTime rentalEnd;
  final bool isActive;
  final Timestamp createdAt;

  RentalTransaction({
    required this.id,
    required this.cardId,
    required this.cardName,
    required this.renterId,
    required this.creatorId,
    required this.costPerDay,
    this.rentalDays = 1,
    required this.totalCost,
    required this.creatorEarnings,
    required this.rentalStart,
    required this.rentalEnd,
    this.isActive = true,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  bool get isExpired => DateTime.now().isAfter(rentalEnd);

  Map<String, dynamic> toMap() => {
    'id': id,
    'cardId': cardId,
    'cardName': cardName,
    'renterId': renterId,
    'creatorId': creatorId,
    'costPerDay': costPerDay,
    'rentalDays': rentalDays,
    'totalCost': totalCost,
    'creatorEarnings': creatorEarnings,
    'rentalStart': Timestamp.fromDate(rentalStart),
    'rentalEnd': Timestamp.fromDate(rentalEnd),
    'isActive': isActive && !isExpired,
    'createdAt': createdAt,
  };

  factory RentalTransaction.fromMap(Map<String, dynamic> map) {
    return RentalTransaction(
      id: map['id'] ?? '',
      cardId: map['cardId'] ?? '',
      cardName: map['cardName'] ?? 'Unknown',
      renterId: map['renterId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      costPerDay: map['costPerDay'] ?? 50,
      rentalDays: map['rentalDays'] ?? 1,
      totalCost: map['totalCost'] ?? 50,
      creatorEarnings: map['creatorEarnings'] ?? 35,
      rentalStart: (map['rentalStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rentalEnd: (map['rentalEnd'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 1)),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] as Timestamp?,
    );
  }
}

class CardPopularityScore {
  final String cardId;
  final String cardName;
  final String creatorId;
  final String creatorName;
  final String attribute;
  final int cost;

  final int totalUsageCount;
  final int totalRentalCount;
  final int totalBattlesWithCard;
  final int totalWinsWithCard;
  final double winRate;
  final int totalEarnings;

  final double popularityScore;
  final int rank;
  final DateTime lastUpdated;

  CardPopularityScore({
    required this.cardId,
    required this.cardName,
    required this.creatorId,
    required this.creatorName,
    required this.attribute,
    required this.cost,
    required this.totalUsageCount,
    required this.totalRentalCount,
    required this.totalBattlesWithCard,
    required this.totalWinsWithCard,
    required this.winRate,
    required this.totalEarnings,
    required this.popularityScore,
    this.rank = 0,
    required this.lastUpdated,
  });

  // レンタル回数で進化するオーナーカードのレベル（0=無印, 1〜3=進化段階）
  // しきい値: 5回=Lv1, 15回=Lv2, 30回=Lv3
  int get evolutionLevel {
    if (totalRentalCount >= 30) return 3;
    if (totalRentalCount >= 15) return 2;
    if (totalRentalCount >= 5) return 1;
    return 0;
  }

  int get rentalsUntilNextEvolution {
    const thresholds = [5, 15, 30];
    for (final t in thresholds) {
      if (totalRentalCount < t) return t - totalRentalCount;
    }
    return 0; // 最大進化済み
  }

  String get evolutionBadge => switch (evolutionLevel) {
    1 => '✨Lv.1',
    2 => '💫Lv.2',
    3 => '🌟Lv.3',
    _ => '',
  };

  CardPopularityScore copyWith({int? totalRentalCount, int? totalEarnings}) {
    return CardPopularityScore(
      cardId: cardId,
      cardName: cardName,
      creatorId: creatorId,
      creatorName: creatorName,
      attribute: attribute,
      cost: cost,
      totalUsageCount: totalUsageCount,
      totalRentalCount: totalRentalCount ?? this.totalRentalCount,
      totalBattlesWithCard: totalBattlesWithCard,
      totalWinsWithCard: totalWinsWithCard,
      winRate: winRate,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      popularityScore: popularityScore,
      rank: rank,
      lastUpdated: lastUpdated,
    );
  }

  String get attributeEmoji => switch (attribute) {
    'joy' => '☀️',
    'anger' => '🔥',
    'sadness' => '🌙',
    _ => '⭐',
  };

  Map<String, dynamic> toMap() => {
    'cardId': cardId,
    'cardName': cardName,
    'creatorId': creatorId,
    'creatorName': creatorName,
    'attribute': attribute,
    'cost': cost,
    'totalUsageCount': totalUsageCount,
    'totalRentalCount': totalRentalCount,
    'totalBattlesWithCard': totalBattlesWithCard,
    'totalWinsWithCard': totalWinsWithCard,
    'winRate': winRate,
    'totalEarnings': totalEarnings,
    'popularityScore': popularityScore,
    'rank': rank,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
  };

  factory CardPopularityScore.fromMap(Map<String, dynamic> map) {
    final totalBattles = map['totalBattlesWithCard'] ?? 1;
    final totalWins = map['totalWinsWithCard'] ?? 0;
    final winRate = totalBattles > 0 ? totalWins / totalBattles : 0.0;

    // スコア計算：使用回数 × 勝率 × レンタル回数 + 収益 × 0.01
    final usageScore = (map['totalUsageCount'] ?? 0) * winRate;
    final rentalScore = (map['totalRentalCount'] ?? 0) * 0.5;
    final earningsScore = ((map['totalEarnings'] ?? 0) / 100).clamp(0.0, 100.0);
    final score = usageScore + rentalScore + earningsScore;

    return CardPopularityScore(
      cardId: map['cardId'] ?? '',
      cardName: map['cardName'] ?? 'Unknown',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? 'Unknown',
      attribute: map['attribute'] ?? 'joy',
      cost: map['cost'] ?? 1,
      totalUsageCount: map['totalUsageCount'] ?? 0,
      totalRentalCount: map['totalRentalCount'] ?? 0,
      totalBattlesWithCard: totalBattles,
      totalWinsWithCard: totalWins,
      winRate: winRate,
      totalEarnings: map['totalEarnings'] ?? 0,
      popularityScore: score,
      rank: map['rank'] ?? 0,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
