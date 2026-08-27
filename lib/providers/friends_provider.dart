import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:card_rivals/models/friend.dart';
import 'package:card_rivals/models/friend_request.dart';
import 'package:card_rivals/models/player_public_profile.dart';

final firestore = FirebaseFirestore.instance;

/// Get current user ID from auth (assumes auth provider exists)
/// This should be connected to your existing auth provider
final currentUserIdProvider = FutureProvider<String>((ref) async {
  // TODO: Connect to your existing auth provider
  // For now, return a placeholder
  return 'current-user-id';
});

/// Stream of current user's friends list
final friendsListProvider =
    StreamProvider.autoDispose.family<List<Friend>, String>((ref, userId) {
  return firestore
      .collection('users')
      .doc(userId)
      .collection('friends')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Friend.fromFirestore(doc))
        .toList();
  });
});

/// Get friends count for a user
final friendsCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, userId) async {
  final snapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('friends')
      .count()
      .get();
  return snapshot.count ?? 0;
});

/// Stream of incoming friend requests
final incomingFriendRequestsProvider =
    StreamProvider.autoDispose.family<List<FriendRequest>, String>(
        (ref, userId) {
  return firestore
      .collection('users')
      .doc(userId)
      .collection('friendRequests')
      .where('recipientId', isEqualTo: userId)
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('expiresAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => FriendRequest.fromFirestore(doc))
        .toList();
  });
});

/// Stream of outgoing friend requests
final outgoingFriendRequestsProvider =
    StreamProvider.autoDispose.family<List<FriendRequest>, String>(
        (ref, userId) {
  return firestore
      .collection('users')
      .doc(userId)
      .collection('friendRequests')
      .where('senderId', isEqualTo: userId)
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('sentAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => FriendRequest.fromFirestore(doc))
        .toList();
  });
});

/// Get count of pending friend requests
final pendingRequestsCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, userId) async {
  final snapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('friendRequests')
      .where('recipientId', isEqualTo: userId)
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .count()
      .get();
  return snapshot.count ?? 0;
});

/// Get public profile of a player
final playerPublicProfileProvider =
    FutureProvider.autoDispose.family<PlayerPublicProfile, String>(
        (ref, playerId) async {
  final doc = await firestore.collection('users').doc(playerId).get();
  if (!doc.exists) {
    throw Exception('Player not found');
  }
  return PlayerPublicProfile.fromFirestore(doc);
});

/// Search players by name/ID
final searchPlayersProvider = FutureProvider.autoDispose
    .family<List<CompactPlayerProfile>, String>((ref, query) async {
  if (query.isEmpty) {
    return [];
  }

  // Search by display name (prefix search)
  final snapshot = await firestore
      .collection('users')
      .where('displayName', isGreaterThanOrEqualTo: query)
      .where('displayName', isLessThan: query + 'z')
      .limit(20)
      .get();

  return snapshot.docs
      .map((doc) {
        final profile = PlayerPublicProfile.fromFirestore(doc);
        return CompactPlayerProfile.fromPublicProfile(profile);
      })
      .toList();
});

/// Get friend leaderboard (friends sorted by rating)
final friendLeaderboardProvider =
    FutureProvider.autoDispose.family<List<CompactPlayerProfile>, String>(
        (ref, userId) async {
  final friendsSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('friends')
      .get();

  if (friendsSnapshot.docs.isEmpty) {
    return [];
  }

  final friends = friendsSnapshot.docs
      .map((doc) => Friend.fromFirestore(doc))
      .toList();

  // Fetch full profiles for friends
  final List<CompactPlayerProfile> profiles = [];
  for (final friend in friends) {
    try {
      final profileDoc =
          await firestore.collection('users').doc(friend.friendId).get();
      if (profileDoc.exists) {
        final profile = PlayerPublicProfile.fromFirestore(profileDoc);
        profiles.add(CompactPlayerProfile.fromPublicProfile(profile));
      }
    } catch (e) {
      // Skip friends whose profile can't be fetched
      continue;
    }
  }

  // Sort by rating (descending)
  profiles.sort((a, b) => b.rating.compareTo(a.rating));
  return profiles;
});

/// Get friend stats (battles against specific friend)
final friendStatsProvider =
    FutureProvider.autoDispose.family<FriendStats, String>((ref, friendId) async {
  // This will be populated by Cloud Function data
  // For now, return empty stats
  return const FriendStats();
});

/// Provider for checking if a player is a friend
final isFriendProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, otherUserId) async {
  final currentUserId = await ref.watch(currentUserIdProvider.future);
  final friendDoc = await firestore
      .collection('users')
      .doc(currentUserId)
      .collection('friends')
      .doc(otherUserId)
      .get();
  return friendDoc.exists;
});

/// Provider for checking if a friend request exists
final hasFriendRequestProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, otherUserId) async {
  final currentUserId = await ref.watch(currentUserIdProvider.future);
  final query = await firestore
      .collection('users')
      .doc(currentUserId)
      .collection('friendRequests')
      .where('senderId', isEqualTo: currentUserId)
      .where('recipientId', isEqualTo: otherUserId)
      .limit(1)
      .get();
  return query.docs.isNotEmpty;
});

// ============================================================
// Functions for friend management (typically called from UI)
// ============================================================

/// Send a friend request
Future<void> sendFriendRequest({
  required String senderId,
  required String senderName,
  required double senderRating,
  required String recipientId,
  String? message,
}) async {
  final batch = firestore.batch();
  final now = DateTime.now();
  final expiresAt = now.add(const Duration(days: 30));

  final requestId = firestore.collection('temp').doc().id;

  final requestData = {
    'id': requestId,
    'senderId': senderId,
    'senderName': senderName,
    'senderRating': senderRating,
    'recipientId': recipientId,
    'sentAt': Timestamp.fromDate(now),
    'message': message,
    'viewedAt': false,
    'expiresAt': Timestamp.fromDate(expiresAt),
  };

  // Add to recipient's friendRequests
  batch.set(
    firestore
        .collection('users')
        .doc(recipientId)
        .collection('friendRequests')
        .doc(requestId),
    requestData,
  );

  await batch.commit();
}

/// Accept a friend request
Future<void> acceptFriendRequest({
  required String requestId,
  required String userId,
  required String friendId,
  required String friendName,
  required double friendRating,
  required int friendTier,
  required String senderName,
  required double senderRating,
}) async {
  final batch = firestore.batch();
  final now = DateTime.now();

  // Add friend to user's friends list
  batch.set(
    firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(friendId),
    {
      'friendId': friendId,
      'friendName': friendName,
      'friendRating': friendRating,
      'friendTier': friendTier,
      'addedAt': Timestamp.fromDate(now),
      'lastSeenAt': null,
      'group': null,
      'notificationsEnabled': true,
      'customAlias': null,
      'friendBattleCount': 0,
      'friendWinRate': 0.0,
    },
  );

  // Add user to friend's friends list (reciprocal)
  batch.set(
    firestore
        .collection('users')
        .doc(friendId)
        .collection('friends')
        .doc(userId),
    {
      'friendId': userId,
      'friendName': senderName,
      'friendRating': senderRating,
      'friendTier': 1, // Placeholder - should be fetched from Cloud Function
      'addedAt': Timestamp.fromDate(now),
      'lastSeenAt': null,
      'group': null,
      'notificationsEnabled': true,
      'customAlias': null,
      'friendBattleCount': 0,
      'friendWinRate': 0.0,
    },
  );

  // Delete the friend request
  batch.delete(
    firestore
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .doc(requestId),
  );

  await batch.commit();
}

/// Reject a friend request
Future<void> rejectFriendRequest({
  required String requestId,
  required String userId,
}) async {
  await firestore
      .collection('users')
      .doc(userId)
      .collection('friendRequests')
      .doc(requestId)
      .delete();
}

/// Remove a friend
Future<void> removeFriend({
  required String userId,
  required String friendId,
}) async {
  final batch = firestore.batch();

  // Remove from user's friends
  batch.delete(
    firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(friendId),
  );

  // Remove from friend's friends (reciprocal)
  batch.delete(
    firestore
        .collection('users')
        .doc(friendId)
        .collection('friends')
        .doc(userId),
  );

  await batch.commit();
}

/// Cancel a friend request
Future<void> cancelFriendRequest({
  required String requestId,
  required String userId,
}) async {
  await firestore
      .collection('users')
      .doc(userId)
      .collection('friendRequests')
      .doc(requestId)
      .delete();
}

/// Update friend alias/notes
Future<void> updateFriendAlias({
  required String userId,
  required String friendId,
  required String? alias,
}) async {
  await firestore
      .collection('users')
      .doc(userId)
      .collection('friends')
      .doc(friendId)
      .update({'customAlias': alias});
}

/// Update friend group/category
Future<void> updateFriendGroup({
  required String userId,
  required String friendId,
  required String? group,
}) async {
  await firestore
      .collection('users')
      .doc(userId)
      .collection('friends')
      .doc(friendId)
      .update({'group': group});
}

/// Toggle notifications for a friend
Future<void> toggleFriendNotifications({
  required String userId,
  required String friendId,
  required bool enabled,
}) async {
  await firestore
      .collection('users')
      .doc(userId)
      .collection('friends')
      .doc(friendId)
      .update({'notificationsEnabled': enabled});
}
