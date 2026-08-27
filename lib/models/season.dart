import 'package:cloud_firestore/cloud_firestore.dart';

/// シーズンの種類
enum SeasonType {
  spring,   // 春
  summer,   // 夏
  autumn,   // 秋
  winter,   // 冬
}

/// シーズンの属性ボーナス
class SeasonBonus {
  final String attribute; // 属性（喜/怒/哀）
  final double damageMultiplier; // ダメージ倍率
  final double coinBonusMultiplier; // コイン獲得倍率
  final double expBonusMultiplier; // 経験値倍率

  SeasonBonus({
    required this.attribute,
    this.damageMultiplier = 1.0,
    this.coinBonusMultiplier = 1.0,
    this.expBonusMultiplier = 1.0,
  });

  SeasonBonus copyWith({
    String? attribute,
    double? damageMultiplier,
    double? coinBonusMultiplier,
    double? expBonusMultiplier,
  }) {
    return SeasonBonus(
      attribute: attribute ?? this.attribute,
      damageMultiplier: damageMultiplier ?? this.damageMultiplier,
      coinBonusMultiplier: coinBonusMultiplier ?? this.coinBonusMultiplier,
      expBonusMultiplier: expBonusMultiplier ?? this.expBonusMultiplier,
    );
  }

  Map<String, dynamic> toMap() => {
    'attribute': attribute,
    'damageMultiplier': damageMultiplier,
    'coinBonusMultiplier': coinBonusMultiplier,
    'expBonusMultiplier': expBonusMultiplier,
  };

  factory SeasonBonus.fromMap(Map<String, dynamic> map) {
    return SeasonBonus(
      attribute: map['attribute'] ?? '',
      damageMultiplier: (map['damageMultiplier'] as num?)?.toDouble() ?? 1.0,
      coinBonusMultiplier: (map['coinBonusMultiplier'] as num?)?.toDouble() ?? 1.0,
      expBonusMultiplier: (map['expBonusMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// シーズン情報
class Season {
  final String id;
  final int number; // シーズン番号（例：Season 1）
  final SeasonType type;
  final String title; // シーズンタイトル
  final String description;
  final String? themeUrl; // テーマ画像URL
  final DateTime startDate;
  final DateTime endDate;
  final SeasonBonus seasonBonus; // 季節ボーナス（特定属性強化）
  final int maxRankTier; // 最大ランク層
  final DateTime createdAt;
  final DateTime updatedAt;

  Season({
    required this.id,
    required this.number,
    required this.type,
    required this.title,
    required this.description,
    this.themeUrl,
    required this.startDate,
    required this.endDate,
    required this.seasonBonus,
    this.maxRankTier = 10,
    required this.createdAt,
    required this.updatedAt,
  });

  /// シーズンが進行中か
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// シーズンが開始予定か
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  /// シーズンが終了したか
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// 残り日数
  int get daysRemaining {
    final diff = endDate.difference(DateTime.now());
    return diff.inDays.clamp(0, double.maxFinite.toInt());
  }

  /// 残り秒数
  int get secondsRemaining {
    return endDate.difference(DateTime.now()).inSeconds.clamp(0, double.maxFinite.toInt());
  }

  Season copyWith({
    String? id,
    int? number,
    SeasonType? type,
    String? title,
    String? description,
    String? themeUrl,
    DateTime? startDate,
    DateTime? endDate,
    SeasonBonus? seasonBonus,
    int? maxRankTier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Season(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      themeUrl: themeUrl ?? this.themeUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      seasonBonus: seasonBonus ?? this.seasonBonus,
      maxRankTier: maxRankTier ?? this.maxRankTier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'number': number,
    'type': type.toString().split('.').last,
    'title': title,
    'description': description,
    'themeUrl': themeUrl,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'seasonBonus': seasonBonus.toMap(),
    'maxRankTier': maxRankTier,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory Season.fromMap(Map<String, dynamic> map, {required String id}) {
    final typeStr = map['type'] as String? ?? 'spring';
    final type = SeasonType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => SeasonType.spring,
    );

    return Season(
      id: id,
      number: map['number'] ?? 1,
      type: type,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      themeUrl: map['themeUrl'],
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 90)),
      seasonBonus: SeasonBonus.fromMap(map['seasonBonus'] ?? {}),
      maxRankTier: map['maxRankTier'] ?? 10,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// ユーザーのシーズン進捗
class UserSeasonProgress {
  final String seasonId;
  final String userId;
  final int currentRank; // 現在のランク（1～maxRankTier）
  final int currentRankPoints; // ランク内のポイント（0～100）
  final int totalSeasonPoints; // シーズン総ポイント
  final int battlesWon; // シーズン中の勝利数
  final int battlesPlayed; // シーズン中の対戦数
  final int highestRank; // 最高到達ランク
  final List<String> unlockedRewards; // 解放済みリワード
  final DateTime joinedAt;
  final DateTime updatedAt;

  UserSeasonProgress({
    required this.seasonId,
    required this.userId,
    this.currentRank = 1,
    this.currentRankPoints = 0,
    this.totalSeasonPoints = 0,
    this.battlesWon = 0,
    this.battlesPlayed = 0,
    this.highestRank = 1,
    this.unlockedRewards = const [],
    required this.joinedAt,
    required this.updatedAt,
  });

  /// 勝率
  double get winRate => battlesPlayed == 0 ? 0.0 : (battlesWon / battlesPlayed).clamp(0.0, 1.0);

  /// ランク内の進捗（0.0-1.0）
  double get rankProgress => (currentRankPoints / 100).clamp(0.0, 1.0);

  UserSeasonProgress copyWith({
    String? seasonId,
    String? userId,
    int? currentRank,
    int? currentRankPoints,
    int? totalSeasonPoints,
    int? battlesWon,
    int? battlesPlayed,
    int? highestRank,
    List<String>? unlockedRewards,
    DateTime? joinedAt,
    DateTime? updatedAt,
  }) {
    return UserSeasonProgress(
      seasonId: seasonId ?? this.seasonId,
      userId: userId ?? this.userId,
      currentRank: currentRank ?? this.currentRank,
      currentRankPoints: currentRankPoints ?? this.currentRankPoints,
      totalSeasonPoints: totalSeasonPoints ?? this.totalSeasonPoints,
      battlesWon: battlesWon ?? this.battlesWon,
      battlesPlayed: battlesPlayed ?? this.battlesPlayed,
      highestRank: highestRank ?? this.highestRank,
      unlockedRewards: unlockedRewards ?? this.unlockedRewards,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'seasonId': seasonId,
    'userId': userId,
    'currentRank': currentRank,
    'currentRankPoints': currentRankPoints,
    'totalSeasonPoints': totalSeasonPoints,
    'battlesWon': battlesWon,
    'battlesPlayed': battlesPlayed,
    'highestRank': highestRank,
    'unlockedRewards': unlockedRewards,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory UserSeasonProgress.fromMap(Map<String, dynamic> map) {
    return UserSeasonProgress(
      seasonId: map['seasonId'] ?? '',
      userId: map['userId'] ?? '',
      currentRank: map['currentRank'] ?? 1,
      currentRankPoints: map['currentRankPoints'] ?? 0,
      totalSeasonPoints: map['totalSeasonPoints'] ?? 0,
      battlesWon: map['battlesWon'] ?? 0,
      battlesPlayed: map['battlesPlayed'] ?? 0,
      highestRank: map['highestRank'] ?? 1,
      unlockedRewards: List<String>.from(map['unlockedRewards'] ?? []),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// シーズンランクリワード
class SeasonRankReward {
  final String id;
  final String seasonId;
  final int rankTier; // ランク階層（1～maxRankTier）
  final String title; // リワード名
  final String description;
  final int gemsReward; // ジェム報酬
  final int coinsReward; // コイン報酬
  final String? badgeUrl; // バッジURL
  final String? cardMaterialUrl; // カードマテリアルURL
  final DateTime createdAt;

  SeasonRankReward({
    required this.id,
    required this.seasonId,
    required this.rankTier,
    required this.title,
    required this.description,
    this.gemsReward = 0,
    this.coinsReward = 0,
    this.badgeUrl,
    this.cardMaterialUrl,
    required this.createdAt,
  });

  SeasonRankReward copyWith({
    String? id,
    String? seasonId,
    int? rankTier,
    String? title,
    String? description,
    int? gemsReward,
    int? coinsReward,
    String? badgeUrl,
    String? cardMaterialUrl,
    DateTime? createdAt,
  }) {
    return SeasonRankReward(
      id: id ?? this.id,
      seasonId: seasonId ?? this.seasonId,
      rankTier: rankTier ?? this.rankTier,
      title: title ?? this.title,
      description: description ?? this.description,
      gemsReward: gemsReward ?? this.gemsReward,
      coinsReward: coinsReward ?? this.coinsReward,
      badgeUrl: badgeUrl ?? this.badgeUrl,
      cardMaterialUrl: cardMaterialUrl ?? this.cardMaterialUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'seasonId': seasonId,
    'rankTier': rankTier,
    'title': title,
    'description': description,
    'gemsReward': gemsReward,
    'coinsReward': coinsReward,
    'badgeUrl': badgeUrl,
    'cardMaterialUrl': cardMaterialUrl,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory SeasonRankReward.fromMap(Map<String, dynamic> map, {required String id}) {
    return SeasonRankReward(
      id: id,
      seasonId: map['seasonId'] ?? '',
      rankTier: map['rankTier'] ?? 1,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      gemsReward: map['gemsReward'] ?? 0,
      coinsReward: map['coinsReward'] ?? 0,
      badgeUrl: map['badgeUrl'],
      cardMaterialUrl: map['cardMaterialUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
