import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_request.freezed.dart';
part 'friend_request.g.dart';

/// Represents a friend request between two players
@freezed
class FriendRequest with _$FriendRequest {
  const factory FriendRequest({
    /// Unique ID for this request
    required String id,

    /// ID of the player who initiated the request
    required String senderId,

    /// Display name of the sender (cached)
    required String senderName,

    /// Sender's current rating (cached)
    required double senderRating,

    /// ID of the player receiving the request
    required String recipientId,

    /// Timestamp when the request was sent
    required DateTime sentAt,

    /// Optional personal message from sender
    String? message,

    /// Whether this request has been viewed by recipient
    @Default(false) bool viewedAt,

    /// Expiry timestamp - requests auto-expire after 30 days
    required DateTime expiresAt,
  }) = _FriendRequest;

  factory FriendRequest.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestFromJson(json);

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    return FriendRequest.fromJson({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    });
  }

  /// Check if this request has expired (30 days)
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Get time remaining for this request (in days)
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inDays;
  }
}

/// Enum for friend request status
enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
  expired,
  cancelled,
}

/// Response payload when accepting/rejecting a friend request
@freezed
class FriendRequestResponse with _$FriendRequestResponse {
  const factory FriendRequestResponse({
    /// The friend request ID
    required String requestId,

    /// Response status
    required FriendRequestStatus status,

    /// Timestamp of the response
    required DateTime respondedAt,

    /// Optional rejection reason
    String? reason,
  }) = _FriendRequestResponse;

  factory FriendRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestResponseFromJson(json);
}
