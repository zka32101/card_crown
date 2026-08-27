import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date format: $value');
}

/// Public-facing player profile information visible to friends and leaderboard
class PlayerPublicProfile {
  /// Player's unique ID
  final String playerId;

  /// Player's display name
  final String displayName;

  /// Player's current ELO rating
  final double rating;

  /// Player's tier rank (1-10)
  final int tier;

  /// Player's tier name (Rookie, Veteran, etc.)
  final String tierName;

  /// Total number of battles
  final int battleCount;

  /// Total number of wins
  final int wins;

  /// Player's current win rate percentage
  final double winRate;

  /// Current win streak
  final int currentStreak;

  /// Best win streak achieved
  final int bestStreak;

  /// Favorite kingdom (card type preference)
  final String? favoriteKingdom;

  /// Player's profile avatar URL
  final String? avatarUrl;

  /// Short bio/status message
  final String? bio;

  /// Whether profile is public (vs private to friends only)
  final bool isPublic;

  /// Timestamp of profile last update
  final DateTime lastUpdatedAt;

  /// Timestamp of last battle
  final DateTime? lastBattleAt;

  /// Player's country/region (optional)
  final String? region;

  /// Badge/achievement IDs earned
  final List<String> badges;

  /// Number of current friends
  final int friendCount;

  /// Player's join date
  final DateTime joinedAt;

  const PlayerPublicProfile({
    required this.playerId,
    required this.displayName,
    required this.rating,
    required this.tier,
    required this.tierName,
    this.battleCount = 0,
    this.wins = 0,
    this.winRate = 0.0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.favoriteKingdom,
    this.avatarUrl,
    this.bio,
    this.isPublic = true,
    required this.lastUpdatedAt,
    this.lastBattleAt,
    this.region,
    this.badges = const [],
    this.friendCount = 0,
    required this.joinedAt,
  });

  factory PlayerPublicProfile.fromJson(Map<String, dynamic> json) {
    return PlayerPublicProfile(
      playerId: json['playerId'] as String,
      displayName: json['displayName'] as String,
      rating: (json['rating'] as num).toDouble(),
      tier: json['tier'] as int,
      tierName: json['tierName'] as String,
      battleCount: json['battleCount'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      favoriteKingdom: json['favoriteKingdom'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      lastUpdatedAt: _parseDateTime(json['lastUpdatedAt']),
      lastBattleAt: json['lastBattleAt'] != null ? _parseDateTime(json['lastBattleAt']) : null,
      region: json['region'] as String?,
      badges: (json['badges'] as List?)?.cast<String>() ?? [],
      friendCount: json['friendCount'] as int? ?? 0,
      joinedAt: _parseDateTime(json['joinedAt']),
    );
  }

  factory PlayerPublicProfile.fromFirestore(DocumentSnapshot doc) {
    return PlayerPublicProfile.fromJson({
      ...doc.data() as Map<String, dynamic>,
      'playerId': doc.id,
    });
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'displayName': displayName,
    'rating': rating,
    'tier': tier,
    'tierName': tierName,
    'battleCount': battleCount,
    'wins': wins,
    'winRate': winRate,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'favoriteKingdom': favoriteKingdom,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'isPublic': isPublic,
    'lastUpdatedAt': lastUpdatedAt,
    'lastBattleAt': lastBattleAt,
    'region': region,
    'badges': badges,
    'friendCount': friendCount,
    'joinedAt': joinedAt,
  };

  /// Check if player is currently online (last seen within 5 minutes)
  bool get isOnline {
    if (lastBattleAt == null) return false;
    return DateTime.now().difference(lastBattleAt!).inMinutes < 5;
  }

  /// Get rating tier description
  String get tierDescription {
    return switch (tier) {
      1 => 'Rookie',
      2 => 'Novice',
      3 => 'Apprentice',
      4 => 'Adept',
      5 => 'Expert',
      6 => 'Master',
      7 => 'Grandmaster',
      8 => 'Sage',
      9 => 'Legend',
      10 => 'Ascendant',
      _ => 'Unknown',
    };
  }

  /// Get rating tier color for UI
  String get tierColor {
    return switch (tier) {
      1 => '#888888', // Gray - Rookie
      2 => '#4CAF50', // Green - Novice
      3 => '#2196F3', // Blue - Apprentice
      4 => '#673AB7', // Purple - Adept
      5 => '#FF9800', // Orange - Expert
      6 => '#F44336', // Red - Master
      7 => '#E91E63', // Pink - Grandmaster
      8 => '#FFD700', // Gold - Sage
      9 => '#00BCD4', // Cyan - Legend
      10 => '#9C27B0', // Deep Purple - Ascendant
      _ => '#000000',
    };
  }

  @override
  String toString() => 'PlayerPublicProfile($playerId: $displayName)';
}

/// Compact profile for friend list display
class CompactPlayerProfile {
  final String playerId;
  final String displayName;
  final double rating;
  final int tier;
  final String? avatarUrl;
  final double winRate;
  final DateTime? lastBattleAt;

  const CompactPlayerProfile({
    required this.playerId,
    required this.displayName,
    required this.rating,
    required this.tier,
    this.avatarUrl,
    this.winRate = 0.0,
    this.lastBattleAt,
  });

  factory CompactPlayerProfile.fromJson(Map<String, dynamic> json) {
    return CompactPlayerProfile(
      playerId: json['playerId'] as String,
      displayName: json['displayName'] as String,
      rating: (json['rating'] as num).toDouble(),
      tier: json['tier'] as int,
      avatarUrl: json['avatarUrl'] as String?,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      lastBattleAt: json['lastBattleAt'] != null ? _parseDateTime(json['lastBattleAt']) : null,
    );
  }

  /// Convert from full profile to compact
  factory CompactPlayerProfile.fromPublicProfile(
    PlayerPublicProfile profile,
  ) {
    return CompactPlayerProfile(
      playerId: profile.playerId,
      displayName: profile.displayName,
      rating: profile.rating,
      tier: profile.tier,
      avatarUrl: profile.avatarUrl,
      winRate: profile.winRate,
      lastBattleAt: profile.lastBattleAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'displayName': displayName,
    'rating': rating,
    'tier': tier,
    'avatarUrl': avatarUrl,
    'winRate': winRate,
    'lastBattleAt': lastBattleAt,
  };

  @override
  String toString() => 'CompactPlayerProfile($playerId: $displayName)';
}
