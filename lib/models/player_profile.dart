import 'package:cloud_firestore/cloud_firestore.dart';

// プレイヤーの総合統計情報
class PlayerStats {
  final int totalBattles;
  final int totalWins;
  final int currentRating;
  final int winStreak;
  final int maxWinStreak;
  final int lossStreak;
  final int maxLossStreak;
  final Timestamp lastBattleAt;
  final Timestamp updatedAt;

  PlayerStats({
    required this.totalBattles,
    required this.totalWins,
    required this.currentRating,
    required this.winStreak,
    required this.maxWinStreak,
    required this.lossStreak,
    required this.maxLossStreak,
    required this.lastBattleAt,
    required this.updatedAt,
  });

  factory PlayerStats.empty() {
    final now = Timestamp.now();
    return PlayerStats(
      totalBattles: 0,
      totalWins: 0,
      currentRating: 1200,
      winStreak: 0,
      maxWinStreak: 0,
      lossStreak: 0,
      maxLossStreak: 0,
      lastBattleAt: now,
      updatedAt: now,
    );
  }

  factory PlayerStats.fromFirestore(Map<String, dynamic> data) {
    return PlayerStats(
      totalBattles: (data['totalBattles'] as int?) ?? 0,
      totalWins: (data['totalWins'] as int?) ?? 0,
      currentRating: (data['currentRating'] as int?) ?? 1200,
      winStreak: (data['winStreak'] as int?) ?? 0,
      maxWinStreak: (data['maxWinStreak'] as int?) ?? 0,
      lossStreak: (data['lossStreak'] as int?) ?? 0,
      maxLossStreak: (data['maxLossStreak'] as int?) ?? 0,
      lastBattleAt: (data['lastBattleAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: (data['updatedAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  // 勝率を計算（%で返す）
  double get winRate {
    if (totalBattles == 0) return 0.0;
    return (totalWins / totalBattles) * 100;
  }

  // 平均スコア（1バトルあたりの平均レーティング獲得）
  double get averageScore {
    if (totalBattles == 0) return 0.0;
    return (currentRating - 1200) / totalBattles; // 初期値1200からの変化量
  }
}

// プレイヤープロフィール（表示用）
class PlayerProfile {
  final String userId;
  final String displayName;
  final PlayerStats stats;
  final Timestamp joinedAt;
  final String tier; // Bronze, Silver, Gold, Platinum, Diamond, Master, Grandmaster

  PlayerProfile({
    required this.userId,
    required this.displayName,
    required this.stats,
    required this.joinedAt,
    required this.tier,
  });

  // プロフィール表示用の情報をまとめる
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'tier': tier,
      'rating': stats.currentRating,
      'totalBattles': stats.totalBattles,
      'totalWins': stats.totalWins,
      'winRate': stats.winRate,
      'maxWinStreak': stats.maxWinStreak,
      'joinedAt': joinedAt,
    };
  }
}

// ランキング表示用のデータ
class RankingEntry {
  final int rank;
  final String userId;
  final String displayName;
  final int rating;
  final int totalWins;
  final int totalBattles;
  final String tier;

  RankingEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.rating,
    required this.totalWins,
    required this.totalBattles,
    required this.tier,
  });

  double get winRate {
    if (totalBattles == 0) return 0.0;
    return (totalWins / totalBattles) * 100;
  }

  factory RankingEntry.fromFirestore(int rank, Map<String, dynamic> data) {
    final rating = (data['currentRating'] as int?) ?? 1200;
    return RankingEntry(
      rank: rank,
      userId: data['userId'] as String? ?? '',
      displayName: 'Player-${(data['userId'] as String? ?? '').substring(0, 6)}',
      rating: rating,
      totalWins: (data['totalWins'] as int?) ?? 0,
      totalBattles: (data['totalBattles'] as int?) ?? 0,
      tier: _calculateTier(rating),
    );
  }
}

String _calculateTier(int rating) {
  if (rating >= 2000) return 'Grandmaster';
  if (rating >= 1800) return 'Master';
  if (rating >= 1600) return 'Diamond';
  if (rating >= 1400) return 'Platinum';
  if (rating >= 1200) return 'Gold';
  if (rating >= 1000) return 'Silver';
  return 'Bronze';
}
