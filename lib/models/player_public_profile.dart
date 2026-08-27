import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_public_profile.freezed.dart';
part 'player_public_profile.g.dart';

/// Public-facing player profile information visible to friends and leaderboard
@freezed
class PlayerPublicProfile with _$PlayerPublicProfile {
  const factory PlayerPublicProfile({
    /// Player's unique ID
    required String playerId,

    /// Player's display name
    required String displayName,

    /// Player's current ELO rating
    required double rating,

    /// Player's tier rank (1-10)
    required int tier,

    /// Player's tier name (Rookie, Veteran, etc.)
    required String tierName,

    /// Total number of battles
    @Default(0) int battleCount,

    /// Total number of wins
    @Default(0) int wins,

    /// Player's current win rate percentage
    @Default(0.0) double winRate,

    /// Current win streak
    @Default(0) int currentStreak,

    /// Best win streak achieved
    @Default(0) int bestStreak,

    /// Favorite kingdom (card type preference)
    String? favoriteKingdom,

    /// Player's profile avatar URL
    String? avatarUrl,

    /// Short bio/status message
    String? bio,

    /// Whether profile is public (vs private to friends only)
    @Default(true) bool isPublic,

    /// Timestamp of profile last update
    required DateTime lastUpdatedAt,

    /// Timestamp of last battle
    DateTime? lastBattleAt,

    /// Player's country/region (optional)
    String? region,

    /// Badge/achievement IDs earned
    @Default([]) List<String> badges,

    /// Number of current friends
    @Default(0) int friendCount,

    /// Player's join date
    required DateTime joinedAt,
  }) = _PlayerPublicProfile;

  factory PlayerPublicProfile.fromJson(Map<String, dynamic> json) =>
      _$PlayerPublicProfileFromJson(json);

  factory PlayerPublicProfile.fromFirestore(DocumentSnapshot doc) {
    return PlayerPublicProfile.fromJson({
      ...doc.data() as Map<String, dynamic>,
      'playerId': doc.id,
    });
  }

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
}

/// Compact profile for friend list display
@freezed
class CompactPlayerProfile with _$CompactPlayerProfile {
  const factory CompactPlayerProfile({
    required String playerId,
    required String displayName,
    required double rating,
    required int tier,
    String? avatarUrl,
    @Default(0.0) double winRate,
    DateTime? lastBattleAt,
  }) = _CompactPlayerProfile;

  factory CompactPlayerProfile.fromJson(Map<String, dynamic> json) =>
      _$CompactPlayerProfileFromJson(json);

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
}
