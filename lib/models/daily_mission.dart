import 'package:cloud_firestore/cloud_firestore.dart';

enum MissionType { battle, win, winStreak, attributeWin, damage }

class DailyMission {
  final String id;
  final String userId;
  final MissionType type;
  final String description;
  final String emoji;
  final int target;
  final int progress;
  final int gemReward;
  final int coinReward;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool completed;
  final bool claimed;
  // attributeWin タイプのみ使用: 'joy' | 'anger' | 'sadness'。それ以外の type では null。
  final String? requiredAttribute;

  DailyMission({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.emoji,
    required this.target,
    this.progress = 0,
    required this.gemReward,
    required this.coinReward,
    required this.createdAt,
    required this.expiresAt,
    this.completed = false,
    this.claimed = false,
    this.requiredAttribute,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  double get progressPercent => (progress / target).clamp(0.0, 1.0);

  bool get canClaim => completed && !isExpired && !claimed;

  DailyMission copyWith({
    int? progress,
    bool? completed,
    bool? claimed,
  }) {
    return DailyMission(
      id: id,
      userId: userId,
      type: type,
      description: description,
      emoji: emoji,
      target: target,
      progress: progress ?? this.progress,
      gemReward: gemReward,
      coinReward: coinReward,
      createdAt: createdAt,
      expiresAt: expiresAt,
      completed: completed ?? this.completed,
      claimed: claimed ?? this.claimed,
      requiredAttribute: requiredAttribute,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'type': type.toString().split('.').last,
    'description': description,
    'emoji': emoji,
    'target': target,
    'progress': progress,
    'gemReward': gemReward,
    'coinReward': coinReward,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
    'completed': completed,
    'claimed': claimed,
    'requiredAttribute': requiredAttribute,
  };

  factory DailyMission.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'battle';
    final type = MissionType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => MissionType.battle,
    );

    return DailyMission(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: type,
      description: map['description'] ?? '',
      emoji: map['emoji'] ?? '⭐',
      target: map['target'] ?? 1,
      progress: map['progress'] ?? 0,
      gemReward: map['gemReward'] ?? 1,
      coinReward: map['coinReward'] ?? 100,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 1)),
      completed: map['completed'] ?? false,
      claimed: map['claimed'] ?? false,
      requiredAttribute: map['requiredAttribute'],
    );
  }
}

// ランダムなミッションを生成（バランス調整版）
List<DailyMission> generateDailyMissions(String userId) {
  final now = DateTime.now();
  final tomorrow = now.add(const Duration(days: 1));

  final attributes = ['joy', 'anger', 'sadness'];
  final randomAttr = attributes[DateTime.now().microsecond % 3];
  final attrEmoji = switch (randomAttr) {
    'joy' => '☀️',
    'anger' => '🔥',
    'sadness' => '🌙',
    _ => '⭐',
  };

  final missions = [
    // ミッション1: バトル（基本・易難度）
    DailyMission(
      id: 'mission_${now.day}_battle',
      userId: userId,
      type: MissionType.battle,
      description: '5回バトルに挑戦',
      emoji: '⚔️',
      target: 5,
      gemReward: 1,
      coinReward: 5,
      createdAt: now,
      expiresAt: tomorrow,
    ),

    // ミッション2: 勝利（中難度）
    DailyMission(
      id: 'mission_${now.day}_win',
      userId: userId,
      type: MissionType.win,
      description: '3回勝利する',
      emoji: '🎉',
      target: 3,
      gemReward: 1,
      coinReward: 10,
      createdAt: now,
      expiresAt: tomorrow,
    ),

    // ミッション3: 属性勝利（高難度）
    DailyMission(
      id: 'mission_${now.day}_attr',
      userId: userId,
      type: MissionType.attributeWin,
      description: '$randomAttr属性で2回勝利',
      emoji: attrEmoji,
      target: 2,
      gemReward: 2,
      coinReward: 15,
      createdAt: now,
      expiresAt: tomorrow,
      requiredAttribute: randomAttr,
    ),
  ];

  return missions;
}
