import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a friend relationship between two players
class Friend {
  /// The ID of the friend user
  final String friendId;

  /// The display name of the friend (cached for UI)
  final String friendName;

  /// The rating/ELO of the friend (cached for quick display)
  final double friendRating;

  /// The tier rank of the friend (cached for display)
  final int friendTier;

  /// Timestamp when this friend relationship was established
  final DateTime addedAt;

  /// Last time the friend was online/active (for presence indicator)
  final DateTime? lastSeenAt;

  /// Optional friend group/tag (e.g., "IRL Friends", "Discord Squad")
  final String? group;

  /// Whether notifications are enabled for this friend
  final bool notificationsEnabled;

  /// Custom alias for this friend (if user chooses to rename)
  final String? customAlias;

  /// Friend's total battles for quick stat reference
  final int friendBattleCount;

  /// Friend's win rate for quick stat reference
  final double friendWinRate;

  const Friend({
    required this.friendId,
    required this.friendName,
    required this.friendRating,
    required this.friendTier,
    required this.addedAt,
    this.lastSeenAt,
    this.group,
    this.notificationsEnabled = true,
    this.customAlias,
    this.friendBattleCount = 0,
    this.friendWinRate = 0.0,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendId: json['friendId'] as String,
      friendName: json['friendName'] as String,
      friendRating: (json['friendRating'] as num).toDouble(),
      friendTier: json['friendTier'] as int,
      addedAt: _parseDateTime(json['addedAt']),
      lastSeenAt: json['lastSeenAt'] != null ? _parseDateTime(json['lastSeenAt']) : null,
      group: json['group'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      customAlias: json['customAlias'] as String?,
      friendBattleCount: json['friendBattleCount'] as int? ?? 0,
      friendWinRate: (json['friendWinRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    return Friend.fromJson({...doc.data() as Map<String, dynamic>});
  }

  Map<String, dynamic> toJson() => {
    'friendId': friendId,
    'friendName': friendName,
    'friendRating': friendRating,
    'friendTier': friendTier,
    'addedAt': addedAt,
    'lastSeenAt': lastSeenAt,
    'group': group,
    'notificationsEnabled': notificationsEnabled,
    'customAlias': customAlias,
    'friendBattleCount': friendBattleCount,
    'friendWinRate': friendWinRate,
  };

  @override
  String toString() => 'Friend($friendId: $friendName)';
}

/// Statistics summary for a friend relationship
class FriendStats {
  /// Number of battles won against this friend
  final int winsAgainst;

  /// Number of battles lost against this friend
  final int lossesAgainst;

  /// Total battles with this friend
  final int totalBattles;

  /// Last battle timestamp with this friend
  final DateTime? lastBattleAt;

  /// Win rate vs this specific friend
  final double winRateAgainst;

  const FriendStats({
    this.winsAgainst = 0,
    this.lossesAgainst = 0,
    this.totalBattles = 0,
    this.lastBattleAt,
    this.winRateAgainst = 0.0,
  });

  factory FriendStats.fromJson(Map<String, dynamic> json) {
    return FriendStats(
      winsAgainst: json['winsAgainst'] as int? ?? 0,
      lossesAgainst: json['lossesAgainst'] as int? ?? 0,
      totalBattles: json['totalBattles'] as int? ?? 0,
      lastBattleAt: json['lastBattleAt'] != null ? _parseDateTime(json['lastBattleAt']) : null,
      winRateAgainst: (json['winRateAgainst'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory FriendStats.fromFirestore(DocumentSnapshot doc) {
    return FriendStats.fromJson(doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
    'winsAgainst': winsAgainst,
    'lossesAgainst': lossesAgainst,
    'totalBattles': totalBattles,
    'lastBattleAt': lastBattleAt,
    'winRateAgainst': winRateAgainst,
  };

  /// Calculate win rate percentage
  double get winRatePercentage {
    if (totalBattles == 0) return 0.0;
    return (winsAgainst / totalBattles) * 100;
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date format: $value');
}
