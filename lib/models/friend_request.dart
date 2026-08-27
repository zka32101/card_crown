import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date format: $value');
}

/// Represents a friend request between two players
class FriendRequest {
  /// Unique ID for this request
  final String id;

  /// ID of the player who initiated the request
  final String senderId;

  /// Display name of the sender (cached)
  final String senderName;

  /// Sender's current rating (cached)
  final double senderRating;

  /// ID of the player receiving the request
  final String recipientId;

  /// Timestamp when the request was sent
  final DateTime sentAt;

  /// Optional personal message from sender
  final String? message;

  /// Whether this request has been viewed by recipient
  final bool viewedAt;

  /// Expiry timestamp - requests auto-expire after 30 days
  final DateTime expiresAt;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRating,
    required this.recipientId,
    required this.sentAt,
    this.message,
    this.viewedAt = false,
    required this.expiresAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderRating: (json['senderRating'] as num).toDouble(),
      recipientId: json['recipientId'] as String,
      sentAt: _parseDateTime(json['sentAt']),
      message: json['message'] as String?,
      viewedAt: json['viewedAt'] as bool? ?? false,
      expiresAt: _parseDateTime(json['expiresAt']),
    );
  }

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    return FriendRequest.fromJson({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    });
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'senderRating': senderRating,
    'recipientId': recipientId,
    'sentAt': sentAt,
    'message': message,
    'viewedAt': viewedAt,
    'expiresAt': expiresAt,
  };

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

  @override
  String toString() => 'FriendRequest($id: $senderId -> $recipientId)';
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
class FriendRequestResponse {
  /// The friend request ID
  final String requestId;

  /// Response status
  final FriendRequestStatus status;

  /// Timestamp of the response
  final DateTime respondedAt;

  /// Optional rejection reason
  final String? reason;

  const FriendRequestResponse({
    required this.requestId,
    required this.status,
    required this.respondedAt,
    this.reason,
  });

  factory FriendRequestResponse.fromJson(Map<String, dynamic> json) {
    return FriendRequestResponse(
      requestId: json['requestId'] as String,
      status: FriendRequestStatus.values.byName(json['status'] as String),
      respondedAt: _parseDateTime(json['respondedAt']),
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'status': status.name,
    'respondedAt': respondedAt,
    'reason': reason,
  };
}
