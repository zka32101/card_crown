import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend.freezed.dart';
part 'friend.g.dart';

/// Represents a friend relationship between two players
@freezed
class Friend with _$Friend {
  const factory Friend({
    /// The ID of the friend user
    required String friendId,

    /// The display name of the friend (cached for UI)
    required String friendName,

    /// The rating/ELO of the friend (cached for quick display)
    required double friendRating,

    /// The tier rank of the friend (cached for display)
    required int friendTier,

    /// Timestamp when this friend relationship was established
    required DateTime addedAt,

    /// Last time the friend was online/active (for presence indicator)
    DateTime? lastSeenAt,

    /// Optional friend group/tag (e.g., "IRL Friends", "Discord Squad")
    String? group,

    /// Whether notifications are enabled for this friend
    @Default(true) bool notificationsEnabled,

    /// Custom alias for this friend (if user chooses to rename)
    String? customAlias,

    /// Friend's total battles for quick stat reference
    @Default(0) int friendBattleCount,

    /// Friend's win rate for quick stat reference
    @Default(0.0) double friendWinRate,
  }) = _Friend;

  factory Friend.fromJson(Map<String, dynamic> json) =>
      _$FriendFromJson(json);

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    return Friend.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }
}

/// Statistics summary for a friend relationship
@freezed
class FriendStats with _$FriendStats {
  const factory FriendStats({
    /// Number of battles won against this friend
    @Default(0) int winsAgainst,

    /// Number of battles lost against this friend
    @Default(0) int lossesAgainst,

    /// Total battles with this friend
    @Default(0) int totalBattles,

    /// Last battle timestamp with this friend
    DateTime? lastBattleAt,

    /// Win rate vs this specific friend
    @Default(0.0) double winRateAgainst,
  }) = _FriendStats;

  factory FriendStats.fromJson(Map<String, dynamic> json) =>
      _$FriendStatsFromJson(json);

  factory FriendStats.fromFirestore(DocumentSnapshot doc) {
    return FriendStats.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Calculate win rate percentage
  double get winRatePercentage {
    if (totalBattles == 0) return 0.0;
    return (winsAgainst / totalBattles) * 100;
  }
}
