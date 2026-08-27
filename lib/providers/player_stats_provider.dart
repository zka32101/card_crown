import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/player_profile.dart';
import 'auth_provider.dart';

// プレイヤーの総合統計情報を取得
final playerStatsProvider = FutureProvider<PlayerStats>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return PlayerStats.empty();
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('overall')
        .get();

    if (!doc.exists) {
      return PlayerStats.empty();
    }

    return PlayerStats.fromFirestore(doc.data()!);
  } catch (e) {
    print('Error loading player stats: $e');
    return PlayerStats.empty();
  }
});

// 特定のプレイヤーのプロフィール情報を取得
final playerProfileProvider = FutureProvider.family<PlayerProfile, String>((ref, userId) async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final statsDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('overall')
        .get();

    final stats = statsDoc.exists ? PlayerStats.fromFirestore(statsDoc.data()!) : PlayerStats.empty();

    return PlayerProfile(
      userId: userId,
      displayName: 'Player-${userId.substring(0, 6)}', // 仮名（将来的にカスタム名に対応）
      stats: stats,
      joinedAt: userDoc['createdAt'] as Timestamp? ?? Timestamp.now(),
      tier: _calculateTier(stats.currentRating),
    );
  } catch (e) {
    print('Error loading player profile: $e');
    throw Exception('Failed to load player profile');
  }
});

// レーティングからティアを計算
String _calculateTier(int rating) {
  if (rating >= 2000) return 'Grandmaster';
  if (rating >= 1800) return 'Master';
  if (rating >= 1600) return 'Diamond';
  if (rating >= 1400) return 'Platinum';
  if (rating >= 1200) return 'Gold';
  if (rating >= 1000) return 'Silver';
  return 'Bronze';
}

// プレイヤープロフィール情報をキャッシュ
final myProfileProvider = FutureProvider<PlayerProfile>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  return ref.watch(playerProfileProvider(userId).future);
});
