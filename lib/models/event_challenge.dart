import 'package:cloud_firestore/cloud_firestore.dart';

/// イベントの種類
enum EventType {
  tournament,    // トーナメント
  challenge,     // チャレンジ
  gauntlet,      // ガントレット
  seasonal,      // シーズンイベント
}

/// チャレンジの種類
enum ChallengeType {
  winBattles,        // 〇勝する
  winStreak,         // 連勝を達成
  damage,            // ダメージを与える
  cardTypeWin,       // 特定カードタイプで勝つ
  attributeWin,      // 特定属性で勝つ
}

/// イベント
class GameEvent {
  final String id;
  final String title;
  final String description;
  final String? iconUrl;
  final DateTime startDate;
  final DateTime endDate;
  final EventType type;
  final String? bannerUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameEvent({
    required this.id,
    required this.title,
    required this.description,
    this.iconUrl,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.bannerUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// イベントが進行中か
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// イベントが開始予定か
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  /// イベントが終了したか
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// 残り時間（秒）
  int get secondsRemaining => endDate.difference(DateTime.now()).inSeconds.clamp(0, double.maxFinite.toInt());

  GameEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? iconUrl,
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    String? bannerUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'iconUrl': iconUrl,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'type': type.toString().split('.').last,
    'bannerUrl': bannerUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory GameEvent.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final typeStr = map['type'] as String? ?? 'challenge';
    final type = EventType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => EventType.challenge,
    );

    return GameEvent(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'],
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      type: type,
      bannerUrl: map['bannerUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// チャレンジ
class Challenge {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final ChallengeType type;
  final int target; // 達成目標（例：5勝、1000ダメージ）
  final int difficulty; // 難易度（1-10）
  final int gemReward;
  final int coinReward;
  final String? requiredAttribute; // 属性チャレンジの場合のみ
  final String? requiredCardType; // カードタイプチャレンジの場合のみ
  final DateTime createdAt;

  Challenge({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    this.difficulty = 5,
    this.gemReward = 10,
    this.coinReward = 100,
    this.requiredAttribute,
    this.requiredCardType,
    required this.createdAt,
  });

  Challenge copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    ChallengeType? type,
    int? target,
    int? difficulty,
    int? gemReward,
    int? coinReward,
    String? requiredAttribute,
    String? requiredCardType,
    DateTime? createdAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      target: target ?? this.target,
      difficulty: difficulty ?? this.difficulty,
      gemReward: gemReward ?? this.gemReward,
      coinReward: coinReward ?? this.coinReward,
      requiredAttribute: requiredAttribute ?? this.requiredAttribute,
      requiredCardType: requiredCardType ?? this.requiredCardType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'title': title,
    'description': description,
    'type': type.toString().split('.').last,
    'target': target,
    'difficulty': difficulty,
    'gemReward': gemReward,
    'coinReward': coinReward,
    'requiredAttribute': requiredAttribute,
    'requiredCardType': requiredCardType,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Challenge.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final typeStr = map['type'] as String? ?? 'winBattles';
    final type = ChallengeType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => ChallengeType.winBattles,
    );

    return Challenge(
      id: id,
      eventId: map['eventId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: type,
      target: map['target'] ?? 1,
      difficulty: map['difficulty'] ?? 5,
      gemReward: map['gemReward'] ?? 10,
      coinReward: map['coinReward'] ?? 100,
      requiredAttribute: map['requiredAttribute'],
      requiredCardType: map['requiredCardType'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// ユーザーのチャレンジ進捗
class UserChallengeProgress {
  final String eventId;
  final String challengeId;
  final int progress;
  final bool completed;
  final DateTime? completedAt;
  final bool rewardClaimed;
  final DateTime? claimedAt;
  final DateTime updatedAt;

  UserChallengeProgress({
    required this.eventId,
    required this.challengeId,
    this.progress = 0,
    this.completed = false,
    this.completedAt,
    this.rewardClaimed = false,
    this.claimedAt,
    required this.updatedAt,
  });

  /// 進捗率（0.0-1.0）
  double progressPercent(int target) => (progress / target).clamp(0.0, 1.0);

  UserChallengeProgress copyWith({
    String? eventId,
    String? challengeId,
    int? progress,
    bool? completed,
    DateTime? completedAt,
    bool? rewardClaimed,
    DateTime? claimedAt,
    DateTime? updatedAt,
  }) {
    return UserChallengeProgress(
      eventId: eventId ?? this.eventId,
      challengeId: challengeId ?? this.challengeId,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
      claimedAt: claimedAt ?? this.claimedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserChallengeProgress.fromMap(Map<String, dynamic> map) {
    return UserChallengeProgress(
      eventId: map['eventId'] ?? '',
      challengeId: map['challengeId'] ?? '',
      progress: map['progress'] ?? 0,
      completed: map['completed'] ?? false,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      rewardClaimed: map['rewardClaimed'] ?? false,
      claimedAt: (map['claimedAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'challengeId': challengeId,
    'progress': progress,
    'completed': completed,
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'rewardClaimed': rewardClaimed,
    'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
